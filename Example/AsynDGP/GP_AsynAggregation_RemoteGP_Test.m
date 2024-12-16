%% 
clc; clear; close all;
%%
load('Specified Model\GP Asynchronous Aggregation\DataSet_SARCOS.mat', ...
	'HyperparameterSet','x_dim');
y_dim = 1;
SigmaN = HyperparameterSet{1}.SigmaN;
SigmaF = HyperparameterSet{1}.SigmaF;
SigmaL = HyperparameterSet{1}.SigmaL;
Max_LocalGP_DataQuantity = 500;
Max_LocalGP_Quantity = 100;
LogGP = LoG_GP_MultiOutput(Max_LocalGP_DataQuantity,Max_LocalGP_Quantity, ...
	x_dim,y_dim,SigmaN,SigmaF,SigmaL);
LogGP.AggregationMethod = 'GPOE';
LogGP.o_ratio = 1/100;
%%
load('Specified Model\GP Asynchronous Aggregation\DataSet_SARCOS.mat', ...
	'TrainDataSet');
MaxDataQuantity = size(TrainDataSet.X,2);
% MaxDataQuantity = 10000;
mu_set = nan(y_dim,MaxDataQuantity);
ActivatedLocalGP_QuantitySet = nan(1,MaxDataQuantity);
LearningTimeSet = nan(2,MaxDataQuantity);
for DataNr = 1:MaxDataQuantity
	Data_x = TrainDataSet.X(1:x_dim,DataNr);
	Data_y = TrainDataSet.Y(1:y_dim,DataNr);
	tic;
	UpdateFlag = LogGP.update(Data_x,Data_y);
	LearningTimeSet(1,DataNr) = toc;
	tic;
	[mu_set(:,DataNr),~,~,~,~,ActivatedLocalGP_QuantitySet(DataNr)] = ...
		LogGP.predict(Data_x,Data_y);
	LearningTimeSet(2,DataNr) = toc;
	fprintf('Iteration = %d, \t Flag = %d, Total Data Quantity = %d \n', ...
		DataNr,UpdateFlag,LogGP.DataQuantity);
end
%%
figure;
plot(1:MaxDataQuantity,TrainDataSet.Y(1:y_dim,1:MaxDataQuantity),'r-', ...
	1:MaxDataQuantity,mu_set,'b--');
%%
figure;
Prediction_NormSet = sqrt(sum((mu_set .^ 2),1));
Prediction_ErrorSet = TrainDataSet.Y(1:y_dim,1:MaxDataQuantity) - mu_set;
Prediction_NormErrorSet = sqrt(sum((Prediction_ErrorSet .^ 2),1));
Prediction_CumNormErrorSet = sqrt(cumsum(Prediction_NormErrorSet .^ 2));
Prediction_AverCumNormErrorSet = Prediction_CumNormErrorSet .^ 2 ./ (1:MaxDataQuantity);
Prediction_RelNormErrorSet = Prediction_NormErrorSet ./ Prediction_NormSet;
Prediction_CumRelNormErrorSet = sqrt(cumsum(Prediction_RelNormErrorSet .^ 2));
Prediction_AverCumRelNormErrorSet = Prediction_CumRelNormErrorSet .^ 2 ./ (1:MaxDataQuantity);
semilogy(1:MaxDataQuantity,Prediction_AverCumNormErrorSet);
%%
figure;
stairs(ActivatedLocalGP_QuantitySet);
%%
figure;
semilogy(1:MaxDataQuantity,LearningTimeSet);
legend('Update Time', 'Prediction Time');