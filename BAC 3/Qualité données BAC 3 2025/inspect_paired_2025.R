# Analyse appariée Pretest - Posttest 2025
f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

parse_note <- function(x) as.numeric(gsub(",", ".", as.character(x)))
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

pre$note_num <- parse_note(pre[["Note/20,0"]])
post$note_num <- parse_note(post[["Note/20,0"]])
pre$duree_min <- parse_duration_min(pre$Durée)
post$duree_min <- parse_duration_min(post$Durée)

q_reply_cols <- grep("_reply$", colnames(pre), value = TRUE)
pre$nb_idk <- apply(pre[, q_reply_cols], 1, function(r) sum(grepl("je ne sais pas|don.*t know", r, ignore.case = TRUE)))
post$nb_idk <- apply(post[, q_reply_cols], 1, function(r) sum(grepl("je ne sais pas|don.*t know", r, ignore.case = TRUE)))

pre$nb_omissions <- apply(pre[, q_reply_cols], 1, function(r) sum(is.na(r) | trimws(r) == "" | trimws(r) == "-"))
post$nb_omissions <- apply(post[, q_reply_cols], 1, function(r) sum(is.na(r) | trimws(r) == "" | trimws(r) == "-"))

# Appariement
communs <- intersect(pre$ID, post$ID)

df_paired <- merge(
  pre[, c("ID", "Commencé", "Terminé", "Durée", "duree_min", "note_num", "nb_idk", "nb_omissions")],
  post[, c("ID", "Commencé", "Terminé", "Durée", "duree_min", "note_num", "nb_idk", "nb_omissions")],
  by = "ID",
  suffixes = c("_Pre", "_Post")
)

df_paired$Delta_Note <- round(df_paired$note_num_Post - df_paired$note_num_Pre, 2)
df_paired$Delta_Duree <- round(df_paired$duree_min_Post - df_paired$duree_min_Pre, 2)
df_paired$Delta_IDK <- df_paired$nb_idk_Post - df_paired$nb_idk_Pre

df_paired <- df_paired[order(df_paired$ID), ]

cat("=== TABLEAU COMPLET DES 22 PARTICIPANTS APPARIÉS ===\n")
print(df_paired[, c("ID", "note_num_Pre", "note_num_Post", "Delta_Note", "duree_min_Pre", "duree_min_Post", "nb_idk_Pre", "nb_idk_Post")])

cat("\n=== PARTICIPANTS NON APPARIÉS ===\n")
cat("Pretest uniquement :\n")
print(pre[pre$ID %in% setdiff(pre$ID, post$ID), c("ID", "note_num", "Durée", "duree_min", "nb_idk", "nb_omissions")])
cat("\nPosttest uniquement :\n")
print(post[post$ID %in% setdiff(post$ID, pre$ID), c("ID", "note_num", "Durée", "duree_min", "nb_idk", "nb_omissions")])

