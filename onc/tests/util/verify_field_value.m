function verify_field_value(testCase, data, fieldName, expectedValue)
%VERIFYFIELDVALUE Verifies that the fieldName has the expected value only if it exists
%   Does nothing if fieldName doesnt exist
%   If value is not as expected, throws a soft failure on testCase
    if (isfield(data, fieldName))
        verifyEqual(testCase, data.(fieldName), expectedValue);
    end
end

