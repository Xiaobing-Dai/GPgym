function [xr,dxr] = GP_AsynAggregation_Control_TrackingReference(t,A,w)
if nargin < 2
	A = 0.5;
	w = 5;
end
xr1 = A * sin(w * t);
xr2 = A * w * cos(w * t);
xr = [xr1;xr2];

dxr = - A * w ^ 2 * sin(w * t);
end