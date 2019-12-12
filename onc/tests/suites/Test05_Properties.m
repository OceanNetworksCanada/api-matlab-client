% Properties test suite
%   Contains test cases for the properties discovery service.

classdef Test05_Properties < TestDiscovery

    %% Public Methods
    methods

        function obj = Test05_Properties()
            % Constructor
            obj@TestDiscovery();
            obj.expectedFields('getProperties') = ["description", "hasDeviceData", "hasPropertyData", "propertyCode", "propertyName", "uom"];
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases

        function testGetAllProperties(this)
            % Make an unfiltered properties request
            % verifies: expected fields, minimum rows
            properties = this.o.getProperties();
            verify_fields(this, properties, this.expectedFields('getProperties'));
            this.verify_min_length(properties, 150);
        end

        function testWrongPropertyCode(this)
            % try an invalid propertyCode, verify error structure
            properties = this.o.getProperties({'propertyCode', 'XYZ321'});
            verify_error_response(this, properties);
        end

        function testNoPropertiesFound(this)
            % try a properties query with 0 results, verify result is an empty 0x0 matrix
            properties = this.o.getProperties({'locationCode', 'SAAN', 'deviceCategoryCode', 'POWER_SUPPLY'});
            verifyEqual(this, size(properties), [0 0]);

        end
        %% Single filter test cases
        % These tests invoke getProperties with a single filter, for every supported filter
        % Verifications according to tests documentation at: https://internal.oceannetworks.ca/x/xYI2Ag

        function testFilterPropertyCode(this)
            properties = this.testSingleFilter('getProperties', {'propertyCode', 'absolutehumidity'}, 1, 1);
            verifyEqual(this, properties(1).propertyCode, 'absolutehumidity');
        end

        function testFilterPropertyName(this)
            properties = this.testSingleFilter('getProperties', {'propertyName', 'Bender Electrical Resistance'}, 1, 1);
            verifyEqual(this, properties(1).propertyCode, 'benderelectricalresistance');
        end

        function testFilterDescription(this)
            properties = this.testSingleFilter('getProperties', {'description', 'Kurtosis Statistical Analysis'}, 1, 1);
            verifyEqual(this, properties(1).propertyCode, 'kurtosisstatisticalanalysis');
        end

        function testFilterLocationCode(this)
            properties = this.testSingleFilter('getProperties', {'locationCode', 'ROVMP'}, 10, NaN);
        end

        function testFilterDeviceCategoryCode(this)
            properties = this.testSingleFilter('getProperties', {'deviceCategoryCode', 'CTD'}, 10, NaN);
        end

        function testFilterDeviceCode(this)
            properties = this.testSingleFilter('getProperties', {'deviceCode', 'ALECACTW-CAR0014'}, 3, NaN);
        end
    end
end
