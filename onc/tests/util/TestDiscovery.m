classdef TestDiscovery < matlab.unittest.TestCase
% Discovery services generic test model 
%   Contains common utility functions for discovery test cases
    %% Private Properties
    properties (SetAccess = private)
        o                   % ONC object
        expectedFields      % Map of string array with field names expected in a locations response
    end
    
    %% Public Methods
    methods
        
        function obj = TestDiscovery()
            % Constructor
            global config;
            obj.o = Onc(config.token, config.production, config.showInfo, config.outPath, config.timeout);
            
            obj.expectedFields = containers.Map;
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        
        function verify_min_length(this, data, min)
            % Verifies that data has a min length
            verifyGreaterThanOrEqual(this, length(data), min);
        end
        
        function result = testSingleFilter(this, methodName, filters, minRows, maxRows)
            % Generic single filter test with validation for expected
            % filters and min/max result rows
            %   methodName {String} Name of the method to invoke on ONC object
            %   filters {CellArray} Cell array of strings, with key, value pairs
            %   minRows {Number} Min number of rows expected or NaN for no limit
            %   maxRows {Number} Max number of rows expected or NaN for no limit
            result = this.o.(methodName)(filters);
            fields = this.expectedFields(methodName);
            verify_fields(this, result, fields);
            if ~isnan(minRows)
                verifyGreaterThanOrEqual(this, length(result), minRows);
            end
            if ~isnan(maxRows)
                verifyLessThanOrEqual(this, length(result), maxRows);
            end
        end
    end
end