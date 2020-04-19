% Calculate metrics based on predictions (classification) vs actuals
function [samples_tbl, performance_tbl] = calc_metrics(pred_y_raw, pred_y, actual_y, label_pos, label_neg, epoch)
    % Compile table of actual vs predicted
    samples_tbl = pred_y;
    
    % Initialise table variables
    samples_tbl(:,2) = zeros(size(samples_tbl, 1), 1);
    samples_tbl(:,3) = actual_y;
    samples_tbl(:,4) = zeros(size(samples_tbl, 1), 1);
    
    % Set to table
    samples_tbl = array2table(samples_tbl);
    samples_tbl.Properties.VariableNames = {'Pred_Raw', 'Pred_Class', 'Actual_Class', 'is_Match'};
    
    % Create a table variable to hold prediction type
    samples_tbl.Match_Class = strings([size(samples_tbl, 1), 1]);
    
    % Counter for actual positive and negative
    P_cnt = 0; N_cnt = 0;
    
    % Counter for TP, FP, TN, FP
    TP_cnt = 0; FP_cnt = 0; TN_cnt = 0; FN_cnt = 0;
    
    % For each sample
    for i = 1:size(samples_tbl, 1)
        % Count positive and negative of actual
        if samples_tbl.Actual_Class(i) == label_pos
            P_cnt = P_cnt + 1;
        elseif samples_tbl.Actual_Class(i) == label_neg
            N_cnt = N_cnt + 1;
        end
        
        % Collate prediction class based on model output values vs labels
        if samples_tbl.Pred_Raw(i) == label_neg %samples_tbl(i, 1) < 0
            samples_tbl.Pred_Class(i) = label_neg;
        elseif samples_tbl.Pred_Raw(i) == label_pos
            samples_tbl.Pred_Class(i) = label_pos;
        else
            samples_tbl.Pred_Class(i) = NaN;
        end
        
        % Determine variance between predicted vs actual class values
        if samples_tbl.Pred_Class(i) == samples_tbl.Actual_Class(i)
            samples_tbl.is_Match(i) = 1;
        else
            samples_tbl.is_Match(i) = 0;
        end
        
        % Determine:
        % 1: True Positive (TP)
        % 2: True Negative (TN)
        % 3: False Negative (FN)
        % 4: False Positive (FP)
        % True positive - Actual = 1 and Pred = 1
        if samples_tbl.Pred_Class(i) == label_pos && samples_tbl.Actual_Class(i) == label_pos
            samples_tbl.Match_Class(i) = 'TP';
            TP_cnt = TP_cnt + 1;
        % True Negative - Actual = 0 and Pred = 0
        elseif samples_tbl.Pred_Class(i) == label_neg && samples_tbl.Actual_Class(i) == label_neg
            samples_tbl.Match_Class(i) = 'TN';
            TN_cnt = TN_cnt + 1;
        % False negative - Actual = 1 and Pred = 0
        elseif samples_tbl.Pred_Class(i) == label_neg && samples_tbl.Actual_Class(i) == label_pos
            samples_tbl.Match_Class(i) = 'FN';
            FN_cnt = FN_cnt + 1;
        % False positive - Actual = 0 and Pred = 1
        elseif samples_tbl.Pred_Class(i) == label_pos && samples_tbl.Actual_Class(i) == label_neg
            samples_tbl.Match_Class(i) = 'FP';
            FP_cnt = FP_cnt + 1;
        end
    end
        
    % Calculate sensitivity (TPR)
    tpr = TP_cnt/(TP_cnt + FN_cnt);
    
    % Calculate specificity (TNR)
    tnr = TN_cnt/(TN_cnt + FP_cnt);
    
    % Calculate positive prediction rate (PPV) (Precision)
    ppv = TP_cnt/(TP_cnt + FP_cnt);
    
    % Calculate negative prediction rate (NPV) (Specificity)
    npv = TN_cnt/(TN_cnt + FN_cnt);
    
    % Calculate miss rate (FNR) (False Negative Rate) (1 - Specificity)
    fnr = FN_cnt/(FN_cnt + TP_cnt);
    
    % Calculate fall-out rate (FPR) (False Discovery Rate)
    fpr = FP_cnt/(FP_cnt + TN_cnt);
    
    % Calculate Accuracy
    acc = (TP_cnt + TN_cnt)/(P_cnt + N_cnt);
    
    % Calculate ROC:
    % Get probability output for the respective label for each sample
    cout_pr = max(pred_y_raw, [], 2);
    
    % Calculate ROC and AUC
%     [ROC_x, ROC_y, ~, AUC] = perfcurve(actual_y, cout_pr, label_pos);
    [ROC_y, ROC_x, Thresholds] = calc_ROC(actual_y, pred_y_raw(:,2), 1, 0);

    % Compile into a table
    performance_tbl = array2table([epoch tpr tnr ppv npv fnr fpr acc ...
        TP_cnt, FP_cnt, TN_cnt, FN_cnt]);
    performance_tbl.Properties.VariableNames = {'Epoch', 'TPR', 'TNR', 'PPV', 'NPV', 'FNR', 'FPR', 'ACC', ...
        'TP', 'FP', 'TN', 'FN'};
    performance_tbl.Actual = {actual_y};
    performance_tbl.PRED = {pred_y};
    performance_tbl.PRED_PR = {cout_pr};
    performance_tbl.ROC_x = {ROC_x};
    performance_tbl.ROC_y = {ROC_y};
%     performance_tbl.AUC = AUC;
    
end