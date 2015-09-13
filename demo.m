clear
clc

% Analysis parameters
load('neuroport1min.mat','data')
Zhigh = 6;
Zlow = 4;
nChanForBadT = 10;
dtForBadT = 1000;
dtReject = 1000;
nBadtoRejectC = 2;
GUIplot = 'rejects';

% Neuroport layout
arrayLayout =[     NaN,  2,  1,  3,  4,  6,  8, 10, 14,NaN;
                    65, 66, 33, 34,  7,  9, 11, 12, 16, 18;
                    67, 68, 35, 36,  5, 17, 13, 23, 20, 22;
                    69, 70, 37, 38, 48, 15, 19, 25, 27, 24;
                    71, 72, 39, 40, 42, 50, 54, 21, 29, 26;
                    73, 74, 41, 43, 44, 46, 52, 62, 31, 28;
                    75, 76, 45, 47, 51, 56, 58, 60, 64, 30;
                    77, 78, 82, 49, 53, 55, 57, 59, 61, 32;
                    79, 80, 84, 86, 87, 89, 91, 94, 63, 95;
                   NaN, 81, 83, 85, 88, 90, 92, 93, 96,NaN];

% Calculate bad electrodes and times
[badT, badTbyC, badC] = cleanUtahLFP( ...
    data, Zhigh, Zlow, nChanForBadT, dtForBadT, dtReject, ...
    nBadtoRejectC, GUIplot, arrayLayout);
