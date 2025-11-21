# R Script: Statistical analysis of OF→OR neuronal response transitions

# Load libraries
library(tidyverse)
library(lme4)
library(vcd)

# Path to merged data CSV
csv_file <- "F:/Ex3_BLA/CellReg/merged_neurons_all_animals.csv"
# Read data
merged_all <- read_csv(csv_file)

# Map responses to labels and compute Transition and Stable
merged_all <- merged_all %>%
  mutate(
    OF_label = case_when(
      Response_OF == "Excited"      ~ "Active",
      Response_OF == "Inhibited"    ~ "Inactive",
      Response_OF == "Unresponsive" ~ "Unresponsive",
      TRUE                             ~ NA_character_
    ),
    OR_label = case_when(
      Response_OR == "Excited"      ~ "Active",
      Response_OR == "Inhibited"    ~ "Inactive",
      Response_OR == "Unresponsive" ~ "Unresponsive",
      TRUE                             ~ NA_character_
    ),
    Transition = paste(OF_label, "→", OR_label),
    Stable = if_else(OF_label == OR_label, 1, 0)
  ) %>%
  filter(!is.na(OF_label), !is.na(OR_label))

# Define full set of possible transitions
full_transitions <- expand.grid(
  OF = c("Active", "Inactive", "Unresponsive"),
  OR = c("Active", "Inactive", "Unresponsive")
) %>%
  transmute(Transition = paste(OF, "→", OR)) %>%
  pull(Transition)
# Factor Transition with full levels
merged_all <- merged_all %>%
  mutate(Transition = factor(Transition, levels = full_transitions))

#---- 1. Transition tables and Chi-square/Fisher by sex ----
sexes <- unique(merged_all$Sex)
chi_results <- tibble(Sex=character(), Method=character(), p.value=numeric())
for(sex in sexes) {
  sub <- merged_all %>% filter(Sex == sex)
  tab <- table(sub$Transition, sub$treatment)
  # Chi-square test
  chi <- chisq.test(tab)
  exp <- chi$expected
  n_low <- sum(exp < 5)
  perc_low <- 100 * n_low / length(exp)
  if(any(exp < 1) || perc_low > 20) {
    fisher <- fisher.test(tab)
    chi_results <- chi_results %>%
      add_row(Sex = sex, Method = "Fisher exact", p.value = fisher$p.value)
  } else {
    chi_results <- chi_results %>%
      add_row(Sex = sex, Method = "Chi-square", p.value = chi$p.value)
  }
}
# Adjust p-values (Bonferroni)
chi_results <- chi_results %>%
  mutate(p.adj = p.adjust(p.value, method = "bonferroni"))
print(chi_results)

#---- 2. McNemar test for change in Active proportion by sex ----
mcnemar_results <- tibble(Sex=character(), p.value=numeric())
for(sex in sexes) {
  sub <- merged_all %>% filter(Sex == sex)
  before <- sub$OF_label == "Active"
  after  <- sub$OR_label == "Active"
  tab2 <- table(before, after)
  mct <- mcnemar.test(tab2)
  mcnemar_results <- mcnemar_results %>%
    add_row(Sex = sex, p.value = mct$p.value)
}
# Bonferroni adjust
mcnemar_results <- mcnemar_results %>%
  mutate(p.adj = p.adjust(p.value, method = "bonferroni"))
print(mcnemar_results)

#---- 3. Mixed-effects logistic regression: probability of stable response ----
merged_all <- merged_all %>%
  mutate(
    treatment = factor(treatment),
    Sex = factor(Sex),
    Animal = factor(Animal)
  )
glmm <- glmer(Stable ~ treatment * Sex + (1 | Animal),
              data = merged_all,
              family = binomial,
              control = glmerControl(optimizer = "bobyqa"))
summary(glmm)

#---- 4. GLM without random effect: compare AIC/BIC ----
# Fit GLM
glm_simple <- glm(Stable ~ treatment * Sex,
                  data = merged_all,
                  family = binomial)
# Compare AIC and BIC
model_comp <- tibble(
  Model = c("GLMM", "GLM"),
  AIC   = c(AIC(glmm), AIC(glm_simple)),
  BIC   = c(BIC(glmm), BIC(glm_simple))
)
print(model_comp)

#---- 5. Mosaic plot of Transition by Treatment ----
tab_treat <- table(merged_all$treatment, merged_all$Transition)
mosaic(tab_treat, shade = TRUE,
       labeling_args = list(set_varnames = c(treatment = "Treatment", Transition = "Flow")),
       main = "Mosaic: OF→OR Transition by Treatment")

#---- 6. Bar plot of Stable proportions by Treatment and Sex ----
stab_props <- merged_all %>%
  group_by(treatment, Sex) %>%
  summarise(prop_stable = mean(Stable), .groups = "drop")
ggplot(stab_props, aes(x = treatment, y = prop_stable, fill = Sex)) +
  geom_col(position = position_dodge()) +
  labs(title = "Proportion of Stable Responses by Treatment and Sex",
       x = "Treatment", y = "Proportion Stable", fill = "Sex") +
  theme_minimal()
