%Tommy Blanchard, Jan 2012
classdef MovingStim < handle
    %Moving saccade target, originally made for conveyer belt foraging task  
    properties(Constant = true)
        width = 80;         %Width of stim
        winSize = [150 150];  %Window size for fixation [x y]
        fixateBoxSize = 5;  %Size of the fixate box (pixel width of border)
        graceLength = 0.25;    %Length of grace period
        fixColour = [255 255 255];
        colours = [255,   0,   0;
            255, 125,  50;
            255, 255,   0;
            100, 100, 100;
            0,   0, 255;
            0, 255,   0;
            255,   0, 255;
            0, 255, 255;];
         rewSizes = [0;.06;.08;.1;.12;.14;.16;.18];
%         rewSizes = [0;.09;.12;.15;.18;.21;.24;.27]; %1.5
%        rewSizes = [0; .08; .1; .13; .15; .18; .2; .22];
        dotColour= [255,255,255];
        dotSize  = 10;
        gamble1 = [1, 8];
        gamble2 = [3, 7];
    end
    properties
        initLength;
        shrinkSpeed;    %Factor determining time of fixation required
        speed;         %Speed. Keeping this constant for all stim for now
        startLocation;
        endLocation;
        length;             %Indicates how long fixation must be held for to get reward
        location;           %Location of center of stim. Updated frequently [x, y]
        colour;             %Colour of stim, indicates size of reward
        rewSize;            %Size of reward (should be linked to colour)
        window;             %The graphics window, initialized in main program        
        lastMoveTime;       %Time of last movement, used to calculate next location
        graceCurrent;       %Indicates how long the stim has been in grace period mode
        fixated = 0;        %Is the stim currently being fixated? 1 or 0
        eaten = 0;
        abort;
        aborted = 0;
        gamble = 0;
    end
    
    methods(Access = private)
        function delete(obj)
        end
    end
    
    methods
        function obj = MovingStim(length, location, colour, window, endLocation, speed, shrinkSpeed, gamble)
            %Constructor, reward size is just the rank (lowest to highest)
            %of the reward size (1 is red, lowest, 8 is cyan, highest)
            obj.gamble = gamble;
            obj.initLength = length;
            obj.length = length;
            obj.location = location;
            obj.colour = colour;
            obj.rewSize = obj.rewSizes(colour);
            obj.lastMoveTime = GetSecs;
            obj.window = window;
            obj.graceCurrent = 0;
            obj.startLocation = obj.location(2);
            obj.endLocation = endLocation;
            obj.speed = speed;
            obj.shrinkSpeed = shrinkSpeed;
            obj.abort.location = 0;
            obj.abort.length = 0;
            if (gamble == 1)
                if(rand > 0.5)
                    obj.rewSize = obj.rewSizes(obj.gamble1(1));
                else
                    obj.rewSize = obj.rewSizes(obj.gamble1(2));
                end
            elseif (gamble == 2)
                if (rand > 0.5)
                    obj.rewSize = obj.rewSizes(obj.gamble2(1));
                else
                    obj.rewSize = obj.rewSizes(obj.gamble2(2));
                end
            end
        end 
        function draw(obj)
            rect = [(obj.location(1)-(obj.length/2)) (obj.location(2)-(obj.width/2)) (obj.location(1)+(obj.length/2)) (obj.location(2)+(obj.width/2))];
            if(obj.fixated == 1)
                fixRect1 = rect(1,1:2) - obj.fixateBoxSize;
                fixRect2 = rect(1,3:4) + obj.fixateBoxSize;
                Screen('FillRect', obj.window, obj.fixColour, [fixRect1 fixRect2]);
            end
            if(obj.gamble == 0)
                Screen('FillRect', obj.window, obj.colours(obj.colour,:), rect);
            else
                rect1 = [(obj.location(1)-(obj.length/2)) (obj.location(2)-(obj.width/2)) (obj.location(1)) (obj.location(2)+(obj.width/2))];
                rect2 = [(obj.location(1)) (obj.location(2)-(obj.width/2)) (obj.location(1)+(obj.length/2)) (obj.location(2)+(obj.width/2))];
                if(obj.gamble == 1)
                    Screen('FillRect', obj.window, obj.colours(obj.gamble1(1),:), rect1);
                    Screen('FillRect', obj.window, obj.colours(obj.gamble1(2),:), rect2);
                elseif(obj.gamble == 2)
                    Screen('FillRect', obj.window, obj.colours(obj.gamble2(1),:), rect1);
                    Screen('FillRect', obj.window, obj.colours(obj.gamble2(2),:), rect2);
                end
            end
            Screen('FillOval', obj.window, obj.dotColour, [(obj.location-(obj.dotSize/2)) (obj.location+(obj.dotSize/2))]);
        end
        function a = move(obj)
            %Updates location, based on lastMoveTime and speed
            a = 0;
            curTime = GetSecs;
            obj.graceCurrent = obj.graceCurrent - (curTime - obj.lastMoveTime);
            if(obj.fixated == 0 && obj.graceCurrent <= 0)
                obj.location(2) = obj.location(2) + obj.speed*(curTime - obj.lastMoveTime);
            elseif (obj.fixated == 1)
                shrink(obj, curTime);
            end
            obj.lastMoveTime = curTime;
            if(obj.length <=0)
                reward(obj);
                obj.eaten = 1;
                a = 1;
            elseif(obj.length > 0 && obj.location(2) < obj.endLocation)
                draw(obj);
            else
                a = 1;
                toplexon(5999);
                toplexon(6000 + floor(obj.length));
                disp(5999);
                disp(6000 + floor(obj.length));
            end
        end
        function checkFix(obj, ex, ey)
            %Checks if the monkey is currently fixating on this target
            if(ex>=obj.location(1)-obj.winSize(1))&&(ex<=obj.location(1)+obj.winSize(1)) && (ey>=obj.location(2)-obj.winSize(2)) && (ey <= obj.location(2)+obj.winSize(2))
                if(obj.fixated == 0)
                    obj.fixated = 1;
                    toplexon(5200 + floor(obj.location(2)) - obj.startLocation);
                    toplexon(6000 + floor(obj.length));
                    disp(5200 + floor(obj.location(2)) - obj.startLocation);
                    disp(6000 + floor(obj.length));
                    
                end
                obj.graceCurrent = obj.graceLength;
            elseif(obj.fixated == 1)
                toplexon(5600 + floor(obj.location(2)) - obj.startLocation);
                toplexon(6000 + floor(obj.length));
                disp(5600 + floor(obj.location(2)) - obj.startLocation);
                disp(6000 + floor(obj.length));
                obj.aborted = obj.aborted + 1;
                obj.abort(obj.aborted).location = obj.location;
                obj.abort(obj.aborted).length = obj.length;
                obj.fixated = 0;
            end
        end
        function complete(obj)
            delete(obj);
        end
        function reward(obj)
            toplexon(5050 + 100*obj.rewSize);
            disp(5050 + 100*obj.rewSize);
            if(obj.rewSize > 0)
                daq=DaqDeviceIndex;
                disp(sprintf('Reward time: %4.2fs', obj.rewSize));
                if(obj.rewSize ~= 0)
                    DaqAOut(daq,0,.6);
                    starttime=GetSecs;
                    while (GetSecs-starttime)<(obj.rewSize);
                    end;
                    DaqAOut(daq,0,0);
                    StopJuicer;
                end
            end
        end
        function shrink(obj, curTime)
            obj.length = obj.length - obj.shrinkSpeed * (curTime - obj.lastMoveTime);
        end
    end
end

