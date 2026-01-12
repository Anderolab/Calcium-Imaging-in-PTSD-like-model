# 1. Define contingency table
data <- matrix(c(15,9,2,29,248,227),
               nrow = 3, byrow = TRUE)
colnames(data) <- c("Veh", "Cort")
rownames(data) <- c("Active","Inactive", "Neutral")
print(data)
#
# 2. Global Fisher-Freeman-Halton test
global_test <- fisher.test(data)
print(global_test)

# 3. Fisher's exact test by each row
pvals_fisher_per_row <- numeric(nrow(data))

for (i in 1:nrow(data)) {
  #We extract the row and convert it into a 2×2 table
  sub_table <- matrix(c(data[i, "Veh"], data[i, "Cort"],
                        sum(data[-i, "Veh"]), sum(data[-i, "Cort"])),
                      nrow = 2, byrow = TRUE)
  
  # Fisher’s exact test on row i
  fisher_row <- fisher.test(sub_table)
  
  # Save p-value
  pvals_fisher_per_row[i] <- fisher_row$p.value
}

# 4. Row-wise p-value correction (Holm)
pvals_fisher_holm <- p.adjust(pvals_fisher_per_row, method = "holm")
names(pvals_fisher_holm) <- rownames(data)

# Function to assign asterisks based on the p-value
asterisk_code <- function(pval) {
  if (pval < 0.001) {
    return("***")
  } else if (pval < 0.01) {
    return("**")
  } else if (pval < 0.05) {
    return("*")
  } else {
    return("")
  }
}

# We apply the function to each row-wise Holm-adjusted Fisher p-value
asterisks_fisher <- sapply(pvals_fisher_holm, asterisk_code)

# 5. Display results with asterisks
cat("\n🔹 Adjusted Fisher p-values by row:\n")
print(pvals_fisher_holm)

cat("\n🔹 Astersiks by row:\n")
print(asterisks_fisher)
