# R Script: Detailed analysis of OF→OR neuronal response transitions

# Load libraries
library(tidyverse)
library(lme4)
library(vcd)
library(emmeans)
library(nnet)

# Path to merged data CSV
csv_file <- "F:/Ex3_BLA/Calcium RESULTS/CellREG/EPM_OF_results/merged_metrics_tuning_ROI2.csv"
# Read data
merged_all <- read_csv(csv_file, show_col_types = FALSE)

# Prepare labels, compute Transition and Stable
merged_all <- merged_all %>%
  mutate(
    OF_label = recode(Response_OF,
                      "Excited" = "Active",
                      "Inhibited" = "Inactive",
                      "Unresponsive" = "Unresponsive"),
    EPM_label = recode(Response_EPM,
                      "Excited" = "Active",
                      "Inhibited" = "Inactive",
                      "Unresponsive" = "Unresponsive"),
    Transition = factor(paste(OF_label, "→", EPM_label),
                        levels = paste(
                          rep(c("Active","Inactive","Unresponsive"), each = 3),
                          "→",
                          rep(c("Active","Inactive","Unresponsive"), times = 3)
                        )),
    Stable = if_else(OF_label == EPM_label, 1, 0)
  ) %>%
  filter(!is.na(OF_label), !is.na(EPM_label))

# Convert grouping variables to factors
merged_all <- merged_all %>%
  mutate(
    treatment = factor(treatment),
    Sex = factor(Sex),
    Animal = factor(Animal)
  )

# ---- A. GLM for Stable ~ treatment * Sex ----
glm_simple <- glm(Stable ~ treatment * Sex,
                  data = merged_all,
                  family = binomial)

# Extract marginal probabilities via emmeans
emm <- emmeans(glm_simple, ~ treatment * Sex, type = "response")
emm_df <- as.data.frame(emm)
print(emm_df)

# Plot marginal probabilities
plot(emm, comparisons = TRUE) +
  labs(title = "Estimated Probability of Stable Response",
       y = "Probability (Stable)", x = "Treatment")

# ---- B. Multinomial model for Transition categories ----
model_multinom <- multinom(Transition ~ treatment * Sex, data = merged_all)
summary(model_multinom)

# Obtain predicted probabilities for each transition by group
# Use emmeans to get probabilities for each Transition level by treatment and Sex
emm_mn <- emmeans(model_multinom, ~ Transition | treatment * Sex, type = "response")
emm_mn_df <- as.data.frame(emm_mn)
print(names(emm_mn_df))  # should include 'Transition', 'treatment', 'Sex', 'prob'

# Visualization: bar plots of predicted transition probabilities
ggplot(emm_mn_df, aes(x = treatment, y = prob, fill = Transition)) +
  geom_col(position = position_dodge()) +
  facet_wrap(~ Sex) +
  labs(title = "Predicted Transition Probabilities by Treatment and Sex",
       y = "Probability", x = "Treatment", fill = "Transition") +
  theme_minimal()




# Bar plot of observed stable proportions by Treatment and Sex
stab_props <- merged_all %>%
  group_by(treatment, Sex) %>%
  summarise(prop_stable = mean(Stable), .groups = "drop")

ggplot(stab_props, aes(x = treatment, y = prop_stable, fill = Sex)) +
  geom_col(position = position_dodge()) +
  labs(title = "Observed Proportion of Stable Responses",
       x = "Treatment", y = "Proportion Stable", fill = "Sex") +
  theme_minimal()


