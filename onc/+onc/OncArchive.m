classdef OncArchive < onc.Service
    %% Contains the functionality that wraps API archivefile services
    % To be inherited by the Onc class
    
    methods (Access = public)
        function fileList = getListByLocation(this, filters, varargin)
            %% Get a list of files for a given location and device category
            % filtered by other optional parameters.
            % 
            % getListByLocation(filters, allPages)
            %
            % - filters:  (struct)  Describes the data origin
            % - allPages: (logical) When true, if the data is too long to fit a single request,
            %                       multiple pages will be requested until all data is obatined
            %
            % Returns: ([struct]) File list obtained
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Archive+file+download+methods
            
            [allPages] = util.param(varargin, 'allPages', false);
            fileList = this.getList(filters, 'location', allPages);
        end

        function r = getListByDevice(this, filters, varargin)
            %% Get a list of files for a given device
            % filtered by other optional parameters.
            % 
            % getListByDevice(filters, allPages)
            %
            % * filters:  (struct)  Describes the data origin
            % * allPages: (logical) When true, if the data is too long to fit a single request,
            %                       multiple pages will be requested until all data is obatined
            %
            % Returns: ([struct]) File list obtained
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Archive+file+download+methods
            
            [allPages] = util.param(varargin, 'allPages', false);
            r = this.getList(filters, 'device', allPages);
        end

        function fileInfo = getFile(this, filename, varargin)
            %% Download the archive file identified by filename
            % 
            % getFile(filename, overwrite)
            %
            % * filename:  [char]    Archive file filename
            % - overwrite: (logical) When true, downloaded files will overwrite any file with the
            %                        same filename, otherwise file will be skipped
            %
            % Returns: (struct) Information on the download result
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Archive+file+download+methods
            if ~exist('filename', 'var')
                filename = '';
            end
            [overwrite, showMsg] = util.param(varargin, 'overwrite', false, 'showMsg', true);
            
            url = this.serviceUrl('archivefiles');
            filters = struct('token', this.token,'method', 'getFile', 'filename', filename);
            
            if showMsg, fprintf('Downloading file "%s"...\n', filename); end
            
            [response, info] = ...
                util.do_request(url, filters, 'timeout', this.timeout, 'showInfo', this.showInfo, ...
                                'showProgress', true);

            if not(info.status == 200)
                %fileInfo = jsondecode(response);
                fileInfo = response;
                return;
            end

            outPath    = this.outPath;
            saveStatus = util.save_as_file(response, outPath, filename, overwrite);

            txtStatus  = 'error';
            if info.status == 200
                if saveStatus == 0
                    txtStatus = 'completed';
                    if showMsg, fprintf('   File was downloaded to "%s"\n', filename); end
                end

                fullUrl = this.getDownloadUrl(filename);
                fileInfo = struct(             ...
                    'url'         , fullUrl,   ...
                    'status'      , txtStatus, ...
                    'size'        , info.size, ...
                    'downloadTime', round(info.duration, 3), ...
                    'file'        , filename);

                return;
            end

            fileInfo = struct( ...
                'url'         , "",        ...
                'status'      , txtStatus, ...
                'size'        , 0,         ...
                'downloadTime', 0,         ...
                'file'        , "");
        end


        function results = getDirectFiles(this, filters, varargin)
            %% Downloads all archive files that match the filters
            % Uses geListByDevice or getListByLocation to get a file list, then getFile's everything
            % 
            % getDirectFiles(filters, overwrite, allPages)
            %
            % * filters:   (struct)  Describes the data origin
            % - allPages:  (logical) When true, if the data is too long to fit a single request,
            %                        multiple pages will be requested until all data is obatined
            % - overwrite: (logical) When true, downloaded files will overwrite any file with the
            %                        same filename, otherwise file will be skipped
            %
            % Returns: [struct] Information on the results of the operation, with 'downloadResults'
            %          for each file downloaded and general 'stats'
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Archive+file+download+methods
            [overwrite, allPages] = util.param(varargin, 'overwrite', false, 'allPages', false);
            
            % Sanitize filters
            filters = util.sanitize_filters(filters);

            % make sure we only get a simple list of files
            if isfield(filters, 'returnOptions')
                filters = rmfield(filters, 'returnOptions');
            end

            % Get a list of files
            if isfield(filters, 'locationCode') && isfield(filters, 'deviceCategoryCode')
                dataRows = this.getListByLocation(filters, allPages);
            elseif isfield(filters, 'deviceCode')
                dataRows = this.getListByDevice(filters, allPages);
            else
                msg = 'ERROR: getDirectFiles filters require either a combination of (locationCode)';
                msg = [msg ' and (deviceCategoryCode), or a (deviceCode) present.'];
                error('Archive:InvalidFilters', msg);
            end

            n = length(dataRows.files);
            fprintf('Obtained a list of %d files to download.\n', n);

            % Download the files obtained
            tries = 1;
            successes = 0;
            size = 0;
            time = 0;
            downInfos = [];
            for i = 1 : numel(dataRows.files)
                firstCell = dataRows.files(i);
                filename  = firstCell{1};

                % only download if file doesn't exist (or overwrite is True)
                outPath  = this.outPath;
                filePath = sprintf('%s/%s', outPath, filename);
                fileExists = isfile(filePath);

                if not(fileExists) || (fileExists && overwrite)
                    fprintf('   (%d of %d) Downloading file: "%s"\n', tries, n, filename);
                    downInfo = this.getFile(filename, overwrite, 'showMsg', false);

                    % Skip this file if the request failed
                    if util.is_failed_response(downInfo)
                        fprintf('   Skipping "%s" due to an error.\n', filename);
                        tries = tries + 1;
                        errorInfo = struct( ...
                            'url'         , this.getDownloadUrl(filename), ...
                            'status'      , 'error', ...
                            'size'        , 0,       ...
                            'downloadTime', 0,       ...
                            'file'        , "");
                        downInfos = [downInfos, errorInfo];
                        continue;
                    end

                    size  = size + downInfo.size;
                    time  = time + downInfo.downloadTime;
                    tries = tries + 1;

                    if strcmp(downInfo.status, 'completed')
                        successes = successes + 1;
                    end
                    downInfos = [downInfos, downInfo];
                else
                    fprintf('   Skipping "%s": File already exists.\n', filename);
                    downInfo = struct( ...
                        'url'         , getDownloadUrl(this, filename), ...
                        'status'      , 'skipped', ...
                        'size'        , 0,         ...
                        'downloadTime', 0,         ...
                        'file'        , filename);
                    downInfos = [downInfos, downInfo];
                end
            end

            fprintf('%d files (%s) downloaded\n', successes, util.format_size(size));
            fprintf('Total Download Time: %s\n', util.format_duration(time));

            results = struct( ...
                'downloadResults', downInfos, ...
                'stats', struct(              ...
                    'totalSize'   , size,     ...
                    'downloadTime', time,     ...
                    'fileCount'   , successes));
        end
    end
    
    methods (Access = private, Hidden = true)
        function url = getDownloadUrl(this, filename)
            %% Given a filename, returns an archivefile absolute download URL
            %
            % * filename: [char] Archive file name
            %
            % Returns: [char] Download URL
            base = this.serviceUrl('archivefiles');
            url = sprintf('%s?method=getFile&filename=%s&token=%s', base, filename, this.token);
        end

        function result = getList(this, filters, by, varargin)
            %% Generic function for getListByLocation() and getListByDevice()
            %
            % * filters:  (struct)  Describes the data origin
            % * by:       [char]    One of: 'location', 'device'
            % - allPages: (logical) When true, if the data is too long to fit a single request,
            %                       multiple pages will be requested until all data is obatined
            %
            % Returns: [struct] Information on the list of files obtained
            [allPages] = util.param(varargin, 'allPages', false);

            url = this.serviceUrl('archivefiles');
            filters = util.sanitize_filters(filters);
            filters.token = this.token;

            if strcmp(by, 'location')
                filters.method = 'getListByLocation';
            else
                filters.method = 'getListByDevice';
            end

            % parse and remove the artificial parameter extension
            extension = '';
            if isfield(filters, 'extension')
                extension = filters.extension; % Don't remove yet
            end

            if allPages
                mp = onc.MultiPage(this.showInfo, this.timeout);
                result = mp.getAllPages('archivefiles', url, filters);
            else
                if isfield(filters, 'extension')
                    filters = rmfield(filters, 'extension');
                end
                result = this.doRequest(url, filters);
                result = util.filter_by_extension(result, extension);
            end
        end
    end
end
