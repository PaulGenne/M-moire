# Script d'inspection et de profilage détaillé : BAC 3 2025
# Pretest et Posttest

f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

cat("=== DIMENSIONS ===\n")
cat(sprintf("Pretest 2025  : %d lignes, %d colonnes\n", nrow(pre), ncol(pre)))
cat(sprintf("Posttest 2025 : %d lignes, %d colonnes\n\n", nrow(post), ncol(post)))

# Vérification des IDs
cat("=== IDENTIFIANTS (ID) ===\n")
cat("Pretest IDs:\n")
print(sort(pre$ID))
cat("Posttest IDs:\n")
print(sort(post$ID))

cat("\nDoublons d'ID dans Pretest  :", anyDuplicated(pre$ID), "\n")
cat("Doublons d'ID dans Posttest :", anyDuplicated(post$ID), "\n")

ids_pre <- sort(unique(pre$ID))
ids_post <- sort(unique(post$ID))

communs <- intersect(ids_pre, ids_post)
pre_only <- setdiff(ids_pre, ids_post)
post_only <- setdiff(ids_post, ids_pre)

cat(sprintf("\nIDs communs (appariés) : %d\n", length(communs)))
print(communs)
cat(sprintf("IDs uniquement dans Pretest : %d\n", length(pre_only)))
print(pre_only)
cat(sprintf("IDs uniquement dans Posttest : %d\n", length(post_only)))
print(post_only)

# Analyse des colonnes
cat("\n=== STRUCTURE DES COLONNES ===\n")
meta_cols <- colnames(pre)[1:5]
cat("Colonnes métadonnées :", paste(meta_cols, collapse = ", "), "\n")

q_reply_cols <- grep("_reply$", colnames(pre), value = TRUE)
cat(sprintf("Nombre de colonnes de réponse (_reply) : %d\n", length(q_reply_cols)))

# Notes
parse_note <- function(x) as.numeric(gsub(",", ".", as.character(x)))
pre$note_num <- parse_note(pre[["Note/20,0"]])
post$note_num <- parse_note(post[["Note/20,0"]])

cat("\n=== NOTES / 20 ===\n")
cat("Pretest summary:\n")
print(summary(pre$note_num))
cat("Posttest summary:\n")
print(summary(post$note_num))

# Durée
parse_duration_min <- function(dur_str) {
  sapply(dur_str, function(d) {
    if (is.na(d) || d == "") return(NA)
    total_sec <- 0
    m_j <- regexec("([0-9]+)\\s*jour", d); r_j <- regmatches(d, m_j)[[1]]
    if (length(r_j) >= 2) total_sec <- total_sec + as.numeric(r_j[2]) * 86400
    m_h <- regexec("([0-9]+)\\s*heure", d); r_h <- regmatches(d, m_h)[[1]]
    if (length(r_h) >= 2) total_sec <- total_sec + as.numeric(r_h[2]) * 3600
    m_m <- regexec("([0-9]+)\\s*min", d); r_m <- regmatches(d, m_m)[[1]]
    if (length(r_m) >= 2) total_sec <- total_sec + as.numeric(r_m[2]) * 60
    m_s <- regexec("([0-9]+)\\s*s", d); r_s <- regmatches(d, m_s)[[1]]
    if (length(r_s) >= 2) total_sec <- total_sec + as.numeric(r_s[2])
    return(round(total_sec / 60, 2))
  })
}

pre$duree_min <- parse_duration_min(pre$Durée)
post$duree_min <- parse_duration_min(post$Durée)

cat("\n=== DURÉES (minutes) ===\n")
cat("Pretest durées:\n")
print(summary(pre$duree_min))
cat("Posttest durées:\n")
print(summary(post$duree_min))

# Vérification des complétudes et omissions
pre$nb_omissions <- apply(pre[, q_reply_cols], 1, function(r) sum(is.na(r) | trimws(r) == "" | trimws(r) == "-"))
post$nb_omissions <- apply(post[, q_reply_cols], 1, function(r) sum(is.na(r) | trimws(r) == "" | trimws(r) == "-"))

cat("\n=== OMISSIONS DANS PRETEST ===\n")
print(table(pre$nb_omissions))
cat("\n=== OMISSIONS DANS POSTTEST ===\n")
print(table(post$nb_omissions))

# Idk
pre$nb_idk <- apply(pre[, q_reply_cols], 1, function(r) sum(grepl("je ne sais pas|don.*t know", r, ignore.case = TRUE)))
post$nb_idk <- apply(post[, q_reply_cols], 1, function(r) sum(grepl("je ne sais pas|don.*t know", r, ignore.case = TRUE)))

cat("\n=== RÉPONSES 'JE NE SAIS PAS' ===\n")
cat("Pretest idk:\n")
print(table(pre$nb_idk))
cat("Posttest idk:\n")
print(table(post$nb_idk))

# Détail complet par participant
cat("\n=== DÉTAILS PARTICIPANTS PRETEST ===\n")
print(data.frame(ID = pre$ID, Duree = pre$Durée, Duree_min = pre$duree_min, Note = pre$note_num, Omissions = pre$nb_omissions, IDK = pre$nb_idk))

cat("\n=== DÉTAILS PARTICIPANTS POSTTEST ===\n")
print(data.frame(ID = post$ID, Duree = post$Durée, Duree_min = post$duree_min, Note = post$note_num, Omissions = post$nb_omissions, IDK = post$nb_idk))

