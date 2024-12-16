%% GP_AsynAggregation_Test
clc; clear; close all;
%% Aggregation Option
AggregationMethod = 'Our Method';
% AggregationMethod = 'rBCM';
% AggregationMethod = 'gPoE';
% AggregationMethod = 'BCM';
% AggregationMethod = 'PoE';
% AggregationMethod = 'MoE';
if strcmpi(AggregationMethod,'Our Method')
	Lf_factor = 1;
else
	Lf_factor = 0;
end
if strcmpi(AggregationMethod,'Our Method') || ...
		strcmpi(AggregationMethod,'rBCM') || ...
		strcmpi(AggregationMethod,'BCM')
	Prior_factor = 1;
else
	Prior_factor = 0;
end
%%
% DataSetName = 'SARCOS';
% DataSetName = 'KIN40K';
% DataSetName = 'POL';
DataSetName = 'PUMADYN32NM';
load(['Specified Model\GP Asynchronous Aggregation\DataSet_',DataSetName,'.mat'], ...
	'HyperparameterSet','TrainDataSet','x_dim','y_dim');
%% UDP Setting
[~, result] = system('ipconfig');
result = strsplit(result,'\n');
for ResultNr = 1:numel(result)
	if strfind(result{ResultNr},'IPv4')
		break;
	end
end
result = strsplit(result{ResultNr},': ');
LocalIP = result{end};
clear result ResultNr;
%
UDPPort_Quantity = 4;
UDPSend = udpport('IPV4','LocalHost',LocalIP);
UDPSend.UserData = 8000;
UDPSend_Test = udpport('IPV4','EnablePortSharing',true, ...
	'LocalHost',LocalIP,'LocalPort',UDPSend.UserData);
configureMulticast(UDPSend_Test, '226.0.0.1');
UDPRead_Set = cell(UDPPort_Quantity,1);
for UDPPort_Nr = 1:UDPPort_Quantity
	UDPRead_Set{UDPPort_Nr} = udpport('datagram','IPV4', ...
		'LocalHost',LocalIP,'LocalPort',8050 + UDPPort_Nr * 100);
end
%%
beta = 1;
SigmaL = HyperparameterSet{1}.SigmaL;
SigmaF = HyperparameterSet{1}.SigmaF;
alpha = 1;
MaxInformationQuantity = 10;
InformationSet = nan(numel(SigmaL) + 2,MaxInformationQuantity);
InformationQuantity = 0;
SavedInformationNrSet = nan(1,MaxInformationQuantity);
f_hat_set = nan(size(TrainDataSet.X,2),1);
Lf = Lf_factor * exp(-1/2) * SigmaF^2 / 100;
eta_set = nan(1,MaxInformationQuantity);
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
		write(UDPSend,[x_now;y_now],'single', ...
			'226.0.0.1',UDPSend.UserData);
		
		% Manage Information Set
		if strcmpi(AggregationMethod,'Our Method')
			SavedInformationQuantity = 0;
			for InformationNr = 1:InformationQuantity
				saved_var = InformationSet(2,InformationNr);
				saved_x = InformationSet(3:end,InformationNr);
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
		else
			for InformationNr = 1:InformationQuantity
				saved_var = InformationSet(2,InformationNr);
				saved_x = InformationSet(3:end,InformationNr);
				distance_x = norm((x_now - saved_x) ./ SigmaL);
				eta_set(InformationNr) = Lf * distance_x + beta * sqrt(saved_var);
			end
		end
		% Receive Predictions
		for UDPPort_Nr = 1:UDPPort_Quantity
			if UDPRead_Set{UDPPort_Nr}.NumDatagramsAvailable > 0
				received_data = read(UDPRead_Set{UDPPort_Nr}, ...
					UDPRead_Set{UDPPort_Nr}.NumDatagramsAvailable,'single');
				received_data = received_data(end).Data;
				received_mu = received_data(1);
				received_var = received_data(2);
				received_x = reshape(received_data(3:end),[],1);

				distance_x = norm((x_now - received_x) ./ SigmaL);
				if strcmpi(AggregationMethod,'Our Method')
					if Lf * distance_x < alpha * beta * (SigmaF - sqrt(received_var))
						eta = Lf * distance_x + beta * sqrt(received_var);
						if InformationQuantity < MaxInformationQuantity
							InformationQuantity = InformationQuantity + 1;
							InformationSet(1,InformationQuantity) = received_mu;
							InformationSet(2,InformationQuantity) = received_var;
							InformationSet(3:end,InformationQuantity) = received_x;

							eta_set(InformationQuantity) = eta;
						else
							[max_eta, max_eta_index] = max(eta_set);
							if eta < max_eta
								InformationSet(1,max_eta_index) = received_mu;
								InformationSet(2,max_eta_index) = received_var;
								InformationSet(3:end,max_eta_index) = received_x;

								eta_set(max_eta_index) = eta;
							end
						end
					end
				else
					eta = Lf * distance_x + beta * sqrt(received_var);
					if InformationQuantity < MaxInformationQuantity
						InformationQuantity = InformationQuantity + 1;
						InformationSet(1,InformationQuantity) = received_mu;
						InformationSet(2,InformationQuantity) = received_var;
						InformationSet(3:end,InformationQuantity) = received_x;

						eta_set(InformationQuantity) = eta;
					else
						InformationSet(:,1:(MaxInformationQuantity-1)) = ...
							InformationSet(:,2:MaxInformationQuantity);
						eta_set(1:end-1) = eta_set(2:end);

						InformationSet(1,MaxInformationQuantity) = received_mu;
						InformationSet(2,MaxInformationQuantity) = received_var;
						InformationSet(3:end,MaxInformationQuantity) = received_x;
					end
				end
			end
		end

		% Aggregation
		rho = 0;
		w_square_inv = 0;
		f_hat = 0;
		if strcmpi(AggregationMethod,'MoE')
			for InformationNr = 1:InformationQuantity
				mu_i = InformationSet(1,InformationNr);
				f_hat = f_hat + mu_i;
			end
			f_hat = f_hat / InformationQuantity;
		else
		for InformationNr = 1:InformationQuantity
			mu_i = InformationSet(1,InformationNr);
			eta_i = eta_set(InformationNr);
			if strcmpi(AggregationMethod,'Our Method') || ...
					strcmpi(AggregationMethod,'gPoE') || ...
					strcmpi(AggregationMethod,'rBCM')
				rho_i = max(0,log(beta * SigmaF / eta_i));
			else
				rho_i = 1;
			end
			w_i = rho_i / (eta_i ^ 2);

			rho = rho + rho_i;
			w_square_inv = w_square_inv + w_i;

			f_hat = f_hat + w_i * mu_i;
		end
		w_square_inv = w_square_inv + Prior_factor * (1 - rho) / (beta * SigmaF)^2;
		f_hat = f_hat / w_square_inv;
		end
% 		if isnan(f_hat)
% 			f_hat = 0;
% 		end
		f_hat_set(t_step_Nr) = f_hat;
		SendTimeUsage = toc(TimerSend);
		%
		fprintf('t_step_Nr = %d, \t t_send = %6.4f \n',t_step_Nr,SendTimeUsage);
	end
	
end

%%
for UDPPort_Nr = 1:UDPPort_Quantity
	flush(UDPSend,'output');
	flush(UDPSend_Test,'output');
	flush(UDPRead_Set{UDPPort_Nr},'output');
end
clear UDPSend UDPSend_Test UDPRead_Set;
%%
figure;
subplot(2,1,1);
plot(f_hat_set(1:end));
hold on;
plot(TrainDataSet.Y(1,1:end),'--');
ylim([-5,5]);
legend('prediction','actual');
subplot(2,1,2);
sy = var(TrainDataSet.Y(1,1:end));
SMSE = cumsum((f_hat_set(1:end)' - TrainDataSet.Y(1,1:end)) .^ 2,'omitnan') ./ (1:size(TrainDataSet.Y,2)) / sy^2;
semilogy(SMSE);
%%
save(['Result\GP Asynchronous Aggregation\', ...
	DataSetName,'_',AggregationMethod,'.mat']);



