classdef Test09_ArchiveFiles < matlab.unittest.TestCase
    properties (SetAccess = private)
        onc
        F_LOCATION1 = struct("locationCode", "RISS", "deviceCategoryCode", "VIDEOCAM", "dateFrom", "2016-12-01T00:00:00.000Z", "dateTo", "2016-12-01T01:00:00.000Z");
        F_LOCATION3 = struct("locationCode", "RISS", "deviceCategoryCode", "VIDEOCAM", "dateFrom", "2016-12-01T00:00:00.000Z", "dateTo", "2016-12-01T01:00:00.000Z", "rowLimit", 5);
        F_LOCATIONFULL = struct("locationCode", "RISS", "deviceCategoryCode", "VIDEOCAM", "dateFrom", "2016-12-01T00:00:00.000Z", "dateTo", "2016-12-01T01:00:00.000Z", "extension", "mp4");
        F_LOC_RETURN1 = struct("locationCode", "RISS", "deviceCategoryCode", "VIDEOCAM", "dateFrom", "2016-12-01T00:00:00.000Z", "dateTo", "2016-12-01T01:00:00.000Z", "rowLimit", 5, "returnOptions", "archiveLocation");
        F_LOC_RETURN2 = struct("locationCode", "RISS", "deviceCategoryCode", "VIDEOCAM", "dateFrom", "2016-12-01T00:00:00.000Z", "dateTo", "2016-12-03T00:00:00.000Z", "rowLimit", 50, "returnOptions", "all", "extension", "mp4");
        F_DEVICE1 = struct("dateFrom", "2010-01-01T00:00:00.000Z", "dateTo", "2010-01-01T00:02:00.000Z");
        F_DEVICE1EXT = struct("deviceCode", "NAXYS_HYD_007", "dateFrom", "2010-01-01T00:00:00.000Z", "dateTo", "2010-01-01T00:02:00.000Z", "extension", "mp3");
        F_GETDIRECT_DEV = struct("dateFrom", "2010-01-01T00:00:00.000Z", "dateTo", "2010-01-01T00:00:30.000Z", "deviceCode", "NAXYS_HYD_007", "returnOptions", "all");
        F_GETDIRECT_LOC = struct("dateFrom", "2016-12-01T00:00:00.000Z", "dateTo", "2016-12-01T01:00:00.000Z", "locationCode", "RISS", "deviceCategoryCode", "VIDEOCAM", "extension", "mp4");
        F_FAKE = struct("locationCode", "AREA51");
    end
    
    methods (TestClassSetup)
        function prepareSuite(testCase)
            s = rmdir('tests/output/09', 's'); % delete directory contents
        end
    end
    
    methods (TestClassTeardown)
        function cleanSuite(testCase)
            s = rmdir('tests/output/09', 's'); % delete directory contents
        end
    end
    
    %% Public Methods
    methods
        % Constructor
        function this = Test09_ArchiveFiles()
            % prepare generic onc object
            global config;
            this.onc = Onc(config.token, config.production, config.showInfo, 'output/09', config.timeout);
        end
        
        function onc = prepareOnc(this, outPath)
            global config;
            if ~isempty(outPath)
                delete(sprintf('%s/*', outPath));
            end
            onc = Onc(config.token, config.production, config.showInfo, outPath, config.timeout);
        end
    end
    
    %% Test methods
    methods (Test)
        %% General test cases
        
        function test01_list_by_location_1_page(this)
            result = this.onc.getListByLocation(this.F_LOCATION1);
            verifyLength(this, result.files, 15);
        end

        function test02_list_by_location_3_pages(this)
            result = this.onc.getListByLocation(this.F_LOCATION1, true);
            verifyLength(this, result.files, 15);
        end

        function test03_list_by_location_1_page_filter_ext(this)
            result = this.onc.getListByLocation(this.F_LOCATIONFULL);
            verifyLength(this, result.files, 1);
        end

        function test04_list_by_location_wrong_filters(this)
            result = this.onc.getListByLocation(this.F_DEVICE1);
            verify_error_response(this, result);
        end

        function test05_list_by_device_1_page_filter_ext(this)
            result = this.onc.getListByDevice(this.F_DEVICE1EXT);
            verifyLength(this, result.files, 4);
        end

        function test06_get_file(this)
            onc9 = this.prepareOnc('output/09/06');
            onc9.getFile('NAXYS_HYD_007_20091231T235919.476Z-spect-small.png');
            verify_files_in_path(this, onc9.outPath, 1);
        end

        function test07_direct_files_device_returnOptions(this)
            onc9 = this.prepareOnc('output/09/07');
            result = onc9.getDirectFiles(this.F_GETDIRECT_DEV);
            verify_files_in_path(this, onc9.outPath, 12);
            verifyLength(this, result.downloadResults, 12);
        end

        function test08_direct_files_location_overwrite(this)
            onc9 = this.prepareOnc('output/09/08');
            result = onc9.getDirectFiles(this.F_GETDIRECT_LOC);
            verifyLength(this, result.downloadResults, 1);
            verify_field_value(this, result.downloadResults(1), 'status', 'completed');
            verify_files_in_path(this, onc9.outPath, 1);
            result = onc9.getDirectFiles(this.F_GETDIRECT_LOC);
            verifyLength(this, result.downloadResults, 1);
            verify_field_value(this, result.downloadResults(1), 'status', 'skipped');
            verify_files_in_path(this, onc9.outPath, 1);
        end

        function test09_getfile_wrong_filename(this)
            onc9 = this.prepareOnc('output/09/09');
            result = onc9.getFile('FAKEFILE.XYZ');
            verify_error_response(this, result);
        end

        function test10_direct_files_no_source(this)
            onc9 = this.prepareOnc('output/09/10');
            verifyError(this, ...
                @() onc9.getDirectFiles(this.F_FAKE), ...
                'Archive:InvalidFilters');
        end

        function test11_list_by_device_wrong_filters(this)
            result = this.onc.getListByDevice(this.F_FAKE);
            verify_error_response(this, result);
        end

        function test12_list_by_location_3_pages_archiveLocations(this)
            result = this.onc.getListByLocation(this.F_LOC_RETURN1, true);
            verifyLength(this, result.files, 15);
            verify_has_field(this, result.files(1), 'archiveLocation');
        end

        function test13_list_by_device_3_pages_extension_all(this)
            result = this.onc.getListByLocation(this.F_LOC_RETURN2, true);
            verifyLength(this, result.files, 2);
            verify_has_field(this, result.files(1), 'uncompressedFileSize')
        end

        function test14_save_file_empty_outpath(this)
            filename = 'NAXYS_HYD_007_20091231T235919.476Z-spect-small.png';
            onc9   = this.prepareOnc('');
            result = onc9.getFile(filename);
            verifyTrue(this, isfile(filename));
            delete(filename); % clean up
        end

    end
end