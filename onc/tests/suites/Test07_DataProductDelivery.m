% DataProductsDelivery test suite
%   Contains test cases for the dataProducts discovery service.

classdef Test07_DataProductDelivery < matlab.unittest.TestCase
    %% Private Properties
    properties (SetAccess = private)
        onc
        outPath
        maxRetries     % default max Number of orderDataProduct() retries
        Params = struct( ...
            'dataProductCode', 'TSSP',              ...
            'extension', 'png',                     ...
            'dateFrom', '2019-08-29', ...
            'dateTo', '2019-08-30',   ...
            'locationCode', 'CRIP.C1',                ...
            'deviceCategoryCode', 'CTD',       ...                ...
            'dpo_qualityControl', '1',              ...
            'dpo_resample', 'none'...
            );

        expectedFields = struct('url', 'char', ...
                                'status', 'char', ...
                                'size', 'int', ...
                                'file', 'char', ...
                                'index', 'char', ...
                                'downloaded' , 'logical', ...
                                'requestCount', 'int', ...
                                'fileDownloadTime', 'double');
    end

    methods (TestClassSetup)
        function classSetup(this)
            config = load_config();
            this.outPath = 'output';
            this.onc = Onc(config.token, config.production, config.showInfo, this.outPath, config.timeout);
            this.maxRetries = 100;
        end

    end
    
    methods (TestClassTeardown)
        function cleanSuite(this)
            if isfolder(this.outPath)
                rmdir(this.outPath, 's');
            end
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        function updateOncOutPath(this, outPath) 
            this.onc = Onc(this.onc.token, this.onc.production, this.onc.showInfo, outPath, this.onc.timeout);
        end        
    end


    %% Test method
    %% Testing order method
    methods (Test)

        function testInvalidParamValue(this)
            filters = this.Params;
            filters.dataProductCode ='XYZ123';
            verifyError(this, @() this.onc.orderDataProduct(filters, this.maxRetries), 'onc:http400:error127');
        end

        function testValidDefault(this)
            this.updateOncOutPath('output/testValidDefault');
            result = this.onc.orderDataProduct(this.Params);
            verifyTrue(this, length(result.downloadResults) == 3, ...
                'The first two are png files, and the third one is the metadata.');        
            assertEqual(this, result.downloadResults(1).status, 'complete');
            assertEqual(this, result.downloadResults(1).index, '1');
            assertTrue(this, result.downloadResults(1).downloaded);


            assertEqual(this, result.downloadResults(3).status, 'complete');
            assertEqual(this, result.downloadResults(3).index, 'meta');
            assertTrue(this, result.downloadResults(3).downloaded);
            
            verify_files_in_path(this, this.onc.outPath, 3);
            verify_field_value_type(this, result.downloadResults(1), this.expectedFields);
        end

        function testValidNoMetadata(this)
            this.updateOncOutPath('output/testValidNoMetadata');
            result = this.onc.orderDataProduct(this.Params, 'includeMetadataFile', false);
            verifyTrue(this, length(result.downloadResults) == 2);
            assertEqual(this, result.downloadResults(1).status, 'complete');
            assertEqual(this, result.downloadResults(1).index, '1');
            assertTrue(this, result.downloadResults(1).downloaded);
            
            verify_files_in_path(this, this.onc.outPath, 2, 'The first two are png files.');
            verify_field_value_type(this, result.downloadResults(1), this.expectedFields);
        end

        function testValidResultsOnly(this)
            this.updateOncOutPath('output/testValidResultsOnly');
            result = this.onc.orderDataProduct(this.Params, 'downloadResultsOnly', true);
            verifyTrue(this, length(result.downloadResults) == 3, ...
                'The first two are png files, and the third one is the metadata.');        
            assertEqual(this, result.downloadResults(1).status, 'complete');
            assertEqual(this, result.downloadResults(1).index, '1');
            assertTrue(this, ~result.downloadResults(1).downloaded);


            assertEqual(this, result.downloadResults(3).status, 'complete');
            assertEqual(this, result.downloadResults(3).index, 'meta');
            assertTrue(this, ~result.downloadResults(3).downloaded);
            
            verify_files_in_path(this, this.onc.outPath, 0, 'No files should be downloaded when download_results_only is True.');
            verify_field_value_type(this, result.downloadResults(1), this.expectedFields);
           
            
        end
        
        %% Testing run method
        function testInvalidRequestId(this)
            verifyError(this, @() this.onc.runDataProduct(1234567890), 'onc:http400:error127');
        end
        
        %% Testing download method
        function testInvalidRunId(this)
            verifyError(this, @() this.onc.downloadDataProduct(1234567890), 'onc:http400:error127');
        end

        %% Testing cancel method
        function testCancelWithInvalidRequestId(this)
            verifyError(this, @() this.onc.cancelDataProduct(1234567890), 'onc:http400:error127');
        end

        %% Testing status method
        function testStatusWithInvalidRequestId(this)
            verifyError(this, @() this.onc.checkDataProduct(1234567890), 'onc:http400:error127');
        end

        %% Testing restart method
        function testRestartWithInvalidRequestId(this)
            verifyError(this, @() this.onc.restartDataProduct(1234567890), 'onc:http400:error127');
        end

        %% Integration tests
        function testValidManual(this)
            this.updateOncOutPath('output/testValidManual');
            requestId = this.onc.requestDataProduct(this.Params).dpRequestId;
            statusBeforeDownload = this.onc.checkDataProduct(requestId);

            assertEqual(this, statusBeforeDownload.searchHdrStatus, 'OPEN');
            
            runId = this.onc.runDataProduct(requestId).runIds(1);
            data   = this.onc.downloadDataProduct(runId);
            verifyTrue(this, length(data) == 3, ...
                'The first two are png files, and the third one is the metadata.');        
            assertEqual(this, data(1).status, 'complete');
            assertEqual(this, data(1).index, '1');
            assertTrue(this, data(1).downloaded);


            assertEqual(this, data(3).status, 'complete');
            assertEqual(this, data(3).index, 'meta');
            assertTrue(this, data(3).downloaded);
            
            verify_files_in_path(this, this.onc.outPath, 3);
            verify_field_value_type(this, data(1), this.expectedFields);
            
            statusAfterDownload = this.onc.checkDataProduct(requestId);
            assertEqual(this, statusAfterDownload.searchHdrStatus, 'COMPLETED');
        end

        function testValidCancelRestart(this)
            this.updateOncOutPath('output/testValidCancelRestart');
            requestId = this.onc.requestDataProduct(this.Params).dpRequestId;
            runId = this.onc.runDataProduct(requestId, false).runIds(1);
            responseCancel = this.onc.cancelDataProduct(requestId);

            verify_field_value(this, responseCancel, 'dpRunId', runId);
            verify_field_value(this, responseCancel, 'status', 'cancelled');

            %update MATLAB:nonExistentField error to actual http400 error for this test 
            %after api service fixes the issue that this 400 error does not contain "errors" field
            assertError(this, @() this.onc.downloadDataProduct(runId), 'MATLAB:nonExistentField')

            runIdAfterRestart = this.onc.restartDataProduct(requestId).runIds(1);
            assertEqual(this, runIdAfterRestart, runId);

            responseDownload = this.onc.downloadDataProduct(runId);
            assertEqual(this, length(responseDownload), 3,  "The first two are png files, and the third one is the metadata");
            verify_files_in_path(this, this.onc.outPath, 3);
            verify_field_value_type(this, responseDownload(1), this.expectedFields);
        end
    end
        

    
end
