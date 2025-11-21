function [out, mn, mx] = F_Norm(raw)
%F_NORM Normalize each column with values 0 to 1

    mx = max(raw.').';
    mn = min(raw.').';
    out = (raw-mn)./(mx-mn); 


end

