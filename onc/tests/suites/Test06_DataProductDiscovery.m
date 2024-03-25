% DataProductsDiscovery test suite
%   Contains test cases for the dataProducts discovery service.

classdef Test06_DataProductDiscovery < matlab.unittest.TestCase
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
            filters = {'dataProductCode','XYZ123'};
            verifyError(this, @() this.onc.getDataProducts(filters), 'onc:http400:error127');
        end

        function testInvalidParamName(this)
            % try an invalid locationCode, verify error structure
            filters = {'fakeParamName', 'HSD'};
            verifyError(this, @() this.onc.getDataProducts(filters), 'onc:http400:error129');
        end

        function testNoData(this)
            % try a deviceCategories query with 0 results, verify result message
            filters = {'dataProductCode', 'HSD', 'extension', 'txt'};
            verifyError(this, @() this.onc.getDataProducts(filters), 'onc:http404');
        end

        function testValidParams(this)
            filters = {'dataProductCode', 'HSD', 'extension', 'png'};
            
            dataProducts = this.onc.getDataProducts(filters);
            verifyTrue(this, length(dataProducts) >= 1);
            expectedDataProductFields = ["dataProductCode", "dataProductName", "dataProductOptions", ...
                                    "extension", "hasDeviceData", "hasPropertyData", "helpDocument"];
            verify_fields(this, dataProducts(1), expectedDataProductFields);
            expectedDataProductOptions = ["allowableRange", "allowableValues", "defaultValue", ...
                                           "documentation", "option", "suboptions"];
            verify_fields(this, dataProducts(1).dataProductOptions(7), expectedDataProductOptions);
            expectedDataProductOptionsAllowableRange = ["lowerBound", "onlyIntegers", "unitOfMeasure", "upperBound"];
            verify_fields(this, dataProducts(1).dataProductOptions(7).allowableRange, expectedDataProductOptionsAllowableRange);
        end
    end
end
