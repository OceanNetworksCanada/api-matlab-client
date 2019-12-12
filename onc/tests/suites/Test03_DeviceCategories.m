% DeviceCategories test suite
%   Contains test cases for the deviceCategories discovery service.

classdef Test03_DeviceCategories < TestDiscovery

    %% Public Methods
    methods

        function obj = Test03_DeviceCategories()
            % Constructor
            obj@TestDiscovery();
            obj.expectedFields('getDeviceCategories') = ["description", "deviceCategoryCode", "deviceCategoryName", "hasDeviceData", "longDescription"];
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases

        function testGetAllDeviceCategories(this)
            % Make an unfiltered deviceCategories request
            % verifies: expected fields, minimum rows
            deviceCategories = this.o.getDeviceCategories();
            verify_fields(this, deviceCategories, this.expectedFields('getDeviceCategories'));
            this.verify_min_length(deviceCategories, 100);
        end

        function testWrongDeviceCategoryCode(this)
            % try an invalid locationCode, verify error structure
            deviceCategories = this.o.getDeviceCategories({'deviceCategoryCode', 'XYZ321'});
            verify_error_response(this, deviceCategories);
        end

        function testNoDeviceCategoriesFound(this)
            % try a deviceCategories query with 0 results, verify result is an empty 0x0 matrix
            deviceCategories = this.o.getDeviceCategories({'locationCode', 'SAAN', 'propertyCode', 'co2concentration'});
            verifyEqual(this, size(deviceCategories), [0 0]);
        end

        %% Single filter test cases
        % These tests invoke getDeviceCategories with a single filter, for every supported filter
        % Verifications according to tests documentation at: https://internal.oceannetworks.ca/x/xYI2Ag

        function testFilterDeviceCategoryCode(this)
            deviceCategories = this.testSingleFilter('getDeviceCategories', {'deviceCategoryCode', 'ADCP1200KHZ'}, 1, 1);
            verifyEqual(this, deviceCategories(1).deviceCategoryCode, 'ADCP1200KHZ');
        end

        function testFilterDeviceCategoryName(this)
            deviceCategories = this.testSingleFilter('getDeviceCategories', {'deviceCategoryName', 'Current Profiler 1200'}, 1, 1);
            verifyEqual(this, deviceCategories(1).deviceCategoryCode, 'ADCP1200KHZ');
        end

        function testFilterDescription(this)
            deviceCategories = this.testSingleFilter('getDeviceCategories', {'description', '3D Camera'}, 1, 1);
            verifyEqual(this, deviceCategories(1).deviceCategoryCode, 'CAMERA_3D');
        end

        function testFilterLocationCode(this)
            deviceCategories = this.testSingleFilter('getDeviceCategories', {'locationCode', 'CQSBG'}, 1, NaN);
        end

        function testFilterPropertyCode(this)
            deviceCategories = this.testSingleFilter('getDeviceCategories', {'propertyCode', 'co2concentration'}, 1, NaN);
        end
    end
end
