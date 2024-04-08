function ext = extractFileExtension(filename)
    % get extension from filename (string or char array)
    % this function is called by save_as_file.m to decide which download method to use

    filename = char(filename);
    possibleExtensionStartIndex = strfind(filename, '.');
    if ~isempty(possibleExtensionStartIndex)
        extensionStartIndex = possibleExtensionStartIndex(end);
        ext = filename(extensionStartIndex + 1:end);
    else
        ext = '';
    end
end