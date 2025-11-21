Bdycam_Path = "G:\Ex3_BLA\Behaviour videos\IMO\";
list = dir(Bdycam_Path);
list = string({list.name});
for v_ix = 3:length(list)
    path = convertStringsToChars(Bdycam_Path + list(v_ix))
    savepath = strcat(path(1:end-3), 'mat');
    video = VideoReader(path);

    % Extracting and binning movement
    [Glob_Mov, EdgePixels] = F_GetGlobalMovement(video);

    % Saving
    Mov = [];
    Mov.GlobalMovement = Glob_Mov;
    Mov.EdgePixels = EdgePixels;
    save(savepath, "Mov")

end


