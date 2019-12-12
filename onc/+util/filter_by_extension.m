% Filter file list results to only those where the filename ends with the extension
% If extension is empty no change will be made
% @keywords internal
%
% @param self      Calling object
% @param results   Results as otained by getListByLocation() or getListByDevice()
% @param extension (character) Extension to search for (i.e. 'txt')
%
% @return Filtered list
function results = filter_by_extension(results, extension)
    if isempty(extension), return; end

    extension = sprintf('.%s', extension); % match the dot to avoid matching substrings
    n = length(extension);

    % determine the row structure
    isStructRow = false;
    if ~isempty(results.files)
        if isa(results.files(1), 'struct')
            isStructRow = true;
        end
    end

    % preallocate an array of flags
    flags = zeros([n, 1], 'logical');

    % set a flag for all found elements
    for i = 1 : numel(results.files)
        file = results.files(i);
        if isa(file, 'cell'), file = file{1}; end

        if isStructRow
            fileExt = file.filename(end - n + 1 : end);
        else
            fileExt = file(end - n + 1 : end);
        end

        if strcmp(fileExt, extension)
            flags(i) = true;
        end
    end

    results.files = results.files(flags == 1);
end