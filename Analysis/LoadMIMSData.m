clear all;close all;clc
cd('RawData\Fabguard') 

D = dir('*.dat');
FileList = {D.name};
[s,v] = listdlg('PromptString','Select file(s) to process:','SelectionMode','multiple','ListString', FileList);
startRow = 2;

for i = 1:length(s)
    cd('..\..\RawData\Fabguard')
    [TimeRelativeSec,TimeAbsoluteUTC,amu5,amu12,amu14,amu15,amu16,amu18,amu28,amu29,amu30,amu32,amu33,amu34,amu40,amu44,amu45] = importFileFabGuard(D(s(i)).name,startRow);
    [filepath,filename,ext] = fileparts(D(s(i)).name);

    DateTimeEST = datetime(TimeAbsoluteUTC,'convertfrom','posixtime','timezone','America/New_York');
    DateTimeEST.Format = 'dd-MM-uuuu HH:mm:ss';
    MIMS = table(DateTimeEST,TimeAbsoluteUTC,TimeRelativeSec,amu5,amu12,amu14,amu15,amu16,amu18,amu28,amu29,amu30,amu32,amu33,amu34,amu40,amu44,amu45);

    cd('..\..\ProcessedData\Fabguard')
    save(filename,'MIMS');
end