function fx = GP_AsynAggregation_Control_UnknownFunction(x)
x1 = x(1,:);
x2 = x(2,:);

fx = 1 + 0.1 * x1 .* x2 + 0.5 * cos(x2) - 10 * sin(5 * x1) + 1 ./ (2 * (1 + exp(- x2 / 10)));
% fx = 1 - sin(x1) + 1 ./ (2 * (1 + exp(- x2 / 10)));
% fx = 0 * fx;
end