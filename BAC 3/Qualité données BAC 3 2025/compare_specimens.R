# Comparaison des spécimens 2024 vs 2025
f_2024 <- "BAC 3/UMONS_Pretest_2024.csv"
f_2025 <- "BAC 3/UMONS_Pretest_2025.csv"

d24 <- read.csv(f_2024, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
d25 <- read.csv(f_2025, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

q24 <- colnames(d24)[7:32]
cat("Questions 2024 (26):\n")
print(q24)

# 2025
q_sol_cols <- paste0("Question_", 1:28, "_solution")
q_sex_cols <- paste0("Question_", 1:28, "_sex")
sols_25 <- sapply(q_sol_cols, function(c) unique(d25[[c]])[1])
sex_25  <- sapply(q_sex_cols, function(c) unique(d25[[c]])[1])

cat("\nQuestions 2025 (28):\n")
print(data.frame(Q = 1:28, Solution = sols_25, Sex = ifelse(sex_25 == "FALSE", "F", sex_25)))

