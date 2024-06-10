function isLatestVersion = checkVersion()
    url = 'https://github.com/OceanNetworksCanada/api-matlab-client/releases/latest';
    isLatestVersion = 0;
    try
        % get latest version
        releaseInfo = webread(url);
        versionPattern = '<title>Release (\d+\.\d+\.\d+)';
        version = regexp(releaseInfo, versionPattern, 'tokens', 'once');
        latestVersion = version{1};
        % get local version
        librariesVersion = ver;
        localVersion ='0.0.0';
        for i = librariesVersion
            if strcmp(i.Name,'Ocean Networks Canada API Client Library')
                localVersion = i.Version;
                break;
            end
        end

        % compare 
        if ~strcmp(localVersion, latestVersion)
            [oncFolderPath, ~, ~] = fileparts(which('Onc')); 
            localFilePath = [oncFolderPath '\..\doc\UpdateInstruction.html'];
            formattedPath = ['file:///', strrep(localFilePath, '\', '/')];
            link = sprintf('<a href="%s">How to update this library</a>', formattedPath);
            warning(['You are using an outdated version(%s) of the library. Update to the latest version(%s) to avoid potential errors. ' ...
                'For instructions on updating to the latest version, please visit: %s'], localVersion, latestVersion, link);
        else
            isLatestVersion = 1;
        end
    catch ME
        % do nothing
    end
