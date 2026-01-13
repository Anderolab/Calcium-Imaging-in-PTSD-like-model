# 1) Create contingency table

data <- matrix(c(8,8,20,15,269,274),
               nrow = 3, byrow = TRUE)
colnames(data) <- c("Veh", "Cort")
rownames(data) <- c("Active", "Inactive", "Neutral")
print(data)
# ------------------------------
# 2) Chi-square test and standarized residuals
chi_square_result <- chisq.test(data, correct = FALSE)
chi_square_result

# Extract standarized residuals (z-scores)
stdres <- chi_square_result$stdres
stdres  # Matrix of z-values

# ------------------------------
# 3) Convert z-values to  p-values (bilaterals)

# For each cell, p = 2 * P(Z > |z|)
pvals <- 2 * pnorm(-abs(stdres))
# 4) Apply HOLM correction

# a) Convert p matrix to a vector
pvals_vector <- as.vector(pvals)

# b) Adjust the p-values "holm"
pvals_holm <- p.adjust(pvals_vector, method = "holm")

# c) Reshape back into a matrix (to visualize each cell)
pvals_holm_matrix <- matrix(pvals_holm,
                            nrow = nrow(stdres),
                            ncol = ncol(stdres),
                            byrow = FALSE,
                            dimnames = dimnames(stdres))

pvals_holm_matrix
#------------------------------------------------
# 5) Assign asterisks according to p-value ranges

#Define an auxiliary function that assigns the asterisks
star_code <- function(pval) {
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

# Apply the function to each cell of the pvals_holm_matrix matrix
asterisks_matrix <- matrix(
  sapply(pvals_holm_matrix, star_code),
  nrow = nrow(pvals_holm_matrix),
  ncol = ncol(pvals_holm_matrix),
  dimnames = dimnames(pvals_holm_matrix)
)

asterisks_matrix