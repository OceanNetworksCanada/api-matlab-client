function text = format_size(numBytes)
    if numBytes == 0
        text = '0 bytes';
        return;
    end

    % Common names for sizes:
    powers = 1000.^(0:8);
    units = {'bytes','KB','MB','GB','TB','PB','EB','ZB','YB'};

    % Find the correct index to use:
    ind = find(powers < numBytes, 1, 'last');

    % Print a message in the command window:
    text = sprintf('%s %s', num2str(numBytes / powers(ind), '%0.2f'), units{ind});
end
