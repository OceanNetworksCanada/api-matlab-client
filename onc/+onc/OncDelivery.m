classdef OncDelivery < onc.Service
    %% Functionality that wraps the API data product delivery services
    % To be inherited by the Onc class
    
    properties (SetAccess = protected)
        % Default seconds to wait between consecutive download tries of a file
        % (when no estimate processing time is available)
        pollPeriod = 2.0
    end

    methods (Access = public)
        function [r, status] = orderDataProduct(this, filters, varargin)
            %% Request, run and download a data product as described by the filters
            %
            % orderDataProduct(filters, maxRetries, downloadResultsOnly, includeMetadataFile)
            %
            % * filters:    (struct)  Describes the data origin
            % - maxRetries: (int)     Total maximum number of request calls allowed, 0 for no limit
            % - downloadResultsOnly:  (logical) When true, files are not downloaded
            %                         By default (false) generated files are downloaded
            % - metadata:   (logical) When true, a metadata file is downloaded,
            %                         otherwise it is skipped
            % - overwrite:  (logical) When true downloaded files will overwrite any file
            %                         with the same filename, otherwise they will be skipped
            %
            % Returns: [struct] A list of results (one named list for each file) with
            %                   information on the operation outcome
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLIBS/Data+product+download+methods
            [maxRetries, downloadResultsOnly, metadata, overwrite] = util.param(varargin, ...
                'maxRetries', 0, 'downloadResultsOnly', false, 'includeMetadataFile', true, 'overwrite', false);

            fileList = [];

            % Request the product
            [rqData, ~] = this.requestDataProduct(filters);

            % Run the product request
            [runData, status] = this.runDataProduct(rqData.dpRequestId);


            if downloadResultsOnly
                % Only run and return links
                for i = 1 : numel(runData.runIds)
                    runId = runData.runIds(i);
                    fileList = [fileList, this.infoForProductFiles(runId, runData.fileCount, metadata)];
                end
            else
                % Run and download files
                for i = 1 : numel(runData.runIds)
                    runId = runData.runIds(i);
                    fileList = [fileList, this.downloadProductFiles(runId, metadata, maxRetries, overwrite)];
                end
            end

            fprintf('\n');
            this.printProductOrderStats(fileList, runData);
            r = this.formatResult(fileList, runData);
        end

        function [r, status] = requestDataProduct(this, filters)
            %% Request a data product generation described by the filters
            %
            % requestDataProduct(filters)
            %
            % * filters (struct) Filters that describe this data product
            %
            % Returns: (struct) Parsed httr response
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Data+product+download+methods
            filters = util.sanitize_filters(filters);
            filters.method = 'request';
            filters.token  = this.token;

            url = sprintf('%sapi/dataProductDelivery', this.baseUrl);
            fprintf('Requesting data product...\n');
            [r, info] = this.doRequest(url, filters);
            status = info.status;
            this.estimatePollPeriod(r);
            this.printProductRequest(r);

        end

        function [r, status] = runDataProduct(this, dpRequestId, waitComplete)
            %% Run a data product generation request
            %
            %
            % runDataProduct (dpRequestId)
            %
            % * dpRequestId (int) Request id obtained by requestDataProduct()
            % - waitComplete: wait until dp finish when set to true (default)
            %
            % Returns: (struct) information of the run process
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLIBS/Data+product+download+methods
            
            if ~exist('waitComplete','var'), waitComplete = true; end
            url = sprintf('%sapi/dataProductDelivery', this.baseUrl);
            log = onc.DPLogger();

            r = struct('runIds', [], 'fileCount', 0, 'runTime', 0, 'requestCount', 0);
            filters = struct('method', 'run', 'token', this.token, 'dpRequestId', dpRequestId);

            % run timed run request
            tic
            cancelUrl = url + "?method=cancel&token="+string(this.token)+"&dpRequestId=" + string(dpRequestId);
            if waitComplete
                fprintf('\nTo cancel this data product, visit url:\n   %s\n', cancelUrl);
            else
                fprintf('\nTo cancel this data product, please execute command ''onc.cancelDataProduct(%d)''\n', dpRequestId)
            end
            flag = 'queued';
            while ~strcmp(flag,'complete') && ~strcmp(flag,'cancelled')
                [response, info] = this.doRequest(url, filters);
                status = info.status;
                r.requestCount = r.requestCount + 1;
                
                % repeat only if waitComplete
                if waitComplete
                    log.printResponse(response);
                    if status == 202
                       pause(this.pollPeriod); 
                    end
                else
                    break;
                end
                flag = response.status;
            end
            duration = toc;
            fprintf('\n')

            % prepare response
            r.fileCount = response(1).fileCount;
            r.runTime   = round(duration, 3);

            % gather a list of runIds
            for i = 1 : numel(response)
                run = response(i);
                r.runIds = [r.runIds, run.dpRunId];
            end
        end
        
        function response = checkDataProduct(this, dpRequestId)
            %% Check the status of a data product
            %
            %
            % checkDataProduct (dpRequestId)
            %
            % * dpRequestId (int) Request id obtained by requestDataProduct()
            %
            % Returns: response (struct): status of this data product
            %
            url = sprintf('%sapi/dataProductDelivery', this.baseUrl);
            filters = struct('method', 'status', 'token', this.token, 'dpRequestId', dpRequestId);
            response = this.doRequest(url, filters);
        end

        function [response, info] = cancelDataProduct(this, dpRequestId)
            %% Cancel a running data product
            %
            %
            % cancelDataProduct (dpRequestId)
            %
            % * dpRequestId (int) Request id obtained by requestDataProduct()
            %
            % Returns: response (struct): cancel process status and message
            %          info (struct): cancel process http code and status
            %
            url = sprintf('%sapi/dataProductDelivery', this.baseUrl);
            filters = struct('method', 'cancel', 'token', this.token, 'dpRequestId', dpRequestId);
            [response, info] = this.doRequest(url, filters);
            if isfield(response, 'status') && strcmp(response.status, 'cancelled') && info.status == 200
                fprintf("The data product with request id %d and run id %d has been successfully cancelled\n", dpRequestId, response.dpRunId);
            else
                fprintf("Failed to cancel the data Product.");
            end
        end

        function fileData = downloadDataProduct(this, runId, varargin)
            %% Download a data product manually with a runId
            % Can optionally return just the download links
            %
            % downloadDataProduct(runId, maxRetries, downloadResultsOnly, includeMetadataFile, overwrite)
            %
            % * runId               (int)     Run ID as provided by runDataProduct()
            % - maxRetries          (int)     Maximum number of API requests allowed, 0 for no limit
            % - downloadResultsOnly (logical) When true, files are not downloaded
            %                                 By default (false) generated files are downloaded
            % - includeMetadataFile (logical) When true, a metadata file is downloaded,
            %                                 otherwise it is skipped
            % - overwrite           (logical) When true downloaded files will overwrite any file
            %                                 with the same filename, otherwise they will be skipped
            %
            % Returns: [struct] A list of results (one struct for each downloaded file) with
            %          information on the operation outcome
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLIBS/Data+product+download+methods
            [maxRetries, downloadResultsOnly, metadata, overwrite] = util.param(varargin, ...
                'maxRetries', 0, 'downloadResultsOnly', false, 'includeMetadataFile', true, 'overwrite', false);

            if downloadResultsOnly
                fileData = this.infoForProductFiles(runId, 0, metadata);
            else
                fileData = this.downloadProductFiles(runId, metadata, maxRetries, overwrite);
            end
        end

        function [response, info] = restartDataProduct(this, dpRequestId, waitComplete)
            %% Restart a cancelled data product
            %
            %
            % restartDataProduct (dpRequestId, waitComplete)
            %
            % * dpRequestId (int) Request id obtained by requestDataProduct()
            % - waitComplete (optional): wait until dp finish when set to true (default)
            %
            % Returns: response (struct): restart process status and message
            %          info (struct): restart process http code and status
            %
            if ~exist('waitComplete','var'), waitComplete = true; end 
            url = sprintf('%sapi/dataProductDelivery', this.baseUrl);
            filters = struct('method', 'restart', 'token', this.token, 'dpRequestId', dpRequestId);
            [response, info] = this.doRequest(url, filters);
            if isfield(response, 'status') && (strcmp(response.status, 'data product running') || strcmp(response.status, 'queued')) && info.status == 200
                fprintf("The data product with request id %d and run id %d has been successfully restarted\n", dpRequestId, response.dpRunId);
            else
                fprintf("Failed to restart the data product");
            end
            if waitComplete
                [response, info] = this.runDataProduct(dpRequestId, true);
            end
        end
    end
        
    methods (Access = private, Hidden = true)
        function fileList = downloadProductFiles(this, runId, varargin)
            %% Download all data product files for provided run id
            %
            % * runId       (int)     Run id returned by runDataProduct()
            % - getMetadata (logical) When true, the metadata file will be downloaded
            % - maxRetries  (int)     Maximum number of API requests allowed, 0 for no limit
            % - overwrite   (logical) When true downloaded files will overwrite any file
            %                         with the same filename, otherwise they will be skipped
            % - fileCount   (int)     The number of files to download, or 0 if unknown
            %
            % Returns: ([struct]) a list of results for each file
            [getMetadata, maxRetries, overwrite, fileCount] = util.param(varargin, ...
                'getMetadata', true, 'maxRetries', 0, 'overwrite', true, 'fileCount', 0);

            fileList = [];
            index    = 1;
            baseUrl  = this.baseUrl;
            token    = this.token;
            outPath  = this.outPath;

            % keep increasing index until fileCount or until we get 404
            timeout = this.timeout;
            fprintf('\nDownloading data product files with runId %d...\n', runId);
            dpf = onc.DataProductFile(runId, string(index), baseUrl, token, this.showInfo);

            % loop thorugh file indexes
            doLoop = true;
            while doLoop
                status = dpf.download(timeout, this.pollPeriod, outPath, maxRetries, overwrite);

                if status == 200 || status == 777
                    % file was downloaded (200), or downloaded & skipped (777)
                    fileList = [fileList, dpf.getInfo()];
                    index    = index + 1;
                    dpf      = onc.DataProductFile(runId, string(index), baseUrl, token, this.showInfo);
                elseif status ~= 202 || (fileCount > 0 && index >= fileCount)
                    % no more files to download
                    doLoop = false;
                end
            end

            % get metadata if required
            if getMetadata
                dpf = onc.DataProductFile(runId, 'meta', baseUrl, token, this.showInfo);
                status = dpf.download(timeout, this.pollPeriod, outPath, maxRetries, overwrite);
                if status ~= 200
                    fprintf('\n   Metadata file was not downloaded\n');
                end
                fileList = [fileList, dpf.getInfo()];
            end
            fprintf('\nDownload process finished.\n');
        end


        function fileList = infoForProductFiles(this, dpRunId, varargin)
            %% Returns a list of information lists for each file available for download
            % Returned rows will have the same structure as those returned by DataProductFile.getInfo()
            %
            % * dpRunId     (int)     Run id returned by runDataProduct()
            % - fileCount   (int)     The number of files to download, or 0 if unknown
            % - getMetadata (logical) When true, the metadata file will be included
            %
            % Returns: ([struct]) List of results for each file
            [fileCount, getMetadata] = util.param(varargin, 'fileCount', 0, 'getMetadata', false);
            
            % If we don't know the fileCount, get it from the server (takes longer)
            if fileCount <= 0
                fprintf('\nObtaining download information for data product files with runId %d...\n', dpRunId)
                fileCount = this.countFilesInProduct(dpRunId);
            end
            fprintf('   %d files available for download', fileCount);

            % Build a file list of data product file information
            % populate backwards to pre-allocate memory in matlab
            for i = fileCount : -1 : 1
                indexes(i) = string(i);
            end
            if getMetadata
                indexes = [indexes, "meta"];
            end
            
            % populate backwards to pre-allocate memory
            n = numel(indexes);
            for i = n : -1 : 1
                index = indexes(i);
                dpf = onc.DataProductFile(dpRunId, index, this.baseUrl, this.token, this.showInfo);
                dpf.setComplete();
                fileList(i) = dpf.getInfo();
            end
        end

        function n = countFilesInProduct(this, runId)
            %% Given a runId, polls the 'download' method to count the number of files available
            % Uses HTTP HEAD to avoid downloading the files
            %
            % * runId (int) Run id returned by runDataProduct()
            %
            % Returns: (int) Number of files available for download
            base = sprintf('%sapi/dataProductDelivery?method=download&dpRunId=%d&token=%s', ...
                            this.baseUrl, runId, this.token);
            status = 200;
            n = 0;

            index = 1;
            while ((status == 200) || (status == 202))
                fileUrl = sprintf('%s&index=%d', base, index);
                status = util.test_url(fileUrl, this.showInfo, this.timeout);
                
                if status == 200
                    % count successful HEAD request
                    index = index + 1;
                    n = n + 1;
                elseif status == 202
                    % If the file is still running, wait
                    pause(this.pollPeriod);
                end
            end
        end

        function this = estimatePollPeriod(this, response)
            %% Sets a poll period adequate to the estimated processing time
            % Longer processing times require longer poll periods to avoid going over maxRetries
            %
            % - response (object) Response obtained in requestDataProduct() for the DP request
            %
            % Returns: (int) suggested time between server polls (seconds)
            if isfield(fieldnames(response), 'estimatedProcessingTime')
                % Parse estimated processing time (if the API returns it, which is
                % not the case with archived data products)
                txtEstimated = response.estimatedProcessingTime;
                parts = split(txtEstimated, ' ');
                if length(parts) == 2
                    unit = parts(2);
                    factor = 1;
                    if unit == "min"
                        factor = 60;
                    elseif unit == "hour"
                        factor = 3600;
                    end
                    total = factor * str2double(parts(1));
                    period = max(0.02 * total, 1.0); % poll every 2%

                    % set an upper limit to pollPeriod [sec]
                    period = min(period, 1);
                    this.pollPeriod = period;
                end
            end
        end
        
        function printProductOrderStats(~, fileList, runInfo)
            %% Prints a formatted representation of the total time and size downloaded
            % after the product order finishes
            %
            % * fileList ([struct]) As returned by downloadProductFiles()
            % * runInfo  ([struct]) As returned by runDataProduct()
            downloadCount = 0;
            downloadTime  = 0;
            size = 0;

            for i = 1 : numel(fileList)
                file = fileList(i);
                size = size + file.size;

                if file.downloaded
                    downloadCount = downloadCount + 1;
                    downloadTime  = downloadTime  + file.fileDownloadTime;
                end
            end

            % Print run time
            runSeconds = runInfo.runTime;
            fprintf('\nTotal run time: %s\n', util.format_duration(runSeconds));

            % Print download time
            if downloadCount > 0
                if downloadTime < 1.0
                    txtDownTime = sprintf('%.3f seconds', downloadTime);
                else
                    txtDownTime = util.format_duration(downloadTime);
                end
                fprintf('Total download Time: %s\n', txtDownTime);

                % Print size and count of files
                fprintf('%d files (%s) downloaded\n', downloadCount, util.format_size(size))
            else
                fprintf('No files downloaded.\n')
            end
        end


        function printProductRequest(~, response)
            %% Prints the response after a data product request
            % The request response format might differ depending on the product origin
            % as it can be 'assembled' on the fly, or reused from existing products
            %
            % * response (object) Parsed httr response
            isGenerated = isfield(response, 'estimatedFileSize');
            fprintf('Request Id: %d\n', response.dpRequestId);

            if isGenerated
                size = response.estimatedFileSize; % API returns it as a formatted string
                fprintf('Estimated File Size: %s\n', size);

                if isfield(response, 'estimatedProcessingTime')
                    fprintf('Estimated Processing Time: %s\n', response.estimatedProcessingTime)
                else
                    size = util.format_size(response.fileSize);
                    fprintf('File Size: %s\n', size);
                    fprintf('Data product is ready for download.\n');
                end
            end
        end

        function result = formatResult(~, fileList, runInfo)
            %% Aggregates individual download results obtained in orderDataProduct()
            % into a list of formatted results to return, and a named list with
            % general stats of the operation
            %
            % * fileList ([struct]) List of individual download results
            % * runInfo  (struct)   As returned by runDataProduct()
            %
            % Returns: ([struct]) A list with 'downloadResults' (list of download results) and
            %         'stats' (general stats for the full operation)
            size = 0;
            downloadTime = 0;
            requestCount = runInfo.requestCount;

            for i = 1 : numel(fileList)
                file = fileList(i);
                downloadTime = downloadTime + file.fileDownloadTime;
                size         = size + file.size;
                requestCount = requestCount + file.requestCount;
            end

            result = struct( ...
                'downloadResults', fileList, ...
                'stats', struct( ...
                    'runTime'     , round(runInfo.runTime, 3), ...
                    'downloadTime', round(downloadTime, 3), ...
                    'requestCount', requestCount, ...
                    'totalSize'   , size));
        end
    end
end
