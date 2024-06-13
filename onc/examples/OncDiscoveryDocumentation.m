%% ONC Discovery Services
    % Contains the functionality that wraps the API discovery services
    % To be inherited by the Onc class
    % Discovery methods can be used to search for available locations, deployments, device categories, devices, properties, 
    % and data products. They support numerous filters and might resemble an "advanced search" function for ONC data sources.
    % 
    % Use discovery methods to:
    % 
    % Obtain the identification codes required to use other API services.
    % 
    % * Obtain the identification codes required to use other API services.
    % * Explore what's available in a certain location or device.
    % * Obtain the deployment dates for a device.
    % * List available data products for download in a particular device or location.
    % 
    % Note
    % 
    % * Locations can contain other locations.
    % * "Cambridge bay" may contain separate children locations for its underwater network and shore station.
    % * Locations can contain device categories, which contain devices, which contain properties.
    % * Searches can be performed without considering the hierarchy mentioned above.
    % * You can search for locations with data on a specific property or search for all properties in a specific location.

%% getLocations
            % Obtain a filtered list of locations
            %
            % Input: filters(struct) - Describes the data origin
            %
            % Returns: ([struct]) List of locations found
            %
            % See https://data.oceannetworks.ca/OpenAPI#get-/locations for usage and available query string parameters.
            % 
            % Parameters: 
            % Query string parameters in the API request. Return all locations available if None.
            % Supported parameters are:    
            %
            % * locationCode
            % * deviceCategoryCode
            % * propertyCode
            %
            % Returns:
            % API response. Each location returned in the list is a dict with the following structure.
            %
            % * deployments: int
            % * locationName: str
            % * depth: float
            % * bbox: dict
            % ......
