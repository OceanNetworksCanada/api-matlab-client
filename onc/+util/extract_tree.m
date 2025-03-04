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
            treeLocationName = replaceaccentcharacters(treeLocationName);
            
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

function outputStr = replaceaccentcharacters(inputStr)
%%---------------------------------------------------------------------
% General:  Replace accented characters with base ASCII equivalents
%
% Input:    inputStr - string containing accented characters
%           CHAR_REPLACEMENT - character array containing non-base ASCII characters and their replacements
%
% Input:    outputStr - string with base ASCII characters only
%
% Modify Date/Author:  20241218, S. Plovie, A. Slonimer
%---------------------------------------------------------------------
persistent CHAR_REPLACEMENT
% Constants
% Special characters need to be stored as encoded byte sequences and then 
% decoded, because MATLAB versions older than 2019b use a different default 
% encoding
% Typing special characters directly in an .m file may cause issues due to 
% encoding mismatches
CHAR_REPLACEMENT_BYTES = { ...
    [195 161 195 160 195 162 195 164 195 163 195 165], 97; ...      'áàâäãå', 'a'
    [195 129 195 128 195 130 195 132 195 131 195 133], 65; ...      'ÁÀÂÄÃÅ', 'A'
    [197 147 195 169 195 168 195 170 195 171], 101; ...             'œéèêë', 'e'
    [195 137 195 136 195 138 195 139], 69; ...                      'ÉÈÊË', 'E'
    [195 173 195 172 195 174 195 175], 105; ...                     'íìîï', 'i'
    [195 141 195 140 195 142 195 143], 73; ...                      'ÍÌÎÏ', 'I'
    [195 179 195 178 195 180 195 182 195 181 195 184], 111; ...     'óòôöõø', 'o'
    [195 147 195 146 195 148 195 150 195 149 195 152], 79; ...      'ÓÒÔÖÕØ', 'O'
    [195 186 195 185 195 187 195 188], 117; ...                     'úùûü', 'u'
    [195 154 195 153 195 155 195 156], 85; ...                      'ÚÙÛÜ', 'U'
    [195 189 195 191], 121; ...                                     'ýÿ', 'y'
    [195 157], 89; ...                                              'Ý', 'Y'
    [195 167], 99; ...                                              'ç', 'c'
    [195 135], 67; ...                                              'Ç', 'C'
    [195 177], 110; ...                                             'ñ', 'n'
    [195 145], 78; ...                                              'Ñ', 'N'
    };
if isempty(CHAR_REPLACEMENT)
    CHAR_REPLACEMENT = cellfun( ...
        @(x) native2unicode(x, 'UTF-8'), ...
        CHAR_REPLACEMENT_BYTES, ...
        'UniformOutput', false ...
        );
end
%% Replace accented characters
outputStr = inputStr;
if any(~isempty(intersect(inputStr, strjoin(CHAR_REPLACEMENT(:, 1), ''))))
    for iCharRep = 1:length(CHAR_REPLACEMENT)
        [~, iOutputStr] = intersect(outputStr, CHAR_REPLACEMENT{iCharRep, 1});
        if ~isempty(iOutputStr)
            outputStr(iOutputStr) = CHAR_REPLACEMENT{iCharRep, 2};
        end
    end
end
end
