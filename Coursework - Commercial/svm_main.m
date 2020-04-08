clear();
clc();
load('source.mat');

[trn_y] = to_str_labels(trn_y);
[val_y] = to_str_labels(val_y);
[tst_y] = to_str_labels(tst_y);

% KernelFunction: 'gaussian', 'rbf', 'linear','polynomial'
% Alpha coefficient: 'Alpha'
% Nu: 0 to 1 balancing between most training examples in the positive class
% and minimise the weights int he score function
% BoxConstraint
% KernelScale
% PolynomialOrder
% 

% Train model
SVMModel = fitcsvm(trn_x, trn_y,'KernelFunction','linear',...
    'Standardize',true,'ClassNames',{'-1','+1'});

% Predict using validation set
[pred_y, pred_y_score] = predict(SVMModel, val_x);

% Update labels from "-1" to 0 and "1" to 1
pred_y = to_num_labels(pred_y);
val_y = to_num_labels(val_y);

[~, val_metric] = calc_metrics(pred_y_score, pred_y, val_y, 1, 0, NaN);

% Plot ROC
plt_title = "ROC: SVM";
i = 1;
plot_ROC([], val_metric, [], i, plt_title);


fprintf('---------- END ----------\n');

% Replace label to string '+1' or '-1'
function [new_y] = to_str_labels(y)
    new_y = [];
    for i=1:size(y,1)
        if y(i) == 1
            new_y = [new_y; "+1"];
        elseif y(i) == -1
            new_y = [new_y; "-1"];
        else
            new_y = [new_y; NaN];
        end
    end
end

% Convert from string labels '+1' or '-1' to numbers
function [new_y] = to_num_labels(y)
    new_y = [];
    for i=1:size(y,1)
        new_label = str2num(string(y(i)));
        if new_label == -1
            new_label = 0;
        end
        new_y = [new_y; new_label];
    end
end
