% Deployments test suite
%   Contains test cases for the deployments discovery service.

classdef Test02_Deployments < TestDiscovery

    %% Public Methods
    methods

        function obj = Test02_Deployments()
            % Constructor
            obj@TestDiscovery();
            obj.expectedFields('getDeployments') = ["begin", "depth", "deviceCode", "end", "hasDeviceData", "heading", "lat", "locationCode", "lon", "pitch", "roll"];
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases

        function testGetAllDeployments(this)
            % Make an unfiltered deployments request
            % verifies: expected fields, minimum rows
            deployments = this.o.getDeployments();
            verify_fields(this, deployments, this.expectedFields('getDeployments'));
            this.verify_min_length(deployments, 500);
        end

        function testISODateRange(this)
            % Test a date range with format ISO8601
            filters = {'dateFrom', '2014-02-24T00:00:01.000Z', 'dateTo', '2014-03-24T00:00:01.000Z'};
            deployments = this.testSingleFilter('getDeployments', filters, 100, NaN);
        end

        function testWrongLocationCode(this)
            % try an invalid locationCode, verify error structure
            deployments = this.o.getDeployments({'locationCode', 'CQS34543BG'});
            verify_error_response(this, deployments);
        end

        function testNoDeploymentsFound(this)
            % try a deployments query with 0 results, verify result is an empty 0x0 matrix
            deployments = this.o.getDeployments({'locationCode', 'SAAN', 'dateTo', '1995-03-24T00:00:01.000Z'});
            verifyEqual(this, size(deployments), [0 0]);

        end
        %% Single filter test cases
        % These tests invoke getdeployments with a single filter, for every supported filter
        % Verifications according to tests documentation at: https://internal.oceannetworks.ca/x/xYI2Ag

        function testFilterLocationCode(this)
            deployments = this.testSingleFilter('getDeployments', {'locationCode', 'CQSBG'}, 2, NaN);
        end

        function testFilterDeviceCategoryCode(this)
            deployments = this.testSingleFilter('getDeployments', {'deviceCategoryCode', 'CTD'}, 50, NaN);
        end

        function testFilterDeviceCode(this)
            deployments = this.testSingleFilter('getDeployments', {'deviceCode', 'NORTEKADCP9917'}, 1, NaN);
        end

        function testFilterPropertyCode(this)
            deployments = this.testSingleFilter('getDeployments', {'propertyCode', 'co2concentration'}, 1, NaN);
        end
    end
end
