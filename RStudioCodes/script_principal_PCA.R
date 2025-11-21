paquetes <- c("readxl", "missMDA", "FactoMineR", "factoextra", "ggplot2", 
              "ggpubr", "dplyr", "emmeans", "car")
install_if_missing <- function(p) {
  if (!require(p, character.only = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}
invisible(lapply(paquetes, install_if_missing))
source("C:/Users/1627858/OneDrive - UAB/Escritorio/datos definitivos conducta/PCA/funciones_anova.R")
source("C:/Users/1627858/OneDrive - UAB/Escritorio/datos definitivos conducta/PCA/funciones_pca.R")
source("C:/Users/1627858/OneDrive - UAB/Escritorio/datos definitivos conducta/PCA/analisis_general.R")

ruta <- "C:/Users/1627858/OneDrive - UAB/Escritorio/datos definitivos conducta/PCA/PCA_SPSS.xlsx"
datos <- cargar_datos(ruta)
datos <- preparar_factores(datos)
datos <- crear_grupo_combinado(datos)
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

# Screeplot clásico
plot_scree(pca_result$eigenvalues)
# Biplot sex
scores_varimax$Sex <- datos$Sex
ggplot(scores_varimax, aes(x = RC1, y = RC2, color = Sex)) +
  geom_point(size = 5, alpha = 0.8) +
  stat_ellipse(type = "norm", linetype = 2) +
  theme_minimal() +
  labs(
    title = "Scatter plot by sex",
    x = "RC1",
    y = "RC2",
    color = "Sex"
  ) +
  scale_color_manual(values = c(
    "Male" = "#1f77b4",   
    "Female" = "#DDD127" 
  )) +
  theme(
    axis.text = element_text(size = 22),        # Tamaño de números en los ejes
    axis.title = element_text(size = 24),       # Tamaño de etiquetas "RC1", "RC2"
    plot.title = element_text(size = 24, hjust = 0.5),  # Tamaño y centrado del título
    legend.text = element_text(size = 24),
    legend.title = element_text(size = 24)
  )



# ==============GRAFICO DE DISPERSION============
# Combinar scores con grupos
scores_varimax$GrupoCombinado <- datos$GrupoCombinado

# Gráfico de dispersión PC1 vs PC2
ggplot(scores_varimax, aes(x = RC1, y = RC2, color = GrupoCombinado)) +
  geom_point(size = 5, alpha = 0.8) +
  stat_ellipse(type = "norm", linetype = 2) +
  theme_minimal() +
  labs(
    title = "Scatter plot",
    x = "RC1",
    y = "RC2",
    color = "Grupo"
  ) +
  scale_color_manual(values = c(
    "Control.Vehicle" = "#66B56B38",
    "Control.Cort"    = "#D0E897FF",
    "IMO.Vehicle"     = "#7F669866",
    "IMO.Cort"        = "#FFB2BFFF"
  ))

#========== CARGAS VARIMAX ================

n_comps <- pca_result$ncp_kaiser
plots_varimax <- lapply(1:n_comps, function(i) plot_cargas_varimax(pca_result$pca_varimax, i))
library(ggpubr)
ggarrange(plotlist = plots_varimax, ncol = 2, nrow = ceiling(n_comps / 2))


niveles_orden <- c("Control.Vehicle", "Control.Cort", "IMO.Vehicle", "IMO.Cort")
colores_barras <- c(
  "Control.Vehicle" = "#3CB56BFF",
  "Control.Cort"    = "#D0E897FF",
  "IMO.Vehicle"     = "#7F669866",
  "IMO.Cort"        = "#FFB2BFFF"
)
colores_puntos <- c(
  "Control.Vehicle" = "#3CB56BFF",
  "Control.Cort"    = "#ABD649FF",
  "IMO.Vehicle"     = "#7F6698FF",
  "IMO.Cort"        = "#FF5B14FF"
)

# Ejecuta el análisis
plots_general <- analisis_general(coord_pca, niveles_orden, colores_barras, colores_puntos)

head(scores_varimax)
View(scores_varimax)
write.table(scores_varimax, "scores_varimax.csv", sep = ";", dec = ",", row.names = TRUE)
#============ Muestra los gráficos=============
ggarrange(plotlist = plots_general, ncol = 2, nrow = 3, common.legend = TRUE, legend = "bottom")

# graficos de barras: 

barplots_varimax <- function(data, niveles_orden, colores_barras) {
  message("\n============== Gráficos de barras de medias ==============")
  
  data$GrupoCombinado <- factor(data$GrupoCombinado, levels = niveles_orden)
  plots <- list()
  
  for (i in 1:5) {
    comp <- paste0("RC", i)  # <- aquí cambio PC por RC
    
    p <- ggplot(data, aes_string(x = "GrupoCombinado", y = comp, fill = "GrupoCombinado")) +
      stat_summary(fun = mean, geom = "bar", color = "black", width = 0.7) +
      stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2, color = "black") +
      scale_fill_manual(values = colores_barras) +
      theme_minimal() +
      labs(
        title = paste("Media ± SEM - RC", i),
        x = "Grupo combinado",
        y = paste0("Score medio RC", i)
      ) +
      theme(
        plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none"
      )
    
    plots[[i]] <- p
  }
  
  return(plots)
}

# Luego creas la lista y la muestras:

barplots_general <- barplots_varimax(coord_pca, niveles_orden, colores_barras)

ggarrange(plotlist = barplots_general, ncol = 2, nrow = 3, common.legend = TRUE, legend = "bottom")

# Extrae el PCA rotado para poder guardarlo

pca_result <- hacer_pca(datos, vars_pca)
pca_varimax     <- pca_result$pca_varimax



