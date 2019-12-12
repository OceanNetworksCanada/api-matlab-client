% Pretty prints a complex hierarchy of lists
% 
% Note that this is only a convenience function and might round
% printed values due to MATLAB's printf implementation
%
% @param item  Hierarchy item (can be a list or an atomic element)
% @param name  (character) Item name if its an element in a named list
% @param level (numeric)   Depth level in the hierarchy, starting at 0
% @param comma (logical)   If TRUE, a comma is printed after this element
% @param file  A file connection to an open file if we should print to it,
%               or "" (no file, print to console)
function pretty_print(item, key, level)
    spacer = repmat('    ', 1, level);
    type = class(item);
    isList = (isvector(item) && (length(item) > 1));

    % print spacer
    fprintf('%s', spacer);
    
    % print scalar variable
    if (length(key) > 0), fprintf('%s: ', key); end

    % special case: empty array [] or string ''
    if isempty(item)
        if ischar(item)
            fprintf("''");
        else
            fprintf('[]');
        end
    elseif iscell(item)
        % print as cell array (only cells of non-complex types are supported)
        fprintf('{\n');
        n = numel(item);
        for i = 1 : n
            util.pretty_print(item{i}, '', level + 1);

            if (i < n), fprintf(','); end
            fprintf('\n');
        end
        fprintf('%s}', spacer);
    elseif isList
        if ischar(item)
            fprintf("\'%s\'", item);
        else
            % print as array
            n = numel(item);
            fprintf('[\n');
            if isstruct(item)
                for i = 1 : n
                    util.pretty_print(item(i), '', level + 1);
                    
                    if (i < n), fprintf(','); end
                    fprintf('\n');
                end
            else
                for i = 1 : n
                    val = item(i);
                    if (mod(val, 1) == 0)
                        fprintf('%s    %d', spacer, val);
                    else
                        fprintf('%s    %g', spacer, val);
                    end
                    if (i < n), fprintf(','); end
                    fprintf('\n');
                end
            end
            fprintf('%s]', spacer);
        end
    else
        if isstruct(item)
            % print structure
            fprintf('struct(\n');
            names = fieldnames(item);
            for i = 1 : numel(names)
                name  = names{i};
                value = item.(name);
                util.pretty_print(value, name, level + 1);
                fprintf('\n');
            end
            fprintf('%s)', spacer);
        else
            if ischar(item)
                fprintf("'%s'", item);
            elseif isinteger(item)
                fprintf('%d', item);
            elseif isnumeric(item)
                if (mod(item, 1) == 0)
                    fprintf('%d', item);
                else
                    fprintf('%g', item);
                end
            elseif islogical(item)
                if (item), fprintf('true'); else, fprintf('false'); end
            else
                fprintf("'%s'", item);
            end
        end
    end
    
    if (level == 0)
        fprintf('\n');
    end
end
