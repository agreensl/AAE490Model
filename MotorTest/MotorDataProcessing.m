clear
clc

%% Load data from File

fileName = '2_19_627pm.csv';
sampleFreq = 1; %[samples/sec]

% Find KV from csv File
fileID = fopen(fileName);
line = '     ';
while line(3:4) ~= 'KV'
    line = fgetl(fileID);
end
kv = str2double(line(8 : end));
fclose(fileID);

% Skip initial info lines
fileID = fopen(fileName);
dataStartLine = 0;
line = '#';
while line(1) == '#'
    line = fgetl(fileID);
    dataStartLine = dataStartLine + 1;
end
fclose(fileID);

% Load Numerical Data
dataStartLine = dataStartLine + 2; %data starts 2 lines after last '#'
data = csvread(fileName, dataStartLine - 1, 1 - 1); %row & line start at 0

throttlePosition = data(:, 1); % reading from throttle [ms]
powerDraw = data(:, 2); %[W]
voltage = data(:, 3); %[V]
current = powerDraw ./ voltage; %[A] current reading doesn't work
speed = data(:, 7); %[rpm]
time = sampleFreq * [0 : length(throttlePosition)];

