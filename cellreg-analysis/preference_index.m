% 1) Lee el archivo conservando nombres de columna exactos
inputFile = 'F:\Ex3_BLA\Calcium RESULTS\cell_reg_EPM_OF_results.xlsx';
T = readtable(inputFile, 'PreserveVariableNames', true);

% (Opcional) mira qué nombres MATLAB ha importado
disp(T.Properties.VariableNames)

% 2) Extrae fluorescencias usando paréntesis dinámicos
F_closed = T.('Mean_ROI1_EPM (close)');
F_open   = T.('Mean_ROI2_EPM (OPEN)');
F_center = T.('Mean_ROI1_OF center');
F_peri   = T.('Mean_ROI2_OF_periphery');

% 3) Calcula índices de preferencia
IP_EPM = (F_open - F_closed) ./ (F_open + F_closed);
IP_OF  = (F_center - F_peri)   ./ (F_center + F_peri);

% 4) Evita división por cero
IP_EPM(~isfinite(IP_EPM)) = NaN;
IP_OF (~isfinite(IP_OF )) = NaN;

% 5) Añade columnas y guarda
T.IP_EPM_computed = IP_EPM;
T.IP_OF_computed  = IP_OF;

[folder,name,~] = fileparts(inputFile);
outputFile = fullfile(folder, [name '_with_IP.xlsx']);
writetable(T, outputFile);

fprintf('Guardado en: %s\n', outputFile);