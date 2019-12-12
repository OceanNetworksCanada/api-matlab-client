function verify_field_value_not_empty(testCase, data, fieldName)
%verify_field_value_not_empty Throws a verification failure if data.fieldName exists but is an empty string
%   Doesn't do anything if the field doesn't exist
    if isfield(data, fieldName)
        verifyNotEqual(testCase, data.(fieldName), '');
    end
end
