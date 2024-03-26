function config = globals()
    clc;
            
    addpath(genpath(''));
    addpath(genpath('util'));
    addpath(genpath('suites'));
    addpath(genpath('../'));
            

    % grab token from "TOKEN" file
    f = fopen('TOKEN','r');
    if f > 0
       line = fgetl(f);
       fclose(f);
    else
       line = getenv('TOKEN_STRING');
    end
    
    % Set and save config
    config.production = true;
    config.showInfo = false;
    config.outPath = 'output';
    config.timeout = 60;
    config.token = strtrim(line);    

    save('config.mat', 'config')
end
