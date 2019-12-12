function validLength = verify_cell_array_length(testCase, data, minRows, maxRows)
    % verifies that a 1D cell array meets min and max dimensions
    %     throws verification soft failures in obj if rules are not met
    %     if min or max are NaN, they are not evaluated
    %     returns number of rows
    validLength = true;
    [~, l] = size(data);

    if ~isnan(minRows)
        if (l < minRows), validLength = false; end
        verifyGreaterThanOrEqual(testCase, l, minRows);
    end
    if ~isnan(maxRows)
        if (l > maxRows), validLength = false; end
        verifyLessThanOrEqual(testCase, l, maxRows);
    end
end
