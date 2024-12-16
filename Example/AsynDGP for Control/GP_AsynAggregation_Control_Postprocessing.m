%% GP_AsynAggregation_Control_Postprocessing
clc; clear; close all;
%%
AggregationOptionSet = {'Our Method'; 'rBCM'; 'gPoE'; 'BCM'; 'PoE'; 'MoE'};
AggregationOptionPlotCpnfigurationSet = ...
	{'r-','b-','c-','b--','c--','m-'};
%%
TrackingErrorFigure = figure('Name','Tracking Error');
TrackingErrorAxes = subplot(2,1,1,'Parent',TrackingErrorFigure);
PredictionErrorAxes = subplot(2,1,2,'Parent',TrackingErrorFigure);
for AggregationOptionNr = 1:numel(AggregationOptionSet)
	AggregationOptionName = AggregationOptionSet{AggregationOptionNr};
	load(['Result\GP Asynchronous Aggregation\Control_',AggregationOptionName,'.mat'], ...
		't_set','norm_e_set','y_set','f_hat_set');
	%
	RMSE_TrackingError_set = ...
		sqrt(cumsum(norm_e_set .^ 2) ./ (1:numel(norm_e_set)));
	semilogy(TrackingErrorAxes,t_set,RMSE_TrackingError_set, ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
	hold(TrackingErrorAxes,'on');
	%
	RMSE_PredictionError_set = ...
		sqrt(cumsum((y_set - f_hat_set') .^ 2) ./ (1:numel(norm_e_set)));
	semilogy(PredictionErrorAxes,t_set,RMSE_PredictionError_set, ...
		AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
	hold(PredictionErrorAxes,'on');
end
legend(TrackingErrorAxes, AggregationOptionSet, ...
	'NumColumns',4);
xlim(TrackingErrorAxes,[min(t_set),max(t_set)]);
xlim(PredictionErrorAxes,[min(t_set),max(t_set)]);

