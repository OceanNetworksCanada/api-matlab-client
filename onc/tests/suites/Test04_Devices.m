% Devices test suite
%   Contains test cases for the devices discovery service.

classdef Test04_Devices < matlab.unittest.TestCase

    properties
        onc
    end
    
    methods (TestClassSetup)
        function classSetup(this)
            config = globals();
            this.onc = Onc(config.token, config.production, config.showInfo, config.outPath, config.timeout);
        end
    end

    %% Test methods
    methods (Test)
        %% General test cases
        function testInvalidTimeRangeGreaterStartTime(this)
            filters = {'deviceCode', 'BPR-Folger-59','dateFrom', '2020-01-01', 'dateTo', '2019-01-01'};
            verifyError(this, @() this.onc.getDevices(filters), 'onc:http400:error23');
        end

        function testInvalidTimeRangeFutureStartTime(this)
            filters = {'deviceCode', 'BPR-Folger-59', 'dateFrom', '2050-01-01'};
            verifyError(this, @() this.onc.getDevices(filters), 'onc:http400:error25');
        end
        
        function testInvalidParamValue(this)
            filters = {'deviceCode', 'XYZ123'};
            verifyError(this, @() this.onc.getDevices(filters), 'onc:http400:error127');
        end
        
        function testInvalidParamName(this)
            filters = {'fakeParamName', 'BPR-Folger-59'};
            verifyError(this, @() this.onc.getDevices(filters), 'onc:http400:error129');
        end
        
        function testNoData(this)
            filters = {'deviceCode', 'BPR-Folger-59', 'dateTo', '1900-01-01'};
            verifyError(this, @() this.onc.getDevices(filters), 'onc:http404');
        end
        
        function testValidParams(this)
            filters = {'deviceCode', 'BPR-Folger-59', 'dateFrom', '2005-09-17', 'dateTo', '2020-09-17'};
            devices = this.onc.getDevices(filters);
            verifyTrue(this, length(devices) >= 1);
            expectedDevicesFields = ["cvTerm", "dataRating", "deviceCategoryCode", "deviceCode", ...
                                     "deviceId", "deviceLink", "deviceName", "hasDeviceData"];
            verify_fields(this, devices(1), expectedDevicesFields);
            expectedCvTermFields = ["uri", "vocabulary"];
            verify_fields(this, devices(1).cvTerm.device, expectedCvTermFields);
            expectedDataRatingFields = ["dateFrom", "dateTo", "samplePeriod", "sampleSize"];
            verify_fields(this, devices(1).dataRating, expectedDataRatingFields);
        end
    end
end
