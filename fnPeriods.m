function [A,T,L] = fnPeriods(X,dt)
%FINDADJACENT    Finds the number of discontinuous periods in a list of
%time points
%
% INPUTS
% X = 1-D array. List of time points
% dt = minimum separation between 2 times to be different periods
%
% OUTPUTS
% A = Number of discontinuous time periods in the array X
% T = 1-D array. Starting index of a timepoint
% L = 1-D array. Length of time period that starts at T
%
% ASSUMPTIONS
% none of the values of interest are equal to 123456789
%
% >> findadjacent([1,2,3,4,8,9,55,56,57])
%    3

A = 0;
T = [];
L = [];

if ~isempty(X)
    A = 1;
    T = X(1);
    Tlen = length(X);
    cur_period = 1;
    for t=2:Tlen
        if (X(t) - dt) > T(cur_period)
            cur_period = cur_period + 1;
            A = A + 1;
            T(cur_period) = X(t);
            L(cur_period-1) = X(t-1) - T(cur_period-1);
        end
    end

    % Calculate length of last time period
    if cur_period > 1
        L(cur_period) = X(Tlen) - T(cur_period);
    else
        L = length(X);
    end
end