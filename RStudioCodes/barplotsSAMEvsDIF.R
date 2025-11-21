

# ==== Paquetes ====
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(readr)
  library(broom); library(purrr); library(writexl); library(scales)
})

# ==== DATOS ====
# Usa tu 'df' ya creado con columnas: state, trt (veh/cort), same, different
# Ejemplo (comenta si ya lo tienes):
  library(tibble)
   df <- tribble(
    ~state,        ~trt,   ~same, ~different,
    "active",     "veh",      5,        17,
    "inactive",   "veh",      0,         0,
    "unresponsive","veh",     44,         23,
    "active",     "cort",     1,         1,
    "inactive",   "cort",     0,         8,
    "unresponsive","cort",    64,        21
)
# Ordenar factores (asegura consistencia)
df <- df %>%
  mutate(
    state = factor(state, levels = c("active","inactive","unresponsive")),
    trt   = factor(trt,   levels = c("veh","cort"))
  )

# ==== 1) Fisher 2×2 GLOBAL (colapsado sobre estados) ====
overall <- df %>%
  group_by(trt) %>%
  summarise(same = sum(same), different = sum(different), .groups = "drop") %>%
  arrange(trt)

m_overall <- rbind(
  same      = c(veh = overall$same[overall$trt=="veh"],  cort = overall$same[overall$trt=="cort"]),
  different = c(veh = overall$different[overall$trt=="veh"], cort = overall$different[overall$trt=="cort"])
)
ft_overall <- fisher.test(m_overall)

# Proporciones e IC exactos por tratamiento
bt_veh  <- binom.test(overall$same[overall$trt=="veh"],
                      overall$same[overall$trt=="veh"] + overall$different[overall$trt=="veh"])
bt_cort <- binom.test(overall$same[overall$trt=="cort"],
                      overall$same[overall$trt=="cort"] + overall$different[overall$trt=="cort"])

overall_summary <- tibble(
  trt = c("veh","cort"),
  same = c(overall$same[overall$trt=="veh"],  overall$same[overall$trt=="cort"]),
  different = c(overall$different[overall$trt=="veh"], overall$different[overall$trt=="cort"]),
  total = same + different,
  prop_same = same/total,
  ci_lo = c(bt_veh$conf.int[1], bt_cort$conf.int[1]),
  ci_hi = c(bt_veh$conf.int[2], bt_cort$conf.int[2])
)

overall_test <- tibble(
  test = "Fisher overall 2x2 (same vs different por tratamiento)",
  p_value = ft_overall$p.value,
  odds_ratio = suppressWarnings(as.numeric(ft_overall$estimate)),
  ci_lo = suppressWarnings(ft_overall$conf.int[1]),
  ci_hi = suppressWarnings(ft_overall$conf.int[2])
)

# ==== 2) Fisher 2×2 POR ESTADO (ajuste Holm) ====
wide <- df %>%
  select(state, trt, same, different) %>%
  pivot_wider(names_from = trt, values_from = c(same, different), values_fill = 0)

by_state <- lapply(levels(df$state), function(s){
  sub <- filter(wide, state == s)
  m <- rbind(
    same      = c(veh = sub$same_veh,      cort = sub$same_cort),
    different = c(veh = sub$different_veh, cort = sub$different_cort)
  )
  ft <- fisher.test(m)
  
  tot_veh  <- sub$same_veh + sub$different_veh
  tot_cort <- sub$same_cort + sub$different_cort
  p_veh  <- if (tot_veh  > 0) sub$same_veh  / tot_veh  else NA_real_
  p_cort <- if (tot_cort > 0) sub$same_cort / tot_cort else NA_real_
  
  tibble(
    state = s,
    same_veh = sub$same_veh, diff_veh = sub$different_veh, total_veh = tot_veh, prop_same_veh = p_veh,
    same_cort = sub$same_cort, diff_cort = sub$different_cort, total_cort = tot_cort, prop_same_cort = p_cort,
    fisher_p = ft$p.value,
    fisher_OR = suppressWarnings(as.numeric(ft$estimate)),
    fisher_ci_lo = suppressWarnings(ft$conf.int[1]),
    fisher_ci_hi = suppressWarnings(ft$conf.int[2])
  )
}) %>% bind_rows() %>%
  mutate(p_holm = p.adjust(fisher_p, method = "holm"))


# ==== 3) Plot (barras 100% apiladas) ====
colores_barras <- c(same = "#90D14D", different = "#F52632")

df_long <- df %>%
  select(state, trt, same, different) %>%
  pivot_longer(c(same, different), names_to = "change", values_to = "n") %>%
  group_by(state, trt) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup()

p_bars <- ggplot(df_long, aes(x = trt, y = pct, fill = change)) +
  geom_col(width = 0.8, color = "white", linewidth = 0.5) +
  facet_wrap(~ state, nrow = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  scale_fill_manual(values = colores_barras, name = "Change") +
  labs(x = "Treatment", y = "Proportion of cells") +
  theme_classic(base_size = 12)

print(p_bars)


# ==== 4) Exportar TODO a un único .xlsx con hojas múltiples ====

export_dir  <- "/Users/leire/Desktop/Calcium RESULTS/CellREG/OR_SI_results"  # carpeta destino
file_name   <- "Same_vs_different_obj_juv_males.xlsx"   

export_path <- file.path(export_dir, file_name)
sheets <- list(
  overall_summary    = overall_summary,
  overall_fisher     = overall_test,
  by_state_fisher    = by_state,
  overall_prop_test  = overall_prop_test,
  by_state_prop_test = by_state_prop,
  plot_data_long     = df_long
)
write_xlsx(sheets, path = export_path)
cat("Excel escrito en:\n", normalizePath(export_path), "\n")

# ==== 5) (Opcional) Ver matrices en consola ====
cat("\nMatriz global 2x2 (same/different x veh/cort):\n"); print(m_overall)
cat("\nMatrices 2x2 por estado:\n")
for (s in levels(df$state)) {
  sub <- filter(wide, state == s)
  m <- rbind(
    same      = c(veh = sub$same_veh,      cort = sub$same_cort),
    different = c(veh = sub$different_veh, cort = sub$different_cort)
  )
  cat("\nEstado:", s, "\n"); print(m)
}
