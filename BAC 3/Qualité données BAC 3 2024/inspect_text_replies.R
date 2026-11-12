# Inspection approfondie des valeurs textuelles des réponses
f_pre  <- "BAC 3/UMONS_Pretest_2024.csv"
f_post <- "BAC 3/UMONS_posttest_2024.csv"

pre_raw  <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post_raw <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

q_cols <- colnames(pre_raw)[7:32]

# Lister toutes les réponses uniques données dans le Pretest
reps_pre <- sort(unique(unlist(lapply(pre_raw[, q_cols], as.character))))
cat("=== Réponses uniques dans Pretest 2024 ===\n")
print(reps_pre)

# Lister toutes les réponses uniques données dans le Posttest
reps_post <- sort(unique(unlist(lapply(post_raw[, q_cols], as.character))))
cat("\n=== Réponses uniques dans Posttest 2024 ===\n")
print(reps_post)

# Fréquence de chaque réponse au Pretest
cat("\nTop réponses au Pretest :\n")
print(sort(table(unlist(pre_raw[, q_cols])), decreasing = TRUE))

# Fréquence de chaque réponse au Posttest
cat("\nTop réponses au Posttest :\n")
print(sort(table(unlist(post_raw[, q_cols])), decreasing = TRUE))

