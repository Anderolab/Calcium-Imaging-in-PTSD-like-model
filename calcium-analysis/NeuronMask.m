load('C:\Users\18jos\Desktop\FEAR MEMORY\paperLeire\DLC\SI_ms\ms_M9_SI.mat','ms');

%% 


image = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
mask = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
img_f = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
img_fbin = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));



scaleFactor = 5;

videoFileName = 'C:\Users\18jos\Desktop\neuronMaskLucas.avi'; 
videoWriter = VideoWriter(videoFileName);
videoWriter.FrameRate = 30;
open(videoWriter);

videoFileName2 = 'C:\Users\18jos\Desktop\nueronColorMapLucas.avi';
videoWriter2 = VideoWriter(videoFileName2);
videoWriter2.FrameRate = 30;
open(videoWriter2);



for i = 1:size(ms.SFPs, 3)
    image = ms.SFPs(:, :, i);  % Get the current frame
    image = image .* (image > mean(image(image ~= 0)));  % Mask the image
    
    highResImg = imresize(image, scaleFactor, 'bicubic');  % Upscale image
    mask(image > 0 & mask == 0) = i;  % Update mask
end


% Loop through FiltTraces for creating the videos
for b = 1:size(ms.FiltTraces, 1)
    normFl = normalize(ms.FiltTraces(b, :), 'range');  % Normalize the traces
    maskFl = ms.FiltTraces(b,:)>0;
    % Update img_f on the GPU (this can be moved to GPU too)
    for a = 1:size(ms.FiltTraces, 2)
        img_f(mask == a) = normFl(1, a);
    end
    
    % Write the frame to video
    writeVideo(videoWriter, img_f);
    
    % Create a figure for the second video (without visible figure)
    figure('Visible', 'off');
    imagesc(img_f);
    colorbar;
    % Capture frame
    writeVideo(videoWriter2,getframe(gcf));
    close(gcf);
    
end

% Close video writers
close(videoWriter);
close(videoWriter2);
