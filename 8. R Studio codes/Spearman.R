# ==================================LOAD LIBRARIES========================================================
library(tidyverse)
library(reshape2)
library(ggplot2)
library(readxl)

#======================================WIRTE PATH==========================================================
data <- read_excel("C:/Users/1627858/OneDrive - UAB/Escritorio/datos definitivos conducta/PCA/PCA_SPSS.xlsx")

# Define your variables
pcs_vars <- c("RC1", "RC2", "RC3", "RC4", "RC5", "RC6")
genes_vars <- c("PPM1F 2h", "PPM1F 1day", "PPM1F 5day", "CAMKIIg 2h", "CAMKIIg 1day", "CAMKIIg 5day")

# --- Function to compute the correlation matrix and p-values ---
correlation_matrix <- function(df1, df2, method = "spearman") {
  cors <- matrix(NA, nrow = ncol(df1), ncol = ncol(df2))
  pvals <- matrix(NA, nrow = ncol(df1), ncol = ncol(df2))
  
  for (i in 1:ncol(df1)) {
    for (j in 1:ncol(df2)) {
      test <- cor.test(df1[[i]], df2[[j]], method = method)
      cors[i, j] <- test$estimate
      pvals[i, j] <- test$p.value
    }
  }
  
  rownames(cors) <- colnames(df1)
  colnames(cors) <- colnames(df2)
  rownames(pvals) <- colnames(df1)
  colnames(pvals) <- colnames(df2)
  
  return(list(correlation = cors, pvalue = pvals))
}

# --- Correlation method ---
method_to_use <- "spearman"


#======================================CORRELATIONS SPLITTED BY SEX========================================

for (sex in unique(data$Sex)) {
  cat("Processing sex:", sex, "\n")
  
  data_sub <- data %>% filter(Sex == sex)
  if (nrow(data_sub) == 0) {
    cat("There is no data for this sex.\n")
    next
  }
  
  pcs   <- data_sub %>% select(all_of(pcs_vars))
  genes <- data_sub %>% select(all_of(genes_vars))
  
  res   <- correlation_matrix(pcs, genes, method = method_to_use)
  cors  <- res$correlation
  pvals <- res$pvalue
  
  df_melt <- melt(cors)
  colnames(df_melt) <- c("PC", "Gene", "Correlation")
  df_melt$pval <- as.vector(pvals)
  df_melt$pval <- as.numeric(df_melt$pval)
  
  df_melt$Significant <- cut(df_melt$pval,
                             breaks = c(-Inf, 0.001, 0.01, 0.05, Inf),
                             labels = c("***", "**", "*", ""),
                             right = TRUE)
  
  print(
    ggplot(df_melt, aes(x = Gene, y = PC, fill = Correlation)) +
      geom_tile(color = "white") +
      scale_fill_gradientn(
        colours = c("#053061", "#2166AC", "#4393C3", "white", "#DC6CD6", "#EB2E80", "#F1026A"),
        limits = c(-1, 1),
        name = "Correlation"
      ) +
      geom_text(aes(label = Significant), color = "black", size = 14) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 18),
        axis.text.y = element_text(size = 18),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.title = element_text(size = 18),
        legend.text = element_text(size = 16),
        legend.key.height = unit(2, "cm"),
        legend.key.width = unit(0.5, "cm")
      ) +
      ggtitle(paste("SPEARMAN CORRELATION -", sex, " | n =", nrow(data_sub))) +
      scale_y_discrete(limits = rev(pcs_vars))
  )
}
