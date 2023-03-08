classdef Onc < onc.OncDiscovery & onc.OncDelivery & onc.OncRealTime & onc.OncArchive
    %% ONC Facilitates access to Ocean Networks Canada's data through the Oceans 2.0 API.
    % For detailed information and usage examples, visit our official documentation
    % at https://wiki.oceannetworks.ca/display/CLmatlab
    %
    % ONC Properties:
    % token    - User token, can be obtained at: https://data.oceannetworks.ca/Profile
    % showInfo - Print verbose comments for debugging
    % outPath  - Output path for downloaded files
    % timeout  - Number of seconds before a request to the API is canceled
    % tree     - ONC data search tree
    %
    % ONC Methods:
    % 
    %% Discovery Methods
    % 
    % getLocations         - Obtain a filtered list of locations
    % getLocationHierarchy - Obtain a filtered tree of locations with their children
    % getDeployments       - Obtain a filtered list of deployments
    % getDeviceCategories  - Obtain a filtered list of device categories
    % getDevices           - Obtain a filtered list of devices
    % getProperties        - Obtain a filtered list of properties
    % getDataProducts      - Obtain a filtered list of data products
    %
    %% Data Product Delivery Methods
    %
    % orderDataProduct    - Request, run and download a data product
    % requestDataProduct  - Manually request a data product
    % runDataProduct      - Manually run a data product request
    % downloadDataProduct - Manually download an available data product
    %
    %% Near real-time data access methods
    %
    % getDirectByLocation    - Obtain scalar data readings from a device category in a location
    % getDirectByDevice      - Obtain scalar data readings from a device
    % getDirectRawByLocation - Obtain raw data readings from a device category in a location
    % getDirectRawByDevice   - Obtain raw data readings from a device
    %
    %% Archive file download methods
    %
    % getListByLocation - Get a list of archived files for a device category in a location
    % getListByDevice   - Get a list of archived files for a device
    % getFile           - Download a file with the given filename
    % getDirectFiles    - Download a list of archived files that match the filters provided
    %
    %% Utility methods
    %
    % print     - Prints a dictionary in a format easier to read
    % formatUtc - Formats the provided date string to meet ISO8601
    
    %%
    properties (SetAccess = public)
        token               % User token, can be obtained at: https://data.oceannetworks.ca/Profile
        showInfo = false    % Print verbose comments for debugging
        outPath  = 'output' % Output path for downloaded files
        timeout  = 60       % Number of seconds before a request to the API is canceled
        tree     = []       % ONC Data Search Tree
    end

    properties (SetAccess = private)
        production = true % Whether the ONC Production server is used for requests
        baseUrl    = 'https://data.oceannetworks.ca/'  % Base URL for API requests
    end

    methods (Access = public)
        function this = Onc(token, varargin)
            %% Class initializer
            % All toolkit functionality must be invoked from an Onc object
            %
            % Onc(token, production=true, showInfo=false, outPath='output', timeout=60)
            %
            % * token:      ([char])  User token
            % - production: (logical) Send requests to the production server (otherwise use internal QA)
            % - showInfo:   (logical) Whether verbose debug messages are displayed
            % - outPath:    ([char])  Output path for downloaded files
            % - timeout:    (int)     Number of seconds before a request to the API is canceled
            %
            % Returns: The Onc object created.
            
            % parse inputs (can be named or positional)
            p = inputParser;
            addRequired(p, 'token', @ischar);
            addOptional(p, 'production', true, @islogical);
            addOptional(p, 'showInfo', false, @islogical);
            addOptional(p, 'outPath', 'output', @ischar);
            addOptional(p, 'timeout', 60, @isnumeric);
            parse(p, token, varargin{:});

            this.token      = strtrim(p.Results.token);
            this.production = p.Results.production;
            this.showInfo   = p.Results.showInfo;
            this.timeout    = p.Results.timeout;

            % sanitize outPath
            opath = strtrim(p.Results.outPath);
            if strlength(opath) > 0
                opath = strrep(opath, '\', '/');
                if opath(end) == '/'
                    opath = opath(1:end-1);
                end
            end
            this.outPath = opath;

            if not(this.production)
                this.baseUrl = 'https://qa.oceannetworks.ca/';
            end
            
            %If a search tree file exists, load it.  If not, generate and save one
            [source_path,~,~] = fileparts(which('Onc.m'));
            tree_path = fullfile(source_path,'onc_tree.mat');
            if ~exist(tree_path,'file')
                fprintf('\n Loading ONC search tree.  Accessible with onc.tree \n');
                tree = util.extract_tree(this);
                save(tree_path, 'tree')
            elseif exist(tree_path,'file')
                %Check if it's more than a week old. If so, update it:
                dir_files = dir(source_path);
                filenames = {dir_files(:).name};
                [~,idx] = ismember('onc_tree.mat',filenames);
                treeFileDate = dir_files(idx).datenum;
                if now - treeFileDate > 7
                    fprintf('\n Updating ONC search tree.  Accessible with onc.tree \n');
                    tree = util.extract_tree(this);
                    save(tree_path, 'tree')
                end
            end
            temp = load(tree_path);
            this.tree = temp.tree;
            %These codes can then be used for input to onc.getDevices by
            %providing the locationCodes
            
            
        end

        function print(~, data)
            %% Helper for printing a result in the console
            %
            % print(object)
            %
            % * object: ([struct]) Struct vector to print (usually the result of another function)
            util.pretty_print(data, '', 0);
        end
        
        function text = formatUtc(~, dateString)
            %% Formats a date string as ISO8601 UTC
            %
            % * dateString: ([char]) A string that describes a date. Can also be "now"
            %
            % Returns: ([char]) Formatted date string, suitable for API requests
            if strcmp(dateString, "now")
                dt = datetime();
            else
                % sanitize input
                dateString = strrep (dateString, '/', '-');
                dt = datetime(dateString);
            end
            
            dt.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''';
            text = sprintf('%s', char(dt));
        end
        
    end
    
    methods (Access = private)
        function log(this, msg)
            %% Prints message to console only when showInfo is true
            %
            % * msg: ([char]) The message to print
            if this.showInfo
                fprintf("%s\n", msg)
            end
        end
    end
end
