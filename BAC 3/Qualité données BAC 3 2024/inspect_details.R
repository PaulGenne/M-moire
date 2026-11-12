# Inspection détaillée des réponses et du barème
f_post <- "BAC 3/UMONS_posttest_2024.csv"
post_raw <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
q_cols <- colnames(post_raw)[7:32]
genres_attendus <- sapply(strsplit(q_cols, "_"), function(x) x[2])

# Regardons pour B3_24_02 (note = 18.5)
reps <- trimws(as.character(post_raw[2, q_cols]))
for(i in 1:26) {
  cat(sprintf("Q%02d: Attendu = %-12s | Reponse = %-12s | Match exact = %s\n", 
              i, genres_attendus[i], reps[i], tolower(genres_attendus[i]) == tolower(reps[i])))
}
