function [UDPSend,UDPRead_Set] = GP_AsynAggregation_UDPSet_Server(UDPPort_Quantity)
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
end