clear all;
close all;
clc;

% by Olav Krigolson
% program to connect to a MUSE and move a circle on screen

% define key variables
% specify a Muse Name
museName = 'MuseS-4161';
% specify a training channel and a frequency
% channels, 1 = TP9, 2 = AF7, 3 = AF8, 4 = TP10
trainingChannel = 4;
% specify a training frequency band
% 1 = Delta, 2 = Theta, 3 = Alpha, 4 = Beta
trainingBand = 3;
% set the SD multiplier for difficulty of control
controlDifficulty = 1.5;
% the length of baseline data collection, in seconds
baselineTime = 10;
% muse sampling rate
sampleRate = 256;
% key parameter for biquad filters, this is a recommended value
bandWidth = 0.707;
% turn on high pass, low pass, and notch with 1, off with 0
whichFilters = [1 1 1];
% set up biquad high pass filter coefficients
frequency = 0.1;
highPass = biQuadHighPass(frequency,sampleRate,bandWidth);
% set up biquad high pass filter coefficients
frequency = 30;
lowPass = biQuadLowPass(frequency,sampleRate,bandWidth);
% setup biquad notch filter coefficients
frequency = 60;
notchFilter = biQuadNotch(frequency,sampleRate,bandWidth);
% create a bunch of empty variables
events = zeros(4,10000000);
eegData = zeros(4,12);
eegSamples = zeros(1,12);
tempEEG = zeros(4,12);
plotBuffer = zeros(4,512);
previousSamples = zeros(4,2,3);
previousResults = zeros(4,2,3);
% define the background screen colour
backgroundColor = [166 166 166];
% define the screen size
screenSize = [0 0 800 600];
%screenSize = [];
% define default text size
textSize = 24;
% define the text color
textColor = [255 255 255];
% define circle size by its radius
circleRadius = 30;
% define a key to crash out of the program
exitKey = KbName('Q');
% define the circle colour
drawColor = [0 255 0];
% the amount the circle goes back down each loop
lossMovement = 0;
% bar scaling factor
barScale = 200;

% define muse BLE names and characteristics
museServiceUUID = 'FE8D';
museControlCharacteristic = '273E0001-4C4D-454D-96BE-F03BAC821358';
museEEGCh1Characteristic = '273E0003-4C4D-454D-96BE-F03BAC821358';
museEEGCh2Characteristic = '273E0004-4C4D-454D-96BE-F03BAC821358';
museEEGCh3Characteristic = '273E0005-4C4D-454D-96BE-F03BAC821358';
museEEGCh4Characteristic = '273E0006-4C4D-454D-96BE-F03BAC821358';
museEEGChAux1Characteristic = '273E0007-4C4D-454D-96BE-F03BAC821358';
museACCCharacteristic = '273E000A-4C4D-454D-96BE-F03BAC821358';
museGyroCharacteristic = '273E0009-4C4D-454D-96BE-F03BAC821358';
museTeleCharacteristic = '273E000B-4C4D-454D-96BE-F03BAC821358';

% connect to a MUSE
b = ble(museName);

disp('Muse Connected...');

% set up the control charactertistic to write to
controlCharacteristic = characteristic(b,museServiceUUID,museControlCharacteristic);
% set up characteristics for channels 1 to 4
chCharacteristic{1} = characteristic(b,museServiceUUID,museEEGCh1Characteristic);
chCharacteristic{2} = characteristic(b,museServiceUUID,museEEGCh2Characteristic);
chCharacteristic{3} = characteristic(b,museServiceUUID,museEEGCh3Characteristic);
chCharacteristic{4} = characteristic(b,museServiceUUID,museEEGCh4Characteristic);

disp('Starting Grapics Routine...');

% send values to open the data stream from the Muse
% each message begins with the number of bytes, the message, and a linefeed (10)
% send a h to stop the muse temporarily
write(controlCharacteristic,[uint8(2) uint8('h') uint8(10)],'withoutresponse');
% disable the aux channel by sending p21 (p20 to enable)
write(controlCharacteristic,[uint8(4) uint8('p') uint8('2') uint8('1') uint8(10)],'withoutresponse');
% send a "s" to the muse to tell it to start
write(controlCharacteristic,[uint8(2) uint8('s') uint8(10)],'withoutresponse');
% send a "d" to the muse to tell it to continue
write(controlCharacteristic,[uint8(2) uint8('d') uint8(10)],'withoutresponse');

% skip Psychtoolbox sync tests to avoid sync failure issues
% Screen('Preference', 'SkipSyncTests', 1); 
% open a Psychtoolbox drawing window
[win, rec] = Screen('OpenWindow', 0 , backgroundColor, screenSize, 32, 2);
% get the x and y coordinates of the middle of the screen
xPos = rec(3)/2;
yPos = rec(4) - 50;
yMid = rec(4)/2;

% setup some parameters
Screen(win,'TextSize', textSize);

% put up the task name in the middle of the screen
DrawFormattedText(win, 'BCI Circle Control','center', 'center', [255 255 255],[],[],[],2);
Screen('Flip', win);
WaitSecs(2);

collectData = true;

baselineData = [];

tic;
endTime = toc;

while endTime < baselineTime
    
    for channelCounter = 1:4
    
        % read a characteristic
        chData = read(chCharacteristic{channelCounter});
        % convert the data to EEG format
        [eegEvent, eegSample] = readMuse(chData);
        
        % store the values
        events(channelCounter,dataCounter) = eegEvent;
        tempEEG(channelCounter,:) = eegSample;
        
    end
    
    dataCounter = dataCounter + 1;
    
    % flip the current sample around
    plotSample = flip(tempEEG,2);

    % clean the data with a biquad filter
    [plotSample,previousSamples,previousResults] = applyBiQuad(plotSample,whichFilters,highPass,lowPass,notchFilter,previousSamples,previousResults);

    plotBuffer(:,13:512) = plotBuffer(:,1:500);
    plotBuffer(:,1:12) = plotSample;
    
    % plot FFT output
    % define maximum y value for power
    yMax = 20;
    fftCoefficients = doMuseFFT(plotBuffer,sampleRate);
    
    % isolate the training channel
    currentFFTData = squeeze(fftCoefficients(trainingChannel,:));
    
    % isolate the training band
    if trainingBand == 1
        tempFFT = currentFFTData(1:3);
    end
    if trainingBand == 2
        tempFFT = currentFFTData(4:7);
    end    
    if trainingBand == 3
        tempFFT = currentFFTData(8:12);
    end            
    if trainingBand == 4
        tempFFT = currentFFTData(13:30);
    end
    tempFFT = mean(tempFFT);
    
    baselineData = [tempFFT baselineData];
   
    endTime = toc;
    
end

% get the stats on the baseline power
meanBaselinePower = mean(baselineData);
sdBaselinePower = std(baselineData);

% the on off switch for control
control = 0;

% put up the task name in the middle of the screen
DrawFormattedText(win, 'Baseline Complete, Beginning Game','center', 'center', [255 255 255],[],[],[],2);
Screen('Flip', win);
WaitSecs(2);

while collectData
    
    for channelCounter = 1:4
    
        % read a characteristic
        chData = read(chCharacteristic{channelCounter});
        % convert the data to EEG format
        [eegEvent, eegSample] = readMuse(chData);
        
        % store the values
        events(channelCounter,dataCounter) = eegEvent;
        tempEEG(channelCounter,:) = eegSample;
        
    end
    
    dataCounter = dataCounter + 1;
    
    % flip the current sample around
    plotSample = flip(tempEEG,2);

    % clean the data with a biquad filter
    [plotSample,previousSamples,previousResults] = applyBiQuad(plotSample,whichFilters,highPass,lowPass,notchFilter,previousSamples,previousResults);

    plotBuffer(:,13:512) = plotBuffer(:,1:500);
    plotBuffer(:,1:12) = plotSample;
    
    % plot FFT output
    fftCoefficients = doMuseFFT(plotBuffer,sampleRate);
    
    % isolate the training channel
    currentFFTData = squeeze(fftCoefficients(trainingChannel,:));
    
    % isolate the training band
    if trainingBand == 1
        tempFFT = currentFFTData(1:3);
    end
    if trainingBand == 2
        tempFFT = currentFFTData(4:7);
    end    
    if trainingBand == 3
        tempFFT = currentFFTData(8:12);
    end            
    if trainingBand == 4
        tempFFT = currentFFTData(13:30);
    end
    tempFFT = mean(tempFFT);

    % determine bar height as a z-score
    zBar = (tempFFT - meanBaselinePower)/sdBaselinePower;
    
    % now scale this for drawping purposes
    barHeight = zBar * barScale;
    % make bar height correct for drawing
    if barHeight > yMid
        barBottom = yMid;
        barTop = yMid - barHeight;
    else
        barBottom = yMid - barHeight;
        barTop = yMid;
    end
    if barTop < 0
        barTop = 0;
    end
    if barBottom > rec(4)
        barBottom = rec(4);
    end
    
    if tempFFT > meanBaselinePower + (controlDifficulty * sdBaselinePower)    
        
        % turn on control and change color of bar graph
        control = 1;
        yPos = yPos - 20;
        
    else    
        % turn off control and change color of bar graph
        control = 0;
        yPos = yPos + lossMovement;
    end

    Screen('FillRect', win , [255 0 0], [100 barTop 150 BarBottom], 8);
    Screen('FillOval', win , drawColor, [xPos-circleRadius yPos-circleRadius xPos+circleRadius yPos+circleRadius], 8);
    Screen('Flip', win);

    % crash out of experiment (blocks)
    [~, ~, keyCode] = KbCheck();
    if keyCode(exitKey)
        break;
    end

end