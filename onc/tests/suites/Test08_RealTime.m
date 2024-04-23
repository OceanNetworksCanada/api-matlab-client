classdef Test08_RealTime < matlab.unittest.TestCase
    properties (SetAccess = private)
        onc
        outPath = 'output';
        paramsLocation = struct('locationCode', 'NCBC',...
                                'deviceCategoryCode', 'BPR',...
                                'propertyCode', 'seawatertemperature,totalpressure',...
                                'dateFrom', '2019-11-23T00:00:00.000Z',...
                                'dateTo', '2019-11-23T00:01:00.000Z',...
                                'rowLimit', 80000);

        paramsRawLocation = struct('locationCode', 'NCBC',...
                                'deviceCategoryCode', 'BPR',...
                                'dateFrom', '2019-11-23T00:00:00.000Z',...
                                'dateTo', '2019-11-23T00:01:00.000Z',...
                                'rowLimit', 80000, ...
                                'sizeLimit', 20, ...
                                'convertHexToDecimal', false);
        
        paramsLocationMultiPages = struct('locationCode', 'NCBC',...
                                'deviceCategoryCode', 'BPR',...
                                'propertyCode', 'seawatertemperature,totalpressure',...
                                'dateFrom', '2019-11-23T00:00:00.000Z',...
                                'dateTo', '2019-11-23T00:01:00.000Z',...
                                'rowLimit', 25);

        paramsRawLocationMultiPages = struct('locationCode', 'NCBC',...
                                    'deviceCategoryCode', 'BPR',...
                                    'dateFrom', '2019-11-23T00:00:00.000Z',...
                                    'dateTo', '2019-11-23T00:01:00.000Z',...
                                    'rowLimit', 25, ...
                                    'sizeLimit', 20, ...
                                    'convertHexToDecimal', false);

        paramsDevice = struct('deviceCode', 'BPR-Folger-59', ...
                                'dateFrom', '2019-11-23T00:00:00.000Z', ...
                                'dateTo', '2019-11-23T00:01:00.000Z', ...
                                'rowLimit', 80000);
        
        paramsDeviceMultiPages = struct('deviceCode', 'BPR-Folger-59', ...
                                'dateFrom', '2019-11-23T00:00:00.000Z', ...
                                'dateTo', '2019-11-23T00:01:00.000Z', ...
                                'rowLimit', 25);
    end
    
    methods (TestClassSetup)
        function classSetup(this)
            config = load_config();
            this.onc = Onc(config.token, config.production, config.showInfo, config.outPath, config.timeout);
        end
    end
    
    methods (TestClassTeardown)
        function cleanSuite(this)
            if isfolder(this.outPath)
                rmdir(this.outPath, 's');
            end
        end
    end
    
    %% Test methods
    methods (Test)
        %% Testing scalardata location

        function testLocationInvalidParamValue(this)
            filters = this.paramsLocation;
            filters.locationCode = 'XYZ123';
            verifyError(this, @() this.onc.getDirectByLocation(filters), 'onc:http400:error127');
        end
        
        function testLocationInvalidParamName(this)
            filters = this.paramsLocation;
            filters.fakeParamName = 'NCBC';
            verifyError(this, @() this.onc.getDirectByLocation(filters), 'onc:http400:error129');
        end

        function testLocationNoData(this)
            filters = this.paramsLocation;
            filters.dateFrom = '2000-01-01';
            filters.dateTo = '2000-01-02';
            verifyError(this, @() this.onc.getDirectByLocation(filters), 'onc:http400:error127');
        end

        function testLocationValidParamsOnePage(this)
            result = this.onc.getDirectByLocation(this.paramsLocation);
            resultAllPages = this.onc.getDirectByLocation(this.paramsLocationMultiPages, 'allPages', true);
            assertTrue(this, length(result.sensorData(1).data.values) > this.paramsLocationMultiPages.rowLimit, ...
                        'Test should return at least `rowLimit` rows for each sensor.');
            assertEmpty(this, result.next, 'Test should return only one page.');
            assertEqual(this, resultAllPages.sensorData(1).data, result.sensorData(1).data, ...
                        'Test should concatenate rows for all pages.');
            assertEmpty(this, resultAllPages.next, 'Test should return only one page.');
        end
        
        function testLocationValidParamsMultiplePages(this)
            result = this.onc.getDirectByLocation(this.paramsLocationMultiPages);
            assertEqual(this, length(result.sensorData(1).data.values), this.paramsLocationMultiPages.rowLimit, ...
                        'Test should only return `rowLimit` rows for each sensor.');
            assertTrue(this, ~isempty(result.next), 'Test should return multiple pages.');
        end

        %% Testing rawdata location
        function testRawLocationInvalidParamValue(this)
            filters = this.paramsRawLocation;
            filters.locationCode = 'XYZ123';
            verifyError(this, @() this.onc.getDirectRawByLocation(filters), 'onc:http400:error127');
        end
        
        function testRawLocationInvalidParamName(this)
            filters = this.paramsRawLocation;
            filters.fakeParamName = 'NCBC';
            verifyError(this, @() this.onc.getDirectRawByLocation(filters), 'onc:http400:error129');
        end

        function testRawLocationNoData(this)
            filters = this.paramsRawLocation;
            filters.dateFrom = '2000-01-01';
            filters.dateTo = '2000-01-02';
            verifyError(this, @() this.onc.getDirectRawByLocation(filters), 'onc:http400:error127');
        end

        function testRawLocationValidParamsOnePage(this)
            result = this.onc.getDirectRawByLocation(this.paramsRawLocation);
            resultAllPages = this.onc.getDirectRawByLocation(this.paramsRawLocationMultiPages, 'allPages', true);
            assertTrue(this, length(result.data.readings) > this.paramsRawLocationMultiPages.rowLimit, ...
                        'Test should return at least `rowLimit` rows');
            assertEmpty(this, result.next, 'Test should return only one page.');
            assertEqual(this, resultAllPages.data, result.data, ...
                        'Test should concatenate rows for all pages.');
            assertEmpty(this, resultAllPages.next, 'Test should return only one page.');
        end
        
        function testRawLocationValidParamsMultiplePages(this)
            result = this.onc.getDirectRawByLocation(this.paramsRawLocationMultiPages);
            assertEqual(this, length(result.data.readings), this.paramsRawLocationMultiPages.rowLimit, ...
                        'Test should only return `rowLimit` rows for each sensor.');
            assertTrue(this, ~isempty(result.next), 'Test should return multiple pages.');
        end

        %% Testing scalardata device

        function testDeviceInvalidParamValue(this)
            filters = this.paramsDevice;
            filters.deviceCode = 'XYZ123';
            verifyError(this, @() this.onc.getDirectByDevice(filters), 'onc:http400:error127');
        end

        function testDeviceInvalidParamName(this)
            filters = this.paramsDevice;
            filters.fakeParamName = 'BPR-Folger-59';
            verifyError(this, @() this.onc.getDirectByDevice(filters), 'onc:http400:error129');
        end

        function testDeviceNoData(this)
            filters = this.paramsDevice;
            filters.dateFrom = '2000-01-01';
            filters.dateTo = '2000-01-02';
            result = this.onc.getDirectByDevice(filters);
            assertEmpty(this, result.sensorData);
        end

        function testDeviceValidParamsOnePage(this)
            result = this.onc.getDirectByDevice(this.paramsDevice);
            resultAllPages = this.onc.getDirectByDevice(this.paramsDeviceMultiPages, 'allPages', true);
            assertTrue(this, length(result.sensorData(1).data.values) > this.paramsDeviceMultiPages.rowLimit, ...
                        'Test should return at least `rowLimit` rows.');
            assertEmpty(this, result.next, 'Test should return only one page.');
            assertEqual(this, resultAllPages.sensorData(1).data, result.sensorData(1).data, ...
                        'Test should concatenate rows for all pages.');
            assertEmpty(this, resultAllPages.next, 'Test should return only one page.');
        end
        
        function testDeviceValidParamsMultiplePages(this)
            result = this.onc.getDirectByDevice(this.paramsDeviceMultiPages);
            assertEqual(this, length(result.sensorData(1).data.values), this.paramsDeviceMultiPages.rowLimit, ...
                        'Test should only return `rowLimit` rows for each sensor.');
            assertTrue(this, ~isempty(result.next), 'Test should return multiple pages.');
        end

        %% Testing rawdata device

        function testRawDeviceInvalidParamValue(this)
            filters = this.paramsDevice;
            filters.deviceCode = 'XYZ123';
            verifyError(this, @() this.onc.getDirectRawByDevice(filters), 'onc:http400:error127');
        end

        function testRawDeviceInvalidParamName(this)
            filters = this.paramsDevice;
            filters.fakeParamName = 'BPR-Folger-59';
            verifyError(this, @() this.onc.getDirectRawByDevice(filters), 'onc:http400:error129');
        end

        function testRawDeviceNoData(this)
            filters = this.paramsDevice;
            filters.dateFrom = '2000-01-01';
            filters.dateTo = '2000-01-02';
            result = this.onc.getDirectRawByDevice(filters);
            assertEmpty(this, result.data.lineTypes);
            assertEmpty(this, result.data.readings);
            assertEmpty(this, result.data.times);
        end

        function testRawDeviceValidParamsOnePage(this)
            result = this.onc.getDirectRawByDevice(this.paramsDevice);
            resultAllPages = this.onc.getDirectRawByDevice(this.paramsDeviceMultiPages, 'allPages', true);
            assertTrue(this, length(result.data.readings) > this.paramsDeviceMultiPages.rowLimit, ...
                        'Test should return at least `rowLimit` rows for each sensor.');
            assertEmpty(this, result.next, 'Test should return only one page.');
            assertEqual(this, resultAllPages.data, result.data, ...
                        'Test should concatenate rows for all pages.');
            assertEmpty(this, resultAllPages.next, 'Test should return only one page.');
        end
        
        function testRawDeviceValidParamsMultiplePages(this)
            result = this.onc.getDirectRawByDevice(this.paramsDeviceMultiPages);
            assertEqual(this, length(result.data.readings), this.paramsDeviceMultiPages.rowLimit, ...
                        'Test should only return `rowLimit` rows for each sensor.');
            assertTrue(this, ~isempty(result.next), 'Test should return multiple pages.');
        end
        
    end
end