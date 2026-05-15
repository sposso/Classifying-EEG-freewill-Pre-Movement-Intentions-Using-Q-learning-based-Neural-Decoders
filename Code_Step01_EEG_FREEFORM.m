% This code generates the RAW and FTA features for provided dataName and provided window.
% This code is adapted from a previous project which can be accessed here: https://github.com/JihyeBae13/EMBC22_KTD_EEG_PublicDataTest
% Last modified by Jenna Kim 3/09/26
% Close all figures, clear workspace, and clear command window 
close all; clear; clc; 

%% Global Variables
% Define the path where the data is stored
dataPath = 'C:\Users\jki342.AD\EEG_Codes\NatureFREEFORM';
cellfun(@(x) fprintf('dataName: %s\n', x), {dir(fullfile(dataPath, '*.mat')).name}); %Printing the data files
% Define the path where results will be save
resultPath = 'C:\Users\jki342.AD\EEG_Codes\results\kaya_KTD';
if ~exist(resultPath, 'dir'), mkdir(resultPath); end
% Define the name of the data file to be loaded
% dataName = 'FREEFORMSubjectB1511112StLRHand';
% dataName = 'FREEFORMSubjectC1512082StLRHand';
 dataName = 'FREEFORMSubjectC1512102StLRHand';

disp(['dataName: ' dataName '.mat is selected.'])

tstart = -0.5; % Define start time to extract EEG. Relative to the start of a trial.
tend = 0; % Define end time to extract EEG. Relative to the start of trial.

codePath = pwd; %Script's directory
% Update resultPath to include the 'dataName' directory
resultPath = fullfile(resultPath,dataName);
% Check if a folder with the name 'dataName' exists in the results path
% If it doesn't exist, create it
if ~exist(resultPath, 'dir'), mkdir(resultPath); end

% Define a folder name based on the time window used for EEG extraction
resultFolderName = ['Data_from_' num2str(tstart) '_to' num2str(tend)];
% Update resultPath to include the 'resultFolderName' directory
resultPath = fullfile(resultPath,resultFolderName);
% Check if the folder named 'resultFolderName' exists in the current result path
% If it doesn't exist, create it
if ~exist(resultPath, 'dir'), mkdir(resultPath); end
%% Loading the data information
load([dataPath '\' dataName '.mat']); % Load the data file corresponding to the subject
marker = o.marker; % Marker array
RawEEG = o.data; % EEG data (22 Channels)
ChannelNames = o.chnames; % Channel Names
fs = o.sampFreq; % Sampling frequency
[tlength, nch] = size(RawEEG); % Number of channels
nclass = 3; %Number of classes
%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CHANNEL_DECODIFICATION_3_ CLASSES %%%%%%%%%%%%%%%%%%%%%%%%%%%
j = 1;
k = 1;
l = 1;
m = 1;
%Find beginnings of trials and store them in index vectors
for it = 1:tlength-1
    if (marker(it) == 0) && (marker(it+1) == 1) % Class1 = Left Hand
        indexC1(j,1) = it+1;
        j=j+1;
    elseif (marker(it) == 0) && (marker(it+1) == 2) % Class2 = Right Hand
        indexC2(k,1) = it+1;
        k=k+1;
    elseif (marker(it) == 0) && (marker(it+1) == 3) % Class3 = Neutral
        indexC3(l,1) = it+1;
        l=l+1;
    else
        indexND(m,1) = it; % Nothing displayed to validate total trial numbers
        m=m+1;
    end
end

% Validating the trial extraction based on the marker signal
h = figure;
subplot(2,1,1)
hold on
plot(marker,'k')
plot(indexC1,1,'r*')
plot(indexC2,2,'g*')

xlabel('Time Index')
ylabel('Marker')
title('Single Entire Session')
set(gca,'fontsize', 18);
subplot(2,1,2)
hold on
plot(marker,'k')
plot(indexC1,1,'r*')
plot(indexC2,2,'g*')

xlim([1*10^5 1.15*10^5])
xlabel('Time Index')
ylabel('Marker')
title('Selected Time Interval (Zoomed In)')
set(gca,'fontsize', 18);

saveas(h,fullfile(resultPath,'Fig_TrialExtraction.fig'));
saveas(h,fullfile(resultPath,'Fig_TrialExtraction.tif'));
disp('Trial extraction figures are saved.')
%%
%%%%%%%%%%%%%%%%%%%%% DATA SEGMENTATION %%%%%%%%%%%%%%%%%%%%%%%%%

ntrial = length(indexC1)+length(indexC2); % Number of trials
classID = [ones(size(indexC1)).*1; ones(size(indexC2)).*2];
classTrialIndex = [indexC1; indexC2];
trialEEG = zeros(abs(tend-tstart)*fs,nch,ntrial);

for itr = 1: ntrial
    trialEEG(:,:,itr) = RawEEG(classTrialIndex(itr)+tstart*fs:classTrialIndex(itr)+tend*fs-1,:);
end



%% Define frequency ranges
fmin1 = 0.5; fmax1 = 4;  
fmin2 = 0.5; fmax2 = 30;  
fmin3 = 8; fmax3 = 30;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Feature1: RAW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trialEEG_BP1 = band_pass_filter(trialEEG, fs, fmin1, fmax1);
trialEEG_BP2 = band_pass_filter(trialEEG, fs, fmin2, fmax2);
trialEEG_BP3 = band_pass_filter(trialEEG, fs, fmin3, fmax3);

ntpoints = size(trialEEG,1);
RAWfeature_0_4 = nan(ntrial, ntpoints*(nch-1));
RAWfeature_0_30 = nan(ntrial, ntpoints*(nch-1));
RAWfeature_0_8 = nan(ntrial, ntpoints*(nch-1));

for itr = 1:ntrial
    for ich = 1:nch-1
        RAWfeature_0_4(itr, ntpoints*(ich-1)+1:ntpoints*ich) = trialEEG_BP1(:,ich,itr);
        RAWfeature_0_30(itr, ntpoints*(ich-1)+1:ntpoints*ich) = trialEEG_BP2(:,ich,itr);
        RAWfeature_0_8(itr, ntpoints*(ich-1)+1:ntpoints*ich) = trialEEG_BP3(:,ich,itr);
    end
end

disp('RAW features are extracted.')
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Feature2: Cartesian FTA, REAL & IMAGINARY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trialEEGfft = fft(trialEEG); % FFT of the segmented EEG
lFFT = size(trialEEGfft, 1); % length of FFTf

%Find frequency axis for one-sided FFT from sampling frequency and
%two-sided FFT length
if(mod(lFFT,2) == 0)
    frequencyAxis = 0:fs/lFFT:fs/2;

    %In the case that the fft has an even number of points (zero is not
    %dead center of shifted fft) turn two sided fft into one sided by including all
    %elements from the DC component to the only non-repeated frequency.
    %Double elements from one to positiveFreqLast
    fft1side = [trialEEGfft(1,:,:); 2*trialEEGfft(2:lFFT/2,:,:); ...
        trialEEGfft(lFFT/2+1,:,:)];
else
    frequencyAxis = 0:fs/(lFFT-1):fs/2;

    %Otherwise, all components but zero (DC) are doubled, since
    %fft is symmetric w.r.t the magnitude frequencyAxis

    fft1side = [trialEEGfft(1,:,:); 2*trialEEGfft(2:(lFFT-1)/2+1,:,:)];
end


% find number of frequency components with respect to fmin and fmax
indexfmin1temp = find(frequencyAxis>=fmin1);
indexfmin1 = indexfmin1temp(1); % 0_4
indexfmax1temp = find(frequencyAxis>fmax1);
indexfmax1 = indexfmax1temp(1) - 1;
nFreqComp1 = length(indexfmin1:indexfmax1); % find number of frequency components with respect to fmin and fmax

indexfmin2temp = find(frequencyAxis>=fmin2);
indexfmin2 = indexfmin2temp(1); % 0_30
indexfmax2temp = find(frequencyAxis>fmax2);
indexfmax2 = indexfmax2temp(1)-1;
nFreqComp2 = length(indexfmin2:indexfmax2); 

indexfmin3temp = find(frequencyAxis>=fmin3);
indexfmin3 = indexfmin3temp(1); % 0_8
indexfmax3temp = find(frequencyAxis>fmax3);
indexfmax3 = indexfmax3temp(1)-1;
nFreqComp3 = length(indexfmin3:indexfmax3); 

FTAfeature_0_4 = nan(ntrial,(nch-1)*(2*nFreqComp1-1));
FTAfeature_0_30 = nan(ntrial,(nch-1)*(2*nFreqComp2-1));
FTAfeature_0_8 = nan(ntrial,(nch-1)*(2*nFreqComp3-1));

trialEEGfftReal1side = real(fft1side);
trialEEGfftImaginary1side = imag(fft1side);


for itr = 1:ntrial
    for ich = 1:nch-1
        % 0.1-4 Hz
        feat_4 = zeros(2*nFreqComp1-1,1);
        feat_4(1,1) = trialEEGfftReal1side(indexfmin1,ich,itr);
        feat_4(2:2:end,1) = trialEEGfftReal1side(indexfmin1+1:indexfmax1,ich,itr);
        feat_4(3:2:end,1) = trialEEGfftImaginary1side(indexfmin1+1:indexfmax1,ich,itr);
        FTAfeature_0_4(itr,(2*nFreqComp1-1)*(ich-1)+1:(2*nFreqComp1-1)*ich) = feat_4;

        % 0.1-30 Hz
        feat_30 = zeros(2*nFreqComp2-1,1);
        feat_30(1,1) = trialEEGfftReal1side(indexfmin2,ich,itr);
        feat_30(2:2:end,1) = trialEEGfftReal1side(indexfmin2+1:indexfmax2,ich,itr);
        feat_30(3:2:end,1) = trialEEGfftImaginary1side(indexfmin2+1:indexfmax2,ich,itr);
        FTAfeature_0_30(itr,(2*nFreqComp2-1)*(ich-1)+1:(2*nFreqComp2-1)*ich) = feat_30;

        % 8-30 Hz
        feat_8 = zeros(2*nFreqComp3-1,1);
        feat_8(1,1) = trialEEGfftReal1side(indexfmin3,ich,itr);
        feat_8(2:2:end,1) = trialEEGfftReal1side(indexfmin3+1:indexfmax3,ich,itr);
        feat_8(3:2:end,1) = trialEEGfftImaginary1side(indexfmin3+1:indexfmax3,ich,itr);
        FTAfeature_0_8(itr,(2*nFreqComp3-1)*(ich-1)+1:(2*nFreqComp3-1)*ich) = feat_8;
    end
end
disp('FTA features are extracted.')
%% Saving RAW and FTA Features
% save(fullfile(resultPath,'Data_EEGfeatureRAW.mat'),'RAWfeature_0_4','RAWfeature_0_30','classID')
RAWfeature = RAWfeature_0_4;
save(fullfile(resultPath,'EEGfeatureRAW_4.mat'), 'RAWfeature','classID')

RAWfeature = RAWfeature_0_30;
save(fullfile(resultPath,'EEGfeatureRAW_30.mat'), 'RAWfeature','classID')
% save(fullfile(resultPath,'Data_EEGfeatureFTA.mat'),'FTAfeature_0_4','FTAfeature_0_30','classID')
FTAfeature = FTAfeature_0_4;
save(fullfile(resultPath,'EEGfeatureFTA_4.mat'), 'FTAfeature','classID')

FTAfeature = FTAfeature_0_30;
save(fullfile(resultPath,'EEGfeatureFTA_30.mat'), 'FTAfeature','classID')

RAWfeature = RAWfeature_0_8;
save(fullfile(resultPath,'EEGfeatureRAW_8.mat'), 'RAWfeature','classID')

FTAfeature = FTAfeature_0_8;
save(fullfile(resultPath,'EEGfeatureFTA_8.mat'), 'FTAfeature','classID')
disp(['RAW and FTA featurs are saved in ' resultPath ' .'])
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plotting Features: 1) ERP and 2) Cartesian FTA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ChToPlot = "C3"; % Channel name to plot
ChToPlotIndex = find(ChToPlot == ChannelNames);

if isempty(ChToPlotIndex)
    fprintf('=====================ERROR========================\n');
    fprintf('The entered channel to plot does not exist or is wrong\n');
else
    % Time vector for ERP
    tplot = tstart:1/fs:tend;
    tplot = tplot(1:end-1)';

    % Frequency bands for RAW ERP
    freqBandsRAW = { ...
        struct('name','0.1-4 Hz','data',trialEEG_BP1), ...
        struct('name','0.1-30 Hz','data',trialEEG_BP2) ...
        struct('name','8-30 Hz','data',trialEEG_BP3) ...
    };

    for fb = 1:length(freqBandsRAW)
        band = freqBandsRAW{fb};
        bandName = band.name;
        data_band = band.data;

        % Select channel
        trialEEGToPlot = squeeze(data_band(:,ChToPlotIndex,:));

        % Plot ERP
        h = figure;
        hold on;
        plot(tplot, mean(trialEEGToPlot(:,classID==1),2), 'r', 'LineWidth',2);
        plot(tplot, mean(trialEEGToPlot(:,classID==2),2), 'b', 'LineWidth',2);
        plot(tplot, mean(trialEEGToPlot(:,classID==3),2), 'g', 'LineWidth',2);

        % Plot ±STD
        for cls = 1:3
            col = ['r','b','g'];
            plot(tplot, mean(trialEEGToPlot(:,classID==cls),2)+std(trialEEGToPlot(:,classID==cls),[],2), [':', col(cls)], 'LineWidth',1.5);
            plot(tplot, mean(trialEEGToPlot(:,classID==cls),2)-std(trialEEGToPlot(:,classID==cls),[],2), [':', col(cls)], 'LineWidth',1.5);
        end

        grid on;
        xlim([tstart tend]);
        ylim([-7 7]); % adjust if needed
        xlabel('Relative time from a trial start [sec]');
        ylabel('Voltage [uV]');
        legend({'Left Hand','Right Hand','Neutral'},'Location','southeast');
        title([dataName ', ' convertStringsToChars(ChToPlot) ' - RAW ERP (' bandName ')']);
        set(gca,'fontsize',18);

        % Save figure
        fileName = ['Fig_', dataName ,'_', convertStringsToChars(ChToPlot), '_RAW_ERP_', bandName];
        saveas(h, fullfile(resultPath,[fileName,'.fig']));
        saveas(h, fullfile(resultPath,[fileName,'.tif']));
    end
end
disp(['RAW ERP results for ' char(ChToPlot) ' are plotted and saved for both frequency bands.']);

%% ---------------- Plotting FTA Features for Both Frequency Bands ----------------

% Frequency bands and corresponding nFreqComp
freqBandsFTA = { ...
    struct('name','0.1-4 Hz','nFreq',nFreqComp1), ...
    struct('name','0.1-30 Hz','nFreq',nFreqComp2) ...
    struct('name','8-30 Hz','nFreq',nFreqComp3) ...
};

for fb = 1:length(freqBandsFTA)
    band = freqBandsFTA{fb};
    nFreq = band.nFreq;
    bandName = band.name;

    % Real and Imaginary components for plotting
    FTrealToPlot = squeeze(trialEEGfftReal1side(:,ChToPlotIndex,:));
    FTimaginaryToPlot = squeeze(trialEEGfftImaginary1side(:,ChToPlotIndex,:));

    h = figure;
    fplot = frequencyAxis;
    xlimRange = [0 4];
    ylimRange = [-300 300]; % adjust if needed

    % Plot Real part
    subplot(2,1,1)
    hold on
    plot(fplot, mean(FTrealToPlot(:,classID==1),2),'r','LineWidth',2);
    plot(fplot, mean(FTrealToPlot(:,classID==2),2),'b','LineWidth',2);
    plot(fplot, mean(FTrealToPlot(:,classID==3),2),'g','LineWidth',2);
    % Plot ±STD
    for cls = 1:3
        col = ['r','b','g'];
        plot(fplot, mean(FTrealToPlot(:,classID==cls),2)+std(FTrealToPlot(:,classID==cls),[],2), [':', col(cls)], 'LineWidth',1.5);
        plot(fplot, mean(FTrealToPlot(:,classID==cls),2)-std(FTrealToPlot(:,classID==cls),[],2), [':', col(cls)], 'LineWidth',1.5);
    end
    grid on;
    xlim(xlimRange);
    ylim(ylimRange);
    title([dataName ', ' convertStringsToChars(ChToPlot) ' - Real (' bandName ')']);
    xlabel('Frequency [Hz]');
    ylabel('Real');
    set(gca,'fontsize',18);

    % Plot Imaginary part
    subplot(2,1,2)
    hold on
    plot(fplot, mean(FTimaginaryToPlot(:,classID==1),2),'r','LineWidth',2);
    plot(fplot, mean(FTimaginaryToPlot(:,classID==2),2),'b','LineWidth',2);
    plot(fplot, mean(FTimaginaryToPlot(:,classID==3),2),'g','LineWidth',2);
    for cls = 1:3
        col = ['r','b','g'];
        plot(fplot, mean(FTimaginaryToPlot(:,classID==cls),2)+std(FTimaginaryToPlot(:,classID==cls),[],2), [':', col(cls)], 'LineWidth',1.5);
        plot(fplot, mean(FTimaginaryToPlot(:,classID==cls),2)-std(FTimaginaryToPlot(:,classID==cls),[],2), [':', col(cls)], 'LineWidth',1.5);
    end
    grid on;
    xlim(xlimRange);
    ylim(ylimRange);
    xlabel('Frequency [Hz]');
    ylabel('Imaginary');
    set(gca,'fontsize',18);

    % Save figure
    fileName = ['Fig_', dataName ,'_', convertStringsToChars(ChToPlot), '_FTA_', bandName];
    saveas(h, fullfile(resultPath,[fileName,'.fig']));
    saveas(h, fullfile(resultPath,[fileName,'.tif']));
    end

disp(['Results for ' char(ChToPlot) ' is plotted and saved.'])
%% End of the script
disp('The script executed succefully.')

%%
% Band-pass filter function
function filtered_data = band_pass_filter(data, fs, lowcut, highcut, order)
    if nargin < 5
        order = 4; % default order
    end
    nyq = 0.5 * fs;
    low = lowcut / nyq;
    high = highcut / nyq;
    
    % Correct 'bandpass' argument
    [b,a] = butter(order,[low high],'bandpass');

    filtered_data = zeros(size(data));
    for ch = 1:size(data,2)
        for tr = 1:size(data,3)
            filtered_data(:,ch,tr) = filtfilt(b,a,data(:,ch,tr));
        end
    end
end
