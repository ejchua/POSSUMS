%==========================================================================
% DESCRIPTION: Automated PW sampler sampling routine
% AUTHOR: Emily J. Chua
% DATE CREATED: 2/7/2019
% MAJOR REVISIONS: 
% 3/2019 -- Implemented stopping pump during background wait
% 5/5/2019 -- Implemented switching inlet function
% 5/11/2019 -- Implemented asking user for # of inlets to sample and order
%==========================================================================

clear all;close all;clc;
pause('on');                         % Enable pausing

disp('===================================================================')
disp('Apply power to the valve system, then hit "Enter" to continue.')
k = waitforbuttonpress;

%==========================================================================
% Set up serial port session
%==========================================================================
instrreset;                           % Disconnect and delete all instrument objects

global s
s = serial('COM20');                  % Create a serial port object

% Set serial communication parameters
s.BaudRate = 9600;
s.Parity = 'none';
s.DataBits = 8;
s.StopBits = 1;
s.Terminator = 'CR/LF';
s.FlowControl = 'none';

fopen(s);                            % Connect serial port object to device

disp('===================================================================')
disp(['The port status (open/closed) is: ',s.status])
disp(' ')
disp('If the port has been opened successfully, hit "Enter" to continue.')
w = waitforbuttonpress;

%==========================================================================
% Set up sampling routine
%==========================================================================
% Set up file to save timestamped commands
cd('C:\Users\ejchua\Desktop\PWLOGDATA');
global filename
global fileID
global myformat
filename = sprintf('PWSampler_%s.txt',datestr(now,'mm_dd_yyyy HH_MM'));
fileID = fopen(filename,'w');
myformat = '%s \t %s \r\n';
fprintf(fileID,myformat,'PCTime','Command');

disp('===================================================================')
disp(['A log of timestamped commands are saved in this file: ',filename])

% Ask user for inlets to sample and sampling order
disp('===================================================================')
prompt = 'Enter the desired number of inlets to sample: ';
ninlets = input(prompt);
for ii=1:ninlets
    prompt = 'Enter inlet number: ';
    inlet_order(ii) = input(prompt);
end

% Ask user for sampling times
disp('===================================================================')
disp('Set the desired sample timing -- you are asked to enter two times:')
disp('(1) The time to fill the inlet + loop, and')
disp('(2) An additional buffer time to allow return to signal background')
disp('Note: The sum of the two is the total time between injections.')
disp(' ')
prompt = 'Enter time to fill inlet + loop (minutes): '; 
x = input(prompt);
disp(' ');
prompt = 'Enter additional buffer time to allow signal to return to background (minutes): ';
y = input(prompt);

dt_fill = x*60;                   % Fill time for inlet + loop [sec]
dt_bg = y*60;                     % Time for peak to return to background [sec]

% Turn valves on
fprintf(s,'$vv 1 1');                 
pause(3);                
fprintf(s,'$vv 2 1');                   
pause(3);
disp('===================================================================')
disp([datestr(now),' -- Valves turned on']);              % Display action in Command Window
fprintf(fileID,myformat,datestr(now),'Valves turned on'); % Print time-stamped action to file

% Create a GUI with a button for breaking the loop
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'STOP SAMPLING', ...
                         'Position',[180 180 200 100], ...
                         'ForegroundColor','w',...
                         'BackgroundColor','r',...
                         'FontSize',16,...
                         'Callback', 'delete(gcbf)');

disp('===================================================================')
disp('Hit "Enter" to start sampling.  To stop sampling, press red button in popup window.')
w = waitforbuttonpress;

%==========================================================================
% Conduct sampling routine
%==========================================================================
while(ishandle(ButtonHandle))              % While the Stop button is not pressed
    for ii=inlet_order                     % Loop through the inlets in the specified sequence
        switchInlet(ii);                   % Change inlet -- function syntax at end
        pause(3);
        
        fprintf(s,'$vv 1 comm GOA');                        % Switch to Position A
        fprintf(fileID,myformat,datestr(now),'Position A'); % Print action to file
        disp([datestr(now),' -- Position A']);              % Display action in command window
        pause(3);
        
        fprintf(s,'$sp 1');                                 % Start pump
        fprintf(fileID,myformat,datestr(now),'Pump started'); 
        disp([datestr(now),' -- Pump started'])
        
        %======================================================================   
        pause(dt_fill);                    % Pause for specified fill time  
        %====================================================================== 
        if ~ishandle(ButtonHandle)         % If button is pressed, display this statement and break loop
            disp([datestr(now),' -- SAMPLING STOPPED BY USER']);
            break;
        end
        
        fprintf(s,'$vv 1 comm GOB');       % Switch to Position B (inject sample)
        fprintf(fileID,myformat,datestr(now),'Position B');
        disp([datestr(now),' -- Position B']);  
        pause(3);
        
        fprintf(s,'$sp 0');                % Stop pump
        fprintf(fileID,myformat,datestr(now),'Stopped pump');
        disp([datestr(now),' -- Stopped pump']);
        
    %======================================================================      
        pause(dt_bg);                      % Pause for specified buffer time
    %======================================================================      
        if ~ishandle(ButtonHandle)         % If button is pressed, display this statement and break loop
            disp([datestr(now),' -- SAMPLING STOPPED BY USER']);
            break;
        end
    end
end

%==========================================================================
% Turn valves and pump off, and end serial session after exiting loop
%==========================================================================
fprintf(s,'$sp 0');   
    pause(3)
fprintf(s,'$vv 1 0');
    pause(3)
fprintf(s,'$vv 2 0');
    disp('===================================================================')
    disp([datestr(now),' -- Pump and valves turned off'])
    fprintf(fileID,myformat,datestr(now),'Pump and valves turned off');

% Close session and clean up
fclose(s);                           % Disconnect serial port object from device
fclose(fileID);                      % Close file
delete(s);                           % Remove serial port object from memory
clear s;                             % Remove serial port object from MATLAB workspace

%==========================================================================
% Function definition for switching to next inlet
%==========================================================================
function inlet = switchInlet(ii)
    ncase = ii;
    global s
    global fileID
    global myformat

    switch ncase
        case 1
            fprintf(s,'$vv 2 comm GO1');    % Switch to Inlet #1
            fprintf(fileID,myformat,datestr(now),'Inlet 1');
            disp([datestr(now),' -- Inlet 1']);   
        case 2
            fprintf(s,'$vv 2 comm GO2');    % Switch to Inlet #2
            fprintf(fileID,myformat,datestr(now),'Inlet 2');
            disp([datestr(now),' -- Inlet 2']);              
        case 3
            fprintf(s,'$vv 2 comm GO3');    % Switch to Inlet #3
            fprintf(fileID,myformat,datestr(now),'Inlet 3');
            disp([datestr(now),' -- Inlet 3']);    
        case 4
            fprintf(s,'$vv 2 comm GO4');    % Switch to Inlet #4
            fprintf(fileID,myformat,datestr(now),'Inlet 4');
            disp([datestr(now),' -- Inlet 4']);  
        case 5
            fprintf(s,'$vv 2 comm GO5');    % Switch to Inlet #5    
            fprintf(fileID,myformat,datestr(now),'Inlet 5');
            disp([datestr(now),' -- Inlet 5']);
        case 6
            fprintf(s,'$vv 2 comm GO6');    % Switch to Inlet #6    
            fprintf(fileID,myformat,datestr(now),'Inlet 6');
            disp([datestr(now),' -- Inlet 6']);
        case 7
            fprintf(s,'$vv 2 comm GO7');    % Switch to Inlet #7
            fprintf(fileID,myformat,datestr(now),'Inlet 7');
            disp([datestr(now),' -- Inlet 7']);  
        otherwise
            disp('You specified too many inlets.');
    end
end