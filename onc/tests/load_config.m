function config = load_config()
    % Change the current folder to the folder of this m-file.
    if(~isdeployed)
        cd(fileparts(which(mfilename)));
    end
    
    % If exist config load directly else run globals to get config
    if exist('config.mat', 'file')
       load('config.mat', 'config');
    else
       config = globals();
    end
