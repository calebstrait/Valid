% ---------------------------------------------- %
% -- Aaron's modified version for valid. task -- %
% ---------------------------------------------- %

function DietSelection(initcell, trialTotal, currBlock, passedWindow)

global window;
window = passedWindow;

yStart  = 200;
yEnd    = 500;
xLoc    = 512;
probWorm= 1;
%freqWorm= 10; %Hz
freqWorm= 1.25; %Worm appears every 1.25 secs
speed   = (yEnd - yStart)/1; %Denominator is number of seconds on the screen
offstage= [0, 0, 0];
maxTime = 10;
minTime = 2;
temptSwitch = 0;
gamble1Prob = 0.20;
gamble2Prob = 0;
forcedRewProb = 0;
forcedFixProb = 0;

% Sets up everything needed for saving data.
validData = '/TestData/Valid';
prepare_for_saving;

warning('off', 'MATLAB:warn_r14_stucture_assignment');

%Eyelink setup
if ~Eyelink('IsConnected')
    Eyelink('initialize');%connects to eyelink computer
end
Eyelink('startrecording');%turns on the recording of eye position
Eyelink('StartSetup');
% Wait until Eyelink actually enters Setup mode:
trackerResp = true;
while trackerResp && Eyelink('CurrentMode')~=2 % Mode 2 is setup mode
    % Let the user abort with ESCAPE
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('ESCAPE'))
        disp('Aborted while waiting for Eyelink!');
        trackerResp = false;
    end
end
% Send the keypress 'o' to put Eyelink in output mode
Eyelink('SendKeyButton',double('o'),0,10);
Eyelink('SendKeyButton',double('o'),0,10); %A second time to start recording

backcolour       = [50,   50,  50];
% oldEnableFlag = Screen('Preference', 'VisualDebugLevel', 0);% warning('off','MATLAB:dispatcher:InexactCaseMatch')
% oldLevel = Screen('Preference', 'Verbosity', 0);%Hides PTB Warnings
% window = Screen('OpenWindow', 1, 0);
% Screen('FillRect', window, backcolour);

[xMax, yMax] = Screen('WindowSize', window);
Screen('FillRect', window, offstage, [0 0 xMax yStart - 40])
Screen('FillRect', window, offstage, [0 (yEnd + 40) xMax yMax])
Screen(window,'flip');

lane1 = Lane(xLoc, yStart, yEnd, window, speed, maxTime, minTime, saveCommand, probWorm, temptSwitch, gamble1Prob, gamble2Prob, forcedRewProb,forcedFixProb);
wormTime = 0;

% Also counts trials to determine when to end experiment.
trialCount = 0;
k = keyCheck;
while(k.escape ~= 1 && trialCount <= trialTotal)
    k = keyCheck;
    if(k.juice == 1)
        reward(.2);
    end
    wormTime = getSecs;
    searchTime = getSecs;
    while(lane1.currentWorms == 0 && lane1.currentTempter == 0 && k.escape ~= 1)
        k = keyCheck;
        if(k.juice == 1)
            reward(.2);
        end
        if(k.pause == 1)
            pause(k);
        end
        if(GetSecs - wormTime > freqWorm)
            
            wormTime = GetSecs;
            if(rand < probWorm)
                makeRandWorm(lane1, getSecs - searchTime);
                
                % Increment the trial number.
                trialCount = trialCount + 1;
            end
        end
    end
    e=Eyelink('newestfloatsample');
    full = update(lane1, e.gx(2),e.gy(2));
    if(full == 0);
        Screen('FillRect', window, offstage, [0 0 xMax yStart - 40])
        Screen('FillRect', window, offstage, [0 (yEnd + 40) xMax yMax])
    end
    Screen(window,'flip');
end

% sca

Eyelink('Stoprecording');

% Makes a folder and file where data will be saved.
function prepare_for_saving()
    cd(validData);

    % Check if cell ID was passed in with monkey's initial.
    if numel(initcell) == 1
        initial = initcell;
        cell = '';
    else
        initial = initcell(1);
        cell = initcell(2);
    end

    dateStr = datestr(now, 'yymmdd');
    filename = [initial dateStr '.' cell '1.DS.mat'];
    folderNameDay = [initial dateStr];
    folderNameBlock = ['Block' num2str(currBlock)];
    varName = 'data';   

    % Make and/or enter a folder where trial block folders are located.
    if exist(folderNameDay, 'dir') == 7
        cd(folderNameDay);
    else
        mkdir(folderNameDay);
        cd(folderNameDay);
    end

    % Make and/or enter a folder where .mat files will be saved.
    if exist(folderNameBlock, 'dir') == 7
        cd(folderNameBlock);
    else
        mkdir(folderNameBlock);
        cd(folderNameBlock);
    end

    % Make sure the filename for the .mat file is not already used.
    fileNum = 1;
    while fileNum ~= 0
        if exist(filename, 'file') == 2
            fileNum = fileNum + 1;
            filename = [initial dateStr '.' cell num2str(fileNum) '.DS.mat'];
        else
            fileNum = 0;
        end
    end

    saveCommand = ['save ' filename ' ' varName];
end
end

function k = pause(k)
disp('Paused')
while(k.pressed == 1)
    k = keyCheck;
end
pause = 1;
while(pause == 1 && k.escape ~=1)
    k = keyCheck;
    if(k.pause == 1)
        pause = 0;
    end
end
while(k.pressed == 1)
    k = keyCheck;
end
disp('Unpaused')
end

function key = keyCheck
stopkey=KbName('ESCAPE');
juicekey=KbName('space');
pausekey=KbName('RightControl');
key.pressed = 0;
key.escape = 0;
key.juice = 0;
key.pause = 0;
[keyIsDown,secs,keyCode] = KbCheck;
if keyCode(stopkey)
    key.escape = 1;
    key.pressed = 1;
end
if keyCode(juicekey)
    key.juice = 1;
    key.pressed = 1;
end
if keyCode(pausekey)
    key.pause = 1;
    key.pressed = 1;
end
end

function reward(rewardduration)
% 11/23/11  MAM, TB
if(rewardduration > 0)
    daq=DaqDeviceIndex;
    disp(sprintf('Reward time: %4.2fs', rewardduration));
    if(rewardduration ~= 0)
        DaqAOut(daq,0,.6);
        starttime=GetSecs;
        while (GetSecs-starttime)<(rewardduration);
        end;
        DaqAOut(daq,0,0);
        StopJuicer;
    end
end
end