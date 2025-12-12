% Setting the animal range
Animals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; % Needs to include later on
    % [...] incomplete datasets
IMOs = ["_E", "_L"]; % Data epochs
n_gaussians = 5; % Validation will be required - Lower priority
rec_freq = 60; % FPS
cropping_bins = 2; % In seconds
safeguard_secs = 10; % Number of seconds before and after handling that
    % [...] will not be analysed for safety purpouses


%% Loading the data and resampling the movement to fit CaIM
mov_scores = []; % Empty storage to generate global motion model
edge_pixels = []; % Empty sotrage to generate global % edge model
for an_ix = Animals
    for imo_ix = IMOs
        ms_filename = strcat("H:\DLC\IMO\IMO_ms\ms_M", num2str(an_ix),...
            imo_ix, ".mat"); % Identify the correct file
        bcam_filename = strcat("H:\DLC\IMO\IMO_Mov\BehavVideo_M", num2str(an_ix),...
            imo_ix, ".mat"); % Identify the correct file
        load(bcam_filename) % As Mov
        load(ms_filename) % As ms

        if length(Mov.GlobalMovement) ~= ms.numFrames

            Mov_ = F_CompressResample(Mov.GlobalMovement, ms.numFrames);
                % Compressed movement data for current iteration
            Edgs_ = F_CompressResample(Mov.EdgePixels, ms.numFrames);
                % Compressed edge data for current iteration

        else
            Mov_ = Mov.GlobalMovement;
            Edgs_ = Mov.EdgePixels;
        end

        % Denoising
        Mov_ = [wdenoise(Mov_(1:end), 10)]; % Now denoised
        Edgs_ = [wdenoise(Edgs_(1:end), 10)]; % Now denoised
        mov_scores = [mov_scores, Mov_]; % Saving
        edge_pixels = [edge_pixels, Edgs_]; % Saving
    end
end

%% Fitting the model and creating the threshold
[mov_threshold, edge_threshold] = ...
    F_ExtractCroppingThresholds(mov_scores, edge_pixels, 2);
        % Locally generated function returns the thresholds for movement
        % and %edge data given gaussian mixture fitting.

%% Cropping each ms and behaviour file

for an_ix = Animals
    for imo_ix = IMOs
        % 1 - Setting the search paths
        ms_filename = strcat("H:\DLC\IMO\IMO_ms\ms_M", num2str(an_ix),...
             imo_ix, ".mat"); % Identify the correct file
        bcam_filename = strcat("H:\DLC\IMO\IMO_Mov\BehavVideo_M", num2str(an_ix),...
             imo_ix, ".mat"); % Identify the correct file
        save_filename = strcat("H:\DLC\IMO\IMO_Crop\IMO_M", num2str(an_ix),...
            imo_ix, ".mat"); % Storage

        % 2 - Loading the datasets
        load(bcam_filename) % As Mov
        load(ms_filename) % As ms

        % 3 - Correcting the frame drift if required
        if length(Mov.GlobalMovement) ~= ms.numFrames

            Mov_ = F_CompressResample(Mov.GlobalMovement, ms.numFrames);
                % Compressed movement data for current iteration
            Edgs_ = F_CompressResample(Mov.EdgePixels, ms.numFrames);
                % Compressed edge data for current iteration

        else
            Mov_ = Mov.GlobalMovement;
            Edgs_ = Mov.EdgePixels;
        end

        % 4 - Denoising using wafelet function
        Mov_ = [wdenoise(Mov_(1:end), 10)]; % Now denoised
        Edgs_ = [wdenoise(Edgs_(1:end), 10)]; % Now denoised


        % 5 - Binning the movement and edge data

            % 5.1 -  Removing the tail of each trial
            end_ = floor(length(Mov_)/(rec_freq*cropping_bins)) * ...
                (rec_freq*cropping_bins); % Index of last frame to consider

            % 5.2 - Binning
            binned_mov = resample(Mov_(1:end_), 1, rec_freq*cropping_bins);
                % Movement binned to %cropping_bins% bin widths
            binned_edges = resample(Edgs_(1:end_), 1, ...
                rec_freq*cropping_bins);
                % Edge (%) binned to %cropping_bins% bin widths

        % 6 - Identifying the clear dysrupted/homecage frames
        handle_frames = find(repelem(binned_mov > mov_threshold, ...
            rec_freq*cropping_bins) == 1);
            % Frames where animals are being handled
        

        % 7 -  Identifying frames contiguous to the oultiers as a
                % safeguarding buffer

        safeguards = []; % Handling + safeguard frames

        
        for sec = -rec_freq*safeguard_secs:rec_freq*safeguard_secs
            safeguards = [safeguards, handle_frames+sec];
        end
        
        safeguards = unique(safeguards(safeguards > 0 & ...
            safeguards <= end_));
            % Now only relevant frames

        % 8 - Defining the outlier periods
        handling = zeros(1, end_); % Handling and safeguard binarised
        handling(safeguards) = 1; % Now populated

        % 9 - Identifying frames above the threshold
        edge_outl = find(repelem(binned_edges > edge_threshold, ...
            rec_freq*cropping_bins) == 1); % Homecage frames
        homecage_frames = setdiff(edge_outl, safeguards);
        homecage = zeros(1, end_); % Binarised homecage frames
        homecage(homecage_frames) = 1; % Now populated

        % 10 - Finding longest uninterrupted interval
        exclude_frames = 1-homecage + handling; % Boolean to all 
            % [...] excluding frames
        exclude_frames(end) = exclude_frames(end) == 1; % Adding end cap
        change = find(diff([0; exclude_frames.'; 0]) ~= 0);
            % Frames where a value changes
        lens = [change(2:end); change(end)]-change;
            % Lengths of each repeat
        max_ix = find(lens == max(lens));
            % Index of the longest constant repeats
        start_ix = change(max_ix); % Start of the longest constant repeat
        max_len = lens(max_ix); % Length of the longest constant repeat
        analyse_range = start_ix:(start_ix+max_len-1); % Range of analysis

        % 11 - Generating the saving datasets and saving
        IMO.RawTraces = ms.RawTraces(analyse_range, :);
        IMO.FiltTraces = ms.FiltTraces(analyse_range, :);
        IMO.Movement = Mov_(analyse_range);
        save(save_filename, 'IMO');

    end
end