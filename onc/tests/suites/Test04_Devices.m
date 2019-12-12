% Devices test suite
%   Contains test cases for the devices discovery service.

classdef Test04_Devices < TestDiscovery

    %% Public Methods
    methods

        function obj = Test04_Devices()
            % Constructor
            obj@TestDiscovery();
            obj.expectedFields('getDevices') = ["dataRating", "deviceCode", "deviceId", "deviceLink", "deviceName"];
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases

        function testGetAllDevices(this)
            % Make an unfiltered Ddvices request
            % verifies: expected fields, minimum rows
            devices = this.o.getDevices();
            verify_fields(this, devices, this.expectedFields('getDevices'));
            this.verify_min_length(devices, 300);
        end

        function testISODateRange(this)
            % Test a date range with format ISO8601
            filters = {'dateFrom', '2014-02-24T00:00:01.000Z', 'dateTo', '2014-03-24T00:00:01.000Z'};
            devices = this.testSingleFilter('getDevices', filters, 100, NaN);
        end

        function testWrongDeviceCode(this)
            % try an invalid locationCode, verify error structure
            devices = this.o.getDevices({'deviceCode', 'XYZ321'});
            verify_error_response(this, devices);
        end

        function testNoDevicesFound(this)
            % try a Devices query with 0 results, verify result is an empty 0x0 matrix
            devices = this.o.getDevices({'locationCode', 'SAAN', 'dateTo', '1995-03-24T00:00:01.000Z'});
            verifyEqual(this, size(devices), [0 0]);

        end
        %% Single filter test cases
        % These tests invoke getDevices with a single filter, for every supported filter
        % Verifications according to tests documentation at: https://internal.oceannetworks.ca/x/xYI2Ag

        function testFilterDeviceCode(this)
            devices = this.testSingleFilter('getDevices', {'deviceCode', 'NORTEKADCP9917'}, 1, 1);
            verifyEqual(this, devices(1).deviceCode, 'NORTEKADCP9917');
        end

        function testFilterDeviceName(this)
            devices = this.testSingleFilter('getDevices', {'deviceName', 'Nortek Aquadopp HR-Profiler 2965'}, 1, 1);
            verifyEqual(this, devices(1).deviceCode, 'BC_POD1_AD2M');
        end

        function testFilterLocationCode(this)
            devices = this.testSingleFilter('getDevices', {'locationCode', 'CQSBG'}, 1, NaN);
        end

        function testFilterDeviceCategoryCode(this)
            devices = this.testSingleFilter('getDevices', {'deviceCategoryCode', 'CTD'}, 100, NaN);
        end

        function testFilterPropertyCode(this)
            devices = this.testSingleFilter('getDevices', {'propertyCode', 'co2concentration'}, 2, NaN);
        end

        function testFilterDataProductCode(this)
            devices = this.testSingleFilter('getDevices', {'dataProductCode', 'MP4V'}, 20, NaN);
        end
    end
end
