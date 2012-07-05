function charnov_task(monkeysFirstInitial, trialTotal)
    % ---------------------------------------------- %
    % -------------- Global variables -------------- %
    % ---------------------------------------------- %
    
    % Colors.
    colorBackground = [50 50 50];     % Background color.
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
    
    % Stimuli.
    barToFixDist    = 300;            % Distance from fixation center to bar edge.
    barWidth        = 80;             % Width of all the bar stimuli.
    currLBarHeight  = 0;              % Current height of the leave bar.
    dotRadius       = 10;             % Radius of the fixation dot.
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
    holdFixTime     = 0.5;            % Duration to hold fixation before choosing.
    minFixTime      = 0.2;            % Min time monkey must fixate to start trial.
    timeToFix       = 30;             % Amount of time the monkey has to fixate.
    timeToSaccade   = intmax;         % Time allowed for monkey to make a choice.
    
    % Trial.
    newLBarHeight   = true;              % Whether or not new stay bar height is needed.
    trialType       = 1;              % Current trial. Determines bar placement.
    
    % ---------------------------------------------- %
    % ------------------- Setup -------------------- %
    % ---------------------------------------------- %
    
    % Screen.
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
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
    
    % Displays and removes the error state on the screen.
    function error_state()
        disp('IN ERROR STATE');
        % show error screen for 3 secs
        % restart trial
    end
    
    % Determines if the eye has fixated within the given bounds
    % or the given duration before the given timeout occurs.
    function [fixation, area] = check_fixation(xBoundMin, xBoundMax, ...
                                               yBoundMin, yBoundMax, ...
                                               xBoundMin2nd, xBoundMax2nd, ...
                                               yBoundMin2nd, yBoundMax2nd, ...
                                               duration, timeout, checkTwo)
        startTime = GetSecs;
        
        % Keep checking for fixation until timeout occurs.
        while timeout > (GetSecs - startTime)
            [xCoord, yCoord] = get_eye_coords;
            
            % Check for eye entering either of two locations.
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
            % Otherwise just watch for eye entering one location.
            else
                % Determine if eye is within the fixation boundaries.
                if xCoord >= xBoundMin && xCoord <= xBoundMax && ...
                   yCoord >= yBoundMin && yCoord <= yBoundMax
                    % Determine if eye maintained fixation for given duration.
                    checkFixBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                                    yBoundMin, yBoundMax, ...
                                                    duration);
                    if checkFixBreak == false
                        % Fixation was obtained for desired duration.
                        fixation = true;

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
    function draw_fixation_point()
        Screen('FillOval', window, colorFixDot, [(centerX - dotRadius) ...
                                                 (centerY - dotRadius) ...
                                                 (centerX + dotRadius) ...
                                                 (centerY + dotRadius)]);
        Screen('Flip', window);
    end
    
    % Draws two bars on the screen.
    function draw_bars(leaveBarXMin, leaveBarXMax, leaveBarYMin, ...
                       leaveBarYMax, stayBarXMin, stayBarXMax, ...
                       stayBarYMin, stayBarYMax, fixPoint)
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
    
    % Runs a single trial using current global variable values.
    function run_single_trial()
        draw_fixation_point;
        
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
                      sBXMin, sBXMax, sBYMin, sBYMax, true);
            
            % Determine if eye maintained fixation for given duration.
            checkFixBreak = fix_break_check(fixBoundXMin, fixBoundXMax, ...
                                            fixBoundYMin, fixBoundYMax, ...
                                            holdFixTime);
            
            % Enter error state if fixation lost, otherwise continue trial.
            if checkFixBreak
               error_state; 
            else
                % Redraw bars without fixation (remove fixation point).
                draw_bars(lBXMin, lBXMax, lBYMin, lBYMax, ...
                          sBXMin, sBXMax, sBYMin, sBYMax, false);
            end
            
            % Find out if monkey makes a saccade to either bar.
            [saccade, choice] = check_fixation(lBXMin, lBXMax, lBYMin, lBYMax, ...
                                               sBXMin, sBXMax, sBYMin, sBYMax, ...
                                               minFixTime, timeToSaccade, true);                     
            if saccade
                % Determine which choice monkey made.
                if strcmp(choice, 'first')
                    disp('FIRST CHOICE SELECTED');
                else
                    disp('SECOND CHOICE SELECTED');
                end
            else
                error_state;
            end
        else
            error_state;
        end
        
        %* if (fixating)
            %* draw bars with fixation point remaining
            
            %* wait for 500 ms while checking fixation continuously
                %* if fixation hasn't been broken.
                    %* remove fixation point (cue to saccade)

                    
                    
                    %* continuously check monkey's eye position
                        % *if fixate on a new target==true && target==blue
                        
                        
                            % start shrinking blue bar
                            % after bar is fully shrunk,
                                % reward the monkey with current reward val
                                % reduce reward val by .02 mL
                                    % if reward is reduced to 0, leave at 0
                                % ITI of 1 sec with nothing on screen

                        % *elseif fixate on new target==true && target==gray
                        
                            % set the makenewleavebarheight var to true
                            % start shrinking gray bar
                            % after bar is fully shrunk
                                % clear screen
                                % ITI of 1 sec with nothing on screen
                                % flip trial type
                                % reset value of gray bar
                                
                                
                                
                 %* else
                    %* send error screen
                    %* restart trial
    end
    
    % Rewards monkey using the juicer with the passed duration.
    function reward(rewardDuration)
        % Get a reference the juicer device.
        daq = DaqDeviceIndex;
        
        if (rewardDuration ~= 0)
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
    
    % Shrinks the height of the passed bar to zero at given rate.
    function shrink_bar(barToShrink, shrinkRate)
    end
end