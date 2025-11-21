library(ggplot2)
library(ggpubr)
library(car)
library(emmeans)
library(dplyr)

# Función para análisis ANOVA por sexo y crear gráficos con barras y puntos
analisis_por_sexo <- function(datos, sexo, niveles_orden, colores_barras, colores_puntos) {
  graficos <- list()
  cat("\n\n==============", sexo, "==============\n")
  
  for (i in 1:5) {
    comp <- paste0("PC", i)
    modelo <- lm(as.formula(paste(comp, "~ Stress * Treatment")), data = datos)
    cat("\n\n=== Modelo para", comp, "===\n")
    print(summary(modelo))
    
    if (anova(modelo)$`Pr(>F)`[3] < 0.05) {
      cat("\nRealizando post-hoc para", comp, "...\n")
      post_hoc <- emmeans(modelo, pairwise ~ Stress * Treatment, adjust = "none")
      print(post_hoc)
    }
    
    datos_graf <- datos %>%
      mutate(Grupo = interaction(Stress, Treatment)) %>%
      mutate(Grupo = factor(Grupo, levels = niveles_orden))
    
    p <- ggplot(datos_graf, aes(x = Grupo, y = .data[[comp]], fill = Grupo)) +
      stat_summary(fun = mean, geom = "bar", color = "black") +
      stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2, color = "black") +
      theme_minimal() +
      labs(
        title = paste(sexo, "-", comp),
        x = "",
        y = comp,
        fill = ""
      ) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_fill_manual(values = colores_barras)
    
    p <- p + geom_jitter(data = datos_graf, aes(x = Grupo, y = .data[[comp]], fill = Grupo),
                         width = 0.15, size = 2, shape = 21,
                         color = "black", alpha = 1, show.legend = FALSE) +
      scale_fill_manual(values = colores_puntos)
    
    graficos[[comp]] <- p
  }
  
  return(graficos)
}

# Función ANOVA 3 vías para PC y gráfico unificado con formas por sexo
library(emmeans)

plot_anova_3vias_unificado <- function(df, pc_num, niveles_orden, colores_barras, colores_puntos) {
  comp <- paste0("PC", pc_num)
  df$Sex <- factor(df$Sex, levels = c("Male", "Female"))
  df$Stress <- factor(df$Stress, levels = c("Control", "IMO"))
  df$Treatment <- factor(df$Treatment, levels = c("Vehicle", "Cort"))
  
  # Modelo con factores separados
  modelo <- aov(as.formula(paste(comp, "~ Stress * Treatment * Sex")), data = df)
  
  cat("\n\n=== ANOVA para", comp, "===\n")
  print(Anova(modelo, type = 3))
  
  # Post-hoc para interacción Stress:Treatment ignorando Sex
  emmeans_res <- emmeans(modelo, specs = pairwise ~ Stress:Treatment, adjust = "none")
  
  cat("\n\n=== Resultados Post-hoc para interacción Stress x Treatment (ignorando Sex) ===\n")
  print(emmeans_res$contrasts)
  
  # Para graficar con etiquetas legibles, podemos crear grupo combinado
  df$GrupoCombinado <- interaction(df$Stress, df$Treatment, sep = ".")
  df$GrupoCombinado <- factor(df$GrupoCombinado, levels = niveles_orden)
  
  p <- ggplot(df, aes(x = GrupoCombinado, y = .data[[comp]], fill = GrupoCombinado)) +
    stat_summary(fun = mean, geom = "bar", color = "black") +
    stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2, color = "black") +
    geom_jitter(aes(shape = Sex, fill = GrupoCombinado),
                width = 0.15, size = 2, color = "black", alpha = 1, show.legend = TRUE) +
    scale_fill_manual(values = colores_barras) +
    scale_shape_manual(values = c(Male = 21, Female = 24)) +
    theme_minimal() +
    labs(title = paste("3-way ANOVA:", comp),
         x = "Group (Stress x Treatment)",
         y = comp,
         shape = "Sex",
         fill = "") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p)
}