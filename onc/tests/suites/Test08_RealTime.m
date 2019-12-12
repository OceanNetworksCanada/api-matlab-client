classdef Test08_RealTime < matlab.unittest.TestCase
    properties (SetAccess = private)
        onc
        F_SCALAR1 = struct('locationCode', 'CRIP.C1', 'deviceCategoryCode', 'CTD', 'propertyCode', 'density', ...
                           'dateFrom', '2018-03-24T00:00:00.000Z', 'dateTo', '2018-03-24T00:00:15.000Z');
        % 3 pages of temperature, by location
        F_SCALAR2 = struct('locationCode', 'CRIP.C1', 'deviceCategoryCode', 'CTD', 'propertyCode', 'density', ...
                           'dateFrom', '2018-03-24T00:00:00.000Z',   'dateTo', '2018-03-24T00:00:15.000Z', 'rowLimit', 5);
        % 3 pages of temperature
        F_SCALAR3 = struct('deviceCode', 'BARIX001', 'dateFrom', '2017-06-08T00:00:00.000Z', 'dateTo', 'PT7M', 'rowLimit', 5);
        F_RAW1    = struct('locationCode', 'CRIP.C1', 'deviceCategoryCode', 'CTD', ...
                           'dateFrom', '2018-03-24T00:00:00.000Z', 'dateTo', '2018-03-24T00:00:10.000Z');
        F_RAW3    = struct('locationCode', 'CRIP.C1', 'deviceCategoryCode', 'CTD', ...
                           'dateFrom', '2018-03-24T00:00:00.000Z', 'dateTo', '2018-03-24T00:00:15.000Z', 'rowLimit', 5);
        F_RAWDEV1 = struct('deviceCode', 'BARIX001', 'dateFrom', '2017-06-08T00:00:00.000Z', 'dateTo', 'PT5S');
        F_WRONG_FILTERS = struct('locationCode', 'ONION', 'deviceCategoryCode', 'POTATO', 'propertyCode', 'BANANA', ...
                           'dateFrom', '2018-03-24T00:00:00.000Z', 'dateTo', '2018-03-24T00:00:10.000Z');
        F_NODATA  = struct('locationCode', 'CRIP.C1    ', 'deviceCategoryCode', 'CTD', ...
                           'dateFrom', '2015-03-24T00:00:00.000Z', 'dateTo', '2015-03-24T00:00:10.000Z');
    end
    
    methods (TestClassSetup)
        function prepareSuite(testCase)
            s = rmdir('tests/output/08', 's'); % delete directory contents
        end
    end
    
    methods (TestClassTeardown)
        function cleanSuite(testCase)
            s = rmdir('tests/output/08', 's'); % delete directory contents
        end
    end
    
    %% Public Methods
    methods
        % Constructor
        function this = Test08_RealTime()
            global config;
            this.onc = Onc(config.token, config.production, config.showInfo, config.outPath, config.timeout);
        end
    end
    
    %% Test methods
    methods (Test)
        %% General test cases
        
        function test01_scalar_by_location_1_page(this)
            response = this.onc.getDirectByLocation(this.F_SCALAR1);
            sensorData = response.sensorData(1);
            verify_has_field(this, sensorData, 'data');
            verify_field_value(this, sensorData, 'sensorCode', 'Sensor8_Voltage');
            verify_no_next_page(this, response);
        end

        function test02_scalar_by_location_3_pages(this)
            response = this.onc.getDirectByLocation(this.F_SCALAR2, true);
            sensorData = response.sensorData(1);
            verify_has_field(this, sensorData, 'data');
            verify_field_value(this, sensorData, 'sensorCode', 'Sensor8_Voltage');
            verifyLength(this, sensorData.data.values, 15);
            verify_no_next_page(this, response);
        end

        function test03_scalar_by_location_no_results(this)
            response = this.onc.getDirectByLocation(this.F_NODATA);
            verifyLength(this, response.sensorData, 0);
        end

        function test04_scalar_by_location_wrong_filters(this)
            result = this.onc.getDirectByLocation(this.F_WRONG_FILTERS);
            verify_error_response(this, result);
        end

        function test05_raw_by_location_1_page(this)
            response = this.onc.getDirectRawByLocation(this.F_RAW1);
            verifyLength(this, response.data.readings, 10);
            verify_no_next_page(this, response);
        end

        function test06_raw_by_location_3_pages(this)
            response = this.onc.getDirectRawByLocation(this.F_RAW3, true);
            verifyLength(this, response.data.readings, 15);
            verify_no_next_page(this, response);
        end

        function test07_raw_by_device_1_page(this)
            response = this.onc.getDirectRawByDevice(this.F_RAWDEV1);
            verifyLength(this, response.data.readings, 47);
            verify_no_next_page(this, response);
        end

        function test08_raw_no_results(this)
            response = this.onc.getDirectRawByLocation(this.F_NODATA);
            verifyLength(this, response.data.readings, 0);
        end

        function test09_raw_by_location_wrong_filters(this)
            result = this.onc.getDirectRawByLocation(this.F_WRONG_FILTERS);
            verify_error_response(this, result);
        end

        function test10_scalar_by_device_6_pages(this)
            response = this.onc.getDirectByDevice(this.F_SCALAR3, true);
            sensorData = response.sensorData(1);
            verify_has_field(this, sensorData, 'data');
            verify_field_value(this, sensorData, 'sensorCode', 'analog_input501');
            verifyLength(this, sensorData.data.values, 14);
            verify_no_next_page(this, response);
        end
    end
end