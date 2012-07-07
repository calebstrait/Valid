%CES 3/2/2011

function FadeOps(initial)

%****** TASK
task = 0;
% 0: Buffer small wait to equal large wait
% 1: Buffer chosen from random distribution
% 2: Constant offset added to ITI
% 5: Buffer always = average buffer of task 0
% 6: Second reward after buffer

% Variables that can/should be changed according to task
eye = 2; % Left eye = 1 Right eye = 2
reward1 = 0; %Reward durations
reward2 = .06; 
reward3 = .08; 
reward4 = .1;
reward5 = .12;
reward6 = .14;
radius = 10; %Radius of fixation dot
fixmin = .1; %Fixation time min for fixation dot
fixminbox = 0.2; %Fixation time min for reward

iti = 1; %Intertrial interval
waitrange = 6; %Max wait time
buffrange = 0; %Max buffer time (task 1)
itiT2 = 4; %Iti for task 2

wr = 50; %Wiggle room around choice
hD = 275; %Rectangles' horizontal displacement from center
width = 80; %Width of rects
height = 300; %Height of rects
fixbox = 5; % Thickness of rect fixation cue
windheight = 250; %Height of fixation window
windwidth = 250; %Width of fixation window
dispwind = 0; %Show fixation window
dispcount = 0; % Show timing count

color6 = [0 255 0]; %Reward color 6
color5 = [0 0 255]; %Reward color 5
color4 = [100 100 100]; %Reward color 4
color3 = [255 255 0]; %Reward color 3
color2 = [255 125 50]; %Reward color 2
color1 = [255 0 0]; %Reward color 1
fixcuecolor = [255 255 255]; %Rect fixation cue color
backcolor = [50 50 50]; %Background color
maincolor = [255 255 0]; %Color of fixation dot

% Create data file*****************
% initial is subject initial  e.g. 'G' for George
cd /TestData/FadeOps;
dateS = datestr(now, 'yymmdd');
filename = [initial dateS '.1.FO' num2str(task) '.mat'];
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
        filename = [initial dateS '.' num2str(trynum) '.FO' num2str(task) '.mat'];
    else
        savename = [initial dateS '.' num2str(trynum) '.FO' num2str(task) '.mat'];
        trynum = 0;
    end
end
home

% Setup Eyelink*****************
HideCursor; %This hides the Psychtoolbox startup Screen
oldEnableFlag = Screen('Preference', 'VisualDebugLevel', 0);% warning('off','MATLAB:dispatcher:InexactCaseMatch')
oldLevel = Screen('Preference', 'Verbosity', 0);%Hides PTB Warnings
global window; window = Screen('OpenWindow', 1, 0);
if ~Eyelink('IsConnected')
    Eyelink('initialize');%connects to eyelink computer
end
Eyelink('startrecording');%turns on the recording of eye position
Eyelink('Command', 'randomize_calibration_order = NO');
Eyelink('Command', 'force_manual_accept = YES');
Eyelink('StartSetup');
trackerResp = true; % Wait until Eyelink actually enters Setup mode:
while trackerResp && Eyelink('CurrentMode')~=2 % Mode 2 is setup mode
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('ESCAPE'))% Let the user abort with ESCAPE
        disp('Aborted while waiting for Eyelink!');
        trackerResp = false;
    end
end
Eyelink('SendKeyButton',double('o'),0,10); % Send the keypress 'o' to put Eyelink in output mode
Eyelink('SendKeyButton',double('o'),0,10);

% Count trials for the whole day*****************
cd ..;
daystrials = 0;
thesefiles = dir(foldername);
cd(foldername);
fileIndex = find(~[thesefiles.isdir]);
for i = 1:length(fileIndex)
    thisfile = thesefiles(fileIndex(i)).name;
    thisdata = importdata(thisfile);
    daystrials = daystrials + length(thisdata);
end

% Ask to set up*****************
Screen('FillRect', window, backcolor);
Screen(window,'flip');
continuing = 1;
go = 0;
disp('Right Arrow to start');
gokey=KbName('RightArrow');
nokey=KbName('ESCAPE');
while((go == 0) && (continuing == 1))
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyCode(gokey)
        go = 1;
    elseif keyCode(nokey)
        continuing = 0;
    end
end
while keyIsDown
    [keyIsDown,secs,keyCode] = KbCheck;
end
home

% Set variables*****************
targX = 512;
targY = 384;
Fxmin = targX - (windwidth / 2);
Fxmax = targX + (windwidth / 2);
Fymin = (targY - (windheight / 2));
Fymax = (targY + (windheight / 2));
Lxmin = (targX - (width / 2))-hD; Lxmax = (targX + (width / 2))-hD;
Lymin = (targY - (height / 2)); Lymax = (targY + (height / 2));
Rxmin = (targX - (width / 2))+hD; Rxmax = (targX + (width / 2))+hD;
Rymin = (targY - (height / 2)); Rymax = (targY + (height / 2));
fixating = 0;
step = 5;
trial = 0;
pause = 0;
wait = 1;
buffer = 0;
choice = 0;
timeofchoice = GetSecs - ((wait*waitrange) + buffer + iti);
reactiontime = 0;
savecommand = ['save ' savename ' data'];
correct = 0;
possible = 0;
pcent2graph(1) = 0;
starttime = GetSecs;

while(continuing);
    % Display Count*****************
    if(dispcount == 1 && (step == 3 || step == 4))
        disp([num2str(GetSecs - dispstart)]);
    end
    
    % Set Screen*****************
    if(step == 1)
        if(dispwind == 1)
            Screen('FillRect', window, [0 255 0], [(Fxmin) (Fymin) (Fxmax) (Fymax)]);
            Screen('FillRect', window, [0 0 0], [(Fxmin+5) (Fymin+5) (Fxmax-5) ((Fymax)-5)]);
        end
        Screen('FillOval', window, maincolor, [(targX-radius) ((targY-radius)) (targX+radius) ((targY+radius))]);
    end
    if(step == 2)
        if(fixating == 1)
            Screen('FillRect', window, fixcuecolor, [(Lxmin-fixbox) ((Lymax - (leftwait * height))-fixbox) (Lxmax+fixbox) (Lymax+fixbox)]);
        elseif(fixating == 2)
            Screen('FillRect', window, fixcuecolor, [(Rxmin-fixbox) ((Rymax - (rightwait * height))-fixbox) (Rxmax+fixbox) (Rymax+fixbox)]);
        end
        eval(['Lcolor = color' num2str(leftcolor) ';']);
        eval(['Rcolor = color' num2str(rightcolor) ';']);
        Screen('FillRect', window, Lcolor, [Lxmin (Lymax - (leftwait * height)) Lxmax Lymax]);
        Screen('FillRect', window, Rcolor, [Rxmin (Rymax - (rightwait * height)) Rxmax Rymax]);
    end
    if(step == 3)
        if(choice == 1)
            LyminF = Lymax - ((((wait*waitrange)-(GetSecs - timeofchoice)) / (wait*waitrange)) * (wait * height));
            eval(['Lcolor = color' num2str(leftcolor) ';']);
            if(Lymax > LyminF)
                Screen('FillRect', window, Lcolor, [Lxmin LyminF Lxmax Lymax]);
            end
        elseif(choice == 2)
            RyminF = Rymax - ((((wait*waitrange)-(GetSecs - timeofchoice)) / (wait*waitrange)) * (wait * height));
            eval(['Rcolor = color' num2str(rightcolor) ';']);
            if(Rymax > RyminF)
                Screen('FillRect', window, Rcolor, [Rxmin RyminF Rxmax Rymax]);
            end
        end
    end
    Screen(window,'flip');
    
    % Check eye position*****************
    e = Eyelink('newestfloatsample');
    if(step == 1)
        if(((Fxmin < e.gx(eye)) && (e.gx(eye) < Fxmax)) && (((Fymin) < e.gy(eye)) && (e.gy(eye) < (Fymax)))) %Gaze is in box around fixation dot
            if(fixating == 0)
                fixtime = GetSecs;
                fixating = 1;
            elseif((fixating == 1) && (GetSecs > (fixmin + fixtime))) 
                reactiontime = GetSecs;
                step = 2;
                fixating = 0;
            end
        elseif(fixating == 1)
            fixating = 0;
        end
    elseif(step == 2)
        if(((Lxmin-wr < e.gx(eye)) && (e.gx(eye) < Lxmax+wr)) && ((Lymin-wr < e.gy(eye)) && (e.gy(eye) < Lymax+wr))) %Gaze is in box around LEFT
            if(fixating == 0)
                fixtime = GetSecs;
                fixating = 1;
            elseif((fixating == 1) && (GetSecs > (fixminbox + fixtime))) 
                timeofchoice = GetSecs;
                choice = 1;
                choicecolor = leftcolor;
                wait = leftwait;
                buffer = leftbuffer;
            end
        elseif(fixating == 1)
            fixating = 0;
        end
        if(((Rxmin-wr < e.gx(eye)) && (e.gx(eye) < Rxmax+wr)) && ((Rymin-wr < e.gy(eye)) && (e.gy(eye) < Rymax+wr))) %Gaze is in box around RIGHT
            if(fixating == 0)
                fixtime = GetSecs;
                fixating = 2;
            elseif((fixating == 2) && (GetSecs > (fixminbox + fixtime))) 
                timeofchoice = GetSecs;
                choice = 2;
                choicecolor = rightcolor;
                wait = rightwait;
                buffer = rightbuffer;
            end
        elseif(fixating == 2)
            fixating = 0;
        end
    end
    
    % Watch for keyboard interaction*****************
    comm=keyCapture();
    if(comm==-1) % ESC stops the session
        continuing=0;
    end
    if(comm==1) % Space rewards monkey
        reward(reward5);
    end
    if(comm==2) % Control pauses/unpauses
        if(pause == 0)
            pause = 1;
        else
            timeofchoice = GetSecs - ((wait*waitrange) + buffer + iti)% Commenting out, replacing - no variable called feedbacktime, unpausing crashes. TB April 3, 2012 (feedbacktime + iti);
            pause = 0;
        end
    end
    
    % Progress between steps*****************
    if(step == 2 && choice ~= 0)
        step = 3;
        fixating = 0;
        dispstart = GetSecs;
    elseif(step == 3 && GetSecs > (timeofchoice + (wait*waitrange)))
        step = 4;
        eval(['rewardsize = reward' num2str(choicecolor) ';']);
        reward(rewardsize);
    elseif(step == 4 && GetSecs > (timeofchoice + (wait*waitrange) + buffer))
        disp(GetSecs - timeofchoice)
        step = 5;
        if task == 6
            reward(rewardsize);end
        
        %Save data to .m file
        data(trial).choice = choice;
        data(trial).leftcolor = leftcolor; 
        data(trial).rightcolor = rightcolor; 
        data(trial).leftwait = leftwait;
        data(trial).rightwait = rightwait;
        data(trial).leftbuffer = leftbuffer;
        data(trial).rightbuffer = rightbuffer;
        data(trial).iti = iti;
        data(trial).waitrange = waitrange;
        data(trial).buffrange = buffrange;
        data(trial).reactiontime = (timeofchoice - reactiontime);
        eval(savecommand);
        
    elseif(((step == 5 && GetSecs > (timeofchoice + (wait*waitrange) + buffer + iti)) && (pause == 0)))
        step = 1;
        
        %Print to command window
        disp(' ');
        home;
        if(trial ~= (trial + daystrials))
            disp(['Trial #' num2str(trial) '/' num2str(trial + daystrials)]);
        else
            disp(['Trial #' num2str(trial)]);
        end
        elapsed = GetSecs-starttime;
        disp(sprintf('Elapsed time: %.0fh %.0fm', floor(elapsed/3600), floor((elapsed-(floor(elapsed/3600)*3600))/60)));
        if(trial > 0)
            possible = possible + 1;
            if(((leftcolor >= rightcolor) && (choice == 1)) || ((leftcolor <= rightcolor) && (choice == 2)))
                correct = correct + 1;
            end
            if(possible > 0)
                disp(sprintf('Correct: %3.2f%%', (100*correct/possible)));
            end
            pcent2graph(trial) = (100*correct/possible);
        end
        disp(sprintf('Buffer: %3.3fs', buffer));
        
        %Set up next trial
        choice = 0;
        trial = trial + 1;
        colors = randperm(5) + 1; %Silly hack to eliminate red option, also changed to eliminate same-colour trials TB 3/12/12
        leftcolor = colors(1);
        rightcolor = colors(2);
        %Wait times changed to make it always an LL vs SS trial TB 3/12/12
        wait1 = rand;
        wait2 = rand;
        if(leftcolor > rightcolor)
            leftwait = max(wait1, wait2);
            rightwait = min(wait1, wait2);
        else
            rightwait = max(wait1, wait2);
            leftwait = min(wait1, wait2);
        end
        %Set buffers
        if(task == 0)
            leftbuffer = waitrange*(max(leftwait, rightwait) - leftwait);
            rightbuffer= waitrange*(max(leftwait, rightwait) - rightwait);
        elseif(task == 0 || task == 2 || task == 6)
            leftbuffer = waitrange - (leftwait * waitrange);
            rightbuffer = waitrange - (rightwait * waitrange);
        elseif(task == 1)
            leftbuffer = buffrange; %Buffrange changed to constant, TB 15/3/2012
            rightbuffer = buffrange;
        elseif(task == 5)
            leftbuffer = waitrange * 0.5;
            rightbuffer = waitrange * 0.5;
        end
        %Set iti
        if(task == 2)
            iti = itiT2;
        end
    end
end
if(length(pcent2graph) > 1)
    plot(pcent2graph);
end
Eyelink('stoprecording');
sca;
%keyboard
end

function a = keyCapture()
stopkey=KbName('ESCAPE');
pause=KbName('RightControl');
reward=KbName('space');
[keyIsDown,secs,keyCode] = KbCheck;
if keyCode(stopkey)
    a = -1;
elseif keyCode(reward)
    a = 1; 
elseif keyCode(pause)
    a = 2;
else
    a = 0;
end
while keyIsDown
    [keyIsDown,secs,keyCode] = KbCheck;
end
end

function reward(rewardduration)
daq=DaqDeviceIndex;
if(rewardduration ~= 0)
    DaqAOut(daq,0,.6);
    starttime=GetSecs;
    while (GetSecs-starttime)<(rewardduration);
    end;
    DaqAOut(daq,0,0);
    StopJuicer;
end
end