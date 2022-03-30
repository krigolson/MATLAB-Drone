clear all;
close all;
clc;

%ListenChar(2); %Stop typing in Matlab
%HideCursor();   % hide the cursor

% clear all variables in memory
clear all;
% close all open matlab files and windows
close all;
% clear the console
clc;
% seed the random number generator
rng('shuffle');

% define key variables
% define the background screen colour
backgroundColor = [166 166 166];
% define the screen size
% screenSize = [0 0 800 600];
% define default text size
textSize = 24;
% define the text color
textColor = [255 255 255];
% define circle size by its radius
circleRadius = 30;
% define a key to crash out of the program
exitKey = KbName('Q');

% skip Psychtoolbox sync tests to avoid sync failure issues
% Screen('Preference', 'SkipSyncTests', 1); 
% open a Psychtoolbox drawing window
[win, rec] = Screen('OpenWindow', 0 , backgroundColor, [], 32, 2);
% get the x and y coordinates of the middle of the screen
xPos = rec(3)/2;
yPos = rec(4);

% setup some parameters
Screen(win,'TextSize', textSize);

% define the circle colour
drawColor = [0 255 0];

% put up the task name in the middle of the screen
DrawFormattedText(win, 'Circle Test','center', 'center', [255 255 255],[],[],[],2);
Screen('Flip', win);
WaitSecs(2);
    
while 1
    
    % draw the circle
    Screen('FillOval', win , drawColor, [xPos-circleRadius yPos-circleRadius xPos+circleRadius yPos+circleRadius], 8);
    Screen('Flip',win);

    yPos = yPos - 10;
    WaitSecs(0.1);

    if yPos < 0
        break
    end
    
    % crash out of experiment (trials)
    [~, ~, keyCode] = KbCheck();
    if keyCode(exitKey)
        break;
    end
    
end

DrawFormattedText(win, 'Thanks for playing!','center', 'center', [255 255 255],[],[],[],2);
Screen('Flip', win);
WaitSecs(2);

sca;
ListenChar(0); % allow typing in Matlab
ShowCursor();  % show the cursor