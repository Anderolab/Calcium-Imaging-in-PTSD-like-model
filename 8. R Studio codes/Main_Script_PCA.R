#IMPORTANT READ ME: This code is used to generate plots for the PCA, please, make sure it gives the exact same result as the one conducted in SPSS

paquetes <- c("readxl", "missMDA", "FactoMineR", "factoextra", "ggplot2", 
              "ggpubr", "dplyr", "emmeans", "car")
install_if_missing <- function(p) {
  if (!require(p, character.only = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}
invisible(lapply(paquetes, install_if_missing))
source("PATH TO FUNCTION/funciones_pca.R")

# Write the path to your data 
ruta <- "`PATH TO DATA/RAWDATA.xlsx"
datos <- cargar_datos(ruta)
datos <- preparar_factores(datos)
datos <- crear_grupo_combinado(datos)
# List your variables of interest
vars_pca <- c(
  "EPM_%timeopen","EPM_Nopen","EPM_%timeclose", "EPM_OA/CAN","OF_distance","NOR_NObject", "OF_10mm",
  "NOR_%object", "SI_%juvenile", "SI_%doll", "SI_Ratio", 
  "spt", "spt_día1","fst_sec", "fst_Lat"
)

pca_result <- hacer_pca(datos, vars_pca)
datos_imputados <- pca_result$datos_imputados
scores_varimax <- pca_result$scores_varimax

coord_pca <- datos
colnames(scores_varimax) <- paste0("RC", 1:pca_result$ncp_kaiser)
for (i in 1:pca_result$ncp_kaiser) {
  coord_pca[[paste0("RC", i)]] <- scores_varimax[[i]]
}

# ======================================SCREEPLOT==========================================================

plot_scree_mix(pca_result$eigenvalues, pca_result$var_exp_rotada_pct)

# ======================================VARIMAX LOADINGS===================================================

n_comps <- pca_result$ncp_kaiser
plots_varimax <- lapply(1:n_comps, function(i) plot_cargas_varimax(pca_result$pca_varimax, i))
library(ggpubr)
ggarrange(plotlist = plots_varimax, ncol = 2, nrow = ceiling(n_comps / 2))

