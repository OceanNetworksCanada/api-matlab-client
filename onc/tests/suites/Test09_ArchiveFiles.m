classdef Test09_ArchiveFiles < matlab.unittest.TestCase
    properties (SetAccess = private)
        onc
        outPath = 'output';
        paramsLocation = struct( ...
                                'locationCode', 'NCBC',...
                                'deviceCategoryCode', 'BPR',...
                                'dateFrom', '2019-11-23',...
                                'dateTo', '2019-11-26',...
                                'fileExtension', 'txt',...
                                'rowLimit', 80000,...
                                'page', 1);

        paramsLocationMultiPages = struct( ...
                                'locationCode', 'NCBC',...
                                'deviceCategoryCode', 'BPR',...
                                'dateFrom', '2019-11-23',...
                                'dateTo', '2019-11-26',...
                                'fileExtension', 'txt',...
                                'rowLimit', 2,...
                                'page', 1);
        
        paramsDevice = struct('deviceCode', 'BPR-Folger-59',...
                            'dateFrom', '2019-11-23',...
                            'dateTo', '2019-11-26',...
                            'fileExtension', 'txt',...
                            'rowLimit', 80000,...
                            'page', 1);

        paramsDeviceMultiPages = struct('deviceCode', 'BPR-Folger-59',...
                                    'dateFrom', '2019-11-23',...
                                    'dateTo', '2019-11-26',...
                                    'fileExtension', 'txt',...
                                    'rowLimit', 2,...
                                    'page', 1);
    end
    
    methods (TestClassSetup)
        function classSetup(this)
            config = load_config();
            this.onc = Onc(config.token, config.production, config.showInfo, this.outPath, config.timeout);
        end
    
    end
    
    methods (TestClassTeardown)
        function cleanSuite(this)
            if isfolder(this.outPath)
                rmdir(this.outPath, 's');
            end
        end
    end
    
    %% Protected helper method
    methods (Access = protected)
        function updateOncOutPath(this, outPath) 
            this.onc = Onc(this.onc.token, this.onc.production, this.onc.showInfo, outPath, this.onc.timeout);
        end        
    end
    
    %% Test methods
    methods (Test)
        %% Testing location
        function testLocationInvalidParamValue(this)
            filters = this.paramsLocation;
            filters.locationCode = 'XYZ123';
            verifyError(this, @() this.onc.getListByLocation(filters), 'onc:http400:error127');
        end

        function testLocationInvalidParamName(this)
            filters = this.paramsLocation;
            filters.fakeParamName = 'NCBC';
            verifyError(this, @() this.onc.getListByLocation(filters), 'onc:http400:error129');
        end

        function testLocationNoData(this)
            filters = this.paramsLocation;
            filters.dateFrom = '2000-01-01';
            filters.dateTo = '2000-01-02';
            verifyError(this, @() this.onc.getListByLocation(filters), 'onc:http400:error127');
        end

        function testLocationValidParamsOnePage(this)
            result = this.onc.getListByLocation(this.paramsLocation);
            resultAllPages = this.onc.getListByLocation(this.paramsLocationMultiPages, 'allPages', true);
            assertTrue(this, length(result.files) > this.paramsLocationMultiPages.rowLimit, ...
                        'Test should return at least `rowLimit` rows.');
            assertEmpty(this, result.next, 'Test should return only one page.');
            assertEqual(this, resultAllPages.files, result.files, ...
                        'Test should concatenate rows for all pages.');
            assertEmpty(this, resultAllPages.next, 'Test should return only one page.');
        end

        function testLocationValidParamsMultiplePages(this)
            result = this.onc.getListByLocation(this.paramsLocationMultiPages);
            assertEqual(this, length(result.files), this.paramsLocationMultiPages.rowLimit, ...
                        'Test should only return `rowLimit` rows.');
            assertTrue(this, ~isempty(result.next), 'Test should return multiple pages.');
        end

        %% Testing device

        function testDeviceInvalidParamValue(this)
            filters = this.paramsDevice;
            filters.deviceCode = 'XYZ123';
            verifyError(this, @() this.onc.getListByDevice(filters), 'onc:http400:error127');
        end

        function testDeviceInvalidParamsMissingRequired(this)
            filters = rmfield(this.paramsDevice, 'deviceCode');
            verifyError(this, @() this.onc.getListByDevice(filters), 'onc:http400:error128');
        end

        function testDeviceInvalidParamName(this)
            filters = this.paramsDevice;
            filters.fakeParamName = 'BPR-Folger-59';
            verifyError(this, @() this.onc.getListByDevice(filters), 'onc:http400:error129');
        end

        function testDeviceNoData(this)
            filters = this.paramsDevice;
            filters.dateFrom = '2000-01-01';
            filters.dateTo = '2000-01-02';
            result = this.onc.getListByDevice(filters);
            assertEmpty(this, result.files);
        end

        function testDeviceValidParamsOnePage(this)
            result = this.onc.getListByDevice(this.paramsDevice);
            resultAllPages = this.onc.getListByDevice(this.paramsDeviceMultiPages, 'allPages', true);
            assertTrue(this, length(result.files) > this.paramsDeviceMultiPages.rowLimit, ...
                        'Test should return at least `rowLimit` rows.');
            assertEmpty(this, result.next, 'Test should return only one page.');
            assertEqual(this, resultAllPages.files, result.files, ...
                        'Test should concatenate rows for all pages.');
            assertEmpty(this, resultAllPages.next, 'Test should return only one page.');
        end

        function testDeviceValidParamsMultiplePages(this)
            result = this.onc.getListByDevice(this.paramsDeviceMultiPages);
            assertEqual(this, length(result.files), this.paramsDeviceMultiPages.rowLimit, ...
                        'Test should only return `rowLimit` rows.');
            assertTrue(this, ~isempty(result.next), 'Test should return multiple pages.');
        end
        
        %% Testing download

        function testDownloadInvalidParamValue(this)
            verifyError(this, @() this.onc.getFile('FAKEFILE.XYZ'), 'onc:http400:error96');
        end

        function testDownloadInvalidParamsMissingRequired(this)
            verifyError(this, @() this.onc.getFile(), 'onc:http400:error128');
        end

        function testDownloadValidParams(this)
            this.updateOncOutPath('output/testDownloadValidParams');
            filename = 'BPR-Folger-59_20191123T000000.000Z.txt';
            this.onc.getFile(filename);
            assertTrue(this, exist([this.onc.outPath '/' filename], 'file') == 2);
            verifyError(this, @() this.onc.getFile(filename), 'onc:FileExistsError');
            this.onc.getFile(filename, 'overwrite', true);
            verify_files_in_path(this, this.onc.outPath, 1);
        end

        %% Testing direct download

        function testDirectDownloadValidParamsOnePage(this)
            this.updateOncOutPath('output/testDirectDownloadValidParamsOnePage');
            data = this.onc.getListByLocation(this.paramsLocation);
            result = this.onc.getDirectFiles(this.paramsLocation);
            verify_files_in_path(this, this.onc.outPath, length(data.files));
            assertEqual(this, result.stats.fileCount, length(data.files));
        end

        function testDirectDownloadValidParamsMultiplePages(this)
            this.updateOncOutPath('output/testDirectDownloadValidParamsMultiplePages');
            result = this.onc.getDirectFiles(this.paramsLocationMultiPages);
            verify_files_in_path(this, this.onc.outPath, this.paramsLocationMultiPages.rowLimit);
            assertEqual(this, result.stats.fileCount, this.paramsLocationMultiPages.rowLimit)
        end
    end
end