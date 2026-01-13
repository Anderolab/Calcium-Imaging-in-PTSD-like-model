library(readxl)
library(dplyr)
library(purrr)
# IMPORTANT: do not forget to change the TEST names in all the code 
# Path to file
archivo <- "F:/Ex3_BLA/Calcium RESULTS/CellREG/OR_SI_results/cell_reg_OR_SI_results.xlsx"

# Read excel sheets
OR_data <- read_excel(archivo, sheet = "OR_ROI1")
SI_data <- read_excel(archivo, sheet = "SI_ROI2")
reg_data <- read_excel(archivo, sheet = "Cell reg results")

# Clean key columns
clean_cols <- function(df) {
  df %>%
    mutate(across(c(Animal, Sex, treatment), ~ trimws(as.character(.))))
}

# Apply cleaning and generate indices grouped by Animal
OR_data <- clean_cols(OR_data) %>%
  group_by(Animal) %>%
  mutate(Index_OR = row_number()) %>%
  ungroup()

SI_data <- clean_cols(SI_data) %>%
  group_by(Animal) %>%
  mutate(Index_SI = row_number()) %>%
  ungroup()

reg_data <- clean_cols(reg_data)

# Obtain list of animals
animales <- unique(reg_data$Animal)

# Function to process data by animal
procesar_animal <- function(animal_id) {
  reg_sub <- reg_data %>% filter(Animal == animal_id)
  OR_sub <- OR_data %>% filter(Animal == animal_id)
  SI_sub <- SI_data %>% filter(Animal == animal_id)
  
  merged <- reg_sub %>%
    left_join(OR_sub, by = c("Animal", "Sex", "treatment", "Index_OR")) %>%
    rename(Response_OR = ResponseType) %>%
    left_join(SI_sub, by = c("Animal", "Sex", "treatment", "Index_SI")) %>%
    rename(Response_SI = ResponseType)
  
  # Add stability column
  merged <- merged %>%
    mutate(StableResponse = case_when(
      is.na(Response_OR) | is.na(Response_SI) ~ NA_character_,
      Response_OR == Response_SI ~ "Same",
      TRUE ~ "Different"
    ))
  
  return(merged)
}

# Apply to all animals
merged_all <- map_dfr(animales, procesar_animal)

# See first results
print(head(merged_all, 10))

# Save as CSV
write.csv(merged_all, "F:/Ex3_BLA/Calcium RESULTS/CellREG/OR_SI_results/merged_metrics_tuning_object_juvenile.csv", row.names = FALSE)


merged_all <- merged_all %>%
  mutate(StableResponse = case_when(
    is.na(Response_OR) | is.na(Response_SI) ~ NA_character_,
    Response_OR == Response_SI ~ "Same",
    TRUE ~ "Different"
  ))
summary_counts <- merged_all %>%
  group_by(Animal, Sex, treatment, StableResponse) %>%
  summarise(n = n(), .groups = "drop")

print(summary_counts)

