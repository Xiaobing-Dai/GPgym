function f_hat = GP_AsynAggregation_POE(InformationSet,eta_set)
InformationQuantity = size(InformationSet,2);
w_square_inv = 0;
f_hat = 0;
for InformationNr = 1:InformationQuantity
	mu_i = InformationSet(1,InformationNr);
	eta_i = eta_set(InformationNr);
	w_i = 1 / (eta_i ^ 2);
	w_square_inv = w_square_inv + w_i;
	f_hat = f_hat + w_i * mu_i;
end

f_hat = f_hat / w_square_inv;
end