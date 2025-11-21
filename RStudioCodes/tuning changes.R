# R Script: Alluvial plot from merged_neurons_all_animals.csv

library(tidyverse)
library(ggalluvial)
library(readxl)

# Path to the pre-generated CSV
xlsx_file <- "F:/Ex3_BLA/Calcium RESULTS/CellREG/OR_SI_results/merged_metrics_tuning_object_doll.xlsx"

# Read data
merged_all <- read_excel(xlsx_file, sheet = 1)

# Define custom colors for each response label
label_colors <- c(
  "Active"       = "#CBED92",  # light green for Excited
  "Inactive"     = "#93C2FD",  # light blue for Inhibited
  "Unresponsive" = "#D4D4D4"   # light gray
)

# Filter neurons with valid OR and SI responses, map to new labels, and drop unused levels
alluvial_prep <- merged_all %>%
  filter(!is.na(Response_OR), !is.na(Response_SI)) %>%
  mutate(
    OR_label = case_when(
      Response_OR == "Excited"      ~ "Active",
      Response_OR == "Inhibited"    ~ "Inactive",
      Response_OR == "Unresponsive" ~ "Unresponsive",
      TRUE                             ~ NA_character_
    ),
    SI_label = case_when(
      Response_SI == "Excited"      ~ "Active",
      Response_SI == "Inhibited"    ~ "Inactive",
      Response_SI == "Unresponsive" ~ "Unresponsive",
      TRUE                             ~ NA_character_
    )
  ) %>%
  # Convert to factor with levels matching the defined palette
  mutate(
    OR_label = factor(OR_label, levels = names(label_colors)),
    SI_label = factor(SI_label, levels = names(label_colors))
  ) %>%
  # Drop any levels not present in the data
  mutate(
    OR_label = fct_drop(OR_label),
    SI_label = fct_drop(SI_label)
  )


# #========================ALLUVIALES POR PORCENTAJE EN LUGAR DE CONTEO=============================
# Normalizar a porcentajes globales
global_data_prop <- alluvial_prep %>%
  count(OR_label, SI_label, name = "n") %>%
  mutate(freq = n / sum(n) * 100)

ggplot(global_data_prop, aes(axis1 = OR_label, axis2 = SI_label, y = freq)) +
  scale_x_discrete(limits = c("OR","SI"), expand = c(.1,.1), labels = c("OR","SI")) +
  geom_alluvium(aes(fill = OR_label), width = 1/12) +
  geom_stratum(aes(fill = after_stat(stratum)), width = 1/12, color = "white") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum))) +
  scale_fill_manual(values = label_colors) +
  labs(title = "Global Object → Juvenile Response Flow  (close arms and periphery)",
       y = "Percent", x = "", fill = "Response Type") +
  theme_minimal()
# 
# 
# 
# --- Alluvial por TRATAMIENTO en PORCENTAJE ---
treatment_data_prop <- alluvial_prep %>%
  count(treatment, OR_label, SI_label, name = "n") %>%
  group_by(treatment) %>%
  mutate(freq = 100 * n / sum(n)) %>%
  ungroup()

alluvial_treatment_pct <- ggplot(treatment_data_prop,
                                 aes(axis1 = OR_label, axis2 = SI_label, y = freq)) +
  scale_x_discrete(limits = c("OR","SI"), expand = c(.1,.1), labels = c("OR","SI")) +
  geom_alluvium(aes(fill = OR_label), width = 1/12) +
  geom_stratum(aes(fill = after_stat(stratum)), width = 1/12, color = "white") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum))) +
  scale_fill_manual(values = label_colors) +
  facet_wrap(~ treatment) +
  labs(title = "Object → Juvenile Response Flow by Treatment",
       x = "", y = "Percent", fill = "Response Type") +
  theme_minimal()

print(alluvial_treatment_pct)



# --- Alluvial por SEXO x TRATAMIENTO en PORCENTAJE ---
st_pt_data_prop <- alluvial_prep %>%
  count(treatment, Sex, OR_label, SI_label, name = "n") %>%
  group_by(treatment, Sex) %>%
  mutate(freq = 100 * n / sum(n)) %>%
  ungroup()

alluvial_sex_treatment_pct <- ggplot(st_pt_data_prop,
                                     aes(axis1 = OR_label, axis2 = SI_label, y = freq)) +
  scale_x_discrete(limits = c("Object","Juvenile"), expand = c(.1,.1), labels = c("Object","Juvenile")) +
  geom_alluvium(aes(fill = OR_label), width = 1/12) +
  geom_stratum(aes(fill = after_stat(stratum)), width = 1/12, color = "white") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum))) +
  scale_fill_manual(values = label_colors) +
  facet_grid(treatment ~ Sex) +
  labs(title = "Object → Juvenile Response Flow",
       x = "", y = "Percent", fill = "Response Type") +
  theme_minimal()

print(alluvial_sex_treatment_pct)