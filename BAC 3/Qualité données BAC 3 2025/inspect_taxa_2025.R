# Audit des réponses textuelles aux 28 questions (Pretest et Posttest 2025)
f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

q_reply_cols <- grep("_reply$", colnames(pre), value = TRUE)

all_replies_pre <- unlist(pre[, q_reply_cols])
all_replies_post <- unlist(post[, q_reply_cols])

cat("=== RÉPONSES UNIQUES PRETEST ===\n")
print(table(all_replies_pre))

cat("\n=== RÉPONSES UNIQUES POSTTEST ===\n")
print(table(all_replies_post))

