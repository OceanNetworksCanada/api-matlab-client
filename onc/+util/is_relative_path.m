% true if path provided is relative
function isRelative = is_relative_path(path)
    path = convertStringsToChars(path);
    isRelative = true;

    if path(1) == "/"
        % linux /mac absolute paths start with /
        isRelative = false;
    elseif path(2) == ":"
        % windows absolute path begins with C:\ or similar
        isRelative = false;
    elseif path(1) == "~"
        % linux/mac home path starts with ~
        isRelative = false;
    end
end
