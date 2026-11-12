# Vérification des questions, solutions et sexes (Pretest vs Posttest)
f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

# Vérifier si solutions et sexes sont constants par colonne
q_num <- 1:28
questions_pre <- data.frame(
  Q = q_num,
  Solution_Pre = sapply(q_num, function(i) unique(pre[[paste0("Question_", i, "_solution")]])[1]),
  Sex_Pre = sapply(q_num, function(i) unique(pre[[paste0("Question_", i, "_sex")]])[1]),
  Nb_Sol_Pre = sapply(q_num, function(i) length(unique(pre[[paste0("Question_", i, "_solution")]][pre[[paste0("Question_", i, "_solution")]] != ""]))),
  Nb_Sex_Pre = sapply(q_num, function(i) length(unique(pre[[paste0("Question_", i, "_sex")]][pre[[paste0("Question_", i, "_sex")]] != ""])))
)

questions_post <- data.frame(
  Q = q_num,
  Solution_Post = sapply(q_num, function(i) unique(post[[paste0("Question_", i, "_solution")]])[1]),
  Sex_Post = sapply(q_num, function(i) unique(post[[paste0("Question_", i, "_sex")]])[1]),
  Nb_Sol_Post = sapply(q_num, function(i) length(unique(post[[paste0("Question_", i, "_solution")]][post[[paste0("Question_", i, "_solution")]] != ""]))),
  Nb_Sex_Post = sapply(q_num, function(i) length(unique(post[[paste0("Question_", i, "_sex")]][post[[paste0("Question_", i, "_sex")]] != ""])))
)

q_comp <- merge(questions_pre, questions_post, by = "Q")
cat("=== COMPARAISON DES QUESTIONS PRETEST vs POSTTEST 2025 ===\n")
print(q_comp)

# Vérifions aussi si la note correspond au nombre de bonnes réponses
score_calc_pre <- sapply(1:nrow(pre), function(r) {
  sum(sapply(q_num, function(i) {
    sol <- pre[r, paste0("Question_", i, "_solution")]
    rep <- pre[r, paste0("Question_", i, "_reply")]
    # Vérifier si rep correspond à sol
    # Attention aux règles Moodle pour Halictini, Anthidinii, etc.
    return(tolower(trimws(sol)) == tolower(trimws(rep)))
  }))
})

cat("\nScores calculés Pretest (sur 28) :\n")
print(data.frame(ID = pre$ID, Note_20 = pre$note_num, Bonnes_rep_28 = score_calc_pre, Note_estimee = round(score_calc_pre / 28 * 20, 1)))

# Idem pour posttest
score_calc_post <- sapply(1:nrow(post), function(r) {
  sum(sapply(q_num, function(i) {
    sol <- post[r, paste0("Question_", i, "_solution")]
    rep <- post[r, paste0("Question_", i, "_reply")]
    return(tolower(trimws(sol)) == tolower(trimws(rep)))
  }))
})

cat("\nScores calculés Posttest (sur 28) :\n")
print(data.frame(ID = post$ID, Note_20 = post$note_num, Bonnes_rep_28 = score_calc_post, Note_estimee = round(score_calc_post / 28 * 20, 1)))

