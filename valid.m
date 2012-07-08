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
    taskDirectory = '/Users/bhayden/Documents/AaronMATLAB/randomfour';
    taskTrialTotal = totalTrials;
    totalTrialsRun = 0;
    completedBlocks = 0;
    currentBlock = 0;
    running = true;
    taskName = '';
    
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
                
                charnov(monkeysInitial, taskTrialTotal, currentBlock);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            % Run the stagopsfinal task.
            elseif taskNum == 2
                taskName = 'stagopsfinal';
                print_task(taskName);
                
                stagopsfinal(monkeysInitial, taskTrialTotal, currentBlock);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            % Run the dietselection task.
            elseif taskNum == 3
                taskName = 'dietselection';
                print_task(taskName);
                
                dietselection(monkeysInitial, taskTrialTotal, currentBlock);
                
                totalTrialsRun = totalTrialsRun + taskTrialTotal;
                
                % Check keys for commands.
                keyPress = key_check;
                key_execute(keyPress);
            % Run the fadeops task.
            elseif taskNum == 4
                taskName = 'fadeops';
                print_task(taskName);
                
                fadeops(monkeysInitial, taskTrialTotal, currentBlock);
                
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
    
    % Checks to see what key was pressed.
    function key = key_check()
        % Assign key codes to some variables.
        juiceKey = KbName('space');
        stopKey = KbName('ESCAPE');
        
        % Make sure default values of key are false.
        key.escape = false;
        key.juice = false;
        
        % Get info about any key that was just pressed.
        [keyIsDown, secs, keyCode] = KbCheck;
        
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
        pause(5);
        home; 
    end
end