function charnov_task(monkeysFirstInitial, trialTotal)
    %% Global variables.
    
    leaveBarHeight = 0;    % Height of the gray leave bar.
    trackedEye     = 2;    % Eyelink code for which eye is being tracked.
    trialType      = 0;    % Arrangement of bars on the screen.
    window         = NaN;  % Reference to window used for drawing.
    
    %% Setup.
    
    % Screen settigns and preferences.
    HideCursor;
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    window = Screen('OpenWindow', 1, 0);
    
    % Call helper function to setup Eyelink.
    setup_eyelink;
    
    %% Main experiment loop.
    
    for i = 1:trialTotal
        run_single_trial;
    end
    
    %% Helper functions.
    
    % Determines if the eye has fixated within the given bounds
    % for the given duration before the given timeout occurs.
    function fixation = check_fixation(xBoundMin, xBoundMax, ...
                                       yBoundMin, yBoundMax, ...
                                       duration, timeout)
        startTime = GetSecs;
        
        % Keep checking for fixation until timeout occurs.
        while timeout > (GetSecs - startTime)
            [xCoord yCoord] = get_eye_coords;
            
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
        
        % Timeout reached.
        fixation = false;
    end
    
    % Draws the fixation point on the screen.
    function draw_fixation_point()
        Screen('FillOval', window, focusColor, [0 100 100 100]);
        Screen('Flip', window);
    end
    
    % Draws two bars on the screen.
    function draw_bars(leaveBarPos, stayBarPos, ...
                       leaveBarHeight, stayBarHeight)
        % Clear screen and redraw.
    end
    
    % Checks if the eye breaks fixation bounds before end of duration.
    function fixationBreak = fix_break_check(xBoundMin, xBoundMax, ...
                                             yBoundMin, yBoundMax, ...
                                             duration)
        fixStartTime = GetSecs;
        
        % Keep checking for fixation breaks for the entire duration.
        while duration > (GetSecs - fixStartTime)
            [xCoord yCoord] = get_eye_coords;
            
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
        %draw_fixation_point();
        
        % keep checking eye position
            % if 30 secs have passed without fixation
                % send error screen
                % restart trial

        % if (fixating)
            % draw bars with fixation point remaining
            
            % wait for 500 ms while checking fixation continuously
                % if fixation hasn't been broken.
                    % remove fixation point (cue to saccade)

                    % continuously check monkey's eye position
                        % if fixate on a new target==true && target==blue
                            % start shrinking blue bar
                            % after bar is fully shrunk,
                                % reward the monkey with current reward val
                                % reduce reward val by .02 mL
                                    % if reward is reduced to 0, leave at 0
                                % ITI of 1 sec with nothing on screen

                        % elseif fixate on new target==true && target==gray
                            % start shrinking gray bar
                            % after bar is fully shrunk
                                % clear screen
                                % ITI of 1 sec with nothing on screen
                                % flip trial type
                                % reset value of gray bar
                 % else
                    % send error screen
                    % restart trial
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
    
    % Determines the height, shrink rate and duration of leave bar.
    function set_leave_bar()
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