library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(writexl)

# Ruta al archivo
ruta_excel <- "F:/Ex3_BLA/Calcium RESULTS/CellREG/EPM_OF_results/Percentage_Cell_Reg_EPM_OF.xlsx"

# Paleta de colores
colores <- c("Overlap" = "#FED766",
             "EPM only" = "#2DC2BD",
             "OF only"  = "#8FB8DE")

# Función auxiliar para convertir comas a puntos
to_num <- function(x) { 
  if (is.numeric(x)) x else as.numeric(str_replace_all(as.character(x), ",", ".")) 
}

# Leer datos
df <- read_excel(ruta_excel) %>%
  mutate(
    pct = to_num(`Percentage of cell registered between EPM and OF`),
    EPM = to_num(`cells EPM`),
    OF  = to_num(`cells OF`)
  )

# Asignar grupo por Animal (sexo + tratamiento)
df <- df %>%
  mutate(
    group = case_when(
      Animals %in% c("M10","M11","M12") ~ "Female_Veh",
      Animals %in% c("M4","M5","M6","M7") ~ "Female_Cort",
      Animals %in% c("M8","M9") ~ "Male_Veh",
      Animals %in% c("M1","M2","M3") ~ "Male_Cort",
      TRUE ~ NA_character_
    )
  )

# Calcular células overlap, solo EPM y solo OF
df_calc <- df %>%
  mutate(
    overlap  = pmin(pct * pmin(EPM, OF), pmin(EPM, OF)),  # proporción segura
    only_EPM = pmax(EPM - overlap, 0),
    only_OF  = pmax(OF  - overlap, 0)
  )

# Agrupar por grupo (pooling de células)
totales_grp <- df_calc %>%
  group_by(group) %>%
  summarise(
    Overlap    = sum(overlap,  na.rm = TRUE),
    `EPM only` = sum(only_EPM, na.rm = TRUE),
    `OF only`  = sum(only_OF,  na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(cols = c(Overlap, `EPM only`, `OF only`),
               names_to = "Categoria", values_to = "N") %>%
  group_by(group) %>%
  mutate(pct = N / sum(N)) %>%
  ungroup() %>%
  mutate(Categoria = factor(Categoria, levels = c("Overlap","EPM only","OF only")))

# Donut por grupo (4 paneles)
ggplot(totales_grp, aes(x = 1, y = pct, fill = Categoria)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  facet_wrap(~ group) +
  scale_fill_manual(values = colores) +
  theme_void() +
  theme(
    legend.title = element_blank(),
    strip.text = element_text(size = 14, face = "bold"),
    legend.text = element_text(size = 12)
  ) +
  ggtitle("Proportion of overlapping and context-specific cells by sex and treatment")

# Exportar los resultados
ruta_salida <- "F:/Ex3_BLA/Calcium RESULTS/CellREG/EPM_OF_results/Overlap_summary_by_sex_treatment.xlsx"
write_xlsx(totales_grp, ruta_salida)
cat("Archivo exportado correctamente a:", ruta_salida, "\n")

