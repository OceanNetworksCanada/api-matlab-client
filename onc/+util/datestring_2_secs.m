% Returns a UNIX timestamp for seconds representing a ISO8601 DateString
function secs = datestring_2_secs(datestring)
    dt = datetime(datestring, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
    secs = posixtime(dt);