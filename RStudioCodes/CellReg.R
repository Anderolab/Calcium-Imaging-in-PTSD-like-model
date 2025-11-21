
#==============================================================================================================
#==============WITH NO REGISTERED CELLS ALSO IN PIECHARTS==========================
library(ggplot2)
library(dplyr)

data_animals <- data.frame(
  AnimalID = c("M1", "M2", "M3", "m4", "M5", "M6", "M7", "m8"),
  Sex = c("male", "male", "female", "female", "male", "male", "female", "female"),
  Overlap = c(0.3978, 0.1568, 0.4821, 0.3132, 0.0543, 0.4558, 0.2608, 0.1415 ),
  N_overlap_neurons = c(34, 16, 27, 24, 5, 31, 30, 15),
  N_early = c(93, 102, 56, 83, 92, 68, 115, 106),
  N_late = c(91, 111, 88, 147, 77, 86, 55, 132)
)


# Calcular totales y no overlapped
data_animals <- data_animals %>%
  mutate(
    N_total = N_early + N_late,
    N_nonoverlap = ifelse(!is.na(N_overlap_neurons), N_total - N_overlap_neurons, NA)
  )

# Preparar tabla resumen para gráfico incluyendo Not registered
summary_sex <- data_animals %>%
  group_by(Sex) %>%
  summarise(
    Overlapped = sum(N_overlap_neurons, na.rm = TRUE),
    Non_overlapped = sum(N_nonoverlap, na.rm = TRUE),
    Not_registered = sum(ifelse(is.na(N_overlap_neurons), N_total, 0))
  ) %>%
  tidyr::pivot_longer(cols = c("Overlapped", "Non_overlapped", "Not_registered"),
                      names_to = "Category", values_to = "Count") %>%
  group_by(Sex) %>%
  mutate(
    Percent = Count / sum(Count) * 100,
    Label = paste0(Category, "\n", round(Count), " neurons\n", round(Percent, 1), "%")
  )

# Colores consistentes
colors <- c(
  "Overlapped" = "#90E0EF",
  "Non_overlapped" = "#D81E5B",
  "Not_registered" = "#999999"
)

# Función para gráfico donut
plot_donut <- function(df, sex_filter) {
  ggplot(df %>% filter(Sex == sex_filter),
         aes(x = 2, y = Count, fill = Category)) +
    geom_bar(stat = "identity", width = 1, color = "white") +
    coord_polar("y") +
    geom_text(aes(label = Label),
              position = position_stack(vjust = 0.5),
              color = "white", size = 4.5) +
    xlim(1, 2.5) +
    labs(title = paste("Cell Registration -", sex_filter)) +
    theme_void() +
    theme(legend.position = "none") +
    scale_fill_manual(values = colors)
}

# Graficar machos y hembras
plot_donut(summary_sex, "male")
plot_donut(summary_sex, "female")


#=======================ALLUVIAL====================================================

library(dplyr)
library(tidyr)
library(ggalluvial)
library(ggplot2)

data_animals <- data.frame(
  AnimalID = c("M1", "M2", "M3", "m4", "M5", "M6", "M7", "m8"),
  Sex = c("male", "male", "female", "female", "male", "male", "female", "female"),
  Overlap = c(0.3978, 0.1568, 0.4821, 0.3132, 0.0543, 0.4558, 0.2608, 0.1415 ),
  N_overlap_neurons = c(34, 16, 27, 24, 5, 31, 30, 15),
  N_early = c(93, 102, 56, 83, 92, 68, 115, 106),
  N_late = c(91, 111, 88, 147, 77, 86, 55, 132)
)
# Paso 1: calcular columnas
data_animals <- data_animals %>%
  mutate(
    N_total_neurons = ifelse(!is.na(N_overlap_neurons) & !is.na(Overlap),
                             N_overlap_neurons / Overlap, NA),
    N_nonoverlap = ifelse(!is.na(N_total_neurons),
                          N_total_neurons - N_overlap_neurons, NA),
    N_not_registered = ifelse(is.na(N_overlap_neurons),
                              N_early + N_late,
                              0)
  )

# Paso 2: agrupar por sexo
summary_sex <- data_animals %>%
  group_by(Sex) %>%
  summarise(
    Overlapped = sum(N_overlap_neurons, na.rm = TRUE),
    NonOverlapped = sum(N_nonoverlap, na.rm = TRUE),
    NotRegistered = sum(N_not_registered, na.rm = TRUE)
  )

print("Summary before pivot:")
print(summary_sex)

# Paso 3: pivot_longer, limpiar NAs, forzar categoría y eliminar filas con neuronas = 0
alluvial_data <- summary_sex %>%
  pivot_longer(cols = c("Overlapped", "NonOverlapped", "NotRegistered"),
               names_to = "Category",
               values_to = "Neurons") %>%
  # Forzar que Category no tenga NA. Si hay NA, asignar "NotRegistered"
  mutate(Category = ifelse(is.na(Category), "NotRegistered", Category)) %>%
  # Reemplazar NA en Neurons con 0 (por si acaso)
  mutate(Neurons = ifelse(is.na(Neurons), 0, Neurons)) %>%
  # Eliminar filas con Neurons = 0 para no crear strata vacíos
  filter(Neurons > 0) %>%
  # Forzar factor con niveles exactos
  mutate(
    Category = factor(Category, levels = c("Overlapped", "NonOverlapped", "NotRegistered")),
    Sex = factor(Sex, levels = c("Male", "Female"))
  ) %>%
  droplevels()

print("Final alluvial_data:")
print(alluvial_data)

print("Check NAs in Category:")
print(any(is.na(alluvial_data$Category)))

print("Levels in Category:")
print(levels(alluvial_data$Category))

# Colores
colors <- c(
  Overlapped = "#90E0EF",
  NonOverlapped = "#D81E5B",
  NotRegistered = "#999999"
)

alluvial_data$Category <- droplevels(alluvial_data$Category)
alluvial_data$Sex <- droplevels(alluvial_data$Sex)

ggplot(alluvial_data,
       aes(y = Neurons, axis1 = Sex, axis2 = Category, fill = Category)) +
  geom_alluvium(width = 1/12) +
  geom_stratum(width = 1/12, color = "white") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 4) +
  scale_x_discrete(limits = c("Sex", "Category"), expand = c(0.15, 0.05)) +
  scale_fill_manual(values = colors, na.translate = FALSE) +
  theme_minimal() +
  labs(title = "Cell registration",
       y = "Neurons",
       x = "") +
  theme(legend.position = "none")

#===============ALLUVIAL CON PORCENTAJES==========================================

library(dplyr)
library(tidyr)
library(ggalluvial)
library(ggplot2)

# Tu data de ejemplo (ya pivotada y limpia)
data_animals <- data.frame(
  AnimalID = c("M1", "M2", "M3", "m4", "M5", "M6", "M7", "m8"),
  Sex = c("male", "male", "female", "female", "male", "male", "female", "female"),
  Overlap = c(0.3978, 0.1568, 0.4821, 0.3132, 0.0543, 0.4558, 0.2608, 0.1415 ),
  N_overlap_neurons = c(34, 16, 27, 24, 5, 31, 30, 15),
  N_early = c(93, 102, 56, 83, 92, 68, 115, 106),
  N_late = c(91, 111, 88, 147, 77, 86, 55, 132)
)

data_animals <- data_animals %>%
  mutate(
    N_total_neurons = ifelse(!is.na(N_overlap_neurons) & !is.na(Overlap),
                             N_overlap_neurons / Overlap, NA),
    N_nonoverlap = ifelse(!is.na(N_total_neurons),
                          N_total_neurons - N_overlap_neurons, NA),
    N_not_registered = ifelse(is.na(N_overlap_neurons),
                              N_early + N_late,
                              0)
  )

summary_sex <- data_animals %>%
  group_by(Sex) %>%
  summarise(
    Overlapped = sum(N_overlap_neurons, na.rm = TRUE),
    NonOverlapped = sum(N_nonoverlap, na.rm = TRUE),
    NotRegistered = sum(N_not_registered, na.rm = TRUE)
  )

# Pivotar
alluvial_data <- summary_sex %>%
  pivot_longer(cols = c("Overlapped", "NonOverlapped", "NotRegistered"),
               names_to = "Category",
               values_to = "Neurons") %>%
  filter(Neurons > 0) %>%
  mutate(
    Category = factor(Category, levels = c("Overlapped", "NonOverlapped", "NotRegistered")),
    Sex = factor(Sex, levels = c("Male", "Female"))
  )

# Calcular porcentajes sumando por categoría (ambos sexos)
percentages <- alluvial_data %>%
  group_by(Category) %>%
  summarise(TotalNeurons = sum(Neurons)) %>%
  ungroup() %>%
  mutate(
    Percent = TotalNeurons / sum(TotalNeurons) * 100,
    Label = paste0(as.character(Category), " (", round(Percent, 1), "%)")
  )

# Crear un vector con etiquetas nuevas para los niveles de Category
new_labels <- setNames(percentages$Label, percentages$Category)

# Remapear factor Category para mostrar las etiquetas con porcentajes
alluvial_data <- alluvial_data %>%
  mutate(CategoryLabel = factor(Category, levels = percentages$Category, labels = percentages$Label))

# Colores (los mismos)
colors <- c(
  Overlapped = "#90E0EF",
  NonOverlapped = "#D81E5B",
  NotRegistered = "#999999"
)

# Usar colors renombrados para los nuevos labels
colors_label <- setNames(colors[names(new_labels)], new_labels)

# Graficar con etiquetas nuevas y colores ajustados
ggplot(alluvial_data,
       aes(y = Neurons, axis1 = Sex, axis2 = CategoryLabel, fill = CategoryLabel)) +
  geom_alluvium(width = 1/12) +
  geom_stratum(width = 1/12, color = "black") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 4) +
  scale_x_discrete(limits = c("Sex", "Category"), expand = c(0.15, 0.05)) +
  scale_fill_manual(values = colors_label, na.translate = FALSE) +
  theme_minimal() +
  labs(title = "Cell registration",
       y = "Neurons",
       x = "") +
  theme(legend.position = "none")
