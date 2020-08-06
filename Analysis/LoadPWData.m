clear all;close all;clc
cd('RawData\PWLog')

D = dir('*.txt');
FileList = {D.name};
[s,v] = listdlg('PromptString','Select file(s) to process:','SelectionMode','multiple','ListString', FileList);

for i = 1:length(s)
    cd('..\..\RawData\PWLog')
    [filepath,filename,ext] = fileparts(D(s(i)).name);

    PW = importFilePW(filename);
    PW.PCTime.TimeZone = 'America/New_York';    % Tell MATLAB PCTime is in local time
    DateTimeEST = PW.PCTime;                    % Save DateTime as EST
    PW.PCTime.TimeZone = 'UTC';                 % Change timezone to UTC
    TimeAbsoluteUTC = posixtime(PW.PCTime);
    Command = PW.Command;
    PW = table(DateTimeEST,TimeAbsoluteUTC,Command);

    cd('..\..\ProcessedData\PWLog')
    save(filename,'PW')
end