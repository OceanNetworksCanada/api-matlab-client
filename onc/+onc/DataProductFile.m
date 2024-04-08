classdef DataProductFile < handle
    %% Encapsulates the download of a single data product file
    % and the handling of the server polling and error codes.

    properties
       filters          % (struct)  The list of filters to pass to the download API method
       retries          % (int)     Total count of HTTP requests made by this object
       status           % (int)     Last request's HTTP status code
       downloaded       % (logical) true if the file was downloaded from the API
       baseUrl          % ([char])  String provided by the Onc class
       downloadUrl      % ([char])  URL that downloads this file
       fileName         % ([char])  Filename of the file if downloaded & saved
       fileSize         % (logical) Size in bytes of the file if downloaded & saved
       runningTime      % (float)   Total time spent running (sec)
       downloadingTime  % (float)   Total time spend downloading (sec)
       showInfo         % (logical) Flag provided by the Onc class
    end
	methods
        %% Class initializer
        %
        % * dpRunId  (int)    Run Id of a data product request that was run
        % * index    ([char]) Index of this object's file
        % * baseUrl  ([char]) As provided by the Onc class
        % * token    ([char]) As provided by the Onc class
        % * showInfo ([char]) As provided by the Onc class
        function this = DataProductFile(dpRunId, index, baseUrl, token, showInfo)
            this.retries     = 0;
            this.status      = 202;
            this.downloaded  = false;
            this.baseUrl     = sprintf('%sapi/dataProductDelivery', baseUrl);
            this.fileName    = char('');
            this.fileSize    = 0;
            this.runningTime = 0;
            this.showInfo    = showInfo;
            this.downloadingTime = 0.0;
            
            this.filters = struct(     ...
                'method' , 'download', ...
                'token'  , token,      ...
                'dpRunId', dpRunId,    ...
                'index'  , index);
            
            % prepopulate download URL in case download() never happens
            this.downloadUrl = sprintf('%s?method=download&token=%s&dpRunId=%d&index=%s', ...
                               baseUrl, token, dpRunId, index);
        end

            
        function endStatus = download(this, timeout, pollPeriod, outPath, maxRetries, overwrite)
            %% Downloads this data product file
            % Can poll, wait and retry if the file is not ready to download
            %
            % * overwrite:  (logical) When true, existing files will be overwritten, otherwise they are skipped
            % * timeout:    (int)     As provided by the Onc class
            % * pollPeriod: (float)   As provided by the Onc class
            % * outPath:    ([char])  As provided by the Onc class
            % * maxRetries: (int)     As provided by the Onc class
            %
            % Returns: (integer) The final response's HTTP status code
            
            log = onc.DPLogger();
            this.status = 202;
            request = matlab.net.http.RequestMessage;
            uri = matlab.net.URI(this.baseUrl);
            uri.Query = matlab.net.QueryParameter(this.filters);
            fullUrl = char(uri);
            options = matlab.net.http.HTTPOptions('ConnectTimeout', timeout);
            while this.status == 202
                % run and time request
                if this.showInfo, log.printLine(sprintf('Requesting URL:\n   %s', fullUrl)); end
                tic
                response  = request.send(uri,options);
                duration = toc;
                
                this.downloadUrl = fullUrl;
                this.status      = response.StatusCode;
                this.retries     = this.retries + 1;

                if maxRetries > 0 && this.retries > maxRetries
                    log.printLine(sprintf('ERROR: Maximum number of retries (%d) exceeded', maxRetries));
                    endStatus = 408;
                    return
                end

                % Status 200: file downloaded, 202: processing, 204: no data, 400: error, 404: index out of bounds, 410: gone (file deleted from FTP)
                s = this.status;
                if s == 200
                    % File downloaded, get filename from header and save
                
                    this.downloaded = true;
                    filename        = this.extractNameFromHeader(response);
                    this.fileName   = filename;
                    
                    % Obtain filesize from headers, or fallback to body string length
                    lengthData = response.getFields('Content-Length');
                    if length(lengthData) == 1
                        this.fileSize = str2double(lengthData.Value);
                    else
                        ext = util.extractFileExtension(filename);
                        if strcmp(ext, 'xml')
                            this.fileSize = length(xmlwrite(response.Body.Data));
                        else
                            this.fileSize = strlength(response.Body.Data);
                        end
                    end
                    try
                        saveResult = util.save_as_file(response.Body.Data, outPath, filename, 'overwrite', overwrite);
                    catch ME
                        if strcmp(ME.identifier, 'onc:FileExistsError')
                            log.printLine(sprintf('Skipping "%s": File already exists\n', this.fileName));
                            this.status = 777;
                            saveResult = -2;
                            this.downloaded = false;
                        else
                            rethrow(ME);
                        end
                    end
                    this.downloadingTime = round(duration, 3);

                    % log status
                    if saveResult == 0
                        log.printLine(sprintf('Downloaded "%s"\n', this.fileName));
                    end
                elseif s == 202
                    % Still processing, wait and retry
                    log.printResponse(response.Body.Data);
                    pause(pollPeriod);
                elseif s == 204
                    % No data found
                    log.printLine('No data found.\n');
                elseif s == 400
                    % API Error
                    util.print_error(response, fullUrl);
                    throw(util.prepare_exception(s, double(response.Body.Data.errors.errorCode)));
                elseif s == 404
                    % Index too high, no more files to download
                else
                    % File is gone
                    log.printLine(sprintf('ERROR: File with runId %d and index "%s" not found\n', ...
                                  this.filters.dpRunId, this.filters.index));
                    util.print_error(response, fullUrl);
                end
            end

            endStatus = this.status;
        end

        function filename = extractNameFromHeader(~,response)
            %% Return the file name extracted from the HTTP response
            %
            % * response (object) The successful (200) httr response obtained from a download request
            %
            % Returns: ([char]) The filename as obtained from the headers
            txt = response.getFields('Content-Disposition').Value;
            tokens = split(txt, 'filename=');
            filename = tokens(2);
        end

        function info = getInfo(this)
            %% Return information on this download's outcome
            %
            % Returns: ([struct]) A vector of structs with information on the download result
            errorCodes = containers.Map(...
                {'200', '202', '204', '400', '401', '404', '410', '500', '777'}, ...
                {'complete', 'running', 'no content', 'error', 'unauthorized', 'not found', ...
                'gone', 'server error', 'skipped'});

            txtStatus = errorCodes(string(this.status));
            
            filename = this.fileName;
            if isempty(this.fileName)
                filename = '';
            end

            info = struct( ...
                'url'             , this.downloadUrl,         ...
                'status'          , txtStatus,                ...
                'statusCode'      , this.status,              ...
                'size'            , this.fileSize,            ...
                'file'            , char(filename),           ...
                'index'           , char(this.filters.index), ...
                'downloaded'      , this.downloaded,          ...
                'requestCount'    , this.retries,             ...
                'fileDownloadTime', this.downloadingTime);
        end

        function this = setComplete(this)
            %% Sets this object's status to 200 (complete)
            % Used by onc_delivery methods
            this.status = 200;
        end
    end
end
