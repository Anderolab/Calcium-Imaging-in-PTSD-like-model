library(readxl)
library(missMDA)
library(FactoMineR)
library(factoextra)
library(ggplot2)
library(dplyr)
library(psych)  

# Cargar datos desde Excel
cargar_datos <- function(ruta, hoja = 1) {
  datos <- read_excel(ruta, sheet = hoja)
  return(datos)
}

# Imputar datos faltantes y hacer PCA con rotación Varimax y número óptimo de componentes (eigenvalue > 1)
hacer_pca <- function(datos, vars_pca) {
  datos_pca <- datos[, vars_pca]

  # Estimar número óptimo de componentes para imputación
  n_comp_imput <- estim_ncpPCA(datos_pca, ncp.max = 10)$ncp
  imputado <- imputePCA(datos_pca, ncp = n_comp_imput)
  datos_imputados <- imputado$completeObs
  
  # Calcular matriz de correlación
  R <- cor(datos_imputados)
  
  # Calcular eigenvalues manualmente
  ev <- eigen(R)$values
  eigenvalues <- data.frame(eigenvalue = ev)
  
  # Seleccionar número componentes con eigenvalue > 1 (criterio Kaiser)
  ncp_kaiser <- sum(ev > 1)
  if (ncp_kaiser < 1) ncp_kaiser <- 1  # mínimo 1 componente
  
  # PCA con rotación Varimax usando psych::principal
  pca_varimax <- principal(datos_imputados, nfactors = ncp_kaiser, rotate = "varimax", scores = TRUE)
  scores_varimax <- as.data.frame(pca_varimax$scores)
  colnames(scores_varimax) <- paste0("RC", 1:ncp_kaiser)
  
  return(list(
    datos_imputados = datos_imputados,
    pca_varimax = pca_varimax,
    scores_varimax = scores_varimax,
    ncp_kaiser = ncp_kaiser,
    eigenvalues = eigenvalues
  ))
}

# Preparar factores y reordenar niveles
preparar_factores <- function(datos) {
  datos$Treatment <- factor(datos$Treatment)
  datos$Stress <- factor(datos$Stress)
  datos$Sex <- factor(datos$Sex)
  datos$Stress <- relevel(datos$Stress, ref = "Control")
  datos$Treatment <- relevel(datos$Treatment, ref = "Vehicle")
  return(datos)
}

# Crear variable combinada Stress x Treatment
crear_grupo_combinado <- function(datos) {
  datos$GrupoCombinado <- interaction(datos$Stress, datos$Treatment)
  return(datos)
}

plot_cargas_varimax <- function(pca_varimax, pc_num) {
  cargas <- pca_varimax$loadings[, pc_num]
  nombres <- rownames(pca_varimax$loadings)
  
  df <- data.frame(
    Variable = nombres,
    Loading = cargas,
    Contribution = abs(cargas)
  )
  
  df <- df[order(df$Contribution, decreasing = TRUE), ]
  df$Variable <- factor(df$Variable, levels = df$Variable)
  
  ggplot(df, aes(x = Variable, y = Loading, fill = Contribution)) +
    geom_bar(stat = "identity", color = "white") +
    geom_text(aes(label = round(Loading, 2)),
              hjust = ifelse(df$Loading >= 0, -0.1, 1.1),
              size = 3.5) +
    scale_fill_gradient(low = "#54c1d6", high = "#135c95") +
    coord_flip() +
    theme_minimal() +
    labs(
      title = paste0("Rotated Varimax Loadings - RC", pc_num),
      subtitle = "Bar height = loading (pos/neg), Color = magnitude",
      x = "Variable",
      y = "Loading"
    ) +
    theme(plot.title = element_text(face = "bold")) +
    ylim(c(-1, 1))
}


plot_scree <- function(eigenvalues_df) {
  total_variance <- sum(eigenvalues_df$eigenvalue)
  
  df <- data.frame(
    Component = factor(1:nrow(eigenvalues_df)),
    Eigenvalue = eigenvalues_df$eigenvalue
  )
  
  df$PercentVariance <- 100 * df$Eigenvalue / total_variance
  
  ggplot(df, aes(x = Component, y = Eigenvalue)) +
    geom_bar(stat = "identity", fill = "#EB2E80", color = "#EB2E80", width = 0.7) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "#54c1d6", size= 2) +
    geom_text(aes(label = paste0(round(PercentVariance, 1), "%")), 
              vjust = -0.5, size = 5) +
    theme_minimal() +
    labs(
      title = "Scree Plot",
      x = "Components",
      y = "Eigenvalue"
    ) +
    ylim(0, max(df$Eigenvalue) * 1.5) +
    theme(
      axis.title.x = element_text(size = 18),  # título eje X
      axis.title.y = element_text(size = 18),  # título eje Y
      axis.text.x = element_text(size = 16),   # etiquetas eje X (ticks)
      axis.text.y = element_text(size = 16)    # etiquetas eje Y (ticks)
    )
}


# # Screeplot clásico
# plot_scree(pca_result$eigenvalues)
# 
# ## ── 1. parámetros de estandarización ────────────────────────────────
# mu  <- sapply(pca_result$datos_imputados[, vars_pca], mean)  # medias 16 × 1
# sds <- sapply(pca_result$datos_imputados[, vars_pca],  sd)   # SD    16 × 1
# 
# ## ── 2. matriz de cargas rotadas (16 × k) ────────────────────────────
# k <- pca_result$ncp_kaiser                                      # = 6
# L <- as.matrix(pca_result$pca_varimax$loadings[, 1:k])          # 'loadings' → matrix
# 
# ## ── 3. guarda para futuras sesiones ────────────────────────────────
# save(mu, sds, L, file = "PCA16_parametros.RData")
