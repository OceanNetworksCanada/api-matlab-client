classdef OncRealTime < onc.Service
    %% Contains the functionality that wraps API real-time services
    %  To be inherited by the Onc class
    
    methods (Access = public)
        function r = getDirectByLocation(this, filters, varargin)
            %% Obtains scalar data from a location, from the source described by the filters
            %
            % getDirectByLocation(filters, allPages)
            %
            % * filters:  (struct)  Describes the data origin
            % - allPages: (logical) When true, if the data requested is too large to fit a single
            %                       API resquest, keep downloading data pages until we gather all data
            %
            % Returns: ([struct]) Scalar data obtained for all sensors found
            [allPages] = util.param(varargin, 'allPages', false);
            r = this.getDirectAllPages(filters, 'scalardata', 'getByLocation', allPages);
        end

        function r = getDirectByDevice(this, filters, varargin)
            %% Obtains scalar data from a device, as described by the filters
            %
            % getDirectByDevice(filters, allPages)
            %
            % * filters:  (struct)  Describes the data origin
            % - allPages: (logical) When true, if the data requested is too large to fit a single
            %                        API resquest, keep downloading data pages until we gather all data
            %
            % Returns: ([struct]) Scalar data obtained for all sensors found
            [allPages] = util.param(varargin, 'allPages', false);
            r = this.getDirectAllPages(filters, 'scalardata', 'getByDevice', allPages);
        end

        function r = getDirectRawByLocation(this, filters, varargin)
            %% Obtains raw data from a location, from the source described by the filters
            %
            % getDirectRawByLocation(filters, allPages)
            %
            %
            % * filters:  (struct)  Describes the data origin
            % - allPages: (logical) When true, if the data requested is too large to fit a single
            %                       API resquest, keep downloading data pages until we gather all data
            %
            % Returns: ([struct]) Raw data obtained for all sensors found
            [allPages] = util.param(varargin, 'allPages', false);
            r = this.getDirectAllPages(filters, 'rawdata', 'getByLocation', allPages);
        end


        function r = getDirectRawByDevice(this, filters, varargin)
            %% Obtains raw data from a device, as described by the filters
            %
            % getDirectRawByDevice(filters, allPages)
            %
            %
            % * filters:  (struct)  Describes the data origin
            % - allPages: (logical) When true, if the data requested is too large to fit a single
            %                       API resquest, keep downloading data pages until we gather all data
            %
            % Returns: ([struct]) Raw data obtained for all sensors found
            [allPages] = util.param(varargin, 'allPages', false);
            r = this.getDirectAllPages(filters, 'rawdata', 'getByDevice', allPages);
        end
    end
    
    methods (Access = protected, Hidden = true)
            
        function r = getDirectAllPages(this, filters, service, method, allPages)
            %% Generic method to download and concatenate all pages of data
            % Keeps downloading all scalar or raw data pages until finished
            % Automatically translates sensorCategoryCodes to a string if a list is provided
            %
            % * filters:  (struct)  Describes the data origin
            % * service:  ([char])  One of: 'scalardata', 'rawdata'
            % * method:   ([char])  One of: 'getByDevice', 'getByLocation'
            % * allPages: (logical) When true, if the data requested is too large to fit a single
            %                       API resquest, keep downloading data pages until we gather all data
            %
            % Returns: ([struct]) A single response in the expected format, with all data pages concatenated
            
            % sanitize in case filters is not a struct
            filters = util.sanitize_filters(filters);
            
            url = this.serviceUrl(service);
            filters.method = method;
            filters.token  = this.token;

            % if sensorCategoryCodes is a list, join it into a comma-separated string
            if isfield(filters, 'sensorCategoryCodes')
                codes = filters.sensorCategoryCodes;
                if isvector(codes)
                    filters.sensorCategoryCodes = strjoin(codes, ',');
                end
            end

            if allPages
                mp = onc.MultiPage(this.showInfo, this.timeout);
                r = mp.getAllPages(service, url, filters);
            else
                r = this.doRequest(url, filters);
            end
        end

    end
end
