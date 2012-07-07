function valid(monkeysInitial)
    running = true;
    taskDirectory = '/Users/bhayden/Documents/AaronMATLAB/randomfour';
    
    while running
        % Get a random order to present the following four tasks.
        order = randperm(4);
        
        for i = 1:size(order, 2)
            taskNum = order(i);
            
            % Go to directory with all the task scripts.
            cd(taskDirectory);
            
            % Run the charnov task.
            if taskNum == 1
                charnov(monkeysInitial, 1);
            % Run the stagopsfinal task.
            elseif taskNum == 2
                stagopsfinal(monkeysInitial);
            % Run the dietselection task.
            elseif taskNum == 3
                dietselection(monkeysInitial);
            % Run the fadeops task.
            elseif taskNum == 4
                fadeops(monkeysInitial);
            end
        end
    end
end