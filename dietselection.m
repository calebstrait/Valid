function DietSelection( initcell )

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

cd /TestData/Diet;
%Make the data folder for this date, make a file name
dateS = datestr(now, 'yymmdd');
initial = initcell(1);
if(numel(initcell) == 1)    cell = '';
else                        cell = initcell(2); end
filename = [initial dateS '.' cell '1.DS.mat'];
foldername = [initial dateS];
warning off all;
try
    mkdir(foldername)
end
warning on all;
cd(foldername)
trynum = 1;
while(trynum ~= 0)
    if(exist(filename)~=0)
        trynum = trynum +1;
        filename = [initial dateS '.' cell num2str(trynum) '.DS.mat'];
    else
        savename = [initial dateS '.' cell num2str(trynum) '.DS.mat'];
        trynum = 0;
    end
end
saveCommand = ['save ' savename ' data'];
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
oldEnableFlag = Screen('Preference', 'VisualDebugLevel', 0);% warning('off','MATLAB:dispatcher:InexactCaseMatch')
oldLevel = Screen('Preference', 'Verbosity', 0);%Hides PTB Warnings
window = Screen('OpenWindow', 1, 0);
Screen('FillRect', window, backcolour);
[xMax, yMax] = Screen('WindowSize', window);
Screen('FillRect', window, offstage, [0 0 xMax yStart - 40])
Screen('FillRect', window, offstage, [0 (yEnd + 40) xMax yMax])
Screen(window,'flip');

lane1 = Lane(xLoc, yStart, yEnd, window, speed, maxTime, minTime, saveCommand, probWorm, temptSwitch, gamble1Prob, gamble2Prob, forcedRewProb,forcedFixProb);
wormTime = 0;
k = keyCheck;
while(k.escape ~= 1)
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
sca
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