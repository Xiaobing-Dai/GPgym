function dx = GP_AsynAggregation_Control_Dynamics(t,x,mu,A,w)
fx = GP_AsynAggregation_Control_UnknownFunction(x);
if nargin < 4
	u = GP_AsynAggregation_Control_Controller(t,x,mu);
else
	u = GP_AsynAggregation_Control_Controller(t,x,mu,A,w);
end

dx1 = x(2,:);
dx2 = fx + u;
dx = [dx1;dx2];
end