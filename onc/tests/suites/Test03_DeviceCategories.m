% DeviceCategories test suite
%   Contains test cases for the deviceCategories discovery service.

classdef Test03_DeviceCategories < matlab.unittest.TestCase
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

        function testInvalidParamValue(this)
            % Make an unfiltered deviceCategories request
            % verifies: expected fields, minimum rows
            filters = {'deviceCategoryCode','XYZ123'};
            verifyError(this, @() this.onc.getDeviceCategories(filters), 'onc:http400:error127');
        end

        function testInvalidParamName(this)
            % try an invalid locationCode, verify error structure
            filters = {'fakeParamName', 'CTD'};
            verifyError(this, @() this.onc.getDeviceCategories(filters), 'onc:http400:error129');
        end

        function testNoData(this)
            % try a deviceCategories query with 0 results, verify result message
            filters = {'deviceCategoryCode', 'CTD', 'deviceCategoryName', 'Conductivity','description','TemperatureXXX'};
            verifyError(this, @() this.onc.getDeviceCategories(filters), 'onc:http404');
        end

        function testValidParams(this)
            filters = {'deviceCategoryCode', 'CTD', 'deviceCategoryName', 'Conductivity', 'description', 'Temperature'};
            
            deviceCategories = this.onc.getDeviceCategories(filters);
            verifyTrue(this, length(deviceCategories) >= 1);
            expectedDeviceCategoriesFields = ["cvTerm", "description", "deviceCategoryCode", ...
                                            "deviceCategoryName", "hasDeviceData", "longDescription"];
            verify_fields(this, deviceCategories(1), expectedDeviceCategoriesFields);
            expectedCvTermFields = ["uri", "vocabulary"];
            verify_fields(this, deviceCategories(1).cvTerm.deviceCategory, expectedCvTermFields);
        end
    end
end
