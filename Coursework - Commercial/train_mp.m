% Codes modified from: Neural Computing module Tutorial 4 train_nn function
% Original from Artur S. d'Avila Garcez, Department of Computer Science,
% City, University of London

% conf = neural network configurations (see compile_mp_conf.m)
% Ws = supplied weights
% bs = supplied biases
% trn_y = Trained classification labels
% trn_x = Training features
% vld_y = Validation classification labels
% vld_x = Validation features

function [model, e_best, trn_cout_raws, trn_couts, ...
    vld_cout_raws, vld_couts, best_trn_metrics, best_vld_metrics] ...
    = train_mp(conf, Ws, bs, trn_x, trn_y, vld_x, vld_y)

% INTERNAL VARIABLES:
% SZ = sample size
% VisNum = feature size
% depth = no. of layers (hiddena nd output)
% labNum = no. of output classes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine training samples and features sizes
[SZ,visNum] = size(trn_x);

% Calculate no. of layers (hidden + output)
depth = length(conf.hidNum)+1;

% Calculate output class size
labNum = size(unique(trn_y),1);

if isempty(Ws)
 % Random initialisation of Weights Ws if not provided
    model.Ws{1} = (1/visNum)*(2*rand(visNum,conf.hidNum(1))-1);
    DW{1} = zeros(size(model.Ws{1}));
    % Add another layer of weights for each layer after 1st hidden layer
    for i=2:depth-1
        model.Ws{i} = (1/conf.hidNum(i-1))*(2*rand(conf.hidNum(i-1),conf.hidNum(i))-1);
        DW{i} = zeros(size(model.Ws{i}));
    end
    model.Ws{depth} = (1/conf.hidNum(depth-1))*(2*rand(conf.hidNum(depth-1),labNum)-1);
    % Initialise DW
    DW{depth} = zeros(size(model.Ws{depth}));
else
    % Otherwise assigned given weights to the model
    model.Ws = Ws;
    % Initialise DW
    for i=1:depth, DW{i} = zeros(size(model.Ws{i})); size(model.Ws{i}); end
    clear Ws
end

if isempty(bs)
 % Initialize bs
    % For every layer
    for i=1:depth-1
        model.bs{i} = zeros(1,conf.hidNum(i));
        DB{i} = model.bs{i};
    end
    model.bs{depth} = zeros(1,labNum);
    DB{depth} = model.bs{depth};
else 
    model.bs  = bs;
end
bNum = conf.bNum;

% Set batch nr 1 if not defined (i.e. 0)
if conf.bNum == 0, bNum = round(SZ/conf.sNum); end

% Variables to hold plot data points
plot_trn_acc = [];
plot_vld_acc = [];
plot_mse = [];

vld_best = 0;
e_best = 0;
es_count = 0;
acc_drop_count = 0;
vld_acc  = 0;
tst_acc  = 0;
vld_perf = [];



% Initialise epoch count
e = 0;

% Set running flag as 1
running = 1;

% Set learning rate
lr = conf.params(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FITTING MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% While no early stopping or reach max epoch no.
while running
    
    % Reset MSE
    MSE = 0;
    
    % Increment epoch count
    e = e+1;
    
    % For each batch
   for b=1:bNum
       % Get indexes of observations for batch from training set
       inx = (b-1)*conf.sNum+1:min(b*conf.sNum,SZ);
       
       % Compile batch features and output classification
       batch_x = trn_x(inx,:);
       batch_y = trn_y(inx)+1;
       
       % Batch size
       sNum = size(batch_x,1);
       % Forward mesage to get output
       input{1} = bsxfun(@plus,batch_x*model.Ws{1},model.bs{1});
       % Hidden layer activation function
       actFunc = str2func(conf.activationFnc{1});
       output{1} = actFunc(input{1});
       % For each hidden layer, from first (i=2) to other hidden layers
       for i=2:depth
           
           % Calculate current hidden layer = output of previous layer * weight + bias
           input{i} = bsxfun(@plus,output{i-1}*model.Ws{i},model.bs{i});
           
           % Caluclate input values for next layer per layer activation function
           actFunc=  str2func(conf.activationFnc{i});
           output{i} = actFunc(input{i});
       end
       %output{depth} = output{depth}
       
       % BACKPROPAGATION UPDATE
       
       y = discrete2softmax(batch_y,labNum);
       %disp([y output{depth}]);
       
       % Calculate instaneous energy of neurons
       err{depth} = (y-output{depth}).*deriv(conf.activationFnc{depth},input{depth});
       
       % Determine predicted classification per the max of each label
       % output values
       [~,cout] = max(output{depth},[],2);                                                                                                  
       %sum(sum(batch_y+1==cout))
       
       % Calculate and aggregate MSE
       MSE = MSE + mean(sqrt(mean((output{depth}-y).^2)));
       
       % For every layer backward decrementally
       for i=depth:-1:2
           
           % Error total
           diff = output{i-1}'*err{i}/sNum;
           % Weights adjustment as partial derivative of total error
           DW{i} = lr*(diff - conf.params(4)*model.Ws{i}) + conf.params(3)*DW{i};
           model.Ws{i} = model.Ws{i} + DW{i};
           
           % Bias adjustment
           DB{i} = lr*mean(err{i}) + conf.params(3)*DB{i};
           model.bs{i} = model.bs{i} + DB{i};
           
           % Refresh error to the output of the preceding layer
           err{i-1} = err{i}*model.Ws{i}'.*deriv(conf.activationFnc{i},input{i-1});
       end
       
       diff = batch_x'*err{1}/sNum;        
       DW{1} = lr*(diff - conf.params(4)*model.Ws{1}) + conf.params(3)*DW{1};
       model.Ws{1} = model.Ws{1} + DW{1};       
       
       DB{1} = lr*mean(err{1}) + conf.params(3)*DB{1};
       model.bs{1} = model.bs{1} + DB{1};       
   end
   
   % Capture models after fitting in epoch
   models{e} = model;
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALUATE PERFORMANCE AFTER FITTING WITH TRAINING SET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Get training classification error
   [trn_cout_raw, trn_cout] = run_nn(conf.activationFnc,model,trn_x); 
   trn_acc = sum((trn_cout-1)==trn_y)/size(trn_y,1);
   
   % Change back to lable value from 2 to 1, from 1 to 0
   trn_cout = trn_cout - 1;
   
   trn_cout_raws{e} = trn_cout_raw;
   trn_couts{e} = trn_cout;
   
%    % Calculate metrics
%    [~, trn_metric] = calc_metrics(trn_cout_raw, trn_cout, trn_y, 1, 0, e);
%    trn_metrics{e} = [trn_metric];
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALUATE PERFORMANCE WITH VALIDATION SET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Run again with validation set
   [vld_cout_raw, vld_cout] = run_nn(conf.activationFnc,model,vld_x);
   % Change back to lable value from 2 to 1, from 1 to 0
   vld_cout = vld_cout - 1;
   vld_acc = sum(vld_cout==vld_y)/size(vld_y,1);
   fprintf('[Epoch %4d] MSE = %.5f | Train acc = %.5f | Validation acc = %.5f\n',e,MSE,trn_acc,vld_acc);
   
   vld_cout_raws{e} = vld_cout_raw;
   vld_couts{e} = vld_cout;
   
%    % Calculate metrics
%     [~, vld_metric] = calc_metrics(vld_cout_raw, vld_cout, vld_y, 1, 0, e);
%     vld_metrics{e} = [vld_metric];
    
   % Collect data for plot
   plot_trn_acc = [plot_trn_acc trn_acc];
   plot_vld_acc = [plot_vld_acc vld_acc];
   plot_mse     = [plot_mse MSE];
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EARLY STOPPING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % If early stop is set
   if conf.early_stopping_option ~= "NO_EARLY_STOP"
       % Option VAL_ACC_REDUCE_MULTI: Terminate after repeated deteriation of validation accuracy
        if conf.early_stopping_option == "VAL_ACC_REDUCE_MULTI_STOP"
            % If current epoch validation performance is not the best
            if vld_acc<=vld_best
                % Increment counter for dropping validation performance
                acc_drop_count = acc_drop_count + 1;
                % If accuracy reduces for a number of time defined, end
                if acc_drop_count > conf.E_STOP_REPEAT
                    % set model from past best performing model
                    model = model_best;
                    % Stop running
                    running = 0;
                end
            % Else performance is best yet over the validation data set
            else
                % Set current validation accuracy performance as best
                vld_best = vld_acc;
                % Set current model as best performing model
                model_best = model;
                % Capture epoch number where best model so far identified
                e_best = e;
            end
        end
        
        % Option REDUCE_LR: Reduce Learning Rate after repeated deteriation of validation accuracy
        if conf.early_stopping_option == "VAL_ACC_REDUCE_LOWER_LR"
            % If current epoch validation performance is not the best
            if vld_acc<=vld_best
                % Increment counter for dropping validation performance
                acc_drop_count = acc_drop_count + 1;
                % If accuracy reduces for a number of time, then turn back to the
                % best model and reduce the learning rate
                if acc_drop_count > conf.E_STOP_REPEAT
                    acc_drop_count = 0;
                    es_count = es_count + 1; %number of reduce learning rate
                    lr = lr * conf.LR_REDUCE_FACTOR;
                    model = model_best;
                    fprintf('Learning rate reduced to %.7f!\n', lr);
                end
            % Else performance is best yet over the validation data set
            else
                % Reset counter of degrading validation set perfroamcne
                es_count = 0;
                acc_drop_count = 0;
                % Set current validation accuracy performance as best
                vld_best = vld_acc;
                % Set current model as best performing model
                model_best = model;
                % Capture epoch number where best model so far identified
                e_best = e;
            end
        end
        
        % Option DESIRE_VAL_ACC: Terminate when desired validation accuracy reach
        if conf.early_stopping_option == "DESIRE_VAL_ACC"
            % If the current validation accuracy is better
            if vld_acc > vld_best
                % Replace best validation accuracy
                vld_best = vld_acc;
                % Capture epoch number
                e_best = e;
            end
            % Terminate upon reaching the desired accuracy
            if vld_acc >= conf.E_STOP_VAL_DESIRE_ACC
                % Best model is set to current model
                model_best = model;
                % Stop running
                running=0;
            end
        end
        
        % No early stop - run through all epochs
        else
            % If validation accuracy is better than previous epoch
            if vld_acc>vld_best
                % Best model is set to current model
                model_best = model;
                % Capture epoch number where best model so far identified
                e_best = e;
                % Capture best validation accuracy
                vld_best = vld_acc;
            end
        
    end % ~NO_EARLY_STOP
    
    % Check stop
    if e>=conf.eNum, running=0; end
    
end %while running

    % PRINT BEST EPOCH, VALIDATION ACCURACY
    fprintf('[Best performing Epoch %d] Validation acc = %.10f\n', e_best, vld_best);
    
    % Return the best performing model
    model = models{e_best};
    
    % Calculate Training best metrics per best accuracy epoch
    [~, best_trn_metric] = calc_metrics(trn_cout_raws{e_best}, trn_couts{e_best}, trn_y, 1, 0, e_best);
    best_trn_metrics = best_trn_metric;

    % Calculate Validation metrics per best accuracy epoch
    [~, best_vld_metric] = calc_metrics(vld_cout_raw, vld_cout, vld_y, 1, 0, e_best);
    best_vld_metrics = best_vld_metric;
    
    % ROC based on best performing model
%     [X, Y, T, AUC] = perfcurve(vld_y, cout, 1);

%     % OVERALL PERFORMANCE EVALUATION
%     fig1 = figure(1);
%     set(fig1,'Position',[10,20,300,200]);
%     plot(1:size(plot_trn_acc,2),plot_trn_acc,'r');
%     hold on;
%     plot(1:size(plot_vld_acc,2),plot_vld_acc);    
%     legend('Training','Validation');
%     xlabel('Epochs');ylabel('Accuracy');
%     
%     fig2 = figure(2);
%     set(fig2,'Position',[10,20,300,200]);
%     plot(1:size(plot_mse,2),plot_mse);    
%     xlabel('Epochs');ylabel('MSE');
end