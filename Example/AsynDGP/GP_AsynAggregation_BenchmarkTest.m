%% GP_AsynAggregation_BenchmarkTest
clc; clear all; close all;
%% 
DataSetName_CellSet = {'SARCOS';'KIN40K';'POL';'PUMADYN32NM';'BenchmarkTest';'Toy'};
AggregationMethod_CellSet = {'AsynDGP';'POE';'gPOE';'BCM';'rBCM';'MOE'};
for DataSetNameNr = 4%1:numel(DataSetName_CellSet)
	DataSetName = DataSetName_CellSet{DataSetNameNr};
	for AggregationMethodNr = 1:1%1:numel(AggregationMethod_CellSet)
		AggregationMethod = AggregationMethod_CellSet{AggregationMethodNr};
		if strcmpi(AggregationMethod,'AsynDGP')
			GP_AsynAggregation_BenchmarkTest_AsynDGP(DataSetName);
		else
			GP_AsynAggregation_BenchmarkTest_StaticAggregation(DataSetName,AggregationMethod);
		end
	end
	input([DataSetName,' is finished. Press enter for next data set.']);
end
%%
