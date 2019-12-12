function valid = verify_fields(obj, data, fieldsList)
    % Verifies that all fields in "fieldsList" appear in "data" array structure
    %   Throws a verification soft failure if a field is not found
    valid = true;

    for n = 1 : length(fieldsList)
        fieldName = fieldsList(n);
        isField = isfield(data, fieldName);
        verifyTrue(obj, isField);
        if isField == 0
            fprintf('Expected field not found: %s\n', fieldName);
            valid = false;
        end
    end
end
