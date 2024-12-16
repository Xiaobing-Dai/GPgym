%% GP_AsynAggregation_AggregationScript
%% Manage Information Set
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
%% Receive Predictions
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

%% Aggregation
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