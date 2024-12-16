%% GP_AsynAggregation_DataSet_Preprocessing
clc; clear; close all;
%%
DataSetNameSet = {'SARCOS'; 'KIN40K'; 'POL'; 'PUMADYN32NM'};
%% SARCOS
clear;
% Hyperparameters
HyperparameterStruct = load('Dataset\Gaussian Process\SARCOS\SARCOS_GP_Hyperparameter.mat', ...
	'SigmaF_set','SigmaL_set','SigmaN_set');
y_dim = numel(HyperparameterStruct.SigmaN_set);
x_dim = numel(HyperparameterStruct.SigmaL_set{1});
HyperparameterSet = cell(y_dim,1);
for y_dim_Nr = 1:y_dim
	HyperparameterSet{y_dim_Nr}.SigmaN = HyperparameterStruct.SigmaN_set{y_dim_Nr};
	HyperparameterSet{y_dim_Nr}.SigmaL = HyperparameterStruct.SigmaL_set{y_dim_Nr};
	HyperparameterSet{y_dim_Nr}.SigmaF = HyperparameterStruct.SigmaF_set{y_dim_Nr};
end
% Data Set
TrainDataSetSturct = load('Dataset\Gaussian Process\SARCOS\Sarcos_train.mat', ...
	'sarcos_inv');
TrainDataSet.X = TrainDataSetSturct.sarcos_inv(:,1:21)';
TrainDataSet.Y = TrainDataSetSturct.sarcos_inv(:,22:end)';
save('Specified Model\GP Asynchronous Aggregation\DataSet_SARCOS.mat', ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
%% KIN40K
clear;
% Hyperparameters
HyperparameterStruct = load('Dataset\Gaussian Process\KIN40K\KIN40K_Hyperparameter.mat', ...
	'SigmaF','SigmaL','SigmaN');
y_dim = numel(HyperparameterStruct.SigmaN);
x_dim = numel(HyperparameterStruct.SigmaL);
HyperparameterSet = cell(y_dim,1);
HyperparameterSet{1}.SigmaN = HyperparameterStruct.SigmaN;
HyperparameterSet{1}.SigmaL = HyperparameterStruct.SigmaL;
HyperparameterSet{1}.SigmaF = HyperparameterStruct.SigmaF;
% Data Set
TrainDataSetSturct = load('Dataset\Gaussian Process\KIN40K\KIN40K_train.mat', ...
	'x','y');
TrainDataSet.X = TrainDataSetSturct.x';
TrainDataSet.Y = TrainDataSetSturct.y';
save('Specified Model\GP Asynchronous Aggregation\DataSet_KIN40K.mat', ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
%% POL
clear;
% Hyperparameters
HyperparameterStruct = load('Dataset\Gaussian Process\POL\POL_Hyperparameter.mat', ...
	'SigmaF','SigmaL','SigmaN');
y_dim = numel(HyperparameterStruct.SigmaN);
x_dim = numel(HyperparameterStruct.SigmaL);
HyperparameterSet = cell(y_dim,1);
HyperparameterSet{1}.SigmaN = HyperparameterStruct.SigmaN;
HyperparameterSet{1}.SigmaL = HyperparameterStruct.SigmaL;
HyperparameterSet{1}.SigmaF = HyperparameterStruct.SigmaF;
% Data Set
TrainDataSetSturct = load('Dataset\Gaussian Process\POL\POL_train.mat', ...
	'x','y');
TrainDataSet.X = TrainDataSetSturct.x';
TrainDataSet.Y = TrainDataSetSturct.y';
save('Specified Model\GP Asynchronous Aggregation\DataSet_POL.mat', ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
%% PUMADYN32NM
clear;
% Hyperparameters
HyperparameterStruct = load('Dataset\Gaussian Process\PUMADYN32NM\PUMADYN32NM_Hyperparameter.mat', ...
	'SigmaF','SigmaL','SigmaN');
y_dim = numel(HyperparameterStruct.SigmaN);
x_dim = numel(HyperparameterStruct.SigmaL);
HyperparameterSet = cell(y_dim,1);
HyperparameterSet{1}.SigmaN = HyperparameterStruct.SigmaN;
HyperparameterSet{1}.SigmaL = HyperparameterStruct.SigmaL;
HyperparameterSet{1}.SigmaF = HyperparameterStruct.SigmaF;
% Data Set
TrainDataSetSturct = load('Dataset\Gaussian Process\PUMADYN32NM\PUMADYN32NM_train.mat', ...
	'x','y');
TrainDataSet.X = TrainDataSetSturct.x';
TrainDataSet.Y = TrainDataSetSturct.y';
save('Specified Model\GP Asynchronous Aggregation\DataSet_PUMADYN32NM.mat', ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
%% Control
clear;
rng(0);
x_dim = 2;
y_dim = 1;
X1_range = [-3;3];
X2_range = [-3;3];
X1_mean = mean(X1_range);
X2_mean = mean(X2_range);
X1_radius = (max(X1_range) - min(X1_range)) / 2;
X2_radius = (max(X2_range) - min(X2_range)) / 2;
TrainDataQuantity = 1000;
X_train = diag([X1_radius;X2_radius]) * 2 * (rand(2,TrainDataQuantity) - 0.5) + ...
	repmat([X1_mean;X2_mean],1,TrainDataQuantity);
Y_train = GP_AsynAggregation_Control_UnknownFunction(X_train);
gp = fitrgp(X_train',Y_train', ...
	'KernelFunction','ardsquaredexponential','Standardize',false);
HyperparameterSet = cell(y_dim,1);
HyperparameterSet{1}.SigmaL = gp.KernelInformation.KernelParameters(1:end-1);
HyperparameterSet{1}.SigmaF = gp.KernelInformation.KernelParameters(end);
HyperparameterSet{1}.SigmaN = gp.Sigma;
save('Specified Model\GP Asynchronous Aggregation\DataSet_Control.mat', ...
	'HyperparameterSet','x_dim','y_dim');
%% BenchmarkTest
clear;
% Hyperparameters
HyperparameterStruct = load('Dataset\Gaussian Process\PUMADYN32NM\PUMADYN32NM_Hyperparameter.mat', ...
	'SigmaF','SigmaL','SigmaN');
y_dim = numel(HyperparameterStruct.SigmaN);
x_dim = numel(HyperparameterStruct.SigmaL);
HyperparameterSet = cell(y_dim,1);
HyperparameterSet{1}.SigmaN = HyperparameterStruct.SigmaN;
HyperparameterSet{1}.SigmaL = HyperparameterStruct.SigmaL;
HyperparameterSet{1}.SigmaF = HyperparameterStruct.SigmaF;
% Data Set
TrainDataSetSturct = load('Dataset\Gaussian Process\PUMADYN32NM\PUMADYN32NM_train.mat', ...
	'x','y');
TrainDataSet.X = TrainDataSetSturct.x';
TrainDataSet.Y = TrainDataSetSturct.y';
TrainDataSet.X = TrainDataSet.X(:,1:2000);
TrainDataSet.Y = TrainDataSet.Y(:,1:2000);
save('Specified Model\GP Asynchronous Aggregation\DataSet_BenchmarkTest.mat', ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
%% Toy Example
clear;
% Data Set
t_set = 0:0.02:((5000 - 1) * 0.02);
x1 = tan(0.2 * t_set);
x2 = cos(0.2 * t_set);
x3 = sin(18.5 * t_set);
x4 = 0.5 * t_set;
x_set = [x1;x2;x3;x4];
y_set = 6.5 * (x1 .* x2) - 5.5 * x2 + 7 * exp(x3) + ...
	8 * sin(40 * x4 + pi / 4) - 7 * sin(x4);
y_set = y_set / 10;
figure;
plot(t_set,y_set,'-');
% Hyperparameters
gp = fitrgp(x_set',y_set, ...
	'KernelFunction','ardsquaredexponential','Standardize',false);
SigmaL = gp.KernelInformation.KernelParameters(1:end-1);
SigmaF = gp.KernelInformation.KernelParameters(end);
SigmaN = gp.Sigma;
%
TrainDataSet.X = x_set;
TrainDataSet.Y = y_set;
x_dim = size(x_set,1);
y_dim = size(y_set,1);
HyperparameterSet = cell(y_dim,1);
HyperparameterSet{1}.SigmaN = SigmaN;
HyperparameterSet{1}.SigmaL = SigmaL;
HyperparameterSet{1}.SigmaF = SigmaF;
save('Specified Model\GP Asynchronous Aggregation\DataSet_Toy.mat', ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
