% OncTest Locations test suite
%   Contains test cases for the locations / locationtrees discovery service.

classdef Test01_Locations < matlab.unittest.TestCase
    properties
        onc
    end
    
    methods (TestClassSetup)
        function classSetup(this)
            config = load_config();
            this.onc = Onc(config.token, config.production, config.showInfo, config.outPath, config.timeout);
        end
    end

    %% Test methods
    methods (Test)
        %% getLocations test cases
        function testInvalidTimeRangeGreaterStartTime(this)
            filters = {'locationCode', 'FGPD','dateFrom', '2020-01-01', 'dateTo', '2019-01-01'};
            verifyError(this, @() this.onc.getLocations(filters), 'onc:http400:error23');
        end

        function testInvalidTimeRangeFutureStartTime(this)
            filters = {'locationCode', 'FGPD', 'dateFrom', '2050-01-01'};
            verifyError(this, @() this.onc.getLocations(filters), 'onc:http400:error25');
        end
        
        function testInvalidParamValue(this)
            filters = {'locationCode', 'XYZ123'};
            verifyError(this, @() this.onc.getLocations(filters), 'onc:http400:error127');
        end
        
        function testInvalidParamName(this)
            filters = {'fakeParamName', 'FGPD'};
            verifyError(this, @() this.onc.getLocations(filters), 'onc:http400:error129');
        end
        
        function testNoData(this)
            filters = {'locationCode', 'FGPD', 'dateTo', '1900-01-01'};
            verifyError(this, @() this.onc.getLocations(filters), 'onc:http404');
        end
        
        function testValidParams(this)
            filters = {'locationCode', 'FGPD', 'dateFrom', '2005-09-17', 'dateTo', '2020-09-17'};
            locations = this.onc.getLocations(filters);
            verifyTrue(this, length(locations) >= 1);
            expectedLocationsFields = ["deployments", "locationName", "depth", "bbox", ...
                                    "description", "hasDeviceData", "lon", "locationCode",...
                                    "hasPropertyData", "lat", "dataSearchURL"];
            verify_fields(this, locations(1), expectedLocationsFields);
            expectedBboxFields = ["maxDepth", "maxLat", "maxLon", "minDepth", "minLat", "minLon"];
            verify_fields(this, locations(1).bbox, expectedBboxFields);
        end
        
        %% Location tree test cases
        
        function testTreeInvalidTimeRangeGreaterStartTime(this)
            filters = {'locationCode', 'ARCT', 'dateFrom', '2020-01-01', 'dateTo', '2019-01-01'};
            verifyError(this, @() this.onc.getLocationHierarchy(filters), 'onc:http400:error23');
        end

        function testTreeInvalidTimeRangeFutureStartTime(this)
            filters = {'locationCode', 'ARCT', 'dateFrom', '2050-01-01'};
            verifyError(this, @() this.onc.getLocationHierarchy(filters), 'onc:http400:error25');
        end

        function testTreeInvalidParamValue(this)
            filters = {'locationCode', 'XYZ123'};
            verifyError(this, @() this.onc.getLocationHierarchy(filters), 'onc:http400:error127');
        end

        function testTreeInvalidParamName(this)
            filters = {'fakeParamName', 'ARCT'};
            verifyError(this, @() this.onc.getLocationHierarchy(filters), 'onc:http400:error129');
        end
        
        function testTreeNoData(this)
            filters = {'locationCode', 'ARCT', 'dateTo', '1900-01-01'};
            verifyError(this, @() this.onc.getLocationHierarchy(filters), 'onc:http404');
        end

        function testTreeValidParams(this)
            filters = {'locationCode', 'ARCT', 'deviceCategoryCode', 'VIDEOCAM'};
            locations = this.onc.getLocationHierarchy(filters);
            verifyTrue(this, length(locations) >= 1);
            expectedLocationsFields = ["locationName","children","description","hasDeviceData",...
                                        "locationCode","hasPropertyData"];
            verify_fields(this, locations(1), expectedLocationsFields);
            verifyTrue(this, length(locations(1).children) >= 1);
        end
    end
end