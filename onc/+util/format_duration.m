function text = format_duration(secs)
    duration = seconds(secs);

    if secs < 60
        text = sprintf('%.2f seconds', secs);
    elseif (secs > 60) && (secs < 3600)
        duration.Format = 'mm:ss';
        text = sprintf('%s', char(duration));
    else
        duration.Format = 'hh:mm:ss';
        text = sprintf('%s', char(duration));
    end
end
