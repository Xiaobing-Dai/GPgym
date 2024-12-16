function GP_AsynAggregation_Control_TestFunc(AggregationMethod,MonteCarloNr)
%%
A = rand(1) * 0.2 + 0.4;
w = rand(1) * 2 + 3;
%% Aggregation Option
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
%% Build UDP Communication
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
DataSetName = 'Control';
load(['Specified Model\GP Asynchronous Aggregation\DataSet_',DataSetName,'.mat'], ...
	'HyperparameterSet','x_dim','y_dim');
%%
t_start = 0;
t_step = 0.02;
t_end = 20;
t_set = t_start:t_step:t_end;
x_set = nan(x_dim,numel(t_set));
x0 = rand(x_dim,1);
x_set(:,1) = x0;
%%
beta = 1;
SigmaL = HyperparameterSet{1}.SigmaL;
SigmaF = HyperparameterSet{1}.SigmaF;
SigmaN = HyperparameterSet{1}.SigmaN;
alpha = 1;
MaxInformationQuantity = 20;
InformationSet = nan(numel(SigmaL) + 2,MaxInformationQuantity);
InformationQuantity = 0;
SavedInformationNrSet = nan(1,MaxInformationQuantity);
f_hat_set = nan(numel(t_set),1);
Lf = Lf_factor * exp(-1/2) * SigmaF^2 / 1;
eta_set = nan(1,MaxInformationQuantity);
%%
TimerGeneral = tic;
Timer_t_start = toc(TimerGeneral);
t_Nr = 1;
fprintf([AggregationMethod,' ',num2str(MonteCarloNr),': ']);
ProgressPercentNr = 0;
while true
	if toc(TimerGeneral) - Timer_t_start >= (t_Nr + 1) * t_step
		x_now = x_set(:,t_Nr);
		% Send GP Data Pair
		y_now = GP_AsynAggregation_Control_UnknownFunction(x_now) + ...
			SigmaN * randn(1);
		write(UDPSend,[x_now;y_now],'single', ...
			'226.0.0.1',UDPSend.UserData);
		
		GP_AsynAggregation_AggregationScript;
		if isnan(f_hat)
			f_hat = 0;
		end
		f_hat_set(t_Nr) = f_hat;

		[~,x_temp] = ode45(@(t,x)GP_AsynAggregation_Control_Dynamics(t,x,f_hat,A,w), ...
			[t_Nr-1,t_Nr] * t_step,x_now);
		x_set(:,t_Nr+1) = x_temp(end,:)';

		t_Nr = t_Nr + 1;
		if t_Nr >= ProgressPercentNr * numel(t_set) / 50
			fprintf('=');
			ProgressPercentNr = ProgressPercentNr + 1;
		end
		if t_Nr >= numel(t_set)
			break;
		end
	end
end
fprintf('#\n');
%% Send Terminal Instruction
for TerminalInstructionSendTimeNr = 1:50
	write(UDPSend,-1,'single', ...
		'226.0.0.1',UDPSend.UserData);
	pause(0.02);
end
%%
flush(UDPSend,'output');
flush(UDPSend_Test,'output');
for UDPPort_Nr = 1:UDPPort_Quantity
	flush(UDPRead_Set{UDPPort_Nr},'output');
end
clear UDPSend UDPSend_Test UDPRead_Set;
%%
[xr_set,~] = GP_AsynAggregation_Control_TrackingReference(t_set,A,w);
% plot(t_set,x_set,'r-', ...
% 	t_set,xr_set,'b--')
%%
e_set = x_set - xr_set;
norm_e_set = sqrt(sum(e_set .^ 2,1));
y_set = GP_AsynAggregation_Control_UnknownFunction(x_set);
%%
warning off;
try
	mkdir(['Result\GP Asynchronous Aggregation\Control\',AggregationMethod]);
catch
end
save(['Result\GP Asynchronous Aggregation\Control\',AggregationMethod,'\', ...
	DataSetName,' ',num2str(MonteCarloNr),'.mat']);
warning on;
end




