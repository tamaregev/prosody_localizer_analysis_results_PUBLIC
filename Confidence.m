function [CIerr, CI, SEM] = Confidence(x)
%CONFIDENCE plots 95% confidence intervals based on the t distribution
% if x is an array, rows is treated as participants and columns as effects
%CIerr is the size of error bar (half the range)
% CI are lower and upper values, can only be calculated for a single condition
%   as in - https://www.mathworks.com/matlabcentral/answers/159417-how-to-calculate-the-confidence-interval
%   
N=size(x,1);
SEM = std(x)/sqrt(N);               % Standard Error
ts = tinv([0.025  0.975],N-1);      % T-Score
if ndims(x)==1
    CI = mean(x) + ts*SEM;                      % Confidence Intervals
else
    CI=nan;
end
CIerr = ts(2)*SEM;
end

