
classdef MultiPage < handle
    %% Handles the download of data in multiple pages
    % Used by real-time and archivefile services

    properties
        showInfo % (logical) As provided by the Onc class
        timeout  % (int)     As provided by the Onc class
    end
    
	methods
        function this = MultiPage(showInfo, timeout)
            %% Class initializer
            %
            % * showInfo: (logical) As provided by the Onc class
            % * timeout:  (int)     As provided by the Onc class
            this.showInfo = showInfo;
            this.timeout  = timeout;
        end

        function response = getAllPages(this, service, url, filters)
            %% Obtains all data pages for a request with the filters
            % Multiple pages will be downloaded in sequence until completed
            % Each new page gets concatenated to the previous one (limited to RAM)
            %
            % * service: ([char]) One of: 'archivefiles', 'scalardata', 'rawdata'
            % * url:     ([char]) Url to send the request to
            % * filters: (struct) Describes the data origin
            %
            % Returns: (struct) Response with concatenated data for all pages obtained
        
            % extract and remove extension from the filters
            extension = '';
            if strcmp(service, 'archivefiles')
                if isfield(filters, 'extension')
                    extension = filters.extension;
                    filters = rmfield(filters, 'extension');
                end
            end

            % download first page
            tic
            [response, info] = this.doPageRequest(url, filters, service, extension);
            rNext = response.next;

            if ~isempty(rNext)
                fprintf('Data size is greater than the row limit and will be downloaded in multiple pages.\n');

                pageCount = 1;
                pageEstimate = this.estimatePages(response, service);
                if pageEstimate > 0
                    timeEstimate = util.format_duration(pageEstimate * info.duration);
                    fprintf('Estimated approx. %d pages\n', pageEstimate);
                    fprintf('Estimated approx. %s to complete\n', timeEstimate);
                end

                % keep downloading pages until next is None
                fprintf('\n');
                while ~isempty(rNext)
                    pageCount = pageCount + 1;
                    rowCount  = this.rowCount(response, service);

                    fprintf('   (%d samples) Downloading page %d...\n', rowCount, pageCount);
                    r2 = this.doPageRequest(url, rNext.parameters, service, extension);
                    response = this.catenateData(response, r2, service); % concatenate new data obtained

                    rNext = r2.next;
                end

                duration = round(toc, 3);
                rowCount = this.rowCount(response, service);
                response.next = [];
                fprintf('   (%d samples) Completed in %s.\n', rowCount, util.format_duration(duration));
            end
        end

        function [response, info] = doPageRequest(this, url, filters, service, extension)
            %% Do a page request
            % Wraps the util.do_request method
            % Performs additional processing of the response for certain services
            %
            % * url:       ([char]) Url to send the request to
            % * filters:   (struct) Describes the data origin
            % * service:   ([char]) One of: 'archivefiles', 'scalardata', 'rawdata'
            % * extension: ([char]) Extension to filter results with (for archivefiles service)
            %
            % Returns: (struct) httr response and @TODO

            [response, info] = util.do_request(url, filters, 'timeout', this.timeout, 'showInfo', this.showInfo);
            
            if strcmp(service, 'archivefiles')
                response = util.filter_by_extension(response, extension);
            end
        end
        
        function response = catenateData(~, response, nextResponse, service)
            %% Concatenates the data results from nextResponse into response
            % Compatible with the row structure of scalardata, rowdata and archivefiles
            %
            % * response:     (struct) Initial response
            % * nextResponse: (struct) Response with the next data page to add
            % * service:      ([char]) One of: 'scalardata', 'rawdata', 'archivefiles'
            %
            % Returns (struct) Modified original response

            if strcmp(service, 'scalardata')
                keys = fieldnames(response.sensorData(1).data);

                for i = 1 : numel(response.sensorData)
                    sensor = response.sensorData(i);
                    sensorCode = sensor.sensorCode;

                    % get next page for this sensor (same sensorCode)
                    nextSensor = struct();
                    for i2 = 1 : numel(nextResponse.sensorData)
                        nextSensor = nextResponse.sensorData(i2);
                        if strcmp(nextSensor.sensorCode, sensorCode)
                            % append all keys and stop
                            concatenatedStruct = {};
                            for j = 1 : numel(keys)
                                key = keys{j};
                                sensorData = sensor.data.(key);
                                if isa(sensorData, 'char')
                                    if isempty(char(sensor.data.(key)))
                                        sensorData = repmat({''}, size(sensor.data, 1), 1);
                                    else
                                        sensorData = cellstr(char(sensor.data.(key)));
                                    end
                                elseif length(sensorData) == 1
                                    sensorData = [sensor.data.(key)].';
                                end
                                nextSensorData = nextSensor.data.(key);
                                if isa(nextSensorData, 'char')
                                    nextSensorData = cellstr(char(nextSensor.data.(key)));
                                elseif length(nextSensorData) == 1
                                    nextSensorData = [nextSensor.data.(key)].';
                                end
                                concatenatedStruct.(key) = [sensorData; nextSensorData];
                            end
                            % if non-scalar struct array, return the same
                            if size(response.sensorData(i).data, 1) > 1
                                concatenatedStruct = table2struct(struct2table(concatenatedStruct));
                            end
                            response.sensorData(i).data = concatenatedStruct;
                            break;
                        end
                    end
                end
                
            elseif strcmp(service, 'rawdata')
                keys = fieldnames(response.data);
                concatenatedStruct = {};
                for i = 1 : numel(keys)
                    key = keys{i};
                    responseData = response.data.(key);
                    if isa(responseData, 'char')
                        if isempty(char(response.data.(key)))
                            responseData = repmat({''}, size(response.data, 1), 1);
                        else
                            responseData = cellstr(char(response.data.(key)));
                        end
                    elseif length(responseData) == 1
                        responseData = [response.data.(key)].';
                    end
                    nextResponseData = nextResponse.data.(key);
                    if isa(nextResponseData, 'char')
                        nextResponseData = cellstr(char(nextResponse.data.(key)));
                    elseif length(nextResponseData) == 1
                        nextResponseData = [nextResponse.data.(key)].';
                    end
                    concatenatedStruct.(key) = [responseData; nextResponseData];
                end
                if size(response.data, 1) > 1
                    concatenatedStruct = table2struct(struct2table(concatenatedStruct));
                end
                response.data = concatenatedStruct;
            elseif strcmp(service, 'archivefiles')
                response.files = [response.files; nextResponse.files];
            end
        end

        function pages = estimatePages(this, response, service)
            %% Estimates the total pages this request will require to download
            % from the first page's response
            %
            % * response (struct) Response with the first page
            % * service  ([char]) One of: 'scalardata', 'rawdata', 'archivefiles'
            %
            % Returns (int) Estimated number of pages
            
            % timespan (secs) covered by the data in the response
            pageTimespan = this.responseTimespan(response, service);
            if pageTimespan == 0
                pages = 0;
                return;
            end

            % total timespan to cover
            params  = response.next.parameters;
            tsBegin = util.datestring_2_secs(params.dateFrom);
            tsEnd   = util.datestring_2_secs(params.dateTo);
            totalSeconds = tsEnd - tsBegin;

            % handle cases of very small timeframes
            pageSeconds  = max(pageTimespan, 1);

            pages = ceil(totalSeconds / pageSeconds);
        end

        function count = rowCount(~, response, service)
            %% Returns the number of rows or samples in the response
            %
            % * response (struct) Parsed response
            % * service  ([char]) One of: 'scalardata', 'rawdata', 'archivefiles'
            %
            % Returns: (int) Number of rows or samples per sensor
            switch service
                case "scalardata"
                    if isfield(response.sensorData(1).data, 'sampleTime')
                        sampleTime = response.sensorData(1).data.sampleTime;
                    else
                        sampleTime = response.sensorData(1).data.sampleTimes;
                    end
                    if isa(sampleTime, 'cell')
                        count = length(sampleTime);
                    else
                        count = length({response.sensorData(1).data.sampleTime});
                    end
                case "rawdata"
                    if isfield(response.data, 'times')
                        count = length(response.data.times);
                    else
                        sampleTime = response.data.sampleTime;
                        if isa(sampleTime, 'cell')
                            count = length(sampleTime);
                        else
                            count = length({response.data.sampleTime});
                        end
                    end
                case "archivefiles"
                    count = length(response.files);
                otherwise
                    count = 0;
            end
        end

        function secs = responseTimespan(~, response, service)
            %% Returns the timespan covered by the data in the response
            %
            % * response: (struct) Parsed response
            % * service:  ([char]) One of: 'scalardata', 'rawdata', 'archivefiles'
            %
            % Returns: (float) date interval duration in seconds covered by this response
            isScalar  = strcmp(service, 'scalardata');
            isRaw     = strcmp(service, 'rawdata');
            isArchive = strcmp(service, 'archivefiles');
            
            % grab the first and last sample times
            if isScalar || isRaw
                if isScalar
                    if isfield(response.sensorData(1).data, 'sampleTime')
                        sampleTimes = {response.sensorData(1).data.sampleTime};
                    else
                        sampleTimes = response.sensorData(1).data.sampleTimes;
                    end
                    first = sampleTimes{1};
                    last  = sampleTimes{end};
                else
                    if isfield(response.data, 'sampleTime')
                        sampleTimes = {response.data.sampleTime};
                    elseif isfield(response.data, 'sampleTimes')
                        sampleTimes = response.data.sampleTimes;
                    elseif isfield(response.data, 'times')
                        sampleTimes = response.data.times;
                    else
                        sampleTimes = {response.data.time};
                    end
                    first = sampleTimes(1);
                    last  = sampleTimes(end);
                end    
            elseif isArchive
                row0 = response.files(1);
                rowEnd = response.files(end);
                
                if isa(row0, 'char') || iscell(row0)
                    % extract the date from the filename
                    regExp  = '\\d{8}T\\d{6}d\\.\\d{3}Z';
                    nameFirst = char(row0);
                    nameLast  = char(rowEnd);
                    mFirst = regexp(nameFirst, regExp, 'once', 'match');
                    mLast  = regexp(nameLast,  regExp, 'once', 'match');
                    if isempty(mFirst) || isempty(mLast)
                        secs = 0;
                        return;
                    end
                    first = mFirst(1);
                    last  = mLast(1);
                else
                    first = response.files(1).dateFrom;
                    last  = response.files(end).dateFrom;
                end
            end

            % compute the timespan, return as duration object
            tsFirst = util.datestring_2_secs(first);
            tsLast  = util.datestring_2_secs(last);
            
            secs = tsLast - tsFirst;
        end
    end
end
