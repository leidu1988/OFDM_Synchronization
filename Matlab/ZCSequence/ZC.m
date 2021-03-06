function zc = ZC(N, M, shift)
%ZC Zadoff Chu sequence.
%   ZC(N, M) returns a ZC sequence.
%   N: Length of ZC sequence.
%   M: An integer relatively prime to N.

%   Authors: Neil Judson
%   Copyright 2016 Neil Judson
%   $Revision: 1.1 $  $Date: 2016/07/8 16:00:00 $

%% check input
errMsg = '';
if(N ~= fix(N)), errMsg = 'Input error: N is not an integer.'; end
if(M ~= fix(M)), errMsg = 'Input error: M is not an integer.'; end
% if(mod(N,M) == 0), errMsg = 'input error: N can be divided exactly by M.'; end
if ~isempty(errMsg), error('NeilJudson:InputCheck',errMsg); end

%%
k = 1:1:N;
if(mod(N,2) == 0)
    zc = exp(1i * pi * M * k .* k / N);
else
    zc = exp(1i * pi * M * (k-1) .* k / N);
end
zc = [zc(shift+1:end) zc(1:shift)];

end
    
