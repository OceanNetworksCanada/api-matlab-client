function tree = extract_tree(this)
%Code to extract the Search Tree, and all of the "location codes"
%Can run with no input and get the entire tree, or give it a starting point
%further down the tree.  The codes for these can be found in Search Tree
%Maintenance. These codes can then be used for input to onc.getDevices by
%providing the locationCodes 
%
% Ex. 1 : All ONC locations
% tree = extract_tree
% Ex. 2: Just the Salish Sea
% tree = extract_tree('SAL')
%
% Example usage once extracted:
% >> my_token = '17x081dx-x36x-48c1-x930-01b2d1697x83';  % Found in your ONC profile
% >> onc = Onc(my_token);
% Then, type: 
% >> onc.tree
% Then click the "tab" key to see all options, and select one. Continue to
% add periods and select tab-completion until you've narrowed down your
% desired site.  
% >> onc.tree.Pacific.Salish_Sea.Baynes_Sound.Baynes_Sound_Mooring.L2mbss.aa_info


%if nargin == 0
    filters = {'locationCode', 'ONC'};
%else
%    filters = {'locationCode', varargin{1}};
%end

%filters = {'locationCode', %'ARCT','dateFrom','2019-07-27T00:00:00.000Z','dateTo','2019-08-27T00:00:00.000Z'}; % Not compatible with getTree
result = this.getLocationHierarchy(filters);
%onc.print(result);
%To get this to work, I had to edit the code in OncDiscovery L118 to
%actually use the "getTree" method... was not properly working, and was
%continuing to use the "get" method  

%GOAL: Create a tab/auto-complete dictionary for reference ti easily scan through the
%search tree directory and get site and device codes

field{1,1} = result.locationName; %Arctic
%tree.(field{1,1}) = field{1,1};

%Info for the top Level
struct_set_info{1} = 'locationCode';
struct_set_info{2} = result.locationCode;
struct_set_info{3} = 'locationName';
struct_set_info{4} = result.locationName;
struct_set_info{5} = 'hasDeviceData';
struct_set_info{6} = result.hasDeviceData;
struct_set_info{7} = 'description';
struct_set_info{8} = result.description;
struct_set{1} = 'aa_info';
struct_set{2} = struct(struct_set_info{:});
%Children of the top Level:
for ii=1:size(result.children,1) 
    treeLocationName = strjoin(strsplit(result.children(ii).locationName,' '),'');
    treeLocationName = strjoin(strsplit(treeLocationName,'-'),'');
    %result.children(ii).locationName = strjoin(strsplit(result.children(ii).locationName,' '),'');
    %result.children(ii).locationName = strjoin(strsplit(result.children(ii).locationName,'-'),'');
    struct_set{2*(ii+1) - 1} = treeLocationName;
    struct_set{2*(ii+1)} = '';
end
tree = struct(struct_set{:});


%Enter a recursive loop to construct the tree:
tree = probe_children(result.children, tree);

    
end


function tree = probe_children(input, tree)
%This is a recursive loop to get details about each child

    % Constants
    CHAR_REPLACEMENT = {...
        'áàâäãå', 'a'; ...
        'ÁÀÂÄÃÅ', 'A'; ...
        'œéèêë', 'e'; ...
        'ÉÈÊË', 'E'; ...
        'íìîï', 'i'; ...
        'ÍÌÎÏ', 'I'; ...
        'óòôöõø', 'o'; ...
        'ÓÒÔÖÕØ', 'O'; ...
        'úùûü', 'u'; ...
        'ÚÙÛÜ', 'U'; ...
        'ýÿ', 'y'; ...
        'Ý', 'Y'; ...
        'ç', 'c'; ...
        'Ç', 'C'; ...
        'ñ', 'n'; ...
        'Ñ', 'N'; ...
    };

    for ii=1:size(input,1)
        %Clear variables:
        clear struct_set struct_set_info
        
        %Info for the top Level
        struct_set_info{1} = 'locationCode';
        struct_set_info{2} = input(ii).locationCode;
        struct_set_info{3} = 'locationName';
        struct_set_info{4} = input(ii).locationName;
        struct_set_info{5} = 'hasDeviceData';
        struct_set_info{6} = input(ii).hasDeviceData;
        struct_set_info{7} = 'description';
        struct_set_info{8} = input(ii).description;
        struct_set{1} = 'aa_info';
        struct_set{2} = struct(struct_set_info{:});
        %Children of the top Level:
        for jj=1:size(input(ii).children,1)
            %location_name = input(ii).children(jj).locationName;
            treeLocationName = strjoin(strsplit(input(ii).children(jj).locationName,' '),'_');
            treeLocationName = strjoin(strsplit(treeLocationName,'-'),'_');
            treeLocationName = strjoin(strsplit(treeLocationName,'('),'_');
            treeLocationName = strjoin(strsplit(treeLocationName,')'),'_');
            treeLocationName = strjoin(strsplit(treeLocationName,'.'),'_');
            treeLocationName = strjoin(strsplit(treeLocationName,''''),'_');
            treeLocationName = strjoin(strsplit(treeLocationName,'/'),'_');
    
            % Check for and remove accents in location name characters
            if any(~isempty(intersect(inputStr, strjoin(CHAR_REPLACEMENT(:, 1), ''))))
                treeLocationName = replaceaccentcharacters(treeLocationName, CHAR_REPLACEMENT);
            end
            
            %Split and check to see if the first character is a number
            split_parts = strsplit(treeLocationName,'_');
            if isempty(split_parts{1})
                for kk=1:length(split_parts)-1
            	    split_parts{kk} = split_parts{kk+1};
                end
                split_parts = split_parts(1:end-1);
            
            elseif ~isnan(str2double(split_parts{1}(1)))  
                if length(split_parts)>1
                    temp = split_parts{1};
                    split_parts{1} = split_parts{2};
                    split_parts{2} = temp;
                else
                    split_parts{1} = ['L',split_parts{1}]; 
                end
            end
            treeLocationName = strjoin(split_parts,'_');
                
            struct_set{2*(jj+1) - 1} = treeLocationName;
            struct_set{2*(jj+1)} = '';
        end
        fieldnames = fields(tree);
        tree.(fieldnames{ii+1}) = struct(struct_set{:});
        
        tree.(fieldnames{ii+1}) = probe_children(input(ii).children, tree.(fieldnames{ii+1}));
        %input(ii).children = probe_children(input(ii).children);
    end
end

function outputStr = replaceaccentcharacters(inputStr, CHAR_REPLACEMENT)
%%---------------------------------------------------------------------
% General:  Replace accented characters with base ASCII equivalents
%
% Input:    inputStr - string containing accented characters
%           CHAR_REPLACEMENT - character array containing non-base ASCII characters and their replacements
%
% Input:    outputStr - string with base ASCII characters only
%
% Modify Date/Author:  20241218, S. Plovie
%---------------------------------------------------------------------

%% Replace accented characters
outputStr = inputStr;
for iCharRep = 1:length(CHAR_REPLACEMENT)
    [~, iOutputStr] = intersect(outputStr, CHAR_REPLACEMENT{iCharRep, 1});
    if ~isempty(iOutputStr)
        outputStr(iOutputStr) = CHAR_REPLACEMENT{iCharRep, 2};
    end
end
end