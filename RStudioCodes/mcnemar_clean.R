# =========================
# Limpieza y análisis OR -> SI
# =========================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(writexl)
})

# ---------- 1) Definición de matrices (OR -> SI) ----------
dn <- list(OR = c("active","inhibited","unresponsive"),
           SI = c("active","inhibited","unresponsive"))

FV <- matrix(c(
  0,0,9,
  0,0,0,
  9,1,66
), nrow = 3, byrow = TRUE, dimnames = dn)

FC <- matrix(c(
1,2,9,
0,0,0,
7,6,35
), nrow = 3, byrow = TRUE, dimnames = dn)

MV <- matrix(c(
  5,2,15,
  0,0,0,
  10,13,44
), nrow = 3, byrow = TRUE, dimnames = dn)

MC <- matrix(c(
  1,0,7,
  1,0,0,
  13,8,64
), nrow = 3, byrow = TRUE, dimnames = dn)

M_list <- list(FV = FV, FC = FC, MV = MV, MC = MC)

# ---------- 2) Utilidades ----------
prop_rows <- function(M) {
  sweep(M, 1, rowSums(M), "/")
}

chisq_or_fisher <- function(tab, simulate = TRUE, B = 1e5) {
  chi <- suppressWarnings(chisq.test(tab))
  if (any(chi$expected < 5)) {
    if (all(dim(tab) == c(2,2))) {
      fisher.test(tab)
    } else {
      fisher.test(tab, simulate.p.value = simulate, B = B)
    }
  } else chi
}

# Composición OR vs SI por grupo (usa sumas por filas/columnas de cada matriz)
compare_OR_SI <- function(M) {
  OR <- rowSums(M)              # active/inhibited/unresponsive en OR
  SI <- colSums(M)              # active/inhibited/unresponsive en SI
  rbind(OR = OR, SI = SI)
}


# ---------- 3) McNemar: binarizaciones ----------
# a) categoría vs resto (genérico)
mcnemar_one_vs_rest <- function(M, category, label = NULL) {
  if (is.null(label)) label <- paste0(toupper(substring(category,1,1)), substring(category,2))
  a <- M[category, category]
  b <- sum(M[category, setdiff(colnames(M), category)])
  c <- sum(M[setdiff(rownames(M), category), category])
  d <- sum(M) - a - b - c
  mat <- matrix(c(a,b,c,d), nrow = 2, byrow = TRUE,
                dimnames = list(OR = c(label, paste0("No", label)),
                                SI = c(label, paste0("No", label))))
  list(tab = mat, test = mcnemar.test(mat))
}

# b) responsive (active + inhibited) vs unresponsive
mcnemar_responsive <- function(M) {
  resp <- c("active","inhibited")
  unresp <- "unresponsive"
  a <- sum(M[resp, resp])
  b <- sum(M[resp, unresp])
  c <- sum(M[unresp, resp])
  d <- sum(M[unresp, unresp])
  mat <- matrix(c(a,b,c,d), nrow = 2, byrow = TRUE,
                dimnames = list(OR = c("Responsive","Unresponsive"),
                                SI = c("Responsive","Unresponsive")))
  list(tab = mat, test = mcnemar.test(mat))
}

# =========================
# Limpieza y análisis OR -> SI
# =========================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(writexl)
})

# ---------- 1) Definición de matrices (OR -> SI) ----------
dn <- list(OR = c("active","inhibited","unresponsive"),
           SI = c("active","inhibited","unresponsive"))

FV <- matrix(c(
  0,0,9,
  0,0,0,
  9,1,66
), nrow = 3, byrow = TRUE, dimnames = dn)

FC <- matrix(c(
  1,2,9,
  0,0,0,
  7,6,35
), nrow = 3, byrow = TRUE, dimnames = dn)

MV <- matrix(c(
  5,2,15,
  0,0,0,
  10,13,44
), nrow = 3, byrow = TRUE, dimnames = dn)

MC <- matrix(c(
  1,0,7,
  1,0,0,
  13,8,64
), nrow = 3, byrow = TRUE, dimnames = dn)


M_list <- list(FV = FV, FC = FC, MV = MV, MC = MC)

# ---------- 2) Utilidades ----------
prop_rows <- function(M) {
  sweep(M, 1, rowSums(M), "/")
}

chisq_or_fisher <- function(tab, simulate = TRUE, B = 1e5) {
  chi <- suppressWarnings(chisq.test(tab))
  if (any(chi$expected < 5)) {
    if (all(dim(tab) == c(2,2))) {
      fisher.test(tab)
    } else {
      fisher.test(tab, simulate.p.value = simulate, B = B)
    }
  } else chi
}

# Composición OR vs SI por grupo (usa sumas por filas/columnas de cada matriz)
compare_OR_SI <- function(M) {
  OR <- rowSums(M)              # active/inhibited/unresponsive en OR
  SI <- colSums(M)              # active/inhibited/unresponsive en SI
  rbind(OR = OR, SI = SI)
}

# ---------- 3) McNemar: binarizaciones ----------
# a) categoría vs resto (genérico)
mcnemar_one_vs_rest <- function(M, category, label = NULL) {
  if (is.null(label)) label <- paste0(toupper(substring(category,1,1)), substring(category,2))
  a <- M[category, category]
  b <- sum(M[category, setdiff(colnames(M), category)])
  c <- sum(M[setdiff(rownames(M), category), category])
  d <- sum(M) - a - b - c
  mat <- matrix(c(a,b,c,d), nrow = 2, byrow = TRUE,
                dimnames = list(OR = c(label, paste0("No", label)),
                                SI = c(label, paste0("No", label))))
  list(tab = mat, test = mcnemar.test(mat))
}

# b) responsive (active + inhibited) vs unresponsive
mcnemar_responsive <- function(M) {
  resp <- c("active","inhibited")
  unresp <- "unresponsive"
  a <- sum(M[resp, resp])
  b <- sum(M[resp, unresp])
  c <- sum(M[unresp, resp])
  d <- sum(M[unresp, unresp])
  mat <- matrix(c(a,b,c,d), nrow = 2, byrow = TRUE,
                dimnames = list(OR = c("Responsive","Unresponsive"),
                                SI = c("Responsive","Unresponsive")))
  list(tab = mat, test = mcnemar.test(mat))
}

# ---------- 4) Wrapper: ejecuta todo por grupo ----------
mk_row <- function(grupo, contraste, obj) {
  tab  <- obj$tab; test <- obj$test
  a <- tab[1,1]; b <- tab[1,2]; c <- tab[2,1]; d <- tab[2,2]; N <- a+b+c+d
  OR_pos <- a+b; SI_pos <- a+c
  data.frame(
    grupo = grupo, contraste = contraste, N = N,
    OR_pos_n = OR_pos, OR_pos_pct = round(100*OR_pos/N, 1),
    SI_pos_n = SI_pos, SI_pos_pct = round(100*SI_pos/N, 1),
    a = a, b = b, c = c, d = d,
    estables_n = a + d, estables_pct = round(100*(a + d)/N, 1),
    mcnemar_stat = unname(test$statistic),
    mcnemar_p = unname(test$p.value),
    metodo = as.character(test$method),
    row.names = NULL
  )
}

run_all <- function(M_list, export_xlsx = TRUE, xlsx_path = "mcnemar_summary_OR_SI.xlsx") {
  # 4.1 Composición OR vs SI por Chi-cuadrado/Fisher
  comp_list <- lapply(M_list, compare_OR_SI)
  comp_tests <- lapply(comp_list, chisq_or_fisher)
  comp_df <- do.call(rbind, lapply(names(comp_list), function(g) {
    tab <- comp_list[[g]]
    test <- comp_tests[[g]]
    data.frame(
      grupo = g,
      contraste = "Distribucion_OR_vs_SI_3x3",
      stat = unname(if (!is.null(test$statistic)) test$statistic else NA),
      p = unname(test$p.value),
      metodo = as.character(test$method),
      aOR = tab["OR","active"], iOR = tab["OR","inhibited"], uOR = tab["OR","unresponsive"],
      aSI = tab["SI","active"], iSI = tab["SI","inhibited"], uSI = tab["SI","unresponsive"],
      row.names = NULL
    )
  }))
  
  # 4.2 McNemar en 3 binarizaciones
  summ_df <- do.call(rbind, lapply(names(M_list), function(g) {
    M <- M_list[[g]]
    rbind(
      mk_row(g, "Active_vs_NoActive",         mcnemar_one_vs_rest(M, "active", "Activa")),
      mk_row(g, "Inhibited_vs_NoInhibited",   mcnemar_one_vs_rest(M, "inhibited", "Inhibida")),
      mk_row(g, "Responsive_vs_Unresponsive", mcnemar_responsive(M))
    )
  }))
  
  # 4.3 Export opcional
  if (export_xlsx) {
    write_xlsx(list(
      Composicion_OR_SI = comp_df,
      McNemar = summ_df
    ), path = xlsx_path)
    cat("Archivo escrito: ", normalizePath(xlsx_path), "\n")
  }
  
  list(composicion = comp_df, mcnemar = summ_df)
}

# ---------- 5) Ejecución ----------
# Proporciones por fila (interpretables) para inspección rápida
props <- lapply(M_list, function(M) round(prop_rows(M), 3))
# print(props$FV); print(props$FC); print(props$MV); print(props$MC)  # opcional

out <- run_all(
  M_list,
  export_xlsx = TRUE,
  xlsx_path = "F:/Ex3_BLA/Calcium RESULTS/CellREG/OR_SI_results/mcnemar_summary_OR_SI_J_O.xlsx"
)


# Resumen en consola
print(out$composicion)
print(out$mcnemar)

