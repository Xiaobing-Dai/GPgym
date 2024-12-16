%% GP_AsynAggregation_Control_BatchPostprocessing
clc; clear; close all;
%%
AggregationOptionSet = ...
	{'Our Method'; 'rBCM'; 'gPoE'; 'BCM'; 'PoE'; 'MoE'};
AggregationOptionPlotCpnfigurationSet = ...
	{'r-','b-','c-','b--','c--','m-'};
ResultParentFolderName = 'Result\GP Asynchronous Aggregation\Control\';
%% Single Performance Plot
MonteCarloNr = 3;
SingleTrackingErrorFigure = figure('Name',['Single Tracking Error ',num2str(MonteCarloNr)]);
SingleTrackingErrorAxes = subplot(2,1,1,'Parent',SingleTrackingErrorFigure);
SinglePredictionErrorAxes = subplot(2,1,2,'Parent',SingleTrackingErrorFigure);
for AggregationOptionNr = 1:numel(AggregationOptionSet)
	AggregationMethod = AggregationOptionSet{AggregationOptionNr};
	ResultFolderName = [ResultParentFolderName,AggregationMethod];
	ResultFileName = ['Control ',num2str(MonteCarloNr),'.mat'];
	load([ResultFolderName,'\',ResultFileName], ...
		't_set','norm_e_set','y_set','f_hat_set');
	%
	RMSE_TrackingError_set = ...
		sqrt(cumsum(norm_e_set .^ 2) ./ (1:numel(norm_e_set)));
	semilogy(SingleTrackingErrorAxes,t_set,RMSE_TrackingError_set, ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
	hold(SingleTrackingErrorAxes,'on');
	%
	RMSE_PredictionError_set = ...
		sqrt(cumsum((y_set - f_hat_set') .^ 2) ./ (1:numel(norm_e_set)));
	semilogy(SinglePredictionErrorAxes,t_set,RMSE_PredictionError_set, ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
	hold(SinglePredictionErrorAxes,'on');
end
legend(SingleTrackingErrorAxes, AggregationOptionSet, ...
	'NumColumns',4);
legend(SinglePredictionErrorAxes, AggregationOptionSet, ...
	'NumColumns',4);
xlim(SingleTrackingErrorAxes,[min(t_set),max(t_set)]);
xlim(SinglePredictionErrorAxes,[min(t_set),max(t_set)]);
%% Statistic Performance Computation
do_load_Result = true;
if do_load_Result
	load('Result\GP Asynchronous Aggregation\Control\Our Method\Control 1.mat','t_set');
	MonteCarloMaxQuantity = 100;
	All_RMSE_TrackingError_set = nan(MonteCarloMaxQuantity,numel(t_set),numel(AggregationOptionSet));
	All_RMSE_PredictionError_set = nan(MonteCarloMaxQuantity,numel(t_set),numel(AggregationOptionSet));
	Mean_RMSE_TrackingError_set = nan(numel(AggregationOptionSet),numel(t_set));
	Mean_RMSE_PredictionError_set = nan(numel(AggregationOptionSet),numel(t_set));
	Std_RMSE_TrackingError_set = nan(numel(AggregationOptionSet),numel(t_set));
	Std_RMSE_PredictionError_set = nan(numel(AggregationOptionSet),numel(t_set));
	for AggregationOptionNr = 1:numel(AggregationOptionSet)
		AggregationMethod = AggregationOptionSet{AggregationOptionNr};
		ResultFolderName = [ResultParentFolderName,AggregationMethod];
		for MonteCarloNr = 1:MonteCarloMaxQuantity
			ResultFileName = ['Control ',num2str(MonteCarloNr),'.mat'];
			load([ResultFolderName,'\',ResultFileName], ...
				't_set','norm_e_set','y_set','f_hat_set');
			All_RMSE_TrackingError_set(MonteCarloNr,:,AggregationOptionNr) = ...
				sqrt(cumsum(norm_e_set .^ 2) ./ (1:numel(norm_e_set)));
			All_RMSE_PredictionError_set(MonteCarloNr,:,AggregationOptionNr) = ...
				sqrt(cumsum((y_set - f_hat_set') .^ 2) ./ (1:numel(norm_e_set)));
			
			All_RMSE_TrackingError_set(MonteCarloNr,:,AggregationOptionNr) = ...
				norm_e_set;
			All_RMSE_PredictionError_set(MonteCarloNr,:,AggregationOptionNr) = ...
				abs(y_set - f_hat_set');

			All_RMSE_PredictionError_set(MonteCarloNr,end,AggregationOptionNr) = ...
				All_RMSE_PredictionError_set(MonteCarloNr,end-1,AggregationOptionNr);
			fprintf(['Data for ',AggregationMethod,' ',num2str(MonteCarloNr),' is finished! \n']);
		end
		Mean_RMSE_TrackingError_set(AggregationOptionNr,:) = ...
			mean(All_RMSE_TrackingError_set(:,:,AggregationOptionNr),1);
		Std_RMSE_TrackingError_set(AggregationOptionNr,:) = ...
			std(All_RMSE_TrackingError_set(:,:,AggregationOptionNr),[],1);
		Mean_RMSE_PredictionError_set(AggregationOptionNr,:) = ...
			mean(All_RMSE_PredictionError_set(:,:,AggregationOptionNr),1);
		Std_RMSE_PredictionError_set(AggregationOptionNr,:) = ...
			std(All_RMSE_PredictionError_set(:,:,AggregationOptionNr),[],1);
	end
	Min_RMSE_TrackingError_set = Mean_RMSE_TrackingError_set - 0.5 * Std_RMSE_TrackingError_set;
	Max_RMSE_TrackingError_set = Mean_RMSE_TrackingError_set + 0.5 * Std_RMSE_TrackingError_set;
	Min_RMSE_PredictionError_set = Mean_RMSE_PredictionError_set - 0.5 * Std_RMSE_PredictionError_set;
	Max_RMSE_PredictionError_set = Mean_RMSE_PredictionError_set + 0.5 * Std_RMSE_PredictionError_set;
	Min_RMSE_TrackingError_set(Min_RMSE_TrackingError_set < 1e-10) = 1e-10;
	Min_RMSE_PredictionError_set(Min_RMSE_PredictionError_set < 1e-10) = 1e-10;
	save('Result\GP Asynchronous Aggregation\Control\Summary.mat','t_set', ...
		'Mean_RMSE_TrackingError_set','Std_RMSE_TrackingError_set','Min_RMSE_TrackingError_set','Max_RMSE_TrackingError_set', ...
		'Mean_RMSE_PredictionError_set','Std_RMSE_PredictionError_set','Min_RMSE_PredictionError_set','Max_RMSE_PredictionError_set');
else
	load('Result\GP Asynchronous Aggregation\Control\Summary.mat','t_set', ...
		'Mean_RMSE_TrackingError_set','Std_RMSE_TrackingError_set','Min_RMSE_TrackingError_set','Max_RMSE_TrackingError_set', ...
		'Mean_RMSE_PredictionError_set','Std_RMSE_PredictionError_set','Min_RMSE_PredictionError_set','Max_RMSE_PredictionError_set');
end
%% Statistic Performance Plot
StatisticTrackingErrorFigure = figure('Name',['Statistic Tracking Error ',num2str(MonteCarloNr)]);
StatisticTrackingErrorAxes = subplot(2,1,1,'Parent',StatisticTrackingErrorFigure);
StatisticPredictionErrorAxes = subplot(2,1,2,'Parent',StatisticTrackingErrorFigure);
for AggregationOptionNr = 1:numel(AggregationOptionSet)
	semilogy(StatisticTrackingErrorAxes,t_set,Mean_RMSE_TrackingError_set(AggregationOptionNr,:), ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
	hold(StatisticTrackingErrorAxes,'on');
	%
	semilogy(StatisticPredictionErrorAxes,t_set,Mean_RMSE_PredictionError_set(AggregationOptionNr,:), ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
	hold(StatisticPredictionErrorAxes,'on');
end
for AggregationOptionNr = 1:numel(AggregationOptionSet)
	fill(StatisticTrackingErrorAxes,[t_set,t_set(end:-1:1)], ...
		[Min_RMSE_TrackingError_set(AggregationOptionNr,:),Max_RMSE_TrackingError_set(AggregationOptionNr,end:-1:1)], ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr}(1), ...
		'FaceAlpha',0.1,'EdgeAlpha',0);
	%
	fill(StatisticPredictionErrorAxes,[t_set,t_set(end:-1:1)], ...
		[Min_RMSE_PredictionError_set(AggregationOptionNr,:),Max_RMSE_PredictionError_set(AggregationOptionNr,end:-1:1)], ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr}(1), ...
		'FaceAlpha',0.1,'EdgeAlpha',0);
end
legend(StatisticTrackingErrorAxes, AggregationOptionSet, ...
	'NumColumns',4);
legend(StatisticPredictionErrorAxes, AggregationOptionSet, ...
	'NumColumns',4);
xlim(StatisticTrackingErrorAxes,[min(t_set),10]);
xlim(StatisticPredictionErrorAxes,[min(t_set),10]);
ylim(StatisticTrackingErrorAxes,[0.25;1.5]);
ylim(StatisticPredictionErrorAxes,[1.8;13]);
title(StatisticTrackingErrorAxes,'Tracking Error');
title(StatisticPredictionErrorAxes,'Prediction Error');
xlabel(StatisticTrackingErrorAxes,'t');
xlabel(StatisticPredictionErrorAxes,'t');
ylabel(StatisticTrackingErrorAxes,'RMSE');
ylabel(StatisticPredictionErrorAxes,'RMSE');
%%
TrackingError_tikz_variableName = [];
PredictionError_tikz_variableName = [];
for AggregationOptionNr = 1:numel(AggregationOptionSet)
AggregationMethod = erase(AggregationOptionSet{AggregationOptionNr},' ');

eval([AggregationMethod,'_et_mean = transpose(Mean_RMSE_TrackingError_set(AggregationOptionNr,:));']);
eval([AggregationMethod,'_et_min = transpose(Min_RMSE_TrackingError_set(AggregationOptionNr,:));']);
eval([AggregationMethod,'_et_max = transpose(Max_RMSE_TrackingError_set(AggregationOptionNr,:));']);
TrackingError_tikz_variableName = [TrackingError_tikz_variableName,',' ...
	AggregationMethod,'_et_mean,',AggregationMethod,'_et_min,',AggregationMethod,'_et_max'];

eval([AggregationMethod,'_ef_mean = transpose(Mean_RMSE_PredictionError_set(AggregationOptionNr,:));']);
eval([AggregationMethod,'_ef_min = transpose(Min_RMSE_PredictionError_set(AggregationOptionNr,:));']);
eval([AggregationMethod,'_ef_max = transpose(Max_RMSE_PredictionError_set(AggregationOptionNr,:));']);
PredictionError_tikz_variableName = [PredictionError_tikz_variableName,',' ...
	AggregationMethod,'_ef_mean,',AggregationMethod,'_ef_min,',AggregationMethod,'_ef_max'];
end
t_set = t_set';
data2txt_opt.fname = ['Result\GP Asynchronous Aggregation\', ...
		'tikz format - txt file\','Control_Tracking'];
	eval(['data2txt(data2txt_opt, t_set',TrackingError_tikz_variableName,')']);
data2txt_opt.fname = ['Result\GP Asynchronous Aggregation\', ...
		'tikz format - txt file\','Control_Prediction'];
	eval(['data2txt(data2txt_opt, t_set',PredictionError_tikz_variableName,')']);

