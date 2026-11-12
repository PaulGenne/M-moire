# Inspection approfondie des cas particuliers
f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

cat("=== INSPECTION B3_25_11 (Posttest) ===\n")
row_11 <- post[post$ID == "B3_25_11", ]
print(row_11[, 1:10])

# Quelles sont les questions omises par B3_25_11 ?
q_reply_cols <- grep("_reply$", colnames(post), value = TRUE)
omises_11 <- sapply(row_11[, q_reply_cols], function(x) is.na(x) || trimws(x) == "" || trimws(x) == "-")
cat("Colonnes omises par B3_25_11 :\n")
print(names(omises_11)[omises_11])

cat("\n=== INSPECTION B3_25_24 (Pretest) ===\n")
row_24 <- pre[pre$ID == "B3_25_24", ]
print(row_24[, 1:10])

cat("\n=== INSPECTION B3_25_04 (Pretest vs Posttest) ===\n")
cat("Pretest B3_25_04:\n")
row_04_pre <- pre[pre$ID == "B3_25_04", ]
print(row_04_pre[, 1:10])
cat("Posttest B3_25_04:\n")
row_04_post <- post[post$ID == "B3_25_04", ]
print(row_04_post[, 1:10])

cat("\n=== INSPECTION B3_25_20 (Pretest vs Posttest) ===\n")
cat("Pretest B3_25_20:\n")
row_20_pre <- pre[pre$ID == "B3_25_20", ]
print(row_20_pre[, 1:10])
cat("Posttest B3_25_20:\n")
row_20_post <- post[post$ID == "B3_25_20", ]
print(row_20_post[, 1:10])

# Vérification des dates et délais
cat("\n=== DATES DE DÉBUT ET FIN (Pretest) ===\n")
print(pre[, c("ID", "Commencé", "Terminé", "Durée")])

cat("\n=== DATES DE DÉBUT ET FIN (Posttest) ===\n")
print(post[, c("ID", "Commencé", "Terminé", "Durée")])

