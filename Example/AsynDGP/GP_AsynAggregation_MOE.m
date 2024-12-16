function f_hat = GP_AsynAggregation_MOE(InformationSet)
InformationQuantity = size(InformationSet,2);
f_hat = 0;
for InformationNr = 1:InformationQuantity
	mu_i = InformationSet(1,InformationNr);
	f_hat = f_hat + mu_i;
end
f_hat = f_hat / InformationQuantity;

end