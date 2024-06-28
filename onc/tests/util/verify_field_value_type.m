function verify_field_value_type(testCase, dataStruct, expectedStruct)
    % Verify that dataStruct contains correct fields and the corresponding values
    % are of the correct variable type
    % 
    % Example input:
    %    dataStruct = struct('fieldName1', data1, 'fieldName2', data2, ...);
    %    expectedStruct = struct('fieldName1', 'int', 'fieldName2', 'char', ...);

    expectedFieldNames = fieldnames(expectedStruct);
    for i = 1 : length(expectedFieldNames)
        currField = expectedFieldNames{i};
        verifyTrue(testCase, isfield(dataStruct, currField));
        if strcmp(expectedStruct.(currField), 'int')
            verifyTrue(testCase, isa(dataStruct.(currField), 'double'));
            % using floor to test if this is an integer
            verifyTrue(testCase, floor(dataStruct.(currField)) == dataStruct.(currField));
        else
            verifyTrue(testCase, isa(dataStruct.(currField), expectedStruct.(currField)));
        end
    end
end