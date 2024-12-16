function GP_AsynAggregation_BenchmarkTest_AsynDGP(DataSetName)
%% Aggregation Option
Lf_factor = 1;
Prior_factor = 1;
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
alpha = 1;
MaxInformationQuantity = 4;
InformationSet = nan(numel(SigmaL) + 3,MaxInformationQuantity);
InformationQuantity = 0;
SavedInformationNrSet = nan(1,MaxInformationQuantity);
f_hat_set = nan(size(TrainDataSet.X,2),1);
Lf = Lf_factor * exp(-1/2) * SigmaF^2;
eta_set = nan(1,MaxInformationQuantity);
AllUDPReceivedDataSet = nan(numel(SigmaL) + 3,UDPPort_Quantity,size(TrainDataSet.X,2));
AllAggregationSet = nan(numel(SigmaL) + 4,MaxInformationQuantity,size(TrainDataSet.X,2));
%%
t_step = 0.02;

TimerGeneral = tic;
t_start = toc(TimerGeneral);
t_step_Nr = 0;

while true
	if toc(TimerGeneral) - t_start >= (t_step_Nr + 1) * t_step
		TimerSend = tic;
		t_step_Nr = floor((toc(TimerGeneral) - t_start) / t_step);
		if t_step_Nr >= size(TrainDataSet.X,2)
			break;
		end

		% Send System State
		x_now = TrainDataSet.X(:,t_step_Nr);
		y_now = TrainDataSet.Y(1,t_step_Nr);
		write(UDPSend,[x_now;y_now;t_step_Nr],'single', ...
			'226.0.0.1',UDPSend.UserData);
		
		% Manage Information Set
		SavedInformationQuantity = 0;
		for InformationNr = 1:InformationQuantity
			saved_var = InformationSet(2,InformationNr);
			saved_x = InformationSet(3:end-1,InformationNr);
			distance_x = norm((x_now - saved_x) ./ SigmaL);
			if Lf * distance_x < alpha * beta * (SigmaF - sqrt(saved_var))
				SavedInformationQuantity = SavedInformationQuantity + 1;
				SavedInformationNrSet(SavedInformationQuantity) = InformationNr;
				eta_set(SavedInformationQuantity) = Lf * distance_x + beta * sqrt(saved_var);
			end
		end
		InformationQuantity = SavedInformationQuantity;
		InformationSet(:,1:SavedInformationQuantity) = ...
			InformationSet(:,SavedInformationNrSet(1:SavedInformationQuantity));
		InformationSet(:,(SavedInformationQuantity+1):end) = nan;
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

				distance_x = norm((x_now - received_x) ./ SigmaL);
				
				if Lf * distance_x < alpha * beta * (SigmaF - sqrt(received_var))
					eta = Lf * distance_x + beta * sqrt(received_var);
					if InformationQuantity < MaxInformationQuantity
						InformationQuantity = InformationQuantity + 1;
						InformationSet(1,InformationQuantity) = received_mu;
						InformationSet(2,InformationQuantity) = received_var;
						InformationSet(3:end-1,InformationQuantity) = received_x;
						InformationSet(end,InformationQuantity) = received_t;

						eta_set(InformationQuantity) = eta;
					else
						[max_eta, max_eta_index] = max(eta_set);
						if eta < max_eta
							InformationSet(1,max_eta_index) = received_mu;
							InformationSet(2,max_eta_index) = received_var;
							InformationSet(3:end-1,max_eta_index) = received_x;
							InformationSet(end,max_eta_index) = received_t;

							eta_set(max_eta_index) = eta;
						end
					end
				end

				AllUDPReceivedDataSet(:,UDPPort_Nr,t_step_Nr) = ...
					[received_mu;received_var;received_x;received_t];
			end
		end
		% Aggregation
		rho = 0;
		w_square_inv = 0;
		f_hat = 0;
		for InformationNr = 1:InformationQuantity
			mu_i = InformationSet(1,InformationNr);
			eta_i = eta_set(InformationNr);
			rho_i = max(0,log(beta * SigmaF / eta_i));
			w_i = rho_i / (eta_i ^ 2);

			rho = rho + rho_i;
			w_square_inv = w_square_inv + w_i;

			f_hat = f_hat + w_i * mu_i;
		end
		w_square_inv = w_square_inv + Prior_factor * (1 - rho) / (beta * SigmaF)^2;
		f_hat = f_hat / w_square_inv;

		f_hat_set(t_step_Nr) = f_hat;
		AllAggregationSet(:,:,t_step_Nr) = [InformationSet;eta_set];
		
		%
		SendTimeUsage = toc(TimerSend);
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
	DataSetName,'_AsynDGP.mat']);
end


