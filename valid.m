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

function valid(monkeysInitial)
    taskDirectory = '/Users/bhayden/Documents/AaronMATLAB/randomfour';
    taskTrialTotal = 1;
    completedBlocks = 0;
    currentBlock = 0;
    
    for j = 1:4
        currentBlock = currentBlock + 1;
        
        % Get a random order to present the following four tasks.
        order = randperm(4);
        
        for i = 1:size(order, 2)
            taskNum = order(i);
            
            % Go to directory with all the task scripts.
            cd(taskDirectory);
            
            % Run the charnov task.
            if taskNum == 1
                charnov(monkeysInitial, taskTrialTotal, currentBlock);
            % Run the stagopsfinal task.
            elseif taskNum == 2
                stagopsfinal(monkeysInitial, taskTrialTotal, currentBlock);
            % Run the dietselection task.
            elseif taskNum == 3
                dietselection(monkeysInitial, taskTrialTotal, currentBlock);
            % Run the fadeops task.
            elseif taskNum == 4
                fadeops(monkeysInitial, taskTrialTotal, currentBlock);
            end
        end
        
        completedBlocks = completedBlocks + 1;
    end
end