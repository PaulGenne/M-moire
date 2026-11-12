# Vérification des règles de tolérance taxonomique Moodle (Tribus)
f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

parse_note <- function(x) as.numeric(gsub(",", ".", as.character(x)))
pre$note_num <- parse_note(pre[["Note/20,0"]])

q_num <- 1:28
sols <- sapply(q_num, function(i) unique(pre[[paste0("Question_", i, "_solution")]])[1])

# Pour chaque participant, comparons le score officiel Moodle (pts / 28) avec :
# Hypothèse 1 : strict uniquement (genre exact)
# Hypothèse 2 : genre exact + Anthidinii pour Anthidium/Trachusa/Stelis + Halictini pour Halictus/Lasioglossum

tribu_tol <- function(g) {
  if (g %in% c("Halictus", "Lasioglossum")) return("Halictini")
  if (g %in% c("Anthidium", "Trachusa", "Stelis")) return("Anthidinii")
  return(NA)
}
tribus <- sapply(sols, tribu_tol)

calc_scores <- sapply(1:nrow(pre), function(r) {
  strict <- sum(sapply(q_num, function(i) {
    rep <- trimws(tolower(pre[r, paste0("Question_", i, "_reply")]))
    sol <- tolower(sols[i])
    rep == sol
  }))
  moodle <- sum(sapply(q_num, function(i) {
    rep <- trimws(tolower(pre[r, paste0("Question_", i, "_reply")]))
    sol <- tolower(sols[i])
    tri <- tolower(tribus[i])
    rep == sol || (!is.na(tri) && rep == tri)
  }))
  c(strict = strict, moodle = moodle)
})

pre$pts_officiels <- round(pre$note_num / 20 * 28)
res <- data.frame(
  ID = pre$ID,
  Note_20 = pre$note_num,
  Pts_Moodle_Reel = pre$pts_officiels,
  Pts_Strict_Calc = calc_scores["strict", ],
  Pts_Tribu_Calc = calc_scores["moodle", ]
)
res$Diff_Strict_Reel = res$Pts_Strict_Calc - res$Pts_Moodle_Reel
res$Diff_Tribu_Reel = res$Pts_Tribu_Calc - res$Pts_Moodle_Reel
print(head(res, 15))
cat("\nNombre de correspondances parfaites Hypothèse Strict :", sum(res$Diff_Strict_Reel == 0), "/", nrow(res), "\n")
cat("Nombre de correspondances parfaites Hypothèse Tribu  :", sum(res$Diff_Tribu_Reel == 0), "/", nrow(res), "\n")

