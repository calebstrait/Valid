classdef Lane < handle
    %Works with MovingStim. Originally made for diet selection task.
    properties
        currentWorms = 0;
        worm;
        tempter;
        currentTempter = 0;
        yStart;      %Where the worms are created.
        yEnd;        %Where the worms stop.
        xLocation;  
        window;
        speed;
        shrinkSpeed;
        maxTime;
        minTime;
        minLength;
        saveCommand;
        totalWorms = 0;
        data;
        probWorm;
        temptTrial = 0;
        temptSwitch;
        gamble1Prob;
        gamble2Prob;
        forcedRewProb;
        forcedFixProb;
    end    
    properties(Constant = true)
        maxColour = 8;
        maxLength = 300;
        temptCol = 6; %Min colour during which tempter will appear
        tempterCol = 2; %Max colour of tempter
        tempterMinTime = 6; %Min time a worm must have for tempter to appear
        tempterTime= 5; %Time left when tempter will appear
        tempterProb= .5; %Probability of a tempter when above criteria are met
        forcedRewLength = 8;
        forcedFixLength = 2;
    end
    methods
        function obj = Lane(xLocation, yStart, yEnd, window, speed, maxTime, minTime, saveCommand, probWorm, temptSwitch, gamble1Prob, gamble2Prob, forcedRewProb,forcedFixProb)
            obj.gamble1Prob = gamble1Prob;
            obj.gamble2Prob = gamble2Prob;
            obj.forcedRewProb = forcedRewProb;
            obj.forcedFixProb = forcedFixProb;
            obj.saveCommand = saveCommand;
            obj.xLocation = xLocation;
            obj.window = window;
            obj.yStart = yStart;
            obj.yEnd   = yEnd;
            obj.speed  = speed;
            obj.maxTime = maxTime;
            obj.minTime = minTime;
            obj.shrinkSpeed = obj.maxLength/obj.maxTime;
            obj.minLength = minTime*obj.shrinkSpeed;
            obj.probWorm = probWorm;
            obj.temptSwitch = temptSwitch;
        end
        function makeRandWorm(obj, searchTime)
            if(obj.currentWorms == 0 && obj.currentTempter == 0)
                disp(searchTime);
                frand = rand
                if (frand > obj.forcedFixProb)
                    obj.totalWorms = obj.totalWorms + 1;
                    lrand = rand;
                    length = obj.shrinkSpeed*((ceil(lrand*(obj.maxTime - obj.minTime)) + obj.minTime - 1) + mod((ceil(lrand*(obj.maxTime - obj.minTime)) + obj.minTime - 1), 2));
                    crand = rand;
                    length/obj.shrinkSpeed
                    colour = floor((crand*obj.maxColour) + 1) + mod(floor((crand*obj.maxColour) + 1), 2); %Only even number colours and times
                    colour
                    gambleR = rand;
                    if (gambleR < obj.gamble1Prob)
                        gamble = 1;
                    elseif (gambleR < obj.gamble2Prob)
                        gamble = 2;
                    else
                        gamble = 0;
                    end
                    obj.worm = MovingStim(length, [obj.xLocation obj.yStart], colour, obj.window, obj.yEnd, obj.speed, obj.shrinkSpeed, gamble);
                    obj.data(obj.totalWorms).length = length;
                    obj.data(obj.totalWorms).colour = colour;
                    obj.data(obj.totalWorms).searchTime = searchTime;
                    obj.data(obj.totalWorms).probWorm=obj.probWorm;
                    obj.data(obj.totalWorms).col = obj.worm.colours(colour);
                    obj.data(obj.totalWorms).rewSize = obj.worm.rewSize;
                    obj.data(obj.totalWorms).gamble = obj.worm.gamble;
                    obj.currentWorms = 1;
                    if(obj.temptSwitch == 1)
                        tempterSet(obj);
                    end
                    %PLEXON SEND OVER TRIAL AND WORM INFO
                    toplexon(obj.totalWorms);
                    disp(obj.totalWorms);
                    toplexon(5000 + length/obj.shrinkSpeed);
                    disp(5000 + length/obj.shrinkSpeed);
                    if(gamble == 0)
                        toplexon(5010 + colour);
                        disp(5010 + colour);
                    else
                        toplexon(6300 + gamble);
                        disp(6300 + gamble);
                    end
                    toplexon(5020 + 100*obj.worm.rewSize);
                    disp(5020 + 100*obj.worm.rewSize);
                    toplexon(10000 + floor(searchTime*100));
                    disp(10000 + floor(searchTime*100));
                else
                    %Replace this stuff with fixedstim stuff, you can treat
                    %fixedstim just like a worm
                    
                    %Need to figure out plexon code for this
                    %What colour?
                    obj.totalWorms = obj.totalWorms + 1;

                    [xMax, yMax] = Screen('WindowSize', obj.window);
                    if (frand < obj.forcedRewProb)
                        length = obj.shrinkSpeed*obj.forcedRewLength;
                        bcolour = [80, 30,30];
                        forcedRew = 1;
                        if(rand > .5)
                            colour = 2;
                        else
                            colour = 8;
                        end
                    else
                        length = obj.shrinkSpeed*obj.forcedFixLength;
                        bcolour = [30,80,30];
                        forcedRew = 0;
                        colour = 1;
                    end
                    %PLEXON
                    obj.worm = FixedStim(length, [xMax/2,yMax/2], colour, obj.window, obj.shrinkSpeed,forcedRew); %1 for forced rew
                    toplexon(obj.totalWorms);
                    disp(obj.totalWorms);
                    toplexon(5000 + 2000 + length/obj.shrinkSpeed);
                    disp(5000 + 2000 + length/obj.shrinkSpeed);
                    toplexon(5010+2000 + colour);
                    disp(5010 +2000+ colour);
                    toplexon(5020 + 2000+ 100*obj.worm.rewSize); %Forced trial colours are 2000 more than normal
                    disp(5020 + 2000+ 100*obj.worm.rewSize);
                    toplexon(10000 + floor(searchTime*100));
                    disp(10000 + floor(searchTime*100));
                    toplexon(8000 + forcedRew); %8001 if forcedRew, 8000 if forcedFix
                    disp(8000 + forcedRew);
                    
                    Screen('FillRect', obj.window,bcolour,[0,0,xMax,yMax]);
                    Screen(obj.window,'flip');
                    obj.currentWorms = 2; %2 tells it this is a "full-screen" worm
                end
%                     obj.totalWorms = obj.totalWorms + 1;
%                     toplexon(obj.totalWorms);
%                     disp(obj.totalWorms);
%                     [xMax, yMax] = Screen('WindowSize', obj.window);
%                     width = 80;
%                     length = obj.shrinkSpeed*6;
%                     colour = [0, 255, 255];                    
%                     rect = [(xMax/2-(width/2)) (yMax/2-(length/2)) (xMax/2+(width/2)) (yMax/2+(length/2))];
%                     rect2 = [0,0,xMax,yMax];
%                     Screen('FillRect', obj.window,[80,30,30],rect2);
%                     Screen('FillRect', obj.window, colour, rect);
%                     screen(obj.window,'flip');
%                     lastMoveTime = GetSecs();
%                     while length > 1
%                         curTime = GetSecs();
%                         length = length - obj.shrinkSpeed * (curTime - lastMoveTime);
%                         rect = [(xMax/2-(width/2)) (yMax/2-(length/2)) (xMax/2+(width/2)) (yMax/2+(length/2))];
%                         Screen('FillRect', obj.window, colour, rect);
%                         screen(obj.window,'flip');
%                         lastMoveTime = curTime;
%                     end
%                     reward(.18)
            end
        end
        function tempterSet(obj)
            if(obj.worm.colour >= obj.temptCol && obj.tempterMinTime <= (obj.worm.initLength/obj.shrinkSpeed))
                obj.temptTrial = 1;
            end
        end
        function tempterCheck(obj)
            if(obj.temptTrial == 1 && obj.currentTempter == 0 && (obj.worm.length/obj.shrinkSpeed) < obj.tempterTime)
                q = rand;
                disp(q);
                disp((obj.worm.length/obj.shrinkSpeed));
                if(q < obj.tempterProb)
                    makeTempter(obj);
                end
                obj.temptTrial = 0;
            end
        end
        function makeTempter(obj)
            if(obj.currentTempter == 0)
                obj.currentTempter = 1;
                if(rand > 0.5)
                    length = 2*obj.shrinkSpeed;
                else
                    length = obj.shrinkSpeed;
                end
                obj.tempter = FixedStim(length, [obj.xLocation + 150 + 50 + 200, (obj.yEnd - obj.yStart)/2 + obj.yStart], 2, obj.window, obj.shrinkSpeed);
            end
        end
        function a = update(obj, x, y)
            if(obj.currentWorms == 1 || obj.currentWorms == 2)
                checkFix(obj.worm,x,y);
                if(obj.temptSwitch == 1)
                    tempterCheck(obj);
                end
                done = move(obj.worm);
                if(done == 1)
                    obj.currentWorms = 0;
                    obj.data(obj.totalWorms).eaten = obj.worm.eaten;
                    obj.data(obj.totalWorms).abort = obj.worm.abort;
                    data = obj.data;
                    eval(obj.saveCommand);
                    complete(obj.worm);
                    obj.temptTrial =0;
                end
            end
            if(obj.currentTempter == 1)
                checkFix(obj.tempter,x,y);
                if(obj.tempter.fixated == 0 && obj.currentWorms == 0)
                    obj.data(obj.totalWorms).temptCol   = obj.tempter.colour;
                    obj.data(obj.totalWorms).temptCol   = obj.tempter.rewSize;
                    obj.data(obj.totalWorms).temptCol   = obj.tempter.initLength;
                    obj.data(obj.totalWorms).temptEaten = obj.tempter.eaten;
                    obj.data(obj.totalWorms).temptAbort = obj.tempter.abort;
                    data = obj.data;
                    eval(obj.saveCommand);
                    %PLEXON tempter disappear
                    complete(obj.tempter);
                    obj.currentTempter = 0;
                else
                    doneTempt = move(obj.tempter);
                    if(doneTempt == 1)
                        obj.currentTempter = 0;
                        obj.data(obj.totalWorms).temptCol   = obj.tempter.colour;
                        obj.data(obj.totalWorms).temptCol   = obj.tempter.rewSize;
                        obj.data(obj.totalWorms).temptCol   = obj.tempter.initLength;
                        obj.data(obj.totalWorms).temptEaten = obj.tempter.eaten;
                        obj.data(obj.totalWorms).temptAbort = obj.tempter.abort;
                        data = obj.data;
                        eval(obj.saveCommand);
                        complete(obj.tempter);
                    end
                end
            end
            if(obj.currentWorms == 2)
                a = 1;
            else
                a = 0;
            end
        end
        function reward(size)
            toplexon(5050 + 100*size);
            disp(5050 + 100*size);
            if(obj.rewSize > 0)
                daq=DaqDeviceIndex;
                disp(sprintf('Reward time: %4.2fs', size));
                if(obj.rewSize ~= 0)
                    DaqAOut(daq,0,.6);
                    starttime=GetSecs;
                    while (GetSecs-starttime)<(size);
                    end;
                    DaqAOut(daq,0,0);
                    StopJuicer;
                end
            end
        end
    end
end