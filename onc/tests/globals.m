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
    
    % grab token from "TOKEN" file
    f = fopen('TOKEN','r');
    if f > 0
       token = fgetl(f);
       fclose(f);
    else
       token = getenv('TOKEN');
    end
    
    % Set and save config
    config.production = true;
    config.showInfo = false;
    config.outPath = 'output';
    config.timeout = 60;
    config.token = strtrim(token);    

    save('config.mat', 'config')
end
