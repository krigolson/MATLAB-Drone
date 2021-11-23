clear all;
close all;
clc;

% by Olav Krigolson
% program to connect to a MUSE and a DJI Tello Drone and fly the drone
% using EEG! See MATLAB-Muse for more details on how the base code works.

% connect to the drone
droneObj = ryze("Tello");
disp('Drone Connected!');

% specify a Muse Name
museName = 'MuseS-10A8';

% specify a training channel and a frequency
% channels, 1 = TP9, 2 = AF7, 3 = AF8, 4 = TP10
trainingChannel = 4;
% specify a training frequency band
% 1 = Delta, 2 = Theta, 3 = Alpha, 4 = Beta
trainingBand = 3;
% set the SD multiplier for difficulty of control
controlDifficulty = 2;
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

disp('Muse Characteristics Read...');

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

% create a bunch of empty variables
events = zeros(4,10000000);
eegData = zeros(4,12);
eegSamples = zeros(1,12);
tempEEG = zeros(4,12);
plotBuffer = zeros(4,512);
previousSamples = zeros(4,2,3);
previousResults = zeros(4,2,3);

disp('Starting Data Acquisition...');

% loop through and get some data and plot it
global endCollection
endCollection = 0;
collectData = true;
f = figure;
dataCounter = 1;

barData = zeros(1,30);
baselineData = [];

% setup colors for bar graph
% set up some colors for bar graphs
col(1,:) = [0 0 1]; % -- blue
col(2,:) = [0 0 1]; % -- blue
col(3,:) = [0 0 1]; % -- blue
col(4,:) = [0 0 1]; % -- blue
col(5,:) = [0 0 1]; % -- blue
col(6,:) = [0 0 1]; % -- blue
col(7,:) = [0 0 1]; % -- blue
col(8,:) = [0 0 1]; % -- blue
col(9,:) = [0 0 1]; % -- blue
col(10,:) = [0 0 1]; % -- blue
col(11,:) = [0 0 1]; % -- blue
col(12,:) = [0 0 1]; % -- blue
col(13,:) = [0 0 1]; % -- blue
col(14,:) = [0 0 1]; % -- blue
col(15,:) = [0 0 1]; % -- blue
col(16,:) = [0 0 1]; % -- blue
col(17,:) = [0 0 1]; % -- blue
col(18,:) = [0 0 1]; % -- blue
col(19,:) = [0 0 1]; % -- blue
col(20,:) = [0 0 1]; % -- blue
col(21,:) = [0 0 1]; % -- blue
col(22,:) = [0 0 1]; % -- blue
col(23,:) = [0 0 1]; % -- blue
col(24,:) = [0 0 1]; % -- blue
col(25,:) = [0 0 1]; % -- blue
col(26,:) = [0 0 1]; % -- blue
col(27,:) = [0 0 1]; % -- blue
col(28,:) = [0 0 1]; % -- blue
col(29,:) = [0 0 1]; % -- blue
col(30,:) = [0 0 1]; % -- blue
c = 1:1:30;

disp('Collecting Baseline Data...');
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
% set a paramter so the drone control signal only happens once
startControl = 0;

while collectData
    
    set(f,'windowkeypressfcn',@keyPressed);
    
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
    
    if tempFFT > meanBaselinePower + (controlDifficulty * sdBaselinePower)
        
        % turn on control and change color of bar graph
        control = 1;
        col = [[0 1 0];  col];
        
        if startControl == 0
            startControl = 1;
            takeoff(droneObj);
        end
        
    else
        
        % turn off control and change color of bar graph
        control = 0;
        col = [[0 0 1];  col];
        
    end
    
    col(31,:) = [];
    
    % update power plot data
    barData = [tempFFT barData];
    barData(31) = [];
    
    % draw the bar plot
    barPlot = bar(c,barData,'FaceColor','flat');
    barPlot.CData = col;
    ylim([0 yMax]);
    drawnow; 
   
    if endCollection == 1
        collectData = false;
        land(droneObj);
    end
end

disp('Done!');

% create a callback function to stop data collection
function keyPressed(source, event)
    global endCollection
    KeyPressed=event.Key;
    if strcmp(KeyPressed,'space')
        endCollection = 1;
        close all;
    end
end