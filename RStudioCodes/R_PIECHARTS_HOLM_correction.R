# 1) Crear la tabla de contingencia

data <- matrix(c(94,90,67,112,81,169),
               nrow = 3, byrow = TRUE)
colnames(data) <- c("Veh", "Cort")
rownames(data) <- c("Active", "Inactive", "Neutral")
print(data)
# ------------------------------
# 2) Test chi-cuadrado y residuos estandarizados
chi_square_result <- chisq.test(data, correct = FALSE)
chi_square_result

# Extraer los residuos estandarizados (z-scores)
stdres <- chi_square_result$stdres
stdres  # Matriz de z-values

# ------------------------------
# 3) Convertir z-values a p-values (bilaterales)

# Para cada celda, p = 2 * P(Z > |z|)
pvals <- 2 * pnorm(-abs(stdres))
# 4) Aplicar corrección de Holm

# a) Convertir la matriz de p en un vector
pvals_vector <- as.vector(pvals)

# b) Ajuste de p-values vía método "holm"
pvals_holm <- p.adjust(pvals_vector, method = "holm")

# c) Volver a dar forma de matriz (para ver cada celda)
pvals_holm_matrix <- matrix(pvals_holm,
                            nrow = nrow(stdres),
                            ncol = ncol(stdres),
                            byrow = FALSE,
                            dimnames = dimnames(stdres))

pvals_holm_matrix
#------------------------------------------------
# 5) Asignar asteriscos según rangos de p-valor

# Definimos una función auxiliar que asigna los asteriscos
star_code <- function(pval) {
  if (pval < 0.001) {
    return("***")
  } else if (pval < 0.01) {
    return("**")
  } else if (pval < 0.05) {
    return("*")
  } else {
    return("")
  }
}

# Aplicamos la función a cada celda de la matriz pvals_holm_matrix
asterisks_matrix <- matrix(
  sapply(pvals_holm_matrix, star_code),
  nrow = nrow(pvals_holm_matrix),
  ncol = ncol(pvals_holm_matrix),
  dimnames = dimnames(pvals_holm_matrix)
)

asterisks_matrix