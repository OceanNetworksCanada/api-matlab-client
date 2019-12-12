% DataProductsDiscovery test suite
%   Contains test cases for the dataProducts discovery service.

classdef Test06_DataProductDiscovery < TestDiscovery

    %% Public Methods
    methods

        function obj = Test06_DataProductDiscovery()
            % Constructor
            obj@TestDiscovery();
            obj.expectedFields('getDataProducts') = ["dataProductCode", "dataProductName", "extension", "hasDeviceData", "hasPropertyData", "helpDocument"];
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases

        function testGetAllDataProducts(this)
            % Make an unfiltered dataProducts request
            % verifies: expected fields, minimum rows
            dataProducts = this.o.getDataProducts();
            verify_fields(this, dataProducts, this.expectedFields('getDataProducts'));
            this.verify_min_length(dataProducts, 100);
        end

        function testWrongDataProductCode(this)
            % try an invalid dataProductCode, verify error structure
            dataProducts = this.o.getDataProducts({'dataProductCode', 'XYZ321'});
            verify_error_response(this, dataProducts);
        end

        function testNoDataProductsFound(this)
            % try a dataProducts query with 0 results, verify result is an empty 0x0 matrix
            dataProducts = this.o.getDataProducts({'locationCode', 'SAAN', 'deviceCategoryCode', 'POWER_SUPPLY'});
            verifyEqual(this, size(dataProducts), [0 0]);

        end
        %% Single filter test cases
        % These tests invoke getDataProducts with a single filter, for every supported filter
        % Verifications according to tests documentation at: https://internal.oceannetworks.ca/x/xYI2Ag

        function testFilterDataProductCode(this)
            dataProducts = this.testSingleFilter('getDataProducts', {'dataProductCode', 'CPD'}, 1, 1);
            verifyEqual(this, dataProducts(1).dataProductCode, 'CPD');
        end

        function testFilterExtension(this)
            dataProducts = this.testSingleFilter('getDataProducts', {'extension', 'cor'}, 1, 2);
            verifyEqual(this, dataProducts(1).extension, 'cor');
        end

        function testFilterLocationCode(this)
            dataProducts = this.testSingleFilter('getDataProducts', {'locationCode', 'SAAN'}, 1, NaN);
        end

        function testFilterDeviceCategoryCode(this)
            dataProducts = this.testSingleFilter('getDataProducts', {'deviceCategoryCode', 'CTD'}, 20, NaN);
        end

        function testFilterDeviceCode(this)
            dataProducts = this.testSingleFilter('getDataProducts', {'deviceCode', 'BC_POD1_AD2M'}, 5, NaN);
        end

        function testFilterPropertyCode(this)
            dataProducts = this.testSingleFilter('getDataProducts', {'propertyCode', 'oxygen'}, 10, NaN);
        end
    end
end
