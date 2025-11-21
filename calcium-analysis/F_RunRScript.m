function [Out] = F_RunRScript(script)

threshold = 'FALSE'; %Needed to run correctly the R code 
command = sprintf('"C:\Users\1627858\AppData\Local\Programs\R\R-4.4.1\bin\Rscript "%s" "%s" %s', script, threshold) 
system(command)
disp(script)
end 
