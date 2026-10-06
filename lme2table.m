function T = lme2table(lme, dfMethod)
%LME2TABLE transforms the results structure of the fixed effects coefficients from fitlme into a table which
%could then be saved into an xls file using writetable
% Tamar Regev Dec 19 2020 

% Oct 2026: optional dfMethod argument.
%   lme2table(lme)                   -> residual DF (MATLAB default; same as the original version)
%   lme2table(lme,'satterthwaite')   -> Satterthwaite DF, p-values and confidence intervals
if nargin < 2
    dfMethod = 'residual';
end
[~, ~, C] = fixedEffects(lme, 'DFMethod', dfMethod);   % same columns as lme.Coefficients

Name = C.Name;
Estimate = C.Estimate;
SE = C.SE;
tStat = C.tStat;
DF = C.DF;
pValue = C.pValue;
Lower = C.Lower;
Upper = C.Upper;

T = [table(Name),table(Estimate),table(SE),table(tStat), table(DF), table(pValue), table(Lower), table(Upper)];%,tStat,DF,pValue,Lower,Upper];



end

