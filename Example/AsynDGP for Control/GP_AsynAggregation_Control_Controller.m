function u = GP_AsynAggregation_Control_Controller(t,x,mu,A,w)
K1 = 2;
K2 = 10;

x1 = x(1,:);x2 = x(2,:);
if nargin < 4
	[xr,dxr] = GP_AsynAggregation_Control_TrackingReference(t);
else
	[xr,dxr] = GP_AsynAggregation_Control_TrackingReference(t,A,w);
end
xr1 = xr(1,:);xr2 = xr(2,:);
e1 = x1 - xr1;e2 = x2 - xr2;

u = dxr - mu - K1 * e1 - K2 * e2;
end