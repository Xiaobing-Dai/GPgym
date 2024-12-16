%% GP_AsynAggregation_Postprocessing
clc; clear; close all;
%%
% DataSetNameSet = {'SARCOS'; 'KIN40K'; 'PUMADYN32NM'};
% AggregationOptionSet = {'Our Method'; 'rBCM'; 'gPoE'; 'BCM'; 'PoE'; 'MoE'};
DataSetNameSet = {'SARCOS'; 'KIN40K'; 'POL'; 'PUMADYN32NM';'Toy'};
AggregationOptionSet = {'AsynDGP'; 'rBCM'; 'gPOE'; 'BCM'; 'POE';'MOE'};
AggregationOptionPlotCpnfigurationSet = ...
	{'r-','b-','c-','b--','c--','m-'};
ylim_set = { ...
	[0.3,3],[4,5];
	[0.9,1.5],[1.35,1.65];
	[0.9,1.5],[1.35,1.65];
	[1,1.3],[1.43,1.55];
	[0.3,2.3],[3.2,4.5]
	};
%%
RegressionErrorFigureSet = cell(numel(DataSetNameSet),1);
for DataSetNameNr = [1,2,4]%1:numel(DataSetNameSet)
	DataSetName = DataSetNameSet{DataSetNameNr};
	RegressionErrorFigureSet{DataSetNameNr}.Figure = figure('Name',DataSetName);
	RegressionErrorFigureSet{DataSetNameNr}.SMSE_Axes = subplot(2,1,1, ...
		'Parent',RegressionErrorFigureSet{DataSetNameNr}.Figure);
	RegressionErrorFigureSet{DataSetNameNr}.MSLL_Axes = subplot(2,1,2, ...
		'Parent',RegressionErrorFigureSet{DataSetNameNr}.Figure);
	tikz_variableName = [];
	for AggregationOptionNr = 1:numel(AggregationOptionSet)
		AggregationOptionName = AggregationOptionSet{AggregationOptionNr};
		load(['Result\GP Asynchronous Aggregation\Benchmark\',DataSetName,'_',AggregationOptionName,'.mat'], ...
			'f_hat_set','TrainDataSet');
% 		load(['Result\GP Asynchronous Aggregation\',DataSetName,'_',AggregationOptionName,'.mat'], ...
% 			'f_hat_set','TrainDataSet');
		sy = var(TrainDataSet.Y(1,1:end));
		SMSE = cumsum((f_hat_set(1:end)' - TrainDataSet.Y(1,1:end)) .^ 2,'omitnan') ./ (1:size(TrainDataSet.Y,2)) / sy;
		MSLL = cumsum(0.5 * log(2 * pi * sy) + (f_hat_set' - TrainDataSet.Y(1,1:end)) .^ 2 / (2 * sy), ...
			'omitnan') ./ (1:size(TrainDataSet.Y,2));

		semilogy(RegressionErrorFigureSet{DataSetNameNr}.SMSE_Axes,SMSE, ...
			AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
		hold(RegressionErrorFigureSet{DataSetNameNr}.SMSE_Axes,'on');

		semilogy(RegressionErrorFigureSet{DataSetNameNr}.MSLL_Axes,MSLL, ...
			AggregationOptionPlotCpnfigurationSet{AggregationOptionNr});
		hold(RegressionErrorFigureSet{DataSetNameNr}.MSLL_Axes,'on');

		eval([erase(AggregationOptionName,' '),'_SMSE = transpose(SMSE);']);
		eval([erase(AggregationOptionName,' '),'_MSLL = transpose(MSLL);']);
		
		tikz_variableName = [tikz_variableName,',', ...
			erase(AggregationOptionName,' '),'_SMSE,', ...
			erase(AggregationOptionName,' '),'_MSLL'];
	end
	t = transpose(0:numel(SMSE)-1);
	%
	data2txt_opt.fname = ['Result\GP Asynchronous Aggregation\', ...
		'tikz format - txt file\','Regression_',DataSetName,'_All'];
	data2txt_opt.ndata = numel(t);
	eval(['data2txt(data2txt_opt, t',tikz_variableName,')']);
	%
	clear data2txt_opt;
	data2txt_opt.fname = ['Result\GP Asynchronous Aggregation\', ...
		'tikz format - txt file\','Regression_',DataSetName];
	eval(['data2txt(data2txt_opt, t',tikz_variableName,')']);
	%
	

	legend(RegressionErrorFigureSet{DataSetNameNr}.SMSE_Axes, AggregationOptionSet, ...
		'NumColumns',4);
	xlim(RegressionErrorFigureSet{DataSetNameNr}.SMSE_Axes,[1,size(TrainDataSet.Y,2)]);
	ylim(RegressionErrorFigureSet{DataSetNameNr}.SMSE_Axes,ylim_set{DataSetNameNr,1});

	legend(RegressionErrorFigureSet{DataSetNameNr}.MSLL_Axes, AggregationOptionSet, ...
		'NumColumns',4);
	xlim(RegressionErrorFigureSet{DataSetNameNr}.MSLL_Axes,[1,size(TrainDataSet.Y,2)]);
	ylim(RegressionErrorFigureSet{DataSetNameNr}.MSLL_Axes,ylim_set{DataSetNameNr,2});
end
%%
DelayFigureSet = cell(numel(DataSetNameSet),1);
for DataSetNameNr = [1,2,4]
	
	%
	DataSetName = DataSetNameSet{DataSetNameNr};
	DelayFigureSet{DataSetNameNr}.Figure = figure('Name',DataSetName);
	DelayFigureSet{DataSetNameNr}.Information_Axes = subplot(2,1,1, ...
		'Parent',DelayFigureSet{DataSetNameNr}.Figure);
	DelayFigureSet{DataSetNameNr}.Delay_Axes = subplot(2,1,2, ...
		'Parent',DelayFigureSet{DataSetNameNr}.Figure);
	hold(DelayFigureSet{DataSetNameNr}.Delay_Axes,'on');
	% 
	
	load(['Result\GP Asynchronous Aggregation\Benchmark\', ...
		DataSetName,'_AsynDGP.mat'], ...
		'AllAggregationSet','MaxInformationQuantity', ...
		'AllUDPReceivedDataSet','UDPPort_Quantity');
	AggregationTimeSet = nan(size(AllAggregationSet,3),MaxInformationQuantity);
	for t_Nr = 1:size(AllAggregationSet,3)
		AggregationTimeSet(t_Nr,:) = 0.02 * sort(t_Nr  - AllAggregationSet(end-1,:,t_Nr),2,'descend');
	end
	AggregationTimeSet(isnan(AggregationTimeSet)) = 0;
	plot(DelayFigureSet{DataSetNameNr}.Information_Axes, ...
		1:size(AllAggregationSet,3),AggregationTimeSet);
	% Delay
	DelayTimeSet = nan(size(AllAggregationSet,3),MaxInformationQuantity);
	AllUDPReceivedDataSet(end,:,1) = 0;
	for t_Nr = 1:size(AllAggregationSet,3)
		if t_Nr > 1
			for GP_Nr = 1:UDPPort_Quantity
				if isnan(AllUDPReceivedDataSet(end,GP_Nr,t_Nr))
					AllUDPReceivedDataSet(end,GP_Nr,t_Nr) = AllUDPReceivedDataSet(end,GP_Nr,t_Nr - 1);
				end
			end
		end
		DelayTimeSet(t_Nr,:) = 1 * (t_Nr - AllUDPReceivedDataSet(end,:,t_Nr));
	end
	for InformationNr = 1:MaxInformationQuantity
		plot3(DelayFigureSet{DataSetNameNr}.Delay_Axes, ...
			InformationNr * ones(size(AllAggregationSet,3),1), ...
			1:size(AllAggregationSet,3),DelayTimeSet(:,InformationNr));
	end
	view(DelayFigureSet{DataSetNameNr}.Delay_Axes,[-60,30]);
	%
	tikz_variableName = [];
	for InformationNr = 1:MaxInformationQuantity
		eval(['AggregationDelay_',num2str(InformationNr),' = AggregationTimeSet(:,InformationNr);']);
		eval(['Delay_',num2str(InformationNr),' = DelayTimeSet(:,InformationNr);']);
		tikz_variableName = [tikz_variableName,',', ...
			'AggregationDelay_',num2str(InformationNr),',', ...
			'Delay_',num2str(InformationNr)];
	end
	data2txt_opt.fname = ['Result\GP Asynchronous Aggregation\', ...
		'tikz format - txt file\','Delay_',DataSetName,'_All'];
	data2txt_opt.ndata = size(DelayTimeSet,1);
	eval(['data2txt(data2txt_opt',tikz_variableName,')']);
end



