# 1. Definir la tabla 3x2
data <- matrix(c(59,40,22,18),
               nrow = 2, byrow = TRUE)
colnames(data) <- c("Veh", "Cort")
rownames(data) <- c("Active","Neutral")
print(data)
#
# 2. Prueba global de Fisher-Freeman-Halton
global_test <- fisher.test(data)
print(global_test)

# 3. Test exacto de Fisher por fila si hay valores extremos
pvals_fisher_per_row <- numeric(nrow(data))

for (i in 1:nrow(data)) {
  # Extraemos la fila y convertimos en tabla 2x2
  sub_table <- matrix(c(data[i, "Veh"], data[i, "Cort"],
                        sum(data[-i, "Veh"]), sum(data[-i, "Cort"])),
                      nrow = 2, byrow = TRUE)
  
  # Test de Fisher exacto en la fila i
  fisher_row <- fisher.test(sub_table)
  
  # Guardamos el p-valor
  pvals_fisher_per_row[i] <- fisher_row$p.value
}

# 4. Corrección de p-valores por fila (Holm)
pvals_fisher_holm <- p.adjust(pvals_fisher_per_row, method = "holm")
names(pvals_fisher_holm) <- rownames(data)

# Función para asignar asteriscos según el p-valor
asterisk_code <- function(pval) {
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

# Aplicamos la función a cada p-valor ajustado de Fisher por fila
asterisks_fisher <- sapply(pvals_fisher_holm, asterisk_code)

# 5. Mostrar resultados con asteriscos
cat("\n🔹 P-valores ajustados de Fisher por fila:\n")
print(pvals_fisher_holm)

cat("\n🔹 Asteriscos por fila (según p-valor ajustado de Fisher por fila):\n")
print(asterisks_fisher)
