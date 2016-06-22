%function [] = IRheatTracking()

%% GET VIDEO FILENAME USING GUI PROMPT

clc, close all; clear all; 
scsz = get(0,'ScreenSize');

cd(fileparts(which('IRheatTracking.m')));


promptTXT = {'Enter Video Filename'};
dlg_title = 'Input'; num_lines = 1; presetval = {'IRexample.mp4'};
dlgOut = inputdlg(promptTXT,dlg_title,num_lines,presetval);
vidname = dlgOut{:};


promptTXT = {'Analyze every 1 in X number of frames:'};
dlg_title = 'Input'; num_lines = 1; presetval = {'10'};
dlgOut = inputdlg(promptTXT,dlg_title,num_lines,presetval);
SkpFrm = str2num(dlgOut{:});


%% READ VIDEO INTO FRAME DATA

f = VideoReader(vidname);				% import vid
nf = get(f, 'NumberOfFrames');			% get total number of vid frames

f1 = mean(read(f, 1),3);				% get frame-1 data
szf = size(f1);

nFrms = numel(1:SkpFrm:nf);

f1dat = {zeros(szf)};
framedat = repmat(f1dat,1,nFrms);

%figure(1); imagesc(f1);				% plot frame-1 data



%% GET FRAME DATA

clear f

ff = VideoReader(vidname);

mm=1;
for nn=1:SkpFrm:nf

    framedat{mm} = mean(read(ff, nn), 3);

    if ~mod(mm,100); disp(nn); end

mm = mm+1;
end




%% PROMPT USER FOR NUMBER OF ROI MASKS

% Construct a questdlg with two options
choice = questdlg('How many ROIs are there?', ...
	'ROI Selection', ...
	'One','Two','One');
% Handle response
switch choice
    case 'One'
        disp([choice ' selected - Creating 1 ROI mask...'])
        NumMasks = 1;
    case 'Two'
        disp([choice ' selected - Creating 2 ROI masks...'])
        NumMasks = 2;
    case ''
        disp('Window closed - Creating 1 ROI mask by default...')
        NumMasks = 1;
end



%% CREATE GRAPHICS WINDOW FOR USER TO DRAW ROI
% WE USE MASKS SO WE ARE NOT DETECTING HEAT SIGNALS OUTSIDE OF ROI

if NumMasks == 2

    disp('1. press OK button, then use cursor to draw a rectangle around first ROI')
    disp('2. press OK button, then use cursor to draw a rectangle around second ROI')
    disp('3. exit figure using the X at the top corner of window')
    getROI = @(hImg) round(getPosition(imrect));

    roi = []; pause(1); 
    hImg = imagesc(f1); pause(1)

    [hui] = uicontrol('Style', 'pushbutton', 'String', 'OK','Position', [200 7 50 20],...
                      'Callback', 'roi(end+1,:) = getROI(hImg)');

    % NMui = 0; while NMui < NumMasks; uiwait; NMui = NMui+1; end;
    for nn=1:NumMasks; uiwait; end;

    roi1 = roi(1,:); roi2 = roi(2,:);
    ROIa = [roi1(2) (roi1(2)+roi1(4)) roi1(1) (roi1(1)+roi1(3))];
    ROIb = [roi2(2) (roi2(2)+roi2(4)) roi2(1) (roi2(1)+roi2(3))];

    mask{1} = zeros(size(f1));
    mask{1}(ROIa(1):ROIa(2), ROIa(3):ROIa(4)) = 1;

    mask{2} = zeros(size(f1));
    mask{2}(ROIb(1):ROIb(2), ROIb(3):ROIb(4)) = 1;

else

    disp('1. press OK button, then use cursor to draw a rectangle around first ROI')
    disp('2. exit figure using the X at the top corner of window')
    getROI = @(hImg) round(getPosition(imrect));

    roi = []; pause(1); 
    hImg = imagesc(f1); pause(1)
    
    [hui] = uicontrol('Style', 'pushbutton', 'String', 'OK','Position', [200 7 50 20],...
                      'Callback', 'roi(end+1,:) = getROI(hImg)');

    for nn=1:NumMasks; uiwait; end;

    roi1 = roi(1,:);
    ROIa = [roi1(2) (roi1(2)+roi1(4)) roi1(1) (roi1(1)+roi1(3))];

    mask{1} = zeros(size(f1));
    mask{1}(ROIa(1):ROIa(2), ROIa(3):ROIa(4)) = 1;

end



%% check that the masks are right.
figure(1)
for nn = 1:numel(mask)
    subplot(1,numel(mask),nn);
    imagesc(f1.*mask{nn});
	axis square
end



%% check vague SNR for masks.
figure(1)
for nn = 1:numel(mask)
    subplot(numel(mask),1,nn);
    hist(f1(mask{nn}==1),100);
end

promptTXT = {'Threshold: pick value to separates subject from background:'};
dlg_title = 'Input'; num_lines = 1; presetval = {'160'};
dlgOut = inputdlg(promptTXT,dlg_title,num_lines,presetval);
threshmask = str2num(dlgOut{:});


%% MAIN DATA ACQUISITION LOOP

% nFrms = numel(1:SkpFrm:nf);

n_pixels = zeros(nFrms,NumMasks);
mu = n_pixels;
sd = n_pixels;
mupix = n_pixels;

pixelvals{nFrms,NumMasks} = [];

imgsz = size(f1);
imgszX = imgsz(1)+1;



xloc = zeros(numel(1:numel(framedat)),1); % 479x1 double
yloc = zeros(numel(1:numel(framedat)),1); % 479x1 double

pp = 1;
% for every frame
for mm = 1:numel(framedat)
	
    % load the frame data from the movie
    framedata = framedat{mm};
    
    % for every mask (subregion of image)
	for nn = 1:NumMasks
		
        % find where the hot thing is in the subregion; anything over threshold
        % corresponds to the hot thing in the given image subregion
        subjpixels = framedata.*mask{nn} > threshmask(nn);
		
        % where are the hot pixels?
		% save mean x and y position of the hot thing -- for motion detection.
        [ii, jj] = find(subjpixels);
        yloc(mm,nn) = imgszX-mean(ii);
        xloc(mm,nn) = mean(jj);
	end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xy = [xloc yloc];


%% COMPUTE TOTAL DISTANCE 

% 'xloc' contains vector of x-coordinate positions
% 'yloc' contains vector of y-coordinate positions

for dt = 1:numel(xloc)-1

    Xa = dt;
    Ya = dt;
    Xb = Xa+1;
    Yb = Ya+1;
    
    dL(dt) = sqrt((xloc(Xb) - xloc(Xa))^2 + (yloc(Yb) - yloc(Ya))^2);

end


totalDist = sum(dL);
meanDist = mean(dL);
stdDist = std(dL);
semDist = stdDist / sqrt(numel(dL));

SPF1 = sprintf('  TOTAL AMBULATORY DISTANCE: % 5.6g au \r',totalDist);
SPF2 = sprintf('  MEAN AMBULATORY DISTANCE: % 5.4g au \r',meanDist);
SPF3 = sprintf('  STDEV AMBULATORY DISTANCE: % 5.4g au \r',stdDist);
SPF4 = sprintf('  SEM AMBULATORY DISTANCE: % 5.4g au \r',semDist);

disp(' ')
disp([SPF1, SPF2, SPF3, SPF4])


%% BIN DATA - COMPUTE SUM AND MEAN FOR EACH BIN

nbins = 20;
subs = round(linspace(1,nbins,numel(dL))); % subs(end) = nbins;
BinSumD = accumarray(subs',dL,[],@sum);
BinAveD = accumarray(subs',dL,[],@mean);






%% PLOT DATA
close all

fh1=figure('Position',[100 200 1100 500],'Color','w');
hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
hax2=axes('Position',[.55 .1 .4 .8],'Color','none');

    axes(hax1)
ph1 = plot(xloc,yloc);
    set(ph1,'LineStyle','-','Color',[.9 .2 .2],'LineWidth',2);
    title('Ambulation')

    axes(hax2)
ph2 = plot(BinSumD);
    set(ph1,'LineStyle','-','Color',[.9 .2 .2],'LineWidth',2);
    title('Distance Traveled Per Bin')





%% ADDITIONAL PLOTS

% % Moving average
% wts = [1/10;repmat(1/5,4,1);1/10];
% L = conv(dL,wts,'valid');
% plot(L,'r','LineWidth',2);







