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

function valid(monkeysInitial, totalTrials)
    colorBackground = [50 50 50];   % Background color of entire experiment screen.
    completedBlocks = 0;            % How many blocks of tasks have been completed.
    currentBlock    = 0;            % Block of four tasks currently being completed.
    ITI             = 5;            % Pause time between every trial.
    monkeyScreen    = 1;            % Number of the screen the monkey sees.
    running         = true;         % Stores running state of entire task.
    taskDirectory   = '/Users/bhayden/Documents/AaronMATLAB/randomfour';
                                    % Directory where the tasks's program files are stored.
    taskName        = '';           % Name of the current task being run.
    taskTrialTotal  = totalTrials;  % Number of trials for each subtask to run.
    totalTrialsRun  = 0;            % Total number of trials run for the session.
    
    % Get a window to display stimuli through all sessions.
    window = setup_window;
    
    print_info;
    
    while running
        % Check keys for commands.
        keyPress = key_check;
        key_execute(keyPress);
        
        currentBlock = currentBlock + 1;
        
        % Get a random order to present the following four tasks.
        order = randperm(4);
        
        taskCounter = 1;
        
        while running && taskCounter <= 4
            % Check keys for commands.
            keyPress = key_check;
            key_execute(keyPress);
            
            taskNum = order(taskCounter);
            taskCounter = taskCounter + 1;
            
            % Go to directory with all the task scripts.
            cd(taskDirectory);
            
            % Run the charnov task.
            if taskNum == 1
                taskName = 'charnov';
                print_task(taskName);
                
                charnov(monkeysInitial, taskTrialTotal, currentBlock, window);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            % Run the stagopsfinal task.
            elseif taskNum == 2
                taskName = 'stagopsfinal';
                print_task(taskName);
                
                stagopsfinal(monkeysInitial, taskTrialTotal, currentBlock, window);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            % Run the dietselection task.
            elseif taskNum == 3
                taskName = 'dietselection';
                print_task(taskName);
                
                dietselection(monkeysInitial, taskTrialTotal, currentBlock, window);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            % Run the fadeops task.
            elseif taskNum == 4
                taskName = 'fadeops';
                print_task(taskName);
                
                fadeops(monkeysInitial, taskTrialTotal, currentBlock, window);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            end
            
            print_stats(taskName);
        end
        
        completedBlocks = completedBlocks + 1;
        print_stats(taskName);
    end
    
    % Close the sceen since the experiment is done.
    Screen('CloseAll');
    
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
            disp(oldEnableFlag);
            disp(oldLevel);
        % Give an instance juice reward.
        elseif keyRef.juice == true
            reward(spaceReward);
        end
    end
    
    % Prints what tasks are going to be run and how many times each.
    function print_info()
        home;
        disp('             ');
        disp('****************************************');
        disp('             ');
        disp('Going to run:');
        disp('    - stagopsfinal');
        disp('    - fadops');
        disp('    - dietselection');
        disp('    - charnov');
        disp('             ');
        fprintf('Trials per task:% 4u', taskTrialTotal);
        disp('             ');
        disp('             ');
        disp('****************************************');
    end
    
    % Prints current experiment stats.
    function print_stats(taskName)
        home;
        disp('             ');
        disp('****************************************');
        disp('             ');
        fprintf('Just ran:% 14s', taskName);
        disp('             ');
        disp('             ');
        fprintf('Trials completed:% 4u', totalTrialsRun);
        disp('             ');
        disp('             ');
        fprintf('Blocks completed:% 2u', completedBlocks);
        disp('             ');
        disp('             ');
        disp('****************************************');
    end
    
    % Prints next task to run.
    function print_task(taskName)
        disp('             ');
        disp('             ');
        fprintf('Next task:% 14s', taskName);
        disp('             ');
        disp('             ');
        disp('****************************************');
        pause(ITI);
        home;
    end
    
    % Sets up a new window and sets preferences for it.
    function window = setup_window()
        % Print only PTB errors.
        Screen('Preference', 'VisualDebugLevel', 1);
        
        % Suppress the print out of all PTB warnings.
        Screen('Preference', 'Verbosity', 0);
        
        % Setup a screen for displaying stimuli for this session.
        window = Screen('OpenWindow', monkeyScreen, colorBackground);
    end
end