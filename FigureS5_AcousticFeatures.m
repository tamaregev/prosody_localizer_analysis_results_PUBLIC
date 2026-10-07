%% FigureS5_AcousticFeatures.m
%
% Plots acoustic features (pitch & intensity) extracted from prosody
% localizer stimuli, broken down by condition.
%
% Data source: A01_praat_features_all_20260925_praat-conservative_interp-
%              pchip_smooth-sgolay21_offset-25dbthresh.csv  (Praat-based extraction)
% Conditions:  SP+, SP-, NP+, NP-, InvP+, InvP-
%
% Style is harmonised with the other figures in the paper:
%   - Box plots per condition (median, IQR, whiskers)
%   - Scatter dots = individual stimuli overlaid (jittered, semi-transparent)
%   - Colors / fonts match Figure1_prosody.m and helpers
%
% Output: Figures/FigureS5_AcousticFeatures.pdf  (and .png)
%
% Usage:
%   1. Set project_dir to the root of your local copy of the repository.
%   2. Run the script.

clear; clc;

%% Definitions
project_dir  = '/Users/tamaregev/Dropbox/postdoc/Fedorenko/Prosody/Localizer/PUBLIC'; % replace with your path
results_dir  = [project_dir filesep 'Results'];
figures_dir  = [project_dir filesep 'Figures'];
analysis_dir = [project_dir filesep 'Analysis-Results_PUBLIC'];

csv_file = fullfile(results_dir, 'acoustic_features', ...
    'A01_praat_features_all_20260925_praat-conservative_interp-pchip_smooth-sgolay21_offset-25dbthresh.csv');

if ~exist(figures_dir, 'dir'), mkdir(figures_dir); end

%% ── Load data ───────────────────────────────────────────────────────────────
T = readtable(csv_file);

%% ── Conditions & colours ────────────────────────────────────────────────────
% Colour palette matches Figure1_prosody.m:
%   SP+/SP- = red shades, NP+/NP- = blue shades, InvP+/InvP- = grey shades

conditions      = {'SP+',  'SP-',      'NP+',       'NP-',       'InvP+',       'InvP-'};
condition_labels = {'SP+', 'SP-',      'NP+',       'NP-',       'InvP+',       'InvP-'};
colors          = {[1 0 0],[1 0.5 0.5],[0 0 1],     [0.5 0.5 1], [0.5 0.5 0.5], [0.8 0.8 0.8]};
nConds          = numel(conditions);

%% ── Acoustic features to plot ───────────────────────────────────────────────
% Two-column cell: {CSV column name, y-axis label}
% Note: intensity d/dt mean is omitted — it reduces to (I_last - I_first)/duration
% and so reflects stimulus edge trimming/padding rather than prosody.
features = {
    'pitch_mean',                          'Pitch mean (Hz)';
    'pitch_p05',                           'Pitch p5 (Hz)';
    'pitch_p95',                           'Pitch p95 (Hz)';
    'pitch_range',                         'Pitch range (Hz)';
    'pitch_variance',                      'Pitch variance (Hz^2)';
    'pitch_first_derivative_mean',         'Pitch d/dt mean';
    'pitch_first_derivative_variance',     'Pitch d/dt variance';
    'pitch_first_derivative_abs_mean',     'Pitch |d/dt| mean';
    'intensity_mean',                      'Intensity mean (dB)';
    'intensity_p05',                       'Intensity p5 (dB)';
    'intensity_p95',                       'Intensity p95 (dB)';
    'intensity_range',                     'Intensity range (dB)';
    'intensity_variance',                  'Intensity variance';
    'intensity_first_derivative_variance', 'Intensity d/dt variance';
    'intensity_first_derivative_abs_mean', 'Intensity |d/dt| mean';
};
nFeatures = size(features, 1);

%% ── Scatter parameters ──────────────────────────────────────────────────────
circleSize  = 10;    % marker size (points^2)
alphaLevel  = 0.30;  % transparency (0 = invisible, 1 = opaque)
spreadScale = 6;     % higher → less horizontal jitter

%% ── Layout ──────────────────────────────────────────────────────────────────
nCols = 4;
nRows = ceil(nFeatures / nCols);   % = 4 (15 features: 8 pitch, 7 intensity)

% Position on secondary screen (to the right of a MacBook Pro 13").
% The secondary screen starts at x ≈ 1280. Adjust x/y if your setup differs.
% Width × height chosen to approximate a portrait paper proportion (5:7).
figure('Position', [1300 250 1200 1680]);

% Fixed grid for the plot areas (normalized figure units). MATLAB's default
% subplot layout shrinks each axes differently depending on its tick labels
% and the "x10^5" exponent, so panels end up misaligned; we pin them instead.
gridLeft   = 0.08;   % left edge of first column
gridRight  = 0.97;   % right edge of last column (legend fills the empty 16th slot)
gridTop    = 0.90;   % top edge of first row (room for sgtitle)
gridBottom = 0.04;   % bottom edge of last row (no x tick labels there now)
hGap       = 0.075;  % horizontal gap between panels (y label + tick labels)
vGap       = 0.06;   % vertical gap between panels (room for panel 1's x labels)
axW = (gridRight - gridLeft   - (nCols - 1) * hGap) / nCols;
axH = (gridTop   - gridBottom - (nRows - 1) * vGap) / nRows;
ax  = gobjects(1, nFeatures);

for fi = 1:nFeatures

    ax(fi) = subplot(nRows, nCols, fi);

    feat_col   = features{fi, 1};
    feat_label = features{fi, 2};

    % ── Collect data in condition order ─────────────────────────────────────
    y_all = [];
    g_all = {};
    stim_data = cell(1, nConds);

    for ci = 1:nConds
        idx           = strcmp(T.condition, conditions{ci});
        vals          = T.(feat_col)(idx);
        stim_data{ci} = vals;
        y_all         = [y_all; vals];                              %#ok<AGROW>
        g_all         = [g_all; repmat(conditions(ci), numel(vals), 1)];  %#ok<AGROW>
    end

    % ── Box plots ────────────────────────────────────────────────────────────
    % 'Symbol','' suppresses the default outlier markers (we draw dots below)
    boxplot(y_all, g_all, ...
            'Labels',     condition_labels, ...
            'GroupOrder', conditions, ...
            'Symbol',     '', ...
            'Widths',     0.55, ...
            'MedianStyle','line');

    % Colour each box using patch (boxes are returned in reverse order)
    box_handles = findobj(gca, 'Tag', 'Box');
    for ci = 1:nConds
        bh = box_handles(nConds + 1 - ci);
        patch(bh.XData, bh.YData, colors{ci}, ...
              'FaceAlpha', 0.75, 'EdgeColor', 'k', 'LineWidth', 1.5);
    end

    % Thicken all box lines (whiskers, caps) and make median black & bold
    set(findobj(gca, 'Type', 'line'), 'LineWidth', 1.5);
    % Hide the built-in median (we'll redraw it on top ourselves)
    set(findobj(gca, 'Tag', 'Median'), 'Visible', 'off');

    % ── Individual stimulus dots ─────────────────────────────────────────────
    hold on;
    for ci = 1:nConds
        yy        = stim_data{ci};
        xx        = ci + (rand(size(yy)) - 0.5) / spreadScale;
        dot_color = min(colors{ci} .* 0.7, [1 1 1]);
        scatter(xx, yy, circleSize, dot_color, 'filled', ...
                'MarkerFaceAlpha', alphaLevel, ...
                'MarkerEdgeAlpha', 0);
    end

    % ── Redraw medians in black on top of everything ─────────────────────────
    bw = 0.275;   % half-width of median bar (matches default box width ~0.55)
    for ci = 1:nConds
        med_val = median(stim_data{ci});
        line([ci - bw, ci + bw], [med_val, med_val], ...
             'Color', 'k', 'LineWidth', 2, 'LineStyle', '-');
    end

    % ── Zero reference line for derivative mean features ─────────────────────
    % Drawn only for d/dt mean (can be positive or negative); not variance or |d/dt|
    if contains(feat_col, 'first_derivative_mean') && ~contains(feat_col, 'abs')
        xl = xlim;
        line(xl, [0 0], 'Color', [0.4 0.4 0.4], 'LineStyle', '--', 'LineWidth', 1.2);
    end
    hold off;

    % ── Axes style ───────────────────────────────────────────────────────────
    set(gca, 'fontsize', 13);
    ylabel(feat_label, 'FontSize', 14);
    box off;

    % x tick labels only on the first panel (same condition order everywhere)
    if fi == 1
        xtickangle(45);
    else
        set(gca, 'XTickLabel', {});
    end

    % y ticks: keep all (round) tick marks, but label only the lowest and
    % highest, plus 0 on the pitch d/dt mean panel
    ylim(ylim);                         % freeze limits so ticks don't re-flow
    yt   = yticks;
    yticks(yt);                         % freeze tick positions
    expo = get(gca, 'YAxis').Exponent;  % e.g. 5 for the "x10^5" panels
    lbl  = repmat({''}, 1, numel(yt));
    for k = 1:numel(yt)
        isEnd  = (k == 1 || k == numel(yt));
        isZero = strcmp(feat_col, 'pitch_first_derivative_mean') && yt(k) == 0;
        if isEnd || isZero
            lbl{k} = num2str(yt(k) / 10^expo);
        end
    end
    yticklabels(lbl);
    % Custom labels switch off MATLAB's exponent, so redraw it above the axis
    if expo ~= 0
        text(0, 1.02, sprintf('\\times10^{%d}', expo), 'Units', 'normalized', ...
             'FontSize', 13, 'HorizontalAlignment', 'left', ...
             'VerticalAlignment', 'bottom');
    end

end

% ── Supertitle ────────────────────────────────────────────────────────────────
sgtitle('Acoustic features by condition', 'FontSize', 20, 'FontWeight', 'bold');

% ── Pin every panel to the fixed grid (done last so nothing re-flows it) ─────
slotPos = @(k) [gridLeft + (mod(k - 1, nCols)) * (axW + hGap), ...
                gridTop  - ceil(k / nCols) * axH - (ceil(k / nCols) - 1) * vGap, ...
                axW, axH];
for fi = 1:nFeatures
    try
        ax(fi).PositionConstraint = 'innerposition';   % R2020a+
    catch
        ax(fi).ActivePositionProperty = 'position';     % older releases
    end
    ax(fi).Position = slotPos(fi);
end

% ── Legend in the empty last slot (slot 16) ──────────────────────────────────
% Invisible axes holds dummy points so the legend doesn't touch any real panel
legPos = slotPos(nFeatures + 1);
axLeg  = axes('Position', legPos, 'Visible', 'off');
hold(axLeg, 'on');
legend_handles = gobjects(1, nConds);
for ci = 1:nConds
    legend_handles(ci) = scatter(axLeg, nan, nan, 80, colors{ci}, 'filled', ...
                                 'DisplayName', condition_labels{ci});
end
hold(axLeg, 'off');
hl = legend(axLeg, legend_handles, condition_labels, 'FontSize', 14);
hl.Box   = 'off';
hl.Units = 'normalized';
% Centre the legend inside the slot
hl.Position(1:2) = [legPos(1) + (legPos(3) - hl.Position(3)) / 2, ...
                    legPos(2) + (legPos(4) - hl.Position(4)) / 2];

% ── Save ──────────────────────────────────────────────────────────────────────
set(gcf, 'Renderer', 'painters');   % force vector output (avoids OpenGL rasterisation from alpha)
saveas(gcf, fullfile(figures_dir, 'FigureS5_AcousticFeatures'), 'pdf');
saveas(gcf, fullfile(figures_dir, 'FigureS5_AcousticFeatures'), 'png');
fprintf('Saved FigureS5_AcousticFeatures.pdf / .png to %s\n', figures_dir);
