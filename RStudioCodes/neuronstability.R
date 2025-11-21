# ==== Paquetes ====
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2)
  library(tibble); library(writexl); library(scales)
})

# ==== DATOS (tus datos) ====
df <- tribble(
  ~state,         ~trt,   ~same, ~different,
  "active",       "veh",    0,          9,
  "inactive",     "veh",      0,         0,
  "unresponsive", "veh",     66,        10,
  "active",       "cort",     1,        11,
  "inactive",     "cort",     0,         8,
  "unresponsive", "cort",    35,        13
) %>%
  mutate(
    state = factor(state, levels = c("active","inactive","unresponsive")),
    trt   = factor(trt,   levels = c("veh","cort"))
  )

# ==== Helpers ====
safe_or_ci <- function(mat2x2){
  a <- mat2x2[1,1]; b <- mat2x2[2,1]; c <- mat2x2[1,2]; d <- mat2x2[2,2]
  a2 <- a + 0.5; b2 <- b + 0.5; c2 <- c + 0.5; d2 <- d + 0.5
  or <- (a2*d2)/(b2*c2)
  se <- sqrt(1/a2 + 1/b2 + 1/c2 + 1/d2)
  ci <- exp(log(or) + c(-1,1)*qnorm(0.975)*se)
  c(or=unname(or), ci_lo=ci[1], ci_hi=ci[2])
}
prop_ci_exact <- function(x, n){
  if (n <= 0) return(c(lo=NA_real_, hi=NA_real_))
  bt <- binom.test(x, n)
  c(lo=bt$conf.int[1], hi=bt$conf.int[2])
}

# ==== 1) Global por tratamiento ====
overall <- df %>%
  group_by(trt) %>%
  summarise(same = sum(same), different = sum(different), .groups = "drop") %>%
  arrange(trt)

m_overall <- rbind(
  same      = c(veh = overall$same[overall$trt=="veh"],  cort = overall$same[overall$trt=="cort"]),
  different = c(veh = overall$different[overall$trt=="veh"], cort = overall$different[overall$trt=="cort"])
)
ft_overall <- fisher.test(m_overall)
orci_overall <- safe_or_ci(m_overall)

ci_veh  <- prop_ci_exact(overall$same[overall$trt=="veh"],
                         sum(overall[overall$trt=="veh", c("same","different")]))
ci_cort <- prop_ci_exact(overall$same[overall$trt=="cort"],
                         sum(overall[overall$trt=="cort", c("same","different")]))

overall_summary <- tibble(
  trt = c("veh","cort"),
  same = c(overall$same[1], overall$same[2]),
  different = c(overall$different[1], overall$different[2]),
  total = same + different,
  prop_same = same/total,
  ci_lo = c(ci_veh["lo"], ci_cort["lo"]),
  ci_hi = c(ci_veh["hi"], ci_cort["hi"])
)

overall_test <- tibble(
  test = "Fisher overall 2x2 (same vs different por tratamiento)",
  p_value = ft_overall$p.value,
  odds_ratio_fisher = suppressWarnings(as.numeric(ft_overall$estimate)),
  ci_lo_fisher = suppressWarnings(ft_overall$conf.int[1]),
  ci_hi_fisher = suppressWarnings(ft_overall$conf.int[2]),
  odds_ratio_haldene = orci_overall["or"],
  ci_lo_haldene = orci_overall["ci_lo"],
  ci_hi_haldene = orci_overall["ci_hi"]
)

# prop.test global (p_same veh vs cort)
totals <- overall$same + overall$different
x <- c(overall$same[1], overall$same[2])
n <- c(totals[1], totals[2])
pt_overall <- prop.test(x, n, correct = TRUE)
overall_prop_test <- tibble(
  test = "Prop.test overall (p_same veh vs cort)",
  prop_veh = unname(pt_overall$estimate[1]),
  prop_cort = unname(pt_overall$estimate[2]),
  diff = unname(pt_overall$estimate[1] - pt_overall$estimate[2]),
  ci_lo = unname(pt_overall$conf.int[1]),
  ci_hi = unname(pt_overall$conf.int[2]),
  p_value = unname(pt_overall$p.value),
  method = pt_overall$method
)

# ==== 2) Por estado ====
wide <- df %>%
  group_by(state, trt) %>%
  summarise(same = sum(same), different = sum(different), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = trt, values_from = c(same, different), values_fill = 0)

by_state <- lapply(levels(df$state), function(s){
  sub <- dplyr::filter(wide, state == s)
  tot_veh  <- sub$same_veh + sub$different_veh
  tot_cort <- sub$same_cort + sub$different_cort
  
  # Fisher solo si ambos tratamientos tienen total > 0
  ft <- if (tot_veh > 0 && tot_cort > 0) {
    m <- rbind(
      same      = c(veh = sub$same_veh,      cort = sub$same_cort),
      different = c(veh = sub$different_veh, cort = sub$different_cort)
    )
    fisher.test(m)
  } else NULL
  
  if (!is.null(ft)) {
    m <- rbind(
      same      = c(veh = sub$same_veh,      cort = sub$same_cort),
      different = c(veh = sub$different_veh, cort = sub$different_cort)
    )
    orci <- safe_or_ci(m)
    fisher_p <- ft$p.value
    fisher_OR <- suppressWarnings(as.numeric(ft$estimate))
    fisher_ci_lo <- suppressWarnings(ft$conf.int[1])
    fisher_ci_hi <- suppressWarnings(ft$conf.int[2])
    or_h <- orci["or"]; or_lo <- orci["ci_lo"]; or_hi <- orci["ci_hi"]
  } else {
    fisher_p <- NA_real_; fisher_OR <- NA_real_; fisher_ci_lo <- NA_real_; fisher_ci_hi <- NA_real_
    or_h <- NA_real_; or_lo <- NA_real_; or_hi <- NA_real_
  }
  
  p_veh  <- if (tot_veh  > 0) sub$same_veh  / tot_veh  else NA_real_
  p_cort <- if (tot_cort > 0) sub$same_cort / tot_cort else NA_real_
  
  tibble(
    state = s,
    same_veh = sub$same_veh, diff_veh = sub$different_veh, total_veh = tot_veh, prop_same_veh = p_veh,
    same_cort = sub$same_cort, diff_cort = sub$different_cort, total_cort = tot_cort, prop_same_cort = p_cort,
    fisher_p = fisher_p,
    fisher_OR = fisher_OR,
    fisher_ci_lo = fisher_ci_lo,
    fisher_ci_hi = fisher_ci_hi,
    OR_haldene = or_h,
    OR_haldene_ci_lo = or_lo,
    OR_haldene_ci_hi = or_hi
  )
}) %>% bind_rows() %>%
  mutate(p_holm = p.adjust(fisher_p, method = "holm"))

# prop.test por estado (solo donde ambos totales > 0)
by_state_counts <- df %>%
  group_by(state, trt) %>%
  summarise(x = sum(same), n = sum(same + different), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = trt, values_from = c(x, n), values_fill = 0)

by_state_prop <- by_state_counts %>%
  rowwise() %>%
  do({
    x_veh <- .$x_veh; n_veh <- .$n_veh
    x_cort <- .$x_cort; n_cort <- .$n_cort
    if (n_veh > 0 && n_cort > 0) {
      pt <- prop.test(c(x_veh, x_cort), c(n_veh, n_cort), correct = TRUE)
      tibble(state = .$state,
             x_veh = x_veh, n_veh = n_veh, prop_veh = x_veh/n_veh,
             x_cort = x_cort, n_cort = n_cort, prop_cort = x_cort/n_cort,
             diff = unname(pt$estimate[1] - pt$estimate[2]),
             ci_lo = unname(pt$conf.int[1]),
             ci_hi = unname(pt$conf.int[2]),
             p_value = unname(pt$p.value),
             method = pt$method)
    } else {
      tibble(state = .$state,
             x_veh = x_veh, n_veh = n_veh, prop_veh = ifelse(n_veh>0, x_veh/n_veh, NA_real_),
             x_cort = x_cort, n_cort = n_cort, prop_cort = ifelse(n_cort>0, x_cort/n_cort, NA_real_),
             diff = NA_real_, ci_lo = NA_real_, ci_hi = NA_real_,
             p_value = NA_real_, method = "not estimable (n_veh=0 or n_cort=0)")
    }
  }) %>%
  ungroup() %>%
  mutate(p_holm = ifelse(is.na(p_value), NA_real_, p.adjust(p_value, method = "holm"))) %>%
  select(state,
         x_veh, n_veh, prop_veh,
         x_cort, n_cort, prop_cort,
         diff, ci_lo, ci_hi, p_value, p_holm, method)

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

# ==== 4) Exportar a .xlsx ====
export_dir  <- "F:/Ex3_BLA/Calcium RESULTS/CellREG/OR_SI_results"
file_name   <- "Same_vs_different_object_juvenile_females.xlsx"
if (!dir.exists(export_dir)) dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)

export_path <- file.path(export_dir, file_name)
sheets <- list(
  overall_summary    = overall_summary,
  overall_fisher     = overall_test,
  overall_prop_test  = overall_prop_test,
  by_state_fisher    = by_state,
  by_state_prop_test = by_state_prop,
  plot_data_long     = df_long
)
writexl::write_xlsx(sheets, path = export_path)
cat("Excel escrito en:\n", normalizePath(export_path), "\n")
