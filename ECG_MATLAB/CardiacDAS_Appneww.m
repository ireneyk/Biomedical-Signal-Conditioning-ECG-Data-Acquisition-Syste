function Elite_ECG_Final_App
    % ELITE CARDIAC CONDITIONING SYSTEM
    % Features: Clinical Dark Mode, Neon Waveforms, Pan-Tompkins, Arrhythmia Alarms
    
    % --- UI Initialization (Dark Mode Theme) ---
    fig = uifigure('Name', 'Clinical Grade ECG Monitor', 'Position', [50, 50, 1100, 800], 'Color', [0.1 0.1 0.1]);
    g = uigridlayout(fig, [3, 2]);
    g.RowHeight = {'1x', '1x', '1x'};
    g.ColumnWidth = {'1.6x', '0.8x'};

    % Customizing Axes for Medical Aesthetics
    axRaw = setupAxis(uiaxes(g), 'STAGE 1: RAW ARTIFACT DATA', 1, 1);
    axFilt = setupAxis(uiaxes(g), 'STAGE 2: CONDITIONED ECG (NEON)', 2, 1);
    axAnalysis = setupAxis(uiaxes(g), 'STAGE 3: ENERGY ENVELOPE', 3, 1);
    axFreq = setupAxis(uiaxes(g), 'POWER SPECTRUM (dB)', 1, 2);

    % Dashboard Panel Styling
    pnl = uipanel(g, 'Title', 'SYSTEM DIAGNOSTICS', 'BackgroundColor', [0.15 0.15 0.15], 'ForegroundColor', 'white');
    pnl.Layout.Row = [2, 3]; pnl.Layout.Column = 2;
    
    appData = struct('t', [], 'raw', [], 'y_filt', [], 'y_int', [], 'fs', 1000);

    % Interaction Controls
    uibutton(pnl, 'push', 'Text', 'ACQUIRE SIGNAL', 'Position', [20, 380, 180, 40], ...
        'BackgroundColor', [0 0.8 0.4], 'FontColor', 'black', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,e) processSignal('sim'));
    
    uibutton(pnl, 'push', 'Text', 'LOAD CLINICAL FILE', 'Position', [20, 330, 180, 40], ...
        'BackgroundColor', [0.2 0.2 0.2], 'FontColor', 'white', ...
        'ButtonPushedFcn', @(btn,e) processSignal('load'));

    uilabel(pnl, 'Text', 'Sensitivity Threshold:', 'Position', [20, 275, 150, 20], 'FontColor', 'white');
    sldThresh = uislider(pnl, 'Position', [20, 265, 180, 3], 'Limits', [0.05 0.95], 'Value', 0.4, ...
        'FontColor', 'white', 'ValueChangedFcn', @(sld,e) updateAnalysis());
    
    lblHR = uilabel(pnl, 'Text', '-- BPM', 'Position', [20, 150, 200, 60], 'FontSize', 36, 'FontWeight', 'bold', 'FontColor', [0 1 0]);
    lblStatus = uilabel(pnl, 'Text', 'SYSTEM READY', 'Position', [20, 120, 200, 30], 'FontColor', [0.7 0.7 0.7], 'FontWeight', 'bold');
    lblSNR = uilabel(pnl, 'Text', 'SNR Gain: --', 'Position', [20, 90, 200, 30], 'FontColor', [0.5 0.8 1]);

    % --- Axis Styling Helper ---
    function ax = setupAxis(ax, titleStr, row, col)
        ax.Layout.Row = row; ax.Layout.Column = col;
        ax.Color = [0 0 0]; ax.XColor = [0.5 0.5 0.5]; ax.YColor = [0.5 0.5 0.5];
        ax.Title.String = titleStr; ax.Title.Color = [0.9 0.9 0.9];
        grid(ax, 'on'); ax.GridColor = [0.2 0.2 0.2];
    end

    % --- Core Logic ---
    function processSignal(mode)
        if strcmp(mode, 'sim')
            t = 0:1/appData.fs:10-1/appData.fs; % Increased to 10s for better view
            clean = zeros(size(t));
            for i = 0.5:0.85:9.5
                clean = clean + 1.2*exp(-((t-i)/0.012).^2); 
                clean = clean + 0.3*exp(-((t-(i+0.25))/0.04).^2); 
            end
            raw = clean + 0.5*sin(2*pi*50*t) + 0.3*sin(2*pi*0.15*t) + 0.08*randn(size(t));
        else
            [file, path] = uigetfile({'*.mat;*.csv'});
            if isequal(file,0), return; end
            data = readmatrix(fullfile(path, file));
            raw = data(:,1)'; 
            t = (0:length(raw)-1)/appData.fs;
        end

        % Filter Pipeline
        [bn, an] = designNotch(50/(appData.fs/2), 0.99);
        y_notched = filter(bn, an, raw);
        [blp, alp] = designButter(2, 45/(appData.fs/2), 'low');
        [bhp, ahp] = designButter(2, 0.5/(appData.fs/2), 'high');
        y_filt = filter(blp, alp, y_notched);
        y_filt = filter(bhp, ahp, y_filt);
        
        % Pan-Tompkins energy window
        dy = diff([y_filt(1), y_filt]); 
        y_sq = dy.^2;
        y_int = movmean(y_sq, 35); 

        appData.t = t; appData.raw = raw; appData.y_filt = y_filt; appData.y_int = y_int;
        updateAnalysis();
        
        % Spectral Analysis
        [pxx, f] = periodogram(raw, [], [], appData.fs);
        [pxxf, ff] = periodogram(y_filt, [], [], appData.fs);
        semilogy(axFreq, f, pxx, 'Color', [1 0.3 0.3]); hold(axFreq, 'on');
        semilogy(axFreq, ff, pxxf, 'Color', [0.3 0.6 1], 'LineWidth', 1.2); hold(axFreq, 'off');
        xlim(axFreq, [0 100]); legend(axFreq, {'Raw Noise', 'Filtered Output'}, 'TextColor', 'white', 'Color', 'none');
    end

    function updateAnalysis()
        if isempty(appData.y_int), return; end
        
        threshVal = sldThresh.Value * max(appData.y_int);
        [~, locs_idx] = findPeaksManual(appData.y_int, threshVal, 0.4*appData.fs);
        pks_val = appData.y_filt(locs_idx);
        locs_t = appData.t(locs_idx);

        % Update Visuals with Clinical Colors
        plot(axRaw, appData.t, appData.raw, 'Color', [0.4 0.4 0.4]);
        
        % Neon Green ECG Trace
        plot(axFilt, appData.t, appData.y_filt, 'Color', [0 1 0.5], 'LineWidth', 1.2); 
        hold(axFilt, 'on'); plot(axFilt, locs_t, pks_val, 'y+', 'MarkerSize', 10, 'LineWidth', 2); hold(axFilt, 'off');
        
        % Cyan Energy Envelope
        plot(axAnalysis, appData.t, appData.y_int, 'Color', [0 0.8 1]); 
        hold(axAnalysis, 'on'); yline(axAnalysis, threshVal, 'Color', [1 0.8 0], 'LineStyle', '--'); hold(axAnalysis, 'off');

        % Smart Metrics & Alarm Logic
        if length(locs_t) > 1
            bpm = 60 / mean(diff(locs_t));
            lblHR.Text = sprintf('%.0f BPM', bpm);
            
            % Alarm Logic
            if bpm > 100 || bpm < 50
                lblHR.FontColor = [1 0.2 0.2]; % Red Alarm
                lblStatus.Text = 'ALARM: IRREGULAR RATE'; lblStatus.FontColor = 'red';
            else
                lblHR.FontColor = [0 1 0.5]; % Healthy Green
                lblStatus.Text = 'NORMAL SINUS RHYTHM'; lblStatus.FontColor = [0 0.8 0.4];
            end
            
            snr_val = 10*log10(var(appData.y_filt)/var(appData.raw-appData.y_filt));
            lblSNR.Text = sprintf('SNR Improvement: %.2f dB', snr_val);
        end
    end

    % --- DSP HELPERS ---
    function [b, a] = designNotch(w0, r)
        b = [1, -2*cos(pi*w0), 1]; a = [1, -2*r*cos(pi*w0), r^2];
    end
    function [b, a] = designButter(order, fc, type)
        wa = tan(pi*fc/2);
        if strcmp(type, 'low')
            b = [wa/(1+wa), wa/(1+wa)]; a = [1, -(1-2*(wa/(1+wa)))];
        else
            b = [1/(1+wa), -1/(1+wa)]; a = [1, -(2*(1/(1+wa))-1)];
        end
    end
    function [pks, idx] = findPeaksManual(sig, thresh, minSep)
        pks = []; idx = [];
        for i = 2:length(sig)-1
            if sig(i) > thresh && sig(i) > sig(i-1) && sig(i) > sig(i+1)
                if isempty(idx) || (i - idx(end)) > minSep
                    pks = [pks, sig(i)]; idx = [idx, i];
                end
            end
        end
    end
end