function GP_AsynAggregation_BenchmarkTest_StaticAggregation(DataSetName,AggregationMethod)
%%
load(['Specified Model\GP Asynchronous Aggregation\DataSet_',DataSetName,'.mat'], ...
	'HyperparameterSet','TrainDataSet');
%% UDP Setting
UDPPort_Quantity = 4;
[UDPSend,UDPRead_Set] = GP_AsynAggregation_UDPSet_Server(UDPPort_Quantity);
%%
beta = 100;
SigmaL = HyperparameterSet{1}.SigmaL;
SigmaF = HyperparameterSet{1}.SigmaF;
MaxInformationQuantity = UDPPort_Quantity;
InformationSet = zeros(numel(SigmaL) + 2,MaxInformationQuantity);
f_hat_set = nan(size(TrainDataSet.X,2),1);
eta_prior = beta * SigmaF;
eta_set = eta_prior * ones(1,MaxInformationQuantity);
AllUDPReceivedDataSet = nan(numel(SigmaL) + 3,UDPPort_Quantity,size(TrainDataSet.X,2));
AllAggregationSet = nan(numel(SigmaL) + 3,MaxInformationQuantity,size(TrainDataSet.X,2));
%%
t_step = 0.02;

TimerGeneral = tic;
t_start = toc(TimerGeneral);
t_step_Nr = 0;
while true
	if toc(TimerGeneral) - t_start >= (t_step_Nr + 1) * t_step
		TimerProcess = tic;
		t_step_Nr = floor((toc(TimerGeneral) - t_start) / t_step);
		if t_step_Nr >= size(TrainDataSet.X,2)
			break;
		end
		% Send System State
		x_now = TrainDataSet.X(:,t_step_Nr);
		y_now = TrainDataSet.Y(1,t_step_Nr);
		write(UDPSend,[x_now;y_now;t_step_Nr],'single', ...
			'226.0.0.1',UDPSend.UserData);
		% Receive Predictions
		for UDPPort_Nr = 1:UDPPort_Quantity
			if UDPRead_Set{UDPPort_Nr}.NumDatagramsAvailable > 0
				received_data = read(UDPRead_Set{UDPPort_Nr}, ...
					UDPRead_Set{UDPPort_Nr}.NumDatagramsAvailable,'single');
				received_data = received_data(end).Data;
				received_mu = received_data(1);
				received_var = received_data(2);
				received_x = reshape(received_data(3:end-1),[],1);
				received_t = received_data(end);

				InformationSet(1,UDPPort_Nr) = received_mu;
				InformationSet(2,UDPPort_Nr) = received_var;
				InformationSet(3:end,UDPPort_Nr) = received_x;

				eta_set(UDPPort_Nr) = beta * sqrt(received_var);

				AllUDPReceivedDataSet(:,UDPPort_Nr,t_step_Nr) = ...
					[received_mu;received_var;received_x;received_t];
			end
		end
		% Aggregation
		f_hat = 0;
		switch AggregationMethod
			case 'POE'
				f_hat = GP_AsynAggregation_POE(InformationSet,eta_set);
			case 'gPOE'
				f_hat = GP_AsynAggregation_gPOE(InformationSet,eta_set,eta_prior);
			case 'BCM'
				f_hat = GP_AsynAggregation_BCM(InformationSet,eta_set,eta_prior);
			case 'rBCM'
				f_hat = GP_AsynAggregation_rBCM(InformationSet,eta_set,eta_prior);
			case 'MOE'
				f_hat = GP_AsynAggregation_MOE(InformationSet);
		end
		f_hat_set(t_step_Nr) = f_hat;
		AllAggregationSet(:,:,t_step_Nr) = [InformationSet;eta_set];
		%
		SendTimeUsage = toc(TimerProcess);
		fprintf('t_step_Nr = %d, \t t_send = %6.4f \n',t_step_Nr,SendTimeUsage);
	end
	
end
%% Send Terminal Instruction
for TerminalInstructionSendTimeNr = 1:15
	write(UDPSend,-1,'single', ...
		'226.0.0.1',UDPSend.UserData);
	pause(0.02);
end
%%
for UDPPort_Nr = 1:UDPPort_Quantity
	flush(UDPSend,'output');
	flush(UDPRead_Set{UDPPort_Nr},'output');
end
clear UDPSend UDPSend_Test UDPRead_Set;
%%
save(['Result\GP Asynchronous Aggregation\Benchmark\', ...
	DataSetName,'_',AggregationMethod,'.mat']);
end


