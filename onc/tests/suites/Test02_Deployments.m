% Deployments test suite
%   Contains test cases for the deployments discovery service.

classdef Test02_Deployments < matlab.unittest.TestCase
    properties
        onc
    end
    
    methods (TestClassSetup)
        function classSetup(this)
            config = globals();
            this.onc = Onc(config.token, config.production, config.showInfo, config.outPath, config.timeout);
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases
        function testInvalidTimeRangeGreaterStartTime(this)
            filters = {'locationCode', 'BACAX', 'deviceCategoryCode', 'CTD', 'dateFrom', '2020-01-01', 'dateTo', '2019-01-01'};
            verifyError(this, @() this.onc.getDeployments(filters), 'onc:http400:error23');
        end

        function testInvalidTimeRangeFutureStartTime(this)
            filters = {'locationCode', 'BACAX', 'deviceCategoryCode', 'CTD', 'dateFrom', '2050-01-01'};
            verifyError(this, @() this.onc.getDeployments(filters), 'onc:http400:error25');
        end
        
        function testInvalidParamValue(this)
            filters = {'locationCode', 'XYZ123', 'deviceCategoryCode', 'CTD'};
            verifyError(this, @() this.onc.getDeployments(filters), 'onc:http400:error127');
        end
        
        function testInvalidParamName(this)
            filters = {'fakeParamName', 'BACAX', 'deviceCategoryCode', 'CTD'};
            verifyError(this, @() this.onc.getDeployments(filters), 'onc:http400:error129');
        end
        
        function testNoData(this)
            filters = {'locationCode', 'BACAX', 'deviceCategoryCode', 'CTD', 'dateTo', '1900-01-01'};
            verifyError(this, @() this.onc.getDeployments(filters), 'onc:http400:error127');
        end
        
        function testValidParams(this)
            filters = {'locationCode', 'BACAX', 'deviceCategoryCode', 'CTD', 'dateFrom', '2005-09-17', 'dateTo', '2015-09-17T13:00:00.000Z'};
            deployments = this.onc.getDeployments(filters);
            verifyTrue(this, length(deployments) >= 1);
            expectedDeploymentFields = ["begin", "citation", "depth", "deviceCategoryCode", ...
                                        "deviceCode", "end", "hasDeviceData", "heading", ...
                                        "lat", "locationCode", "lon", "pitch", "roll"];
            verify_fields(this, deployments(1), expectedDeploymentFields);
            expectedCitationFields = ["citation", "doi", "landingPageUrl", "queryPid"];
            verify_fields(this, deployments(1).citation, expectedCitationFields);
        end

        
    end
end
