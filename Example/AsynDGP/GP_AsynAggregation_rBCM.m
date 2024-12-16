function f_hat = GP_AsynAggregation_rBCM(InformationSet,eta_set,eta_prior)
InformationQuantity = size(InformationSet,2);
rho = 0;
w_square_inv = 0;
f_hat = 0;
for InformationNr = 1:InformationQuantity
	mu_i = InformationSet(1,InformationNr);
	eta_i = eta_set(InformationNr);
	rho_i = max(0,log(eta_prior / eta_i));
	w_i = rho_i / (eta_i ^ 2);
	rho = rho + rho_i;
	w_square_inv = w_square_inv + w_i;
	f_hat = f_hat + w_i * mu_i;
end

w_square_inv = w_square_inv + (1 - rho) / (eta_prior ^ 2);
f_hat = f_hat / w_square_inv;

end