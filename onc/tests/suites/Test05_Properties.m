% Properties test suite
%   Contains test cases for the properties discovery service.

classdef Test05_Properties < matlab.unittest.TestCase
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
        %% General test cases

        function testInvalidParamValue(this)
            % Make an unfiltered deviceCategories request
            % verifies: expected fields, minimum rows
            filters = {'propertyCode','XYZ123'};
            verifyError(this, @() this.onc.getProperties(filters), 'onc:http400:error127');
        end

        function testInvalidParamName(this)
            % try an invalid locationCode, verify error structure
            filters = {'fakeParamName', 'conductivity'};
            verifyError(this, @() this.onc.getProperties(filters), 'onc:http400:error129');
        end

        function testNoData(this)
            % try a deviceCategories query with 0 results, verify result message
            filters = {'propertyCode', 'conductivity', 'locationCode', 'SAAN'};
            verifyError(this, @() this.onc.getProperties(filters), 'onc:http404');
        end

        function testValidParams(this)
            filters = {'propertyCode', 'conductivity', 'locationCode', 'BACAX', 'deviceCategoryCode', 'CTD'};
            
            properties = this.onc.getProperties(filters);
            verifyTrue(this, length(properties) >= 1);
            expectedPropertiesFields = ["cvTerm", "description", "hasDeviceData", ...
                                        "hasPropertyData", "propertyCode", "propertyName", "uom"];
            verify_fields(this, properties(1), expectedPropertiesFields);
            expectedCvTermFields = ["uri", "vocabulary"];
            verify_fields(this, properties(1).cvTerm.uom, expectedCvTermFields);
        end
    end
end
