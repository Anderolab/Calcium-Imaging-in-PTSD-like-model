function [Output] = F_SelectEpoch_lei(SourceTable, Variable, Epoch, Task, Pre_Frames, Post_Frames, MaxFrames)
%F_SELECTEPOCH Summary of this function goes here
%   Detailed explanation goes here

% Getting the variable
Data = SourceTable.(Variable);

% Storage array
Segment = [];

% If buffer frames are wanted
if isempty(Pre_Frames) == false
    ep_ix = string(Task.Titles) == Epoch(1);
    sec = Data(:, ...
        (Task.Start(ep_ix)-Pre_Frames):(Task.Start(ep_ix)-1));
    Segment = [Segment, sec];
end

% Looping per session
    for ep = Epoch 
        
        ep_ix = string(Task.Titles) == ep;
        ep_str = string(ep);
        
        startFrame = Task.Start(ep_ix)
        endFrame = min(Task.Start(ep_ix) + Task.Frames(ep_ix) - 1, MaxFrames); % Asegúrate de no exceder MaxFrames
        
        % Asegurar que los frames no excedan el tamaño de Data
        startFrame = min(startFrame, size(Data, 2));
        endFrame = min(endFrame, size(Data, 2));

        sec = Data(:, startFrame:endFrame);
        Segment = [Segment, sec];
        if ep_str == string(Epoch(1))
        disp(['Procesando el primer episodio: ', ep_str]);
        disp(Epoch)
        disp(ep_ix)
        disp(startFrame)
        disp(endFrame)
        disp(sec)
        end
    end

% If buffer frames are wanted
if isempty(Post_Frames) == false
    ep_ix = string(Task.Titles) == Epoch(end);
    sec = Data(:, ...
        (Task.Start(ep_ix)+Task.Frames(ep_ix)-1):...
        (Task.Start(ep_ix)+Task.Frames(ep_ix)+Post_Frames));
    Segment = [Segment, sec];
end

 % Ajuste para igualar el número máximo de frames
if size(Segment, 2) < MaxFrames
    Segment = [Segment, nan(size(Segment, 1), MaxFrames - size(Segment, 2))];
end

% Generating table output
Output = table();

% Populating the output table
vars = string(SourceTable.Properties.VariableNames);
vars = vars(vars ~= Variable);
for v = vars
    Output.(v) = SourceTable.(v);
end

% Saving the segment
title = Variable;% strcat(join(Episode, ' + '), " (", Variable, ")");
Output.(title) = Segment;
end
