function verify_has_field(testCase, data, fieldName)
%VERIFYFIELDVALUE Verifies that the data is a structire with field fieldName
%   Throws a soft failure if the field is not a member
    verifyTrue(testCase, isfield(data, fieldName));
end

