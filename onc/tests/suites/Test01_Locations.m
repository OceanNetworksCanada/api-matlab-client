% OncTest Locations test suite
%   Contains test cases for the locations discovery service.

classdef Test01_Locations < TestDiscovery
    
    %% Public Methods
    methods
        
        function obj = Test01_Locations()
            % Constructor
            obj@TestDiscovery();
            obj.expectedFields('getLocations') = ["deployments", "locationName", "depth", "bbox", "description", "hasDeviceData", "lon", "locationCode", "hasPropertyData", "lat", "dataSearchURL"];
        end
    end
    
    %% Test methods
    methods (Test)
        %% General test cases
        
        function testGetAllLocations(this)
            % Make an unfiltered locations request
            % verifies: expected fields, minimum rows
            locations = this.o.getLocations();
            verify_fields(this, locations, this.expectedFields('getLocations'));
            this.verify_min_length(locations, 500);
        end
        
        function testISODateRange(this)
            % Test a date range with format ISO8601
            filters = {'dateFrom', '2014-02-24T00:00:01.000Z', 'dateTo', '2014-03-24T00:00:01.000Z'};
            locations = this.testSingleFilter('getLocations', filters, 100, NaN);
        end
        
        function testFilterIncludeChildren(this)
            % Test filter includeChildren, verify children were obtained
            filters = {'includeChildren', 'true', 'locationCode', 'SAAN'};
            locations = this.testSingleFilter('getLocations', filters, 30, NaN);
        end
        
        function testWrongLocationCode(this)
            % try an invalid locationCode, verify error structure
            locations = this.o.getLocations({'locationCode', 'CQS34543BG'});
            verify_error_response(this, locations);
        end
        
        function testNoLocationsFound(this)
            % try a locations query with 0 results, verify result is an empty 0x0 matrix
            locations = this.o.getLocations({'locationCode', 'SAAN', 'dateTo', '1995-03-24T00:00:01.000Z'});
            verifyEqual(this, size(locations), [0 0]);
            
        end
        %% Single filter test cases
        % These tests invoke getLocations with a single filter, for every supported filter
        % Verifications according to tests documentation at: https://internal.oceannetworks.ca/x/xYI2Ag
        
        function testFilterLocationCode(this)
            locations = this.testSingleFilter('getLocations', {'locationCode', 'CQSBG'}, 1, 1);
            verifyEqual(this, locations(1).locationName, 'Bubbly Gulch');
        end
        
        function testFilterLocationName(this)
            locations = this.testSingleFilter('getLocations', {'locationName', 'Bubbly Gulch'}, 1, 1);
            verifyEqual(this, locations(1).locationCode, 'CQSBG');
        end
        
        function testFilterDeviceCategoryCode(this)
            locations = this.testSingleFilter('getLocations', {'deviceCategoryCode', 'CTD'}, 50, NaN);
        end
        
        function testFilterDeviceCode(this)
            locations = this.testSingleFilter('getLocations', {'deviceCode', 'NORTEKADCP9917'}, 1, NaN);
        end
        
        function testFilterPropertyCode(this)
            locations = this.testSingleFilter('getLocations', {'propertyCode', 'co2concentration'}, 1, NaN);
        end
        
        function testFilterDataProductCode(this)
            locations = this.testSingleFilter('getLocations', {'dataProductCode', 'MP4V'}, 20, NaN);
        end
    end
end