function y  =unwrapi(x)
% y  =unwrapi(x)
% xを0<=y<2*piの範囲にunwrapする。

y   = atan2(sin(x),cos(x));

% y   = mod(x,2*pi);