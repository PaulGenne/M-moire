pre <- read.csv("BAC 3/UMONS_Pretest_2025.csv", sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
for (id in c("B3_25_03", "B3_25_10")) {
  r <- pre[pre$ID == id, ]
  cat("=== ID:", id, "Note:", r[["Note/20,0"]], "===\n")
  for (i in 1:28) {
    sol <- r[[paste0("Question_", i, "_solution")]]
    rep <- r[[paste0("Question_", i, "_reply")]]
    cat(sprintf("Q%02d: Sol=%-12s | Rep=%-12s\n", i, sol, rep))
  }
}

