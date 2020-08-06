clear all;close all;clc

% Load .mat files
cd('ProcessedData\FabGuard')
D = dir('*.mat');
FileList = {D.name};
[s,v] = listdlg('PromptString','Select a FabGuard file to load:','SelectionMode','single','ListString', FileList);
load(D(s).name)
[filepath,filename,ext] = fileparts(D(s).name);
clearvars D FileList v

cd('..\PWLog')
D = dir('*.mat');
FileList = {D.name};
[s,v] = listdlg('PromptString','Select a PW file to load:','SelectionMode','single','ListString', FileList);
load(D(s).name)

prompt = 'Enter the m/z to analyze: ';
mz = input(prompt);

% Define peak locations and widths
indA = find(PW.Command == 'Position A');
tA = PW.TimeAbsoluteUTC(indA);
tA = interp1(MIMS.TimeAbsoluteUTC,MIMS.TimeAbsoluteUTC,tA,'nearest');
nan = isnan(tA);                 % Find if any times are NaN
for i = 1:length(nan)            % This will happen if FG data starts after PW data 
    if nan(i) ~= 0               % (interp1 needs 2 data points)
        disp([num2str(i),') Cannot match Pos A time to MIMS timeseries.  Hit Enter to replace NaN and continue.'])
        k = waitforbuttonpress;
        disp(' ')
        tA(nan) = MIMS.TimeAbsoluteUTC(1); % Replace the NaN
    end
end

[~,~,indA] = intersect(tA,MIMS.TimeAbsoluteUTC);

indB = find(PW.Command == 'Position B');
tB = PW.TimeAbsoluteUTC(indB);
tB = interp1(MIMS.TimeAbsoluteUTC,MIMS.TimeAbsoluteUTC,tB,'nearest');
nan = isnan(tB);                % Find if any times are NaN
for i = 1:length(nan)           % This will happen if stopped data before last injection completed
    if nan(i) ~= 0
        disp([num2str(i),') Cannot match Pos B time to MIMS timeseries.  Hit Enter to replace NaN and continue.'])
        k = waitforbuttonpress;
        disp(' ')
        tB = tB(1:end-1);       % Cut off last injection
    end
end

[~,~,indB] = intersect(tB,MIMS.TimeAbsoluteUTC);

% Find baseline and peak start/stop indices
prompt = 'Enter the peak start offset: ';
offset = input(prompt);

prompt = 'Enter the peak width: ';
width_pk = input(prompt);

if mz == 32
    sig = MIMS.amu32;
    start_pk = indB + offset;       % Peak start index
    str = 'm/z 32 (A)';
    gas = 'O2';
elseif mz == 28 
    sig = MIMS.amu28;
    start_pk = indB + offset;            % Peak start index
    str = 'm/z 28 (A)';
    gas = 'N2';
elseif mz == 15 
    sig = MIMS.amu15;
    start_pk = indB + offset;            % Peak start index
    str = 'm/z 15 (A)';
    gas = 'CH4';
elseif mz == 40
    sig = MIMS.amu40;
    start_pk = indB + offset;            % Peak start index
    str = 'm/z 40 (A)';
    gas = 'Ar';
elseif mz == 44
    sig = MIMS.amu44;
    start_pk = indB + offset;
    str = 'm/z 44 (A)';
    gas = 'CO2';
else
    fprintf('Invalid choice of analyte.')
end
stop_pk = start_pk + width_pk;      % Stop indices of peaks

% If timeseries stopped before last peak finished, don't include it
if stop_pk(end) > length(MIMS.TimeAbsoluteUTC)
    start_pk(end) = [];
    stop_pk(end) = [];
    indB(end) = [];
end

Npks = length(indB);

start_bl = stop_pk;        % Start indices of baseline segment
stop_bl = start_bl + 6;

flag = find(stop_bl > length(sig));
stop_bl(flag) = length(sig);

% Plot timeseries w/ valve switching times
figure(3),clf
hax = axes;
plot(MIMS.TimeRelativeSec/60,sig)
hold on
hstart=plot(MIMS.TimeRelativeSec(start_pk)/60,sig(start_pk),'.g');
hstop=plot(MIMS.TimeRelativeSec(stop_pk)/60,sig(stop_pk),'.r');
for i = 1:Npks % Plot baseline segments
    hbl = plot(MIMS.TimeRelativeSec(start_bl(i):stop_bl(i))/60,sig(start_bl(i):stop_bl(i)),'-m','linewidth',3);
end
% Plot lines for switch between positions
hB=line([MIMS.TimeRelativeSec(indB) MIMS.TimeRelativeSec(indB)]/60,get(hax,'YLim'),'Color',rgb('DarkGreen'),'linestyle','--');
hA=line([MIMS.TimeRelativeSec(indA) MIMS.TimeRelativeSec(indA)]/60,get(hax,'YLim'),'Color',rgb('DarkRed'),'linestyle','--');
xticks(0:5:max(MIMS.TimeRelativeSec/60))
xlabel('Time (min)')
ylabel(str)
xlim([min(MIMS.TimeRelativeSec) max(MIMS.TimeRelativeSec)]/60)
legend([hA(1),hB(1),hstart,hstop,hbl(1)],'Pos. A','Pos. B','Peak Start','Peak Stop','Baseline')

% Save variables into structure
timepts = struct('indA',indA,'indB',indB,'start_bl',start_bl,'stop_bl',stop_bl,'start_pk',start_pk,'stop_pk',stop_pk,'Npks',Npks);

cd(['..\Timepoints\',gas])
save(filename,'timepts')    
