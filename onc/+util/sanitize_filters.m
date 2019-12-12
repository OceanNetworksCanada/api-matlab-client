% Preprocess filters to fit the expected structure
function r = sanitize_filters(filters)
    % Make sure filters are a struct
    if class(filters) == "cell"
        r = struct();
        
        s = size(filters);
        rows = s(1);
        cols = s(2);
        
        if (rows > 1) && (cols == 2)
            % if the cell array has 2 columns, interpret properly
            for row = 1 : rows
                name = filters{row, 1};
                value = filters{row, 2};
                r.(name) = value;
            end
        else
            % suppose filters is a 1-row cell array
            n = numel(filters);
            for i = 1 : 2 : n
                name = filters{i};
                value = filters{i + 1};
                r.(name) = value;
            end
        end
    else
        r = filters;
    end
    
    % translate boolean values to strings
    names = fieldnames(r);
    for i = 1 : numel(names)
        name = names{i};
        if strcmp(class(r.(name)), "logical")
            if (r.(name) == true)
                r.(name) = "true";
            else
                r.(name) = "false";
            end
        end
    end
end
