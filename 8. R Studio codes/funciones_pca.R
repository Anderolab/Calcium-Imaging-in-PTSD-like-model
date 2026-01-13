library(readxl)
library(missMDA)
library(FactoMineR)
library(factoextra)
library(ggplot2)
library(dplyr)
library(psych)  

# Load data from Excel
cargar_datos <- function(ruta, hoja = 1) {
  datos <- read_excel(ruta, sheet = hoja)
  return(datos)
}

# Impute missing values and do PCA with varimax rotation method (eigenvalue > 1)
hacer_pca <- function(datos, vars_pca) {
  datos_pca <- datos[, vars_pca]

  # Impute
  n_comp_imput <- estim_ncpPCA(datos_pca, ncp.max = 10)$ncp
  imputado <- imputePCA(datos_pca, ncp = n_comp_imput)
  datos_imputados <- imputado$completeObs
  
  # Calculate correlation matrix
  R <- cor(datos_imputados)
  
  # Calculate eigenvalues
  ev <- eigen(R)$values
  eigenvalues <- data.frame(eigenvalue = ev)
  
  # Select number of components with eigenvalue > 1 (Kaiser)
  ncp_kaiser <- sum(ev > 1)
  if (ncp_kaiser < 1) ncp_kaiser <- 1  
  
  # PCA with Varimax rotation
  pca_varimax <- principal(datos_imputados, nfactors = ncp_kaiser, rotate = "varimax", scores = TRUE)
  scores_varimax <- as.data.frame(pca_varimax$scores)
  colnames(scores_varimax) <- paste0("RC", 1:ncp_kaiser)
  
  # % variance explained after rotation (equivalent to SPSS: “Rotation sums of squared loadings – % of variance”)
  var_exp_rotada_pct <- as.numeric(pca_varimax$Vaccounted["Proportion Var", ]) * 100
  var_exp_rotada_acum_pct <- as.numeric(pca_varimax$Vaccounted["Cumulative Var", ]) * 100
  
  return(list(
    datos_imputados = datos_imputados,
    pca_varimax = pca_varimax,
    scores_varimax = scores_varimax,
    ncp_kaiser = ncp_kaiser,
    eigenvalues = eigenvalues,
    var_exp_rotada_pct = var_exp_rotada_pct,
    var_exp_rotada_acum_pct = var_exp_rotada_acum_pct
  ))
}

# Prepare factors and reorder levels
preparar_factores <- function(datos) {
  datos$Treatment <- factor(datos$Treatment)
  datos$Stress <- factor(datos$Stress)
  datos$Sex <- factor(datos$Sex)
  datos$Stress <- relevel(datos$Stress, ref = "Control")
  datos$Treatment <- relevel(datos$Treatment, ref = "Vehicle")
  return(datos)
}

# Create combined variable: Stress by Treatment
crear_grupo_combinado <- function(datos) {
  datos$GrupoCombinado <- interaction(datos$Stress, datos$Treatment)
  return(datos)
}

#===================VARIMAX LOADINGS========================================================

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

#====================SCREEPLOT OF EIGENVALUES AND EXPLAINED ROTATED VARIANCE===============

plot_scree_mix <- function(eigenvalues_df, var_exp_rotada_pct) {
  
  # vector of eigenvalues (no rotated)
  ev <- eigenvalues_df$eigenvalue
  
  # in case more eigenvalues than rotated components are provided (which is normal)
  n_rot <- length(var_exp_rotada_pct)
  
  df <- data.frame(
    Component = factor(seq_along(ev), levels = seq_along(ev)),
    Eigenvalue = ev,
    RotatedPercent = c(var_exp_rotada_pct, rep(NA, length(ev) - n_rot))
  )
  
  ggplot(df, aes(x = Component, y = Eigenvalue)) +
    geom_bar(stat = "identity", fill = "#EB2E80", color = "#EB2E80", width = 0.7) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "#54c1d6", size = 2) +
    geom_text(
      aes(label = ifelse(is.na(RotatedPercent), "", paste0(round(RotatedPercent, 1), "%"))),
      vjust = -0.5, size = 5
    ) +
    theme_minimal() +
    labs(
      title = "Scree with rotated % variance labels",
      subtitle = "Bars: unrotated eigenvalues; Labels: % variance of Varimax-rotated components",
      x = "Components",
      y = "Eigenvalue"
    ) +
    ylim(0, max(df$Eigenvalue, na.rm = TRUE) * 1.5) +
    theme(
      axis.title.x = element_text(size = 18),
      axis.title.y = element_text(size = 18),
      axis.text.x = element_text(size = 16),
      axis.text.y = element_text(size = 16)
    )
}
