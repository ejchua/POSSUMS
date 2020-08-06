clear all;close all;clc

prompt = 'Enter the m/z to analyze: ';
mz = input(prompt);

% Load MIMS data
cd('ProcessedData\Fabguard')
D = dir('*.mat');
FileList = {D.name};
[s,v] = listdlg('PromptString','Select a MIMS file to load:','SelectionMode','single','ListString', FileList);
load(D(s).name)
[filepath,filename,ext] = fileparts(D(s).name);
clearvars D FileList v filepath ext prompt s

if mz == 32
    sig = MIMS.amu32;
    gas = 'O2';
elseif mz == 28
    sig = MIMS.amu28;
    gas = 'N2';
elseif mz == 15
    sig = MIMS.amu15;
    gas = 'CH4';
elseif mz == 40
    sig = MIMS.amu40;
    gas = 'Ar';
elseif mz == 44
    sig = MIMS.amu44;
    gas = 'CO2';
end

% Load timepoints data
cd(['..\Timepoints\',gas])
D = dir('*.mat');
FileList = {D.name};
[s,v] = listdlg('PromptString','Select a timepoints file to load:','SelectionMode','single','ListString', FileList);
load(D(s).name)
[filepath,filename,ext] = fileparts(D(s).name);
clearvars D FileList s v filepath ext

% Calculate baseline segments
for i = 1:length(timepts.start_bl)
    bl_avg(i) = mean(sig(timepts.start_bl(i):timepts.stop_bl(i)));
end

% Baseline correct peaks and integrate
for i = 1:timepts.Npks
    sig_corr = sig(timepts.start_pk(i):timepts.stop_pk(i)) - bl_avg(i);                        % Baseline correction
    PkArea(i) = trapz(MIMS.TimeRelativeSec(timepts.start_pk(i):timepts.stop_pk(i)),sig_corr);  % Peak integration
end

MeanPkArea = mean(PkArea);
StdPkArea = std(PkArea);

PkArea = struct('PkArea',PkArea,'MeanPkArea',MeanPkArea,'StdPkArea',StdPkArea,'Npks',timepts.Npks);

% Save to .mat file
cd(['..\..\..\Output\PeakAreas\',gas])
save(filename,'PkArea')
