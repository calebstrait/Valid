% Copyright (c) 2012 Aaron Roth
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
% 

function charnov(monkeysInitial, trialTotal, currBlock, passedWindow)
    % ---------------------------------------------- %
    % -------------- Global variables -------------- %
    % ---------------------------------------------- %
    
    % Colors.
    colorBackground = [50 50 50];     % Background color.
    colorError      = [0 100 0];      % Color of square in error state.
    colorFixDot     = [255 255 0];    % Fixation dot color.
    colorLeaveBar   = [175 176 175];  % Color of the stay bar stimulus.
    colorStayBar    = [0 163 218];    % Color of the leave bar stimulus.
    
    % Coordinates.
    centerX         = 512;            % X pixel coordinate for the screen center.
    centerY         = 384;            % Y pixel coordinate for the screen center.
    fixBoundXMax    = centerX + 88;   % Max x distance from fixation point to fixate.
    fixBoundXMin    = centerX - 88;   % Min x distance from fixation point to fixate.
    fixBoundYMax    = centerY + 88;   % Max y distance from fixation point to fixate.
    fixBoundYMin    = centerY - 88;   % Mix y distance from fixation point to fixate.
    wiggleX         = 100;            % Bar fixation wiggle room beyond bar boundaries.
    wiggleY         = 300;            % Bar fixation wiggle room beyond bar boundaries.
    
    % References.
    trackedEye      = 2;              % Eyelink code for which eye is being tracked.
    window          = passedWindow;   % Reference to window used for drawing.
    
    % Reward.
    currJuice       = 1.6;            % Current reward amount in milliliters.
    juiceMax        = 1.6;            % Max amount of juice monkey can get.
    juiceUnit       = 0.1;            % Amount reward is reduced by for each stay trial.
    pourTimeOneMl   = 0.3;            % Number of secs juicer needs to pour 1 mL.
    rewarded        = '';             % Wether or not the monkey got a reward.
    rewardSize      = 0;              % How man milliliters of juice the monkey got.
    spaceReward     = 0.2;            % Reward given to monkey when spacebar pressed.
    
    % Saving.
    data            = struct([]);         % Workspace variable where trial data is saved.
    saveCommand     = NaN;                % Command string that will save .mat files.         
    validData       = '/TestData/Valid';  % Directory where .mat files are saved.
    varName         = 'data';             % Name of the var to save in the workspace.
    
    % Shrinking.
    shrinkRate      = 1.625;          % Pixels shrunk in 0.025 s (65 pixels/s).
    shrinkRateSec   = 65;             % Pixels shrunk in 1 s.
    shrinkInterval  = 0.025;          % Time to shrink 1.625 pixels.
    
    % Stimuli.
    barToFixDist    = 300;            % Distance from fixation center to bar edge.
    barWidth        = 80;             % Width of all the bar stimuli.
    currLBarHeight  = 0;              % Current height of the leave bar.
    dotRadius       = 10;             % Radius of the fixation dot.
    errorSquare     = 100;            % Half the width of the error square.
    leaveBarHeights = [32.5  65  ...  % All the possible leave bar heights,
                       97.5  130 ...  %     which are based on shrink times
                       162.5 195 ...  %     ranging from 0.5 to 10.5 s in
                       227.5 260 ...  %     intervals of 0.5 s with a shrink
                       292.5 325 ...  %     rate of 65 pixels/s.
                       357.5 390 ...
                       422.5 455 ...
                       487.5 520 ...
                       552.5 585 ...
                       617.5 650 ...
                       682.5];
    stayBarHeight   = 26;             % Height of the blue stay bar.
    
    % Times.
    errorStateTime  = 3;              % Duration of the error state.
    holdFixTime     = 0.5;            % Duration to hold fixation before choosing.
    ITI             = 1;              % Intertrial interval.
    minFixTime      = 0.2;            % Min time monkey must fixate to start trial.
    timeToFix       = 30;             % Amount of time the monkey has to fixate.
    timeToSaccade   = intmax;         % Time allowed for monkey to make a choice.
    
    % Trial.
    choiceMade      = '';             % Which option the monkey chose.
    currTrial       = 1;              % Current trial.
    newLBarHeight   = true;           % Whether or not new stay bar height is needed.
    startLBarHeight = 0;              % The leave bar height for the current trial.
    trialErrors     = struct([]);     % Stores the errors made during the trial.
    trialType       = 0;              % Current trial. Determines bar placement.
    
    % ---------------------------------------------- %
    % ------------------- Setup -------------------- %
    % ---------------------------------------------- %
    
    % Saving.
    prepare_for_saving;
    
    % ---------------------------------------------- %
    % ------------ Main experiment loop ------------ %
    % ---------------------------------------------- %
    
    trialCount = 0;
    running = true;
    
    while trialTotal > trialCount && running
        keyPress = key_check;
        key_execute(keyPress);
        
        run_single_trial;
        
        trialCount = trialCount + 1;
        print_stats();
    end
    
    % ---------------------------------------------- %
    % ----------------- Functions ------------------ %
    % ---------------------------------------------- %
    
    % Figures out current bar positions based on global variables.
    function [lBXMin, lBXMax, lBYMin, lBYMax, ...
              sBXMin, sBXMax, sBYMin, sBYMax] = bar_positioning()
        % Determine positioning - leave bar: left side; stay bar: right side.
        if trialType == 0
            lBXMin = centerX - barToFixDist - barWidth;
            lBXMax = centerX - barToFixDist;
            
            % Recalulate height of leave bar if needed.
            if newLBarHeight
                set_leave_bar;
                
                lBYMin = centerY - currLBarHeight / 2;
                lBYMax = centerY + currLBarHeight / 2;
            else
                lBYMin = centerY - currLBarHeight / 2;
                lBYMax = centerY + currLBarHeight / 2;
            end
            
            sBXMin = centerX + barToFixDist;
            sBXMax = centerX + barToFixDist + barWidth;
            sBYMin = centerY - stayBarHeight / 2;
            sBYMax = centerY + stayBarHeight / 2;
        % Determine positioning - leave bar: right side; stay bar: left side.
        else
            lBXMin = centerX + barToFixDist;
            lBXMax = centerX + barToFixDist + barWidth;
            
            % Recalulate height of leave bar if needed.
            if newLBarHeight
                set_leave_bar;
                
                lBYMin = centerY - currLBarHeight / 2;
                lBYMax = centerY + currLBarHeight / 2;
            else
                lBYMin = centerY - currLBarHeight / 2;
                lBYMax = centerY + currLBarHeight / 2;
            end
            
            sBXMin = centerX - barToFixDist - barWidth;
            sBXMax = centerX - barToFixDist;
            sBYMin = centerY - stayBarHeight / 2;
            sBYMax = centerY + stayBarHeight / 2;
        end
    end
    
    % Determines if the eye has fixated within the given bounds
    % for the given duration before the given timeout occurs.
    function [fixation, area] = check_fixation(xBoundMin, xBoundMax, ...
                                               yBoundMin, yBoundMax, ...
                                               xBoundMin2nd, xBoundMax2nd, ...
                                               yBoundMin2nd, yBoundMax2nd, ...
                                               duration, timeout, checkTwo)
        startTime = GetSecs;
        
        % Keep checking for fixation until timeout occurs.
        while timeout > (GetSecs - startTime)
            [xCoord, yCoord] = get_eye_coords;
            
            % Determine if one or two locations are being tracked.
            if checkTwo
                % Determine if eye is within either of the two fixation boundaries.
                if (xCoord >= xBoundMin && xCoord <= xBoundMax && ...
                    yCoord >= yBoundMin && yCoord <= yBoundMax) || ...
                   (xCoord >= xBoundMin2nd && xCoord <= xBoundMax2nd && ...
                    yCoord >= yBoundMin2nd && yCoord <= yBoundMax2nd)
                    % Determine if the eye entered the leave option boundaries.
                    if xCoord >= xBoundMin && xCoord <= xBoundMax && ...
                       yCoord >= yBoundMin && yCoord <= yBoundMax
                        % Notify Plexon: Eye looked at leave option.
                        toplexon(4081);
                        
                        % Determine if eye maintained fixation for given duration.
                        checkFixBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                                        yBoundMin, yBoundMax, ...
                                                        duration);
                        
                        if checkFixBreak == false
                            % Notify Plexon: Eye acquired fixtion on leave option.
                            toplexon(4083);
                            
                            % Fixation was obtained for desired duration.
                            fixation = true;
                            area = 'first';
                            
                            return;
                        else
                            % Notify Plexon: Eye looked away from leave option.
                            toplexon(4082);
                        end
                    % Determine if the eye entered the stay option boundaries.
                    else
                        % Notify Plexon: Eye looked at stay option.
                        toplexon(4071);
                        
                        % Determine if eye maintained fixation for given duration.
                        checkFixBreak = fix_break_check(xBoundMin2nd, xBoundMax2nd, ...
                                                        yBoundMin2nd, yBoundMax2nd, ...
                                                        duration);
                        
                        if checkFixBreak == false
                            % Notify Plexon: Eye acquired fixtion on stay option.
                            toplexon(4073);
                            
                            % Fixation was obtained for desired duration.
                            fixation = true;
                            area = 'second';
                            
                            return;
                        else
                            % Notify Plexon: Eye looked away from stay option.
                            toplexon(4072);
                        end
                    end
                end
            else
                % Determine if eye is within the fixation boundary.
                if xCoord >= xBoundMin && xCoord <= xBoundMax && ...
                   yCoord >= yBoundMin && yCoord <= yBoundMax
                    % Notify Plexon: Eye looked at fixation dot.
                    toplexon(4051);
                    
                    % Determine if eye maintained fixation for given duration.
                    checkFixBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                                    yBoundMin, yBoundMax, ...
                                                    duration);
                    
                    if checkFixBreak == false
                        % Notify Plexon: Eye acquired fixation on fixation dot.
                        toplexon(4053);
                        
                        % Fixation was obtained for desired duration.
                        fixation = true;
                        area = 'single';
                        
                        return;
                    else
                        % Notify Plexon: Eye looked away from fixation dot.
                        toplexon(4052);
                    end
                end
            end
        end
        
        % Timeout reached.
        fixation = false;
        area = 'none';
    end
    
    % Draws two bars on the screen.
    function draw_bars(leaveBarXMin, leaveBarXMax, leaveBarYMin, ...
                       leaveBarYMax, stayBarXMin, stayBarXMax, ...
                       stayBarYMin, stayBarYMax, fixPoint, whichToDraw)
        if strcmp(whichToDraw, 'both') == 1
            % Stay bar.
            Screen('FillRect', window, colorStayBar, [stayBarXMin stayBarYMin ...
                                                      stayBarXMax stayBarYMax]);
            
            % Leave bar.
            Screen('FillRect', window, colorLeaveBar, [leaveBarXMin leaveBarYMin ...
                                                       leaveBarXMax leaveBarYMax]);
            
            if fixPoint
                % Redraw fixation point to keep it displayed.
                Screen('FillOval', window, colorFixDot, [(centerX - dotRadius) ...
                                                         (centerY - dotRadius) ...
                                                         (centerX + dotRadius) ...
                                                         (centerY + dotRadius)]);
            end
        elseif strcmp(whichToDraw, 'notstay') == 1
            % Leave bar.
            Screen('FillRect', window, colorLeaveBar, [leaveBarXMin leaveBarYMin ...
                                                       leaveBarXMax leaveBarYMax]);
        elseif strcmp(whichToDraw, 'notleave') == 1
            % Stay bar.
            Screen('FillRect', window, colorStayBar, [stayBarXMin stayBarYMin ...
                                                      stayBarXMax stayBarYMax]);
        end
        
        Screen('Flip', window);
    end
    
    % Draws the fixation point on the screen.
    function draw_fixation_point(color)
        Screen('FillOval', window, color, [(centerX - dotRadius) ...
                                           (centerY - dotRadius) ...
                                           (centerX + dotRadius) ...
                                           (centerY + dotRadius)]);
        Screen('Flip', window);
    end
    
    % Displays the error state on the screen.
    function error_state(errorType)               
        % Check for pressed keys.
        keyPress = key_check;
        key_execute(keyPress);
        
        % Set variables that will help with storing the error type.
        numErrors = length(trialErrors);
        errorName = strcat('error', num2str(numErrors + 1));
        
        % Determine what type of error occured.
        plexonCode = 0;
        
        if strcmp(errorType, 'noInitiate') == 1
            plexonCode = 4007;
            
            % Store the error in a struct.
            if isempty(trialErrors)
                trialErrors(1).error1 = errorType;
            else
                trialErrors.(errorName) = errorType;
            end
        elseif strcmp(errorType, 'noHold') == 1
            plexonCode = 4008;
            
            % Store the error in a struct.
            if isempty(trialErrors)
                trialErrors(1).error1 = errorType;
            else
                trialErrors.(errorName) = errorType;
            end
        elseif strcmp(errorType, 'noChoice') == 1
            plexonCode = 4009;
            
            % Store the error in a struct.
            if isempty(trialErrors)
                trialErrors(1).error1 = errorType;
            else
                trialErrors.(errorName) = errorType;
            end
        end
        
        % Display error screen.
        Screen('FillRect', window, colorError, [(centerX - errorSquare) ...
                                                (centerY - errorSquare) ...
                                                (centerX + errorSquare) ...
                                                (centerY + errorSquare)]);
        Screen('Flip', window);
        
        % Notify Plexon: Error state presented.
        toplexon(plexonCode);
        
        pause(errorStateTime);
    end
    
    % Checks if the eye breaks fixation bounds before end of duration.
    function fixationBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                             yBoundMin, yBoundMax, ...
                                             duration)
        fixStartTime = GetSecs;
        
        % Keep checking for fixation breaks for the entire duration.
        while duration > (GetSecs - fixStartTime)
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
        
            [xCoord, yCoord] = get_eye_coords;
            
            % Determine if the eye has left the fixation boundaries.
            if xCoord < xBoundMin || xCoord > xBoundMax || ...
               yCoord < yBoundMin || yCoord > yBoundMax
                % Eye broke fixation before end of duration.
                fixationBreak = true;
                
                return;
            end
        end
        
        % Eye maintained fixation for entire duration.
        fixationBreak = false;
    end
    
    % Returns the current x and y coordinants of the given eye.
    function [xCoord, yCoord] = get_eye_coords()
        sampledPosition = Eyelink('NewestFloatSample');
        
        xCoord = sampledPosition.gx(trackedEye);
        yCoord = sampledPosition.gy(trackedEye);
    end
    
    % Checks to see what key was pressed.
    function key = key_check()
        % Assign key codes to some variables.
        juiceKey = KbName('space');
        stopKey = KbName('ESCAPE');
        
        % Make sure default values of key are false.
        key.escape = false;
        key.juice = false;
        
        % Get info about any key that was just pressed.
        [~, ~, keyCode] = KbCheck;
        
        % Check pressed key against the keyCode array of 256 key codes.
        if keyCode(juiceKey)
            key.juice = true;
        elseif keyCode(stopKey)
            key.escape = true;
        end
    end
    
    % Execute a passsed key command.
    function key_execute(keyRef)
        % Stop task at end of current trial.
        if keyRef.escape == true
            running = false;
        % Give an instance juice reward.
        elseif keyRef.juice == true
            reward(spaceReward);
            
            % Notify Plexon: Reward given to monkey.
            toplexon(4010);
        end
    end
    
    % Makes a folder and file where data will be saved.
    function prepare_for_saving()
        cd(validData);
        
        % Check if cell ID was passed in with monkey's initial.
        if numel(monkeysInitial) == 1
            initial = monkeysInitial;
            cell = '';
        else
            initial = monkeysInitial(1);
            cell = monkeysInitial(2);
        end
        
        dateStr = datestr(now, 'yymmdd');
        filename = [initial dateStr '.' cell '1.C.mat'];
        folderNameDay = [initial dateStr];
        folderNameBlock = ['Block' num2str(currBlock)];
        
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
                filename = [initial dateStr '.' cell num2str(fileNum) '.C.mat'];
            else
                fileNum = 0;
            end
        end
        
        saveCommand = ['save ' filename ' ' varName];
    end
    
    % Prints current trial stats.
    function print_stats()
        home;
        disp('             ');
        disp('****************************************');
        disp('             ');
        fprintf('Trials completed:% 3u', trialCount);
        disp('             ');
        disp('             ');
        disp('****************************************');
        
        if trialCount == trialTotal
            pause(2);
        end
    end
    
    % Rewards monkey using the juicer with the passed duration.
    function reward(rewardAmount)
        if rewardAmount ~= 0
            % Get a reference the juicer device and set reward duration.
            daq = DaqDeviceIndex;
            rewardDuration = rewardAmount * pourTimeOneMl;
            
            % Open juicer.
            DaqAOut(daq, 0, .6);
            
            startTime = GetSecs;
            
            % Keep looping to keep juicer open until reward end.
            while (GetSecs - startTime) < rewardDuration
            end
            
            % Close juicer.
            DaqAOut(daq, 0, 0);
        end
    end
    
    % Runs a single trial using current global variable values.
    function run_single_trial()
        % Check for pressed keys.
        keyPress = key_check;
        key_execute(keyPress);
        
        % Fixation dot appears.
        draw_fixation_point(colorFixDot);
        
        % Notify Plexon: Fixation dot appeared.
        toplexon(4001);
        
        fixating = check_fixation(fixBoundXMin, fixBoundXMax, ...
                                  fixBoundYMin, fixBoundYMax, ...
                                  0, 0, 0, 0, ...
                                  minFixTime, timeToFix, false);
        
        if fixating
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
        
            % Determine bar positioning.
            [lBXMin, lBXMax, lBYMin, lBYMax, ...
             sBXMin, sBXMax, sBYMin, sBYMax] = bar_positioning;
            
            % Display the bars.
            draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                      sBXMin, sBXMax, sBYMin, sBYMax, true, 'both');
            
            % Notify Plexon: Options appeared.
            toplexon(4002);
            
            % Determine if eye maintained hold fixation for given duration.
            checkFixBreak = fix_break_check(fixBoundXMin, fixBoundXMax, ...
                                            fixBoundYMin, fixBoundYMax, ...
                                            holdFixTime);
            
            % Enter error state if fixation lost, otherwise continue trial.
            if checkFixBreak
                % Notify Plexon: Eye looked away from hold fixation dot.
                toplexon(4061);
            
                % Monkey did not hold fixation before making a choice.
                error_state('noHold');

                % Redo this trial since monkey failed it.
                run_single_trial;

                return;
            else
                % Redraw bars without fixation (remove fixation point).
                draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'both');
                
                % Notify Plexon: Hold dot disappeared.
                toplexon(4003);
            end
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
            
            % Figure out wiggle room for bar fixations.
            lBXMinWig = lBXMin - wiggleX;
            lBXMaxWig = lBXMax + wiggleX;
            
            lBYMinWig = lBYMin - wiggleY;
            lBYMaxWig = lBYMax + wiggleY;
            
            % Make sure leave bar min fix area height does not go beyond screen.
            if lBYMinWig < 0
                lBYMinWig = 0;
            end
            
            % Make sure leave bar max fix area height does not go beyond screen.
            if lBYMaxWig > 768
                lBYMaxWig = 768;
            end
            
            % Finish figuring out wiggle room for bar fixations.
            sBXMinWig = sBXMin - wiggleX;
            sBXMaxWig = sBXMax + wiggleX;
            sBYMinWig = sBYMin - wiggleY;
            sBYMaxWig = sBYMax + wiggleY;
            
            % Find out if monkey makes a choice by saccading to either bar.
            [saccade, choice] = check_fixation(lBXMinWig, lBXMaxWig, ...
                                               lBYMinWig, lBYMaxWig, ...
                                               sBXMinWig, sBXMaxWig, ...
                                               sBYMinWig, sBYMaxWig, ...
                                               minFixTime, timeToSaccade, true);
            
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
            
            if saccade
                % Determine which choice monkey made.
                if strcmp(choice, 'first')
                    % Shrink the leave bar.
                    shrunk = shrink_bar('leave', shrinkRate, currLBarHeight, ...
                                        lBXMin, lBXMax, lBYMin, lBYMax, ...
                                        sBXMin, sBXMax, sBYMin, sBYMax);
                    
                    if shrunk
                        % Hacky way of smoothly presenting a blank screen.
                        draw_fixation_point(colorBackground);
                        
                        % Notify Plexon: Unchosen option removed.
                        toplexon(4006);
                        
                        % Outcome variables.
                        choiceMade = 'leave';
                        rewarded = 'no';
                        rewardSize = 0;
                        
                        % Send variables to Plexon; save them to a .mat file.
                        send_and_save;
                        
                        % Reset juice reward amount.
                        currJuice = juiceMax;
                        
                        % Switch which sides where the bars appear.
                        if trialType == 0
                            trialType = 1;
                        else
                            trialType = 0;
                        end
                        
                        % Make sure a new leave bar height is requested.
                        newLBarHeight = true;
                        
                        % Reset errors variable for the next trial.
                        trialErrors = struct([]);
                        
                        currTrial = currTrial + 1;
                        pause(ITI);
                    end
                else
                    % Shrink the stay bar.
                    shrunk = shrink_bar('stay',shrinkRate, stayBarHeight, ...
                                        lBXMin, lBXMax, lBYMin, lBYMax, ...
                                        sBXMin, sBXMax, sBYMin, sBYMax);
                    
                    if shrunk
                        % Reward the monkey.
                        reward(currJuice);
                        
                        % Notify Plexon: Reward given to monkey.
                        toplexon(4010);
                        
                        % Hacky way of smoothly presenting a blank screen.
                        draw_fixation_point(colorBackground);
                        
                        % Notify Plexon: Unchosen option removed.
                        toplexon(4006);
                        
                        % Outcome variables.
                        choiceMade = 'stay';
                        rewarded = 'yes';
                        rewardSize = currJuice;
                        
                        % Send variables to Plexon; save them to a .mat file.
                        send_and_save;
                        
                        % Reduce the reward level for the next time.
                        currJuice = currJuice - juiceUnit;
                        
                        % Make sure current juice is no lower than zero.
                        if currJuice < 0
                            currJuice = 0;
                        end
                        
                        % Make sure the leave bar height stays the same.
                        newLBarHeight = false;
                        
                        % Reset errors variable for the next trial.
                        trialErrors = struct([]);
                        
                        currTrial = currTrial + 1;
                        pause(ITI);
                    end
                end
            else
                % Monkey never made a choice.
                error_state('noChoice');
                
                % Redo this trial since monkey failed it.
                run_single_trial;
            end
        else
            % Monkey never fixated to initiate trial.
            error_state('noInitiate');
            
            % Redo this trial since monkey failed it.
            run_single_trial;
        end
    end
    
    % Sends trial variables to Plexon and also saves them to a .mat file.
    function send_and_save()
        % Figure out the trial type name in English for this trial.
        if trialType == 0
            stayBarOn = 'right';
        else
            stayBarOn = 'left';
        end
        
        % Figure out foraging time used in this trial.
        foragingTime = startLBarHeight / shrinkRateSec;
        
        % Preallocate some memory.
        allForagingTimes = zeros(1, length(leaveBarHeights));
        
        % Convert bar lengths to the times it takes to shrink them.
        for i = 1:length(leaveBarHeights)
            allForagingTimes(i) = leaveBarHeights(i) / shrinkRateSec;
        end
        
        % Determine if any errors were made.
        if isempty(trialErrors)
            trialErrors = 'none';
        end
        
        % Time to shrink stay bar.
        sBTimeToShrink = stayBarHeight / shrinkRateSec;
        
        % Generate all possible reward values in mL.
        allJuiceAmounts = [];
        totalJuice = juiceMax;
        
        while totalJuice > 0
            allJuiceAmounts(length(allJuiceAmounts) + 1) = totalJuice;
            
            totalJuice = totalJuice - juiceUnit;
            
            if totalJuice <= 0
                totalJuice = 0;
                allJuiceAmounts(length(allJuiceAmounts) + 1) = totalJuice;
            end
        end
        
        % Send variables to Plexon.
        % NEEDS FINISHING!
        
        % Save variables to a .mat file.
        data(currTrial).trial = currTrial;                    % The trial number for this trial.
        data(currTrial).stayBarOn = stayBarOn;                % Which side the say bar was on.
        data(currTrial).foragingTime = foragingTime;          % The foraging time for this trial.
        data(currTrial).choiceMade = choiceMade;              % Which choice the monkey made.
        data(currTrial).rewarded = rewarded;                  % Whether or not a reward was given.
        data(currTrial).rewardSize = rewardSize;              % Reward size given on this trial.
        data(currTrial).trialErrors = trialErrors;            % Errors and error types made.
        data(currTrial).timeToFixate = timeToFix;             % Max allowed for first fixation.
        data(currTrial).minFixTimeToStart = minFixTime;       % Fixatin time needed to start task.
        data(currTrial).holdFixTime = holdFixTime;            % Fixation hold time before saccade.
        data(currTrial).timeToChoose = timeToSaccade;         % Time monkey has to choose.
        data(currTrial).ITI = ITI;                            % Intertrial interval.
        data(currTrial).timeInErrorState = errorStateTime;    % Time spent in the error state.
        data(currTrial).allForagingTimes = allForagingTimes;  % All the possible foraging times.
        data(currTrial).shrinkRate = shrinkRateSec;           % Bar shrink rate in pixels/s.
        data(currTrial).handlingTime = sBTimeToShrink;        % Time for stay bar to shrink.
        data(currTrial).allJuiceAmounts = allJuiceAmounts;    % All the possible juice amounts.
        
        eval(saveCommand);
    end
    
    % Randomly chooses a new height for the leave bar.
    function set_leave_bar()
        % Get a random integer from the range 1 to 21 (inclusive).
        randIndex = round(rand(1) * 20 + 1);
        
        startLBarHeight = leaveBarHeights(randIndex);
        currLBarHeight = leaveBarHeights(randIndex);
    end
    
    % Sets up the Eyelink system.
    function setup_eyelink()
        abortSetup = false;
        setupMode = 2;
        
        % Connect Eyelink to computer if unconnected.
        if ~Eyelink('IsConnected')
            Eyelink('Initialize');
        end
        
        % Start recording eye position.
        Eyelink('StartRecording');
        
        % Preferences (not sure I want to keep).
        Eyelink('Command', 'randomize_calibration_order = NO');
        Eyelink('Command', 'force_manual_accept = YES');
        
        Eyelink('StartSetup');
        
        % Wait until Eyelink actually enters setup mode.
        while ~abortSetup && Eyelink('CurrentMode') ~= setupMode
            [keyIsDown, ~, keyCode] = KbCheck;
            
            if keyIsDown && keyCode(KbName('ESCAPE'))
                abortSetup = true;
                disp('Aborted while waiting for Eyelink!');
            end
        end
        
        % Put Eyelink in output mode.
        Eyelink('SendKeyButton', double('o'), 0, 10);
        
        % Start recording.
        Eyelink('SendKeyButton', double('o'), 0, 10);
    end
    
    % Recursively shrinks the height of the passed bar to zero at given rate.
    function shrunk = shrink_bar(barToShrink, shrinkRate, currHeight, ...
                                 lBXMin, lBXMax, lBYMin, lBYMax, ...
                                 sBXMin, sBXMax, sBYMin, sBYMax)
        % Shrink either the leave or the stay bar.
        if strcmp(barToShrink, 'leave') == 1
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
            
            % Wait for a second to allow for 65 pixel/s shrink rate.
            pause(shrinkInterval);
            
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
            
            newCurrHeight = currHeight - shrinkRate;
            
            if newCurrHeight <= 0
                % Redraw only the non-shrinking bar.
                draw_bars(0, 0, 0, 0, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'notleave');
                
                % Bar is completely shrunk.
                shrunk = true;
                
                % Notify Plexon: Bar is completely shrunk.
                toplexon(4005);
               
                return;
            else
                newYMin = lBYMin + (shrinkRate / 2);
                newYMax = lBYMax - (shrinkRate / 2);
                
                % Redraw both bars with one smaller to shrink.
                draw_bars(lBXMin, lBXMax, newYMin, newYMax, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'both');
                
                % Notify Plexon: Bar is shrinking.
                toplexon(4004);
        
                % Recursive call.
                shrunk = shrink_bar('leave', shrinkRate, newCurrHeight, ...
                                    lBXMin, lBXMax, newYMin, newYMax, ...
                                    sBXMin, sBXMax, sBYMin, sBYMax);
            end
        elseif strcmp(barToShrink, 'stay') == 1
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
            
            % Wait for a second to allow for 65 pixel/s shrink rate.
            pause(shrinkInterval);
            
            % Check for pressed keys.
            keyPress = key_check;
            key_execute(keyPress);
        
            newCurrHeight = currHeight - shrinkRate;
            
            if newCurrHeight <= 0
               % Redraw bars to shrink.
               draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                         0, 0, 0, 0, false, 'notstay');
               
               % Bar is completely shrunk.
               shrunk = true;
               
               % Notify Plexon: Bar is completely shrunk.
               toplexon(4005);
               
               return;
            else
                newYMin = sBYMin + (shrinkRate / 2);
                newYMax = sBYMax - (shrinkRate / 2);
                
                % Redraw both bars with one smaller to shrink.
                draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                          sBXMin, sBXMax, newYMin, newYMax, false, 'both');
                
                % Notify Plexon: Bar is shrinking.
                toplexon(4004);
                
                % Recursive call.
                shrunk = shrink_bar('stay', shrinkRate, newCurrHeight, ...
                                    lBXMin, lBXMax, lBYMin, lBYMax, ...
                                    sBXMin, sBXMax, newYMin, newYMax);
            end
        else
            disp('Shrinking error');
            shrunk = false;
            
            return;
        end
    end
end