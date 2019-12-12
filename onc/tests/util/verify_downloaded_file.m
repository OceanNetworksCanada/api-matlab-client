function fileExists = verify_downloaded_file(testCase, path)
%verify_downloaded_file Verifies that the file in path exists
%   path {string} is an absolute file path
    fileExists = (exist(path, 'file') == 2);
    verifyTrue(testCase, fileExists);
end
