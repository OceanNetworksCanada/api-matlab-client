import matlab.unittest.TestSuite;
clc;

addpath(genpath(''));
addpath(genpath('util'));
addpath(genpath('suites'));
addpath(genpath('../'));
    
% Change the current folder to the folder of this m-file.
if(~isdeployed)
  cd(fileparts(which(mfilename)));
end

% configuration used by default unless test cases say otherwise
global config;
config.production = true;
config.showInfo = false;
config.outPath = 'output';
config.timeout = 60;

% grab token from "TOKEN" file
f = fopen('TOKEN','r');
line = fgetl(f);
fclose(f);
config.token = strtrim(line);
