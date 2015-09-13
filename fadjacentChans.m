function A = fadjacentChans(XY, M, D)
%FINDADJACENT    Find the elements of a matrix that are adjacent to a
%specified index. This function does not include elements that are NaN
%
% INPUTS
% XY = indices of the matrix that you want to find the elements around
% M = matrix that you want to find the elements in
% D = the maximum distance in the two dimensions of the matrix
%
% OUTPUTS
% A = Elements of M that are adjacent to XY
%
% ASSUMPTIONS
% none of the values of interest are equal to 123456789
%
% This function was developed to find the electrodes that are adjacent to a
% specific electrode. e.g. The neuroport array shown here
% neuroport_layout =[NaN,  2,  1,  3,  4,  6,  8, 10, 14,NaN;
%                     65, 66, 33, 34,  7,  9, 11, 12, 16, 18;
%                     67, 68, 35, 36,  5, 17, 13, 23, 20, 22;
%                     69, 70, 37, 38, 48, 15, 19, 25, 27, 24;
%                     71, 72, 39, 40, 42, 50, 54, 21, 29, 26;
%                     73, 74, 41, 43, 44, 46, 52, 62, 31, 28;
%                     75, 76, 45, 47, 51, 56, 58, 60, 64, 30;
%                     77, 78, 82, 49, 53, 55, 57, 59, 61, 32;
%                     79, 80, 84, 86, 87, 89, 91, 94, 63, 95;
%                    NaN, 81, 83, 85, 88, 90, 92, 93, 96,NaN];
% >> findadjacent([1,1], neuroport_layout)
%    [2, 65, 66]


% define boundaries of the matrix
up = max(XY(1)-D(1), 1);
down = min(XY(1)+D(1), size(M,1));
left = max(XY(2)-D(2), 1);
right = min(XY(2)+D(2), size(M,2));

% mark the element of interest
M(XY(1),XY(2)) = 123456789;

% Find adjacent values
A = M(up:down,left:right);

% Remove the original index and any NaNs
A = A(:);
A(A==123456789) = [];
A(isnan(A))=[];