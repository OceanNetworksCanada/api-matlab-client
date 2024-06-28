function config = globals()
    clc;
 
    addpath(genpath(''));
    addpath(genpath('util'));
    addpath(genpath('suites'));
    addpath(genpath('../'));
            
    % Change the current folder to the folder of this m-file.
    if(~isdeployed)
        cd(fileparts(which(mfilename)));
    end       
    
    % grab token from "TOKEN" file or get from env
    f = fopen('TOKEN','r');
    if f > 0
       token = fgetl(f);
       fclose(f);
    else
       token = getenv('TOKEN');
    end
    
    % get environment from ONC_ENV or use QA as default
    config.production = getenv('ONC_ENV');
    if strcmp(config.production, 'prod')
        config.production = true;
    else
        config.production = false;
    end
    % Set and save config
    config.showInfo = false;
    config.outPath = 'output';
    config.timeout = 60;
    config.token = strtrim(token);    

    save('config.mat', 'config')
end
