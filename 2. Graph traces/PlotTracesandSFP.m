 
 
% Create the main figure for the GUI
 fig = uifigure('Name', 'Neurons', 'Position', [50, 100, 600, 400],'WindowStyle','modal');

 % Create a button to open the file dialog
 btn = uibutton(fig, 'push', 'Text', 'Select Animal .ms ', ...
        'Position', [250, 350, 120, 30], 'ButtonPushedFcn', @(btn, event) select_MSfiles());
 


 function mainDev()
    ms = evalin('base', 'ms');
    good_neurons_indices = evalin('base', 'good_neurons_indices');
    neuronsToPlot = good_neurons_indices;
    EdgeMask=zeros(size(ms.SFPs,1),size(ms.SFPs,2),numel(neuronsToPlot));
    EdgeMaskIndx=zeros(size(ms.SFPs,1),size(ms.SFPs,2),numel(neuronsToPlot));
    AllMasks=zeros(size(ms.SFPs,1),size(ms.SFPs,2),numel(neuronsToPlot));
    mask=zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
    maskFP = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
    maskFP2 = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
    img_f = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
    centroids = [];
    se = strel('disk', 1);
    
    for i=1:size(ms.SFPs,3)
        if ismember(i,neuronsToPlot) 
            indx=find(neuronsToPlot==i);
            mask = ms.SFPs(:, :, i); 
            mask = mask.* (mask > mean(mask(mask~= 0)));
            mask = imclose(bwareaopen(mask,10),se);
            stats=regionprops(mask>0,"Centroid");
            centroids=[centroids; stats(1)];
            AllMasks(:,:,indx)=mask>0;
            EdgeMask(:,:,indx)=~edge(mask>0,'canny', [0.1 0.3]);
            EdgeMaskIndx(:,:,indx)=~EdgeMask(:,:,indx).*i;
            maskFP(mask > 0 & maskFP == 0) = i;  % Update mask
            maskFP2(mask > 0 & maskFP2 == 0) = -1;  % Update mask
    
        end
    end
    
    A=ms.FiltTraces(find(ms.FiltTraces==max(ms.FiltTraces)));
    [maxVals, maxIndices] = maxk(A(good_neurons_indices), 20);
    assignin('base','maxIndices',maxIndices);
    
    
    for a = 1:size(ms.FiltTraces, 2)
        if ismember(a,good_neurons_indices)
          aux=maskFP2.*AllMasks(:,:,find(neuronsToPlot==a)); 
          aux=find((aux<A(a) | aux<0) & aux~=0);
          maskFP2(aux)=A(a);
          maskFP(aux) = i;  % Update mask
        end
        
    end

    assignin('base','maskFP2',maskFP2);
    assignin('base','EdgeMask',EdgeMask);
    assignin('base','centroids',centroids);
    assignin('base','ms',ms);

    graficar();
    
 
    
 end  

 function graficar()
    
    ms=evalin('base','ms');
    maskFP2=evalin('base','maskFP2');
    EdgeMask=evalin('base','EdgeMask');
    centroids=evalin('base','centroids');
    maxIndices=evalin('base','maxIndices');
    
    fig1=figure('Position',[650, 100, 600, 400]);
    imagesc(maskFP2);
    colorbar;
    hold on;
    
    for a=1:size(EdgeMask,3)
        if ismember(a,maxIndices)
            [B, ~] = bwboundaries(~EdgeMask(:,:,a), 'noholes'); % Get border coordinates
            for k = 1:length(B)
                boundary = B{k};
                plot(boundary(:, 2), boundary(:, 1), 'w', 'LineWidth', 1); % Red border
                %text(centroids(a).Centroid(1)-2, centroids(a).Centroid(2), num2str(a), 'Color', 'w', 'FontSize', 5,'FontWeight','bold');
            end
        end
    end
    title('Spatial Footprints ['+string(length(maxIndices))+' highlighted neurons]');
    hold off;
    
    fig2=figure('Position',[650, 100, 600, 400]);
    hold on;
    for i = 1:length(maxIndices)
        plot(ms.FiltTraces(:,maxIndices(i)) + (i)*1, 'DisplayName', ['Neurona ' num2str(i)]);
    end
    title('FiltTraces');
    xlabel('Tiempo (frames)');
    ylabel('Intensidad (offset por neurona)');
    legend('show');
    hold off;
    assignin('base','fig1',fig1);
    assignin('base','fig2',fig2);
    

   

 end
    
 function select_neuron()
    fig = evalin('base', 'fig');
    maxIndices = evalin('base', 'maxIndices');
    dropdown = uidropdown(fig, ...
    'Position', [250, 150, 100, 30], ...% Posición y tamaño del desplegable
    'Items', string(1:length(maxIndices)), ... % Opciones del desplegable
    'ValueChangedFcn', @(src, event) valueChanged(src)); % Función a ejecutar cuando cambia la selección
    assignin('base','dropdown',dropdown);
   

    

    
 end
 function finish()
    
    fig1=evalin('base','fig1');
    fig2=evalin('base','fig2');
    [filename, pathname] = uiputfile('*.tif', 'Save SPFs as');
    if isequal(filename,0) || isequal(pathname,0)
        disp('User canceled the save operation.');
    else
        fullpath = fullfile(pathname, filename);
        disp(['Saving file to: ', fullpath]);
        
        % Example: Save a variable to a .mat file
        
        saveas(fig1,fullpath);
    end 
    [filename, pathname] = uiputfile('*.pdf', 'Save Traces as');
    if isequal(filename,0) || isequal(pathname,0)
        disp('User canceled the save operation.');
    else
        fullpath = fullfile(pathname, filename);
        disp(['Saving file to: ', fullpath]);
        
        % Example: Save a variable to a .mat file
        
        saveas(fig2,fullpath);
    end 

    close all;
    fig=evalin('base','fig');
    close(fig);
 
 end

 function valueChanged(src)
    ms = evalin('base', 'ms');
    dropdown = evalin('base','dropdown');
    maxIndices = evalin('base', 'maxIndices');
    
    maxIndices(str2double(src.Value))=[];
    assignin('base', 'maxIndices', maxIndices);
    disp("HOLA")
    close Figure 1;
    close Figure 2
    graficar();
    dropdown.Visible='off';
 end

 function eliminateNeuron()
    fig = evalin('base', 'fig');
    select_neuron();
 end

 function run_code(~)
    % Obtener las variables desde el workspace base
    % ms = evalin('base', 'ms');
    % good_neurons_indices = evalin('base', 'good_neurons_indices');
    % mainDev(good_neurons_indices,ms);
    fig = evalin('base', 'fig');
    mainDev();
    btn4 = uibutton(fig, 'push', 'Text', 'Finish ', ...
             'Position', [190, 200, 120, 30], 'ButtonPushedFcn', @(btn, event) finish());
         
    
    btn5 = uibutton(fig, 'push', 'Text', 'Eliminate Neuron ', ...
             'Position', [320, 200, 120, 30], 'ButtonPushedFcn', @(btn, event) eliminateNeuron());
        
 end


function select_MSfiles(~)
    fig = evalin('base', 'fig');
    % Abre una ventana del explorador de archivos
    [file, path] = uigetfile('*.mat', 'Seleccione el archivo ms del animal');
    
    % Verifica si el usuario seleccionó un archivo o canceló
    if isequal(file, 0)
        disp('No se seleccionó ningún archivo.');
    else
        % Carga el archivo seleccionado como una variable en MATLAB
        full_file_path = fullfile(path, file);
        ms=load(full_file_path, 'ms'); % Asegúrate de que el archivo contenga una variable 'AnimalConfig'
        assignin('base','ms',ms.ms);
        btn2 = uibutton(fig, 'push', 'Text', 'Select Good Neurons', ...
        'Position', [250, 300, 120, 30], 'ButtonPushedFcn', @(btn, event) select_GNfiles());
    end
    
    
end

function select_GNfiles(~)
    fig = evalin('base', 'fig');
    [file, path] = uigetfile('*.mat', 'Seleccione el archivo good_neurons del animal');
    
     % Verifica si el usuario seleccionó un archivo o canceló
     if isequal(file, 0)
        disp('No se seleccionó ningún archivo.');
     else
        % Carga el archivo seleccionado como una variable en MATLAB
        full_file_path = fullfile(path, file);
         good_neurons_indices=load(full_file_path, 'good_neurons_indices'); % Asegúrate de que el archivo contenga una variable 'AnimalConfig'
        assignin('base','good_neurons_indices',good_neurons_indices.good_neurons_indices);
         btn3 = uibutton(fig, 'push', 'Text', 'Run Code', ...
        'Position', [250, 250, 120, 30], 'ButtonPushedFcn', @(btn, event) run_code());
     end
end
    