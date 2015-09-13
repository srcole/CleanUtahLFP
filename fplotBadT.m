function t_plot = fplotBadT(zscoresN,zscoresT,N)
%Returns the time points that should be plotted, based on the highest
%zscores
%
% INPUTS
% zscoresN - array of the number of time periods that the channel went
% above a zscore from z=5 to z=100.
% zscoresT - beginning time points for the time periods in zscoresN
% N - number of plots you want
%
% OUTPUTS
% t_plot = times to plot



% Algorithm:
% 1. Gather the timepoints for the first z-score bin with less than or
% equal to N time points
% 2. Gather the rest of the timepoints from the preceding z-score bin
% Choose the timepoints that are furthest away from those already gathered

% 1. Gather the timepoints for the first z-score bin with less than or
% equal to N time points
Zbin = find(zscoresN<=N,1,'first');
t_plot = zscoresT{Zbin};
N_cur = length(t_plot);
N_toplot = N - N_cur;

if N_cur == 0 && Zbin > 1
    t_plot = zscoresT{Zbin-1}(randperm(length(zscoresT{Zbin-1}),N));
elseif N_cur ~= N && Zbin > 1
    % 2. Gather the rest of the timepoints from the preceding z-score bin
    % Choose the timepoints that are furthest away from those already gathered
    t_maybeplot = zscoresT{Zbin-1};
    smallest_dist = zeros(1,length(t_maybeplot));
    for tm = 1:length(t_maybeplot)
        smallest_dist(tm) = min(abs(t_plot-t_maybeplot(tm)));
    end
    [~,dist_yes_idx] = sort(smallest_dist,2,'descend');
    t_plot = [t_plot,t_maybeplot(dist_yes_idx(1:N_toplot))];
end
