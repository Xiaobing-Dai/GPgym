%% GP_AsynAggregation_Control_BatchTest
clc; clear; close all;
%%
AggregationOptionSet = ...
	{'Our Method'; 'rBCM'; 'gPoE'; 'BCM'; 'PoE'; 'MoE'};
%%
MonteCarloMaxQuantity = 100;
for MonteCarloNr = 41:MonteCarloMaxQuantity
	for AggregationOptionNr = 1:numel(AggregationOptionSet)
		AggregationMethod = AggregationOptionSet{AggregationOptionNr};
		GP_AsynAggregation_Control_TestFunc(AggregationMethod,MonteCarloNr);
	end
end