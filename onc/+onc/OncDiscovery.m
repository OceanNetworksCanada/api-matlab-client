classdef OncDiscovery < onc.Service
    %% Contains the functionality that wraps the API discovery services
    % To be inherited by the Onc class
    methods (Access = public)
        function r = getLocations(this, varargin)
            %% Obtain a filtered list of locations
            % 
            % getLocations(filters)
            %
            % - filters:  (struct)  Describes the data origin
            %
            % Returns: ([struct]) List of locations found
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'locations');
        end

        function r = getLocationHierarchy(this, varargin)
            %% Obtain a filtered tree of locations that includes children locations
            % 
            % getLocationHierarchy(filters)
            %
            % - filters:  (struct)  Describes the data origin
            %
            % Returns: ([struct]) Tree of locations found with children
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'locations', 'method', 'getTree');
        end

        function r = getDeployments(this, varargin)
            %% Obtain a filtered list of deployments
            % 
            % getDeployments(filters)
            %
            % - filters:  (struct)  Describes the data origin
            %
            % Returns: ([struct]) List of deployments found
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'deployments');
        end

        function r = getDevices(this, varargin)
            %% Obtain a filtered list of devices
            % 
            % getDevices(filters)
            %
            % - filters:  (struct)  Describes the data origin
            %
            % Returns: ([struct]) List of devices found
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'devices');
        end

        function r = getDeviceCategories(this, varargin)
            %% Obtain a filtered list of device categories
            % 
            % getDeviceCategories(filters)
            %
            % - filters:  (struct)  Describes the data origin
            %
            % Returns: ([struct]) List of device categories found
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'deviceCategories');
        end

        function r = getProperties(this, varargin)
            %% Obtain a filtered list of properties
            % 
            % getProperties(filters)
            %
            % - filters:  (struct)  Describes the data origin
            %
            % Returns: ([struct]) List of properties found
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'properties');
        end

        function r = getDataProducts(this, varargin)
            %% Obtain a list of available data products for the filters
            % 
            % getDataProducts(filters)
            %
            % - filters: (struct)  Describes the data origin
            %
            % Returns: ([struct]) List of data products found
            %
            % Documentation: https://wiki.oceannetworks.ca/display/CLmatlab/Discovery+methods
            filters = this.getFilters(varargin);
            r = this.discoveryRequest(filters, 'dataProducts');
        end
    end
    
    methods (Access = private, Hidden = true)
        function r = discoveryRequest(this, filters, service, varargin)
            %% Run a generic request for a discovery service
            % 
            % * filters: (struct)  Describes the data origin
            % * service: ([char])  Service to request as defined by the API
            % - method:  ([char])  Method to request, one of {'get', 'getTree'}
            %
            % Returns: ([struct]) List of elements found
            
            %BUG: if varargin = {'method','getTree'}, not actually using getTree...
            %[method] = util.param(varargin, 'method', 'get'); 
            if nargin>3
                if strcmpi(varargin{1},'method') & strcmpi(varargin{2},'getTree')
                    [method] = util.param(varargin, 'method', 'getTree'); 
                else 
                    [method] = util.param(varargin, 'method', 'get'); 
                end
            else
                [method] = util.param(varargin, 'method', 'get'); 
            end
            
            url = this.serviceUrl(service);

            filters = util.sanitize_filters(filters);
            filters.method = method;
            filters.token = this.token;

            r = this.doRequest(url, filters);
            r = this.sanitizeBooleans(r);
        end

        function r = sanitizeBooleans(this, data)
            %% Converts all boolean strings elements in data to logical variables
            %
            % * data ([struct]) list of structures
            %
            % Returns: ([struct]) Sanitized data
            if class(data) ~= "struct" || isempty(data)
                r = data;
                return
            end

            fixHasDeviceData   = false;
            fixHasPropertyData = false;

            % check hasDeviceData only if present and of the wrong type
            % for now we only check the first row
            names1 = fieldnames(data(1));
            if ismember("hasDeviceData", names1)
                if class(data(1).hasDeviceData) ~= "logical", fixHasDeviceData = true; end
            end

            % same for hasPropertyData
            if ismember("hasPropertyData", names1)
                if class(data(1).hasPropertyData) ~= "logical", fixHasPropertyData = true; end
            end

            if fixHasDeviceData || fixHasPropertyData
                for i=1 : numel(data)
                    if fixHasDeviceData
                        data(i).hasDeviceData = (data(i).hasDeviceData == "true");
                    end
                    if fixHasPropertyData
                        data(i).hasPropertyData = (data(i).hasPropertyData == "true");
                    end
                    % Do the same for children if any
                    if isfield(data(i), 'children')
                        if length(data(i).children) > 0
                            data(i).children = this.sanitizeBooleans(data(i).children);
                        end
                    end
                end
            end
            
            r = data;
        end

        function filters = getFilters(this, args)
            %% Helper: Extract filters parameter from vargin
            % 
            % * args: ([cell])  varargin as provided by the calling function
            %
            % Returns: (struct) Filters structure, or an empty structure if not present
            [filters] = util.param(args, 'filters', struct());
        end
    end
end
