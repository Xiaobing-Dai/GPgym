%% GP_AsynAggregation_ToyExampleTest
clear;
%%
t_set = 0:0.02:((5000 - 1) * 0.02);
x1 = tan(0.2 * t_set);
x2 = cos(0.2 * t_set);
x3 = sin(18.5 * t_set);
x4 = 0.5 * t_set;
x_set = [x1;x2;x3;x4];
y_set = 6.5 * (x1 .* x2) - 5.5 * x2 + 7 * exp(x3) + ...
	8 * sin(40 * x4 + pi / 4) - 7 * sin(x4);
figure;
plot(t_set,y_set,'-');
%%
gp = fitrgp(x_set',y_set, ...
	'KernelFunction','ardsquaredexponential','Standardize',false);
SigmaL = gp.KernelInformation.KernelParameters(1:end-1);
SigmaF = gp.KernelInformation.KernelParameters(end);
SigmaN = gp.Sigma;
%%
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
