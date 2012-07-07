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

function charnov(monkeysInitial, trialTotal, currBlock)
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
    
    % References.
    monkeyScreen    = 1;              % Number of the screen the monkey sees.
    trackedEye      = 2;              % Eyelink code for which eye is being tracked.
    window          = NaN;            % Reference to window used for drawing.
    
    % Reward.
    currJuice       = 1.6;            % Current reward amount in microliters.
    juiceMax        = 1.6;            % Max amount of juice monkey can get.
    juiceUnit       = 0.1;            % Amount reward is reduced by for each stay trial.
    pourTimeOneMl   = 0.3;            % Number of secs juicer needs to pour 1 mL.
    
    % Saving.
    validData       = '/TestData/Valid';  % Directory where .mat files are saved.
    saveCommand     = NaN;                % Command string that will save .mat files.
    varName         = 'data';             % Name of the var to save in the workspace.
    
    % Shrinking.
    shrinkRate      = 65;             % Bar shrink rate.
    shrinkInterval  = 1;              % Shrink speed interval.
    
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
    currTrial       = 1;              % Current trial.
    newLBarHeight   = true;           % Whether or not new stay bar height is needed.
    trialType       = 1;              % Current trial. Determines bar placement.
    
    % ---------------------------------------------- %
    % ------------------- Setup -------------------- %
    % ---------------------------------------------- %
    
    % Saving.
    prepare_for_saving;
    
    % Screen.
    window = Screen('OpenWindow', monkeyScreen, colorBackground);
    
    % Eyelink.
    setup_eyelink;
    
    % ---------------------------------------------- %
    % ------------ Main experiment loop ------------ %
    % ---------------------------------------------- %
    
    for i = 1:trialTotal
        run_single_trial;
    end
    
    % ---------------------------------------------- %
    % ----------------- Functions ------------------ %
    % ---------------------------------------------- %
    
    % Displays the error state on the screen.
    function error_state()
        Screen('FillRect', window, colorError, [(centerX - errorSquare) ...
                                                (centerY - errorSquare) ...
                                                (centerX + errorSquare) ...
                                                (centerY + errorSquare)]);
        Screen('Flip', window);
        
        pause(errorStateTime);
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
                    % Determine which boundary the eye entered.
                    if xCoord >= xBoundMin && xCoord <= xBoundMax && ...
                       yCoord >= yBoundMin && yCoord <= yBoundMax
                        % Determine if eye maintained fixation for given duration.
                        checkFixBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                                        yBoundMin, yBoundMax, ...
                                                        duration);
                        
                        if checkFixBreak == false
                            % Fixation was obtained for desired duration.
                            fixation = true;
                            area = 'first';
                            
                            return;
                        end
                    else
                        % Determine if eye maintained fixation for given duration.
                        checkFixBreak = fix_break_check(xBoundMin2nd, xBoundMax2nd, ...
                                                        yBoundMin2nd, yBoundMax2nd, ...
                                                        duration);
                        
                        if checkFixBreak == false
                            % Fixation was obtained for desired duration.
                            fixation = true;
                            area = 'second';
                            
                            return;
                        end
                    end
                end
            else
                % Determine if eye is within the fixation boundary.
                if xCoord >= xBoundMin && xCoord <= xBoundMax && ...
                   yCoord >= yBoundMin && yCoord <= yBoundMax
                    % Determine if eye maintained fixation for given duration.
                    checkFixBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                                    yBoundMin, yBoundMax, ...
                                                    duration);
                    
                    if checkFixBreak == false
                        % Fixation was obtained for desired duration.
                        fixation = true;
                        area = 'single';
                        
                        return;
                    end
                end
            end
        end
        
        % Timeout reached.
        fixation = false;
        area = 'none';
    end
    
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
    
    % Draws the fixation point on the screen.
    function draw_fixation_point(color)
        Screen('FillOval', window, color, [(centerX - dotRadius) ...
                                           (centerY - dotRadius) ...
                                           (centerX + dotRadius) ...
                                           (centerY + dotRadius)]);
        Screen('Flip', window);
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
    
    % Checks if the eye breaks fixation bounds before end of duration.
    function fixationBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                             yBoundMin, yBoundMax, ...
                                             duration)
        fixStartTime = GetSecs;
        
        % Keep checking for fixation breaks for the entire duration.
        while duration > (GetSecs - fixStartTime)
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
        juiceKey = KbName('space');
        pauseKey = KbName('RightControl');
        stopKey  = KbName('ESCAPE');
        
        key.pressed = 0;
        key.escape  = 0;
        key.juice   = 0;
        key.pause   = 0;
        
        [keyIsDown, secs, keyCode] = KbCheck;
        
        if keyCode(juiceKey)
            key.juice = 1;
            key.pressed = 1;
        elseif keyCode(pauseKey)
            key.pause = 1;
            key.pressed = 1;
        elseif keyCode(stopKey)
            key.escape = 1;
            key.pressed = 1;
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
    
    % Runs a single trial using current global variable values.
    function run_single_trial()
        draw_fixation_point(colorFixDot);
        
        fixating = check_fixation(fixBoundXMin, fixBoundXMax, ...
                                  fixBoundYMin, fixBoundYMax, ...
                                  0, 0, 0, 0, ...
                                  minFixTime, timeToFix, false);
        
        if fixating
            % Determine bar positioning.
            [lBXMin, lBXMax, lBYMin, lBYMax, ...
             sBXMin, sBXMax, sBYMin, sBYMax] = bar_positioning;
            
            % Display the bars.
            draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                      sBXMin, sBXMax, sBYMin, sBYMax, true, 'both');
            
            % Determine if eye maintained fixation for given duration.
            checkFixBreak = fix_break_check(fixBoundXMin, fixBoundXMax, ...
                                            fixBoundYMin, fixBoundYMax, ...
                                            holdFixTime);
            
            % Enter error state if fixation lost, otherwise continue trial.
            if checkFixBreak
                % Monkey didn't hold fixation before making a choice.
                error_state;

                % Redo this trial since monkey failed it.
                run_single_trial;

                return;
            else
                % Redraw bars without fixation (remove fixation point).
                draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'both');
            end
            
            % Find out if monkey makes a choice by saccading to either bar.
            [saccade, choice] = check_fixation(lBXMin, lBXMax, lBYMin, lBYMax, ...
                                               sBXMin, sBXMax, sBYMin, sBYMax, ...
                                               minFixTime, timeToSaccade, true);
            
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
                        
                        % Save trial data.
                        data(currTrial).someVar = '<some value>';
                        eval(saveCommand);
                        currTrial = currTrial + 1;
                        
                        % Wait for intertrial interval.
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
                        
                        % Hacky way of smoothly presenting a blank screen.
                        draw_fixation_point(colorBackground);
                        
                        % Reduce the reward level for the next time.
                        currJuice = currJuice - juiceUnit;
                        
                        % Make sure current juice is no lower than zero.
                        if currJuice < 0
                            currJuice = 0;
                        end
                        
                        % Make sure the leave bar height stays the same.
                        newLBarHeight = false;
                        
                        % Save trial data.
                        data(currTrial).someVar = '<some value>';
                        eval(saveCommand);
                        currTrial = currTrial + 1;
                        
                        % Wait for intertrial interval.
                        pause(ITI);
                    end
                end
            else
                % Monkey never made a choice.
                error_state;
                
                % Redo this trial since monkey failed it.
                run_single_trial;
            end
        else
            % Monkey never fixated to initiate trial.
            error_state;
            
            % Redo this trial since monkey failed it.
            run_single_trial;
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
    
    % Randomly chooses a new height for the leave bar.
    function set_leave_bar()
        % Get a random integer from the range 1 to 21 (inclusive).
        randIndex = round(rand(1) * 20 + 1);
        
        currLBarHeight = leaveBarHeights(randIndex);
    end
    
    % Sets up the Eyelink system.
    function setup_eyelink()
        abortFlag = false;
        inSetupMode = 2;
        
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
        
        while ~abortFlag && Eyelink('CurrentMode') ~= inSetupMode
            [keyIsDown, secs, keyCode] = KbCheck;
            
            % Let user abort Eyelink with the escape key.
            if keyIsDown && keyCode(KbName('ESCAPE'))
                disp('Aborted while waiting for Eyelink!');
                abortFlag = true;
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
            % Wait for a second to allow for 65 pixel/s shrink rate.
            pause(shrinkInterval);
            
            newCurrHeight = currHeight - shrinkRate;
            
            if newCurrHeight <= 0
                % Redraw only the non-shrinking bar.
                draw_bars(0, 0, 0, 0, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'notleave');
                
                % Bar is completely shrunk.
                shrunk = true;
                
                return;
            else
                newYMin = lBYMin + (shrinkRate / 2);
                newYMax = lBYMax - (shrinkRate / 2);
                
                % Redraw both bars with one smaller to shrink.
                draw_bars(lBXMin, lBXMax, newYMin, newYMax, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'both');
                
                % Recursive call.
                shrunk = shrink_bar('leave', shrinkRate, newCurrHeight, ...
                                    lBXMin, lBXMax, newYMin, newYMax, ...
                                    sBXMin, sBXMax, sBYMin, sBYMax);
            end
        elseif strcmp(barToShrink, 'stay') == 1
            % Wait for a second to allow for 65 pixel/s shrink rate.
            pause(shrinkInterval);
            
            newCurrHeight = currHeight - shrinkRate;
            
            if newCurrHeight <= 0
               % Redraw bars to shrink.
               draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                         0, 0, 0, 0, false, 'notstay');
               
               % Bar is completely shrunk.
               shrunk = true;
               
               return;
            else
                newYMin = lBYMin + (shrinkRate / 2);
                newYMax = lBYMax - (shrinkRate / 2);
                
                % Redraw both bars with one smaller to shrink.
                draw_bars(lBXMin, lBXMax, newYMin, newYMax, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false, 'both');
                
                % Recursive call.
                shrunk = shrink_bar('leave', shrinkRate, newCurrHeight, ...
                                    lBXMin, lBXMax, newYMin, newYMax, ...
                                    sBXMin, sBXMax, sBYMin, sBYMax);
            end
        else
            disp('Shrinking error');
            shrunk = false;
            
            return;
        end
    end
end