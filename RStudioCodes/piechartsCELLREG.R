library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)

# Ruta a tu archivo
ruta_excel <- "/Users/leire/Desktop/Calcium RESULTS/CellREG/OR_SI_results/Percentage_Cell_Reg_OR_SI.xlsx"

# Colores y tamaños
colores <- c("Overlap" = "#FED766",
             "OR only" = "#2DC2BD",
             "SI only"  = "#8FB8DE")
tam_titulo <- 16
tam_etiquetas <- 12
donut_hole <- 0.55   # 0 = pie sólido, 0.55 = donut

# Leer datos
df <- read_excel(ruta_excel)

# Calcular categorías por animal
# pct es el porcentaje relative a OR (como en tu MATLAB)
df_calc <- df %>%
  mutate(
    pct = `Percentage of cell registered between OR and SI`,
    OR = `cells OR`,
    SI  = `cells SI`,
    overlap  = round(pct * OR),
    only_OR = pmax(OR - overlap, 0),
    only_SI  = pmax(SI  - overlap, 0)
  )

# Totales globales
totales <- df_calc %>%
  summarise(
    overlap = sum(overlap, na.rm = TRUE),
    `OR only` = sum(only_OR, na.rm = TRUE),
    `SI only`  = sum(only_SI,  na.rm = TRUE)
  ) %>%
  pivot_longer(everything(), names_to = "Categoria", values_to = "N") %>%
  mutate(
    pct = N / sum(N),
    Categoria = factor(Categoria, levels = c("overlap","OR only","SI only"),
                       labels = c("Overlap","OR only","SI only"))
  )

# Piechart global
ggplot(totales, aes(x = 1, y = pct, fill = Categoria)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_manual(values = colores) +
  geom_text(aes(label = paste0(Categoria, " (", round(pct*100,1), "%)")),
            position = position_stack(vjust = 0.5), size = tam_etiquetas/3) +
  xlim(c(0, 1 + donut_hole)) +
  labs(title = "Neuron overlapping") +
  theme_void(base_size = tam_etiquetas) +
  theme(
    plot.title = element_text(size = tam_titulo, hjust = 0.5),
    legend.position = "none"
  )

# Exportar valores para GraphPad (conteos y %)
valores_export <- totales %>%
  select(Categoria, N, pct) %>%
  mutate(Percentage = round(pct * 100, 2)) %>%
  select(Categoria, N, Percentage)

print(valores_export)

write_csv(valores_export,
          "/Users/leire/Desktop/Calcium RESULTS/CellREG/OR_SI_results/Piechart_values_for_GraphPad.csv")
