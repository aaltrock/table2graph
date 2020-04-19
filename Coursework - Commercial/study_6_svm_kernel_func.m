%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STUDY: SVM - 
% kerenel function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear();
clc();
rng('default');

export_file_nm = "svm_kernel_tst_results.xlsx";

neurons = {5, 10, 15, 20, 25, 30, 35, 40, 45, 50, ...
    [10, 5], [10, 10], [20, 10], [20, 20], ...
    [30, 15], [30, 30], [40, 20], [40, 40], [50, 25], [50, 50]};

act_funcs_single_hidden = {'tansig', 'tansig'};
act_funcs_two_hidden = {'tansig', 'tansig', 'tansig'};

confs = {};
trn_results = {};
val_results = {};
tst_results = {};
results = {};

for i = 1:size(neurons, 2)
    conf = {};
    plt_title = "";

    % Set hidden layers architecture
    conf.hidNum = neurons{i};

    % Set activation:
    if size(conf.hidNum, 2) == 1
        % If single hidden layer
        conf.activationFnc = act_funcs_single_hidden;
    elseif size(conf.hidNum, 2) == 2
        % If two hidden layers
        conf.activationFnc = act_funcs_two_hidden;
    end

    % Run, train, validation, test
    [model, trn_metrics, val_metrics, tst_metrics] = mlp_main(conf);

    % Compile results
    models{i} = model;
    confs{i} = conf;
    confText = num2str(conf.hidNum) + "; " + strjoin(conf.activationFnc);
    trn_metrics.configuration = confText;
    val_metrics.configuration = confText;
    tst_metrics.configuration = confText;

    % Append result to the set
    trn_results = [trn_results; trn_metrics];
    val_results = [val_results; val_metrics];
    tst_results = [tst_results; tst_metrics];

    % Plot ROC
    plt_title = "ROC: SVM - kernel function: " + strinh(conf.hidNum);
    plot_ROC([], [], tst_metrics, i, plt_title(1));
end

% Write results to file (Configuration, Epoch to FN columns)
columnsToWrite = {'configuration', 'TPR', 'TNR', 'PPV', 'NPV', 'FNR', 'FPR', 'ACC', 'TP', 'FP', 'TN', 'FN'};
writetable(trn_results(:, columnsToWrite), export_file_nm, 'Sheet','trn_results','WriteVariableNames',false, 'Range', 'A1', 'WriteVariableNames', 1);
writetable(val_results(:, columnsToWrite), export_file_nm, 'Sheet','val_results','WriteVariableNames',false, 'Range', 'A1', 'WriteVariableNames', 1);
writetable(tst_results(:, columnsToWrite), export_file_nm, 'Sheet','tst_results','WriteVariableNames',false, 'Range', 'A1', 'WriteVariableNames', 1);

% Save data
save('study_6_svm_kernel_func.mat');