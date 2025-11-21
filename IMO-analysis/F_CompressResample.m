function [Reconstructed] = F_CompressResample(Dataset,TargetLength)
%F_RESAMPLE Summary of this function goes here
%   Detailed explanation goes here
Reconstructed = [];
Ratio = TargetLength/length(Dataset);


for f_ix = 1:TargetLength
    imag_frame = 1+(f_ix-1)/Ratio;
    prev = floor(imag_frame);
    next = ceil(imag_frame);

    estimated = (Dataset(prev)*(imag_frame - prev) + ...
        Dataset(next)*(next - imag_frame));
    if estimated == 0
        estimated = Dataset(prev);
    end
    Reconstructed = [Reconstructed, estimated];

end

end

