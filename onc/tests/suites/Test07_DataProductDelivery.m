% DataProductsDelivery test suite
%   Contains test cases for the dataProducts discovery service.

classdef Test07_DataProductDelivery < matlab.unittest.TestCase
    %% Private Properties
    properties (SetAccess = private)
        maxRetries     % default max Number of orderDataProduct() retries
        
        % dummy filters for downloading a data product with 1 file
        F_DUMMY1 = struct(                          ...
            'dataProductCode', 'TSSD',              ...
            'extension', 'csv',                     ...
            'locationCode', 'BACAX',                ...
            'deviceCategoryCode', 'ADCP2MHZ',       ...
            'dateFrom', '2016-07-27T00:00:00.000Z', ...
            'dateTo', '2016-07-27T00:00:30.000Z',   ...
            'dpo_dataGaps', '0',                    ...
            'dpo_qualityControl', '1',              ...
            'dpo_resample', 'none');
        
        % dummy filters for downloading a data product with 2 files
        F_DUMMY2 = struct(                          ...
            'dataProductCode', 'TSSP',              ...
            'extension', 'png',                     ...
            'locationCode', 'CRIP.C1',              ...
            'deviceCategoryCode', 'CTD',            ...
            'dateFrom', '2019-03-20T00:00:00.000Z', ...
            'dateTo', '2019-03-20T00:30:00.000Z',   ...
            'dpo_qualityControl', '1',              ...
            'dpo_resample', 'none');
        
        % fake filter
        F_FAKE = struct(                            ...
            'dataProductCode', 'FAKECODE',          ...
            'extension', 'XYZ',                     ...
            'locationCode', 'AREA51',               ...
            'deviceCategoryCode', 'AK47',           ...
            'dateFrom', '2019-03-20T00:00:00.000Z', ...
            'dateTo', '2019-03-20T00:30:00.000Z',   ...
            'dpo_qualityControl', '1',              ...
            'dpo_resample', 'none');
    end

    methods (TestClassSetup)
        function prepareSuite(testCase)
            s = rmdir('tests/output/07', 's'); % delete directory contents
        end
    end
    
    methods (TestClassTeardown)
        function cleanSuite(testCase)
            s = rmdir('tests/output/07', 's'); % delete directory contents
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        
        function validStruct = verifyRowStructure(this, data)
            validStruct = verify_fields(this, data, ["url", "status", "status", "size", "file", "index", "downloaded", "requestCount", "fileDownloadTime"]);
        end

        % Validates that row at index has the status and downloaded provided
        function validateRow(this, rows, varargin)
            [index, status, downloaded] = util.param(varargin, 'index', '1', 'status', 'complete', 'downloaded', false);

            % grab the row at index
            row  = rows(1);
            for i = 1: numel(rows)
                if rows(i).index == index
                    row = rows(i);
                    break;
                end
            end
            verifyInstanceOf(this, row, 'struct');

            % verify properties
            verifyEqual(this, row.status, status);
            verifyEqual(this, row.downloaded, downloaded);
        end

        function cleanDirectory(this, outPath)
            % Deletes all files in output directory
            delete(strcat(outPath, '/*'));
        end

        function onc = prepareOnc(this, outPath)
            global config;
            onc = Onc(config.token, config.production, config.showInfo, outPath, config.timeout);
        end
    end

    %% Public Methods
    methods
        function this = Test07_DataProductDelivery()
            this.maxRetries = 100;
        end
    end

    %% Test methods
    methods (Test)

        function test01_order_product_links_only(this)
            % Order a dummy data product, only obtain the download links
            onc = this.prepareOnc('output/07/01');
            this.cleanDirectory(onc.outPath);
            result = onc.orderDataProduct(this.F_DUMMY1, 100, true, false);
            rows   = result.downloadResults;

            verifyLength(this, rows, 1);
            if verifyRowStructure(this, rows(1))
                this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', false);
                verify_files_in_path(this, onc.outPath, 0);
            end

        end

        function test02_order_links_with_metadata(this)
            onc = this.prepareOnc('output/07/02');
            this.cleanDirectory(onc.outPath);
            result = onc.orderDataProduct(this.F_DUMMY1, 100, true, true);
            rows   = result.downloadResults;
            verifyLength(this, rows, 2);
            if verifyRowStructure(this, rows(1))
                this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', false);
                this.validateRow(rows, 'index', 'meta', 'status', 'complete', 'downloaded', false);
            end
            verify_files_in_path(this, onc.outPath, 0);
        end

        function test03_order_and_download(this)
            onc = this.prepareOnc('output/07/03');
            this.cleanDirectory(onc.outPath);
            result = onc.orderDataProduct(this.F_DUMMY1, 100, false, false);
            rows   = result.downloadResults;
            verifyLength(this, rows, 1);
            if verifyRowStructure(this, rows(1))
                this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', true);
            end
            verify_files_in_path(this, onc.outPath, 1);
        end

        function test04_order_and_download_multiple(this)
            onc = this.prepareOnc('output/07/04');
            this.cleanDirectory(onc.outPath);
            result = onc.orderDataProduct(this.F_DUMMY2, 100, false, false);
            rows   = result.downloadResults;
            verifyLength(this, rows, 2);
            if verifyRowStructure(this, rows(1))
                this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', true);
                this.validateRow(rows, 'index', '2', 'status', 'complete', 'downloaded', true);
            end
            verify_files_in_path(this, onc.outPath, 2);
        end

        function test05_order_and_download_with_metadata(this)
            onc = this.prepareOnc('output/07/05');
            this.cleanDirectory(onc.outPath);
            result = onc.orderDataProduct(this.F_DUMMY1, 100, false, true);
            rows   = result.downloadResults;
            verifyLength(this, rows, 2);
            if verifyRowStructure(this, rows(1))
                this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', true);
                this.validateRow(rows, 'index', 'meta', 'status', 'complete', 'downloaded', true);
            end
            verify_files_in_path(this, onc.outPath, 2);
        end

        function test06_order_and_download_multiple_with_metadata(this)
            onc = this.prepareOnc('output/07/06');
            this.cleanDirectory(onc.outPath);
            result = onc.orderDataProduct(this.F_DUMMY2, 100, false, true);
            rows   = result.downloadResults;
            verifyLength(this, rows, 3);
            if verifyRowStructure(this, rows(1))
                this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', true);
                this.validateRow(rows, 'index', '2', 'status', 'complete', 'downloaded', true);
                this.validateRow(rows, 'index', 'meta', 'status', 'complete', 'downloaded', true);
            end
            verify_files_in_path(this, onc.outPath, 3);
        end

        function test07_wrong_order_request_argument(this)
            onc = this.prepareOnc('output/07/07');
            this.cleanDirectory(onc.outPath);
            verifyError(this, @() onc.orderDataProduct(this.F_FAKE, 100, true, false), 'onc:http400');
        end

        function test08_manual_request_run_and_download(this)
            onc = this.prepareOnc('output/07/08');
            this.cleanDirectory(onc.outPath);
            reqId  = onc.requestDataProduct(this.F_DUMMY1).dpRequestId;
            runId  = onc.runDataProduct(reqId).runIds(1);
            rows   = onc.downloadDataProduct( ...
                     runId, 'maxRetries', 0, 'downloadResultsOnly', false, 'includeMetadataFile', true);
            verifyLength(this, rows, 2);
            this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', true);
            this.validateRow(rows, 'index', 'meta', 'status', 'complete', 'downloaded', true);
            verify_files_in_path(this, onc.outPath, 2);
        end

        function test09_manual_request_run_and_download_results_only(this)
            onc = this.prepareOnc('output/07/09');
            this.cleanDirectory(onc.outPath);
            reqId  = onc.requestDataProduct(this.F_DUMMY1).dpRequestId;
            runId  = onc.runDataProduct(reqId).runIds(1);
            rows   = onc.downloadDataProduct(runId, 'downloadResultsOnly', true, 'includeMetadataFile', true);
            verifyLength(this, rows, 2);
            this.validateRow(rows, 'index', '1', 'status', 'complete', 'downloaded', false);
            this.validateRow(rows, 'index', 'meta', 'status', 'complete', 'downloaded', false);
            verify_files_in_path(this, onc.outPath, 0);
        end

        function test10_manual_run_with_wrong_argument(this)
            onc = this.prepareOnc('output/07/10');
            this.cleanDirectory(onc.outPath);
            verifyError(this, @() onc.runDataProduct(1234568790), 'onc:http400');
        end

        function test11_manual_download_with_wrong_argument(this)
            onc = this.prepareOnc('output/07/11');
            this.cleanDirectory(onc.outPath);
            verifyError(this, ...
                @() onc.downloadDataProduct(1234568790, 'downloadResultsOnly', false, 'includeMetadataFile', true), ...
                'DataProductFile:HTTP400');
        end
    end
end
