%Tommy Blanchard, Jan 2012
classdef FixedStim < handle
    %Moving saccade target, originally made for conveyer belt foraging task  
    properties(Constant = true)
        width = 80;         %Width of stim
        winSize = [100 100];  %Window size for fixation [x y]
        fixateBoxSize = 5;  %Size of the fixate box (pixel width of border)
        graceLength = 0.25;
        fixColour = [255 255 255];
        colours = [255,   0,   0;
            255, 125,  50;
            255, 255,   0;
            100, 100, 100;
            0,   0, 255;
            0, 255,   0;
            255,   0, 255;
            0, 255, 255;];
        rewSizes = [0;.06;.08;.1;.12;.14;.16;.18]*2;
        dotColour= [255,255,255];
        dotSize  = 10;
        grace = 0.4;
    end
    properties
        shrinkSpeed;    %Factor determining time of fixation required
        initLength;
        length;             %Indicates how long fixation must be held for to get reward
        location;           %Location of center of stim. Updated frequently [x, y]
        colour;             %Colour of stim, indicates size of reward
        rewSize;            %Size of reward (should be linked to colour)
        window;             %The graphics window, initialized in main program        
        lastMoveTime;       %Time of last movement, used to calculate next location
        fixated;        %Is the stim currently being fixated? 1 or 0
        eaten = 0;
        abort;
        aborted = 0;
        forcedRew;
        graceCurrent = 0;
        unfix = 0;
    end
    
    methods(Access = private)
        function delete(obj)
        end
    end
    
    methods
        function obj = FixedStim(length, location, colour, window, shrinkSpeed, forcedRew)
            %Constructor, reward size is just the rank (lowest to highest)
            %of the reward size (1 is red, lowest, 8 is cyan, highest)
            obj.length = length;
            obj.initLength = length;
            obj.location = location;
            obj.colour = obj.colours(colour,:);
            obj.rewSize = obj.rewSizes(colour);
            obj.lastMoveTime = GetSecs;
            obj.window = window;
            obj.shrinkSpeed = shrinkSpeed;
            obj.abort.location = 0;
            obj.abort.length = 0;
            obj.forcedRew = forcedRew;
            if obj.forcedRew == 1
                obj.fixated = 1;
            else
                obj.fixated = 0;
            end
        end 
        function draw(obj)
            %Just assume they are all rectangles, for now...
            rect = [(obj.location(1)-(obj.length/2)) (obj.location(2)-(obj.width/2)) (obj.location(1)+(obj.length/2)) (obj.location(2)+(obj.width/2))];
            if(obj.fixated == 1 && obj.forcedRew == 0)
                fixRect1 = rect(1,1:2) - obj.fixateBoxSize;
                fixRect2 = rect(1,3:4) + obj.fixateBoxSize;
                Screen('FillRect', obj.window, obj.fixColour, [fixRect1 fixRect2]);
            end
            Screen('FillRect', obj.window, obj.colour, rect);
            if(obj.forcedRew == 0)
                Screen('FillOval', obj.window, obj.dotColour, [(obj.location-(obj.dotSize/2)) (obj.location+(obj.dotSize/2))]);
            end
        end
        function a = move(obj)
            %Updates location, based on lastMoveTime and speed
            a = 0;
            curTime = GetSecs;
            obj.graceCurrent = obj.graceCurrent - (curTime - obj.lastMoveTime);
            if(obj.fixated == 1)
                shrink(obj, curTime);
            elseif(obj.graceCurrent <=0)
                obj.length = obj.initLength;
                if (obj.unfix == 1)
                    toplexon(8000); %Inform plexon of the size reset
                    disp(8000);
                end
                obj.unfix = 0;
            end
            obj.lastMoveTime = curTime;
            if(obj.length <=0)
                reward(obj);
                obj.eaten = 1;
            end
            if(obj.length > 0)
                draw(obj);
            else
                a = 1;
            end
        end
        function checkFix(obj, ex, ey)
            %Checks if the monkey is currently fixating on this target
            if(obj.forcedRew == 0)
                if(ex>=obj.location(1)-obj.winSize(1))&&(ex<=obj.location(1)+obj.winSize(1)) && (ey>=obj.location(2)-obj.winSize(2)) && (ey <= obj.location(2)+obj.winSize(2))
                    if(obj.fixated == 0)
                        %PLEXON tempter fixation acquired
                        obj.fixated = 1;
                        obj.graceCurrent = obj.grace;
                        toplexon(5200);
                        toplexon(6000 + floor(obj.length));
                        disp(5200);
                        disp(6000 + floor(obj.length));
                    end
                elseif(obj.fixated == 1)
                    %PLEXON tempter fixation lost
                    toplexon(5600);
                    toplexon(6000 + floor(obj.length));
                    disp(5600);
                    disp(6000 + floor(obj.length));
                    obj.graceCurrent = obj.grace;
                    obj.aborted = obj.aborted + 1;
                    obj.abort(obj.aborted).location = obj.location;
                    obj.abort(obj.aborted).length = obj.length;
                    obj.fixated = 0;
                    obj.unfix = 1;
                end
            end
        end
        function complete(obj)
            offstage= [0, 0, 0];
            backcolour       = [50,   50,  50];
            Screen('FillRect', obj.window, backcolour);
            [xMax, yMax] = Screen('WindowSize', obj.window);
            yStart  = 200;
            yEnd    = 500;
            Screen('FillRect', obj.window, offstage, [0 0 xMax yStart - 40])
            Screen('FillRect', obj.window, offstage, [0 (yEnd + 40) xMax yMax])
            Screen(obj.window,'flip');
            %Return to "Normal mode" (draw grey rectangle)
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

