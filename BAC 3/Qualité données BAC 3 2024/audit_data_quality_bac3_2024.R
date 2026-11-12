# ==============================================================================
# AUDIT DE QUALITÉ DES DONNÉES ET PROFILAGE (Étape 1) : BAC 3 2024 (PRE & POST)
# Projet de mémoire : Apprentissage de l'identification des abeilles sauvages
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. Configuration de l'environnement et dossiers
dossier_script <- "BAC 3/Qualité données BAC 3 2024"
dossier_output <- file.path(dossier_script, "output")

if (!dir.exists(dossier_output)) {
  dir.create(dossier_output, recursive = TRUE)
}

# Fonction d'export conforme AGENTS.md (UTF-8 avec BOM, séparateur ';' et décimale ',')
exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat(sprintf("  -> Fichier CSV exporté avec succès : %s\n", chemin_fichier))
}

# 1. Chargement des données brutes
f_pre  <- "BAC 3/UMONS_Pretest_2024.csv"
f_post <- "BAC 3/UMONS_posttest_2024.csv"

pre_raw  <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post_raw <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

cat("======================================================================\n")
cat("=== CHARGEMENT DES DONNÉES BRUTES (BAC 3 2024) ===\n")
cat("======================================================================\n")
cat(sprintf("Pretest  : %d participants, %d colonnes\n", nrow(pre_raw), ncol(pre_raw)))
cat(sprintf("Posttest : %d participants, %d colonnes\n\n", nrow(post_raw), ncol(post_raw)))

# 2. Fonctions d'ingénierie des variables et profilage
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

q_cols <- colnames(pre_raw)[7:32]
nb_total_q <- length(q_cols)

enrich_dataset <- function(df, cohorte_name) {
  df$Cohorte <- cohorte_name
  df$note_num <- parse_note(df[["Note/20,0"]])
  df$duree_min <- parse_duration_min(df$Durée)
  
  # Omissions : cases vides ou tirets "-"
  df$nb_omissions <- apply(df[, q_cols], 1, function(row) {
    sum(is.na(row) | trimws(row) == "" | trimws(row) == "-")
  })
  df$nb_repondu <- nb_total_q - df$nb_omissions
  df$taux_completude_pct <- round((df$nb_repondu / nb_total_q) * 100, 1)
  
  # Réponses "Je ne sais pas"
  df$nb_idk <- apply(df[, q_cols], 1, function(row) {
    sum(grepl("je ne sais pas|don.*t know", row, ignore.case = TRUE))
  })
  
  # Clôture administrative Moodle (détection fin de test à heure pile, ex. 08:00)
  df$cloture_auto_moodle <- grepl("08:00$|12:00$|09:00$", trimws(df$Terminé))
  
  # Statut Qualité univarié (intra-test)
  df$Statut_Qualite <- "Valide (Complet 26/26)"
  df$Statut_Qualite[df$nb_repondu == 25] <- "Valide (Omission ponctuelle 25/26)"
  df$Statut_Qualite[df$nb_repondu > 3 & df$nb_repondu < 13] <- "Exclu (Incomplétude majeure < 50%)"
  df$Statut_Qualite[df$nb_repondu >= 1 & df$nb_repondu <= 3] <- "Exclu (Abandon précoce <= 3 questions)"
  df$Statut_Qualite[df$nb_repondu == 0] <- "Exclu (Abandon complet 0 question)"
  
  df$Decision_Inclusion_Univariee <- ifelse(grepl("^Exclu", df$Statut_Qualite), "Exclure", "Conserver")
  
  df$Motif_Exclusion <- ""
  df$Motif_Exclusion[df$Statut_Qualite == "Exclu (Abandon précoce <= 3 questions)"] <- 
    "Abandon quasi-immédiat (1 question tentée sur 26) ; clôture automatique Moodle à 08:00 par expiration de délai"
  df$Motif_Exclusion[df$Statut_Qualite == "Exclu (Incomplétude majeure < 50%)"] <- 
    "Test incomplet arrêté en cours (< 50% répondu)"
  df$Motif_Exclusion[df$Statut_Qualite == "Exclu (Abandon complet 0 question)"] <- 
    "Aucune question tentée (0/26)"
  
  return(df)
}

pre_enriched  <- enrich_dataset(pre_raw, "Pretest")
post_enriched <- enrich_dataset(post_raw, "Posttest")

# 3. Analyse de l'appariement longitudinal (Design intra-sujet Pré-Post)
ids_pre_valides  <- pre_enriched$ID[pre_enriched$Decision_Inclusion_Univariee == "Conserver"]
ids_post_valides <- post_enriched$ID[post_enriched$Decision_Inclusion_Univariee == "Conserver"]
ids_apparies     <- intersect(ids_pre_valides, ids_post_valides)

cat(sprintf("Participants Pretest brut      : %d\n", nrow(pre_enriched)))
cat(sprintf("Participants Pretest valide    : %d (1 exclu : B3_24_27)\n", length(ids_pre_valides)))
cat(sprintf("Participants Posttest brut     : %d\n", nrow(post_enriched)))
cat(sprintf("Participants Posttest valide   : %d (0 exclu univarié)\n", length(ids_post_valides)))
cat(sprintf("Participants appariés (Pre+Post): %d\n\n", length(ids_apparies)))

# Ajout du statut d'appariement
pre_enriched$Apparie <- pre_enriched$ID %in% ids_apparies
post_enriched$Apparie <- post_enriched$ID %in% ids_apparies

pre_enriched$Decision_Inclusion_Apparie <- ifelse(pre_enriched$Apparie, "Conserver", "Exclure (Non apparié)")
post_enriched$Decision_Inclusion_Apparie <- ifelse(post_enriched$Apparie, "Conserver", "Exclure (Non apparié)")

# Préciser les motifs pour les non appariés
pre_enriched$Motif_Exclusion[pre_enriched$Decision_Inclusion_Univariee == "Conserver" & !pre_enriched$Apparie] <- 
  "Présent au Pré-test mais absent au Post-test (Attrition post-formation)"

post_enriched$Motif_Exclusion[post_enriched$Decision_Inclusion_Univariee == "Conserver" & !post_enriched$Apparie] <- 
  "Présent au Post-test uniquement (Absent au Pré-test initial)"

# 4. Table d'audit consolidée (AGENTS.md Règle 5)
# Consignation de TOUTES les anomalies et exclusions (univariées ou d'appariement)
audit_anomalies <- rbind(
  pre_enriched[pre_enriched$Decision_Inclusion_Apparie != "Conserver" | pre_enriched$Decision_Inclusion_Univariee == "Exclure", ],
  post_enriched[post_enriched$Decision_Inclusion_Apparie != "Conserver" | post_enriched$Decision_Inclusion_Univariee == "Exclure", ]
)

tableau_audit <- data.frame(
  Cohorte = audit_anomalies$Cohorte,
  N_ID = audit_anomalies$ID,
  Statut_Tentative = "Tentative unique",
  Statut_Qualite_Test = audit_anomalies$Statut_Qualite,
  Decision_Inclusion_Globale = audit_anomalies$Decision_Inclusion_Univariee,
  Decision_Inclusion_Apparie = audit_anomalies$Decision_Inclusion_Apparie,
  Motif_Exclusion = audit_anomalies$Motif_Exclusion,
  Questions_Repondues = audit_anomalies$nb_repondu,
  Questions_Omises = audit_anomalies$nb_omissions,
  Taux_Completude_Pct = audit_anomalies$taux_completude_pct,
  Duree_Affichee = audit_anomalies$Durée,
  Duree_Minutes = audit_anomalies$duree_min,
  Score_Obtenu_Sur_20 = audit_anomalies$note_num,
  Date_Debut = audit_anomalies$Commencé,
  Date_Fin = audit_anomalies$Terminé,
  Cloture_Auto_Moodle = ifelse(audit_anomalies$cloture_auto_moodle, "Oui (Expiration)", "Non")
)

cat("======================================================================\n")
cat("=== TABLEAU D'AUDIT QUALITÉ ET TRAÇABILITÉ DES EXCLUSIONS ===\n")
cat("======================================================================\n")
print(tableau_audit[, c("Cohorte", "N_ID", "Statut_Qualite_Test", "Decision_Inclusion_Apparie", "Questions_Repondues", "Score_Obtenu_Sur_20", "Duree_Affichee")])

exporter_excel_csv(tableau_audit, file.path(dossier_output, "participants_anomalies_qualite_bac3_2024.csv"))

# 5. Export des jeux de données nettoyés
cols_export <- c("ID", "Commencé", "Terminé", "Durée", "Note/20,0", "Feedback", q_cols)

# A. Datasets nettoyés univariés (tous participants valides)
pre_clean_univ  <- pre_enriched[pre_enriched$Decision_Inclusion_Univariee == "Conserver", cols_export]
post_clean_univ <- post_enriched[post_enriched$Decision_Inclusion_Univariee == "Conserver", cols_export]

exporter_excel_csv(pre_clean_univ, file.path(dossier_output, "BAC3_2024_Pretest_clean.csv"))
exporter_excel_csv(post_clean_univ, file.path(dossier_output, "BAC3_2024_Posttest_clean.csv"))

# B. Dataset apparié strict (N = 25 participants ayant complété Pré et Post)
pre_paired  <- pre_enriched[pre_enriched$Apparie, ]
post_paired <- post_enriched[post_enriched$Apparie, ]

# Trier par ID pour un alignement parfait
pre_paired  <- pre_paired[order(pre_paired$ID), ]
post_paired <- post_paired[order(post_paired$ID), ]

df_paired <- data.frame(
  ID = pre_paired$ID,
  # Pretest
  Pre_Commence = pre_paired$Commencé,
  Pre_Termine  = pre_paired$Terminé,
  Pre_Duree    = pre_paired$Durée,
  Pre_Duree_min= pre_paired$duree_min,
  Pre_Note     = pre_paired$note_num,
  Pre_Repondu  = pre_paired$nb_repondu,
  Pre_IDK      = pre_paired$nb_idk,
  # Posttest
  Post_Commence = post_paired$Commencé,
  Post_Termine  = post_paired$Terminé,
  Post_Duree    = post_paired$Durée,
  Post_Duree_min= post_paired$duree_min,
  Post_Note     = post_paired$note_num,
  Post_Repondu  = post_paired$nb_repondu,
  Post_IDK      = post_paired$nb_idk,
  # Évolution (Delta)
  Delta_Note    = round(post_paired$note_num - pre_paired$note_num, 2),
  Progression_Pct = round(((post_paired$note_num - pre_paired$note_num) / 20) * 100, 1)
)

exporter_excel_csv(df_paired, file.path(dossier_output, "BAC3_2024_paired_clean.csv"))

# 6. Tableau comparatif d'impact du nettoyage (Avant vs Après)
stats_summary <- function(vals, nom_groupe) {
  data.frame(
    Groupe = nom_groupe,
    N = length(vals),
    Moyenne = round(mean(vals, na.rm = TRUE), 2),
    Ecart_Type = round(sd(vals, na.rm = TRUE), 2),
    Mediane = round(median(vals, na.rm = TRUE), 2),
    Q1 = round(quantile(vals, 0.25, na.rm = TRUE), 2),
    Q3 = round(quantile(vals, 0.75, na.rm = TRUE), 2),
    Min = round(min(vals, na.rm = TRUE), 2),
    Max = round(max(vals, na.rm = TRUE), 2)
  )
}

tab_impact <- rbind(
  stats_summary(pre_enriched$note_num, "1. Pretest Brut (Total)"),
  stats_summary(pre_enriched$note_num[pre_enriched$Decision_Inclusion_Univariee == "Conserver"], "2. Pretest Nettoyé (sans B3_24_27)"),
  stats_summary(pre_paired$note_num, "3. Pretest Apparié strict (N=25)"),
  stats_summary(post_enriched$note_num, "4. Posttest Brut (Total)"),
  stats_summary(post_paired$note_num, "5. Posttest Apparié strict (N=25)"),
  stats_summary(df_paired$Delta_Note, "6. Gain de score (Post - Pre) Apparié")
)

cat("\n======================================================================\n")
cat("=== TABLEAU D'IMPACT STATISTIQUE DU PROFILAGE ET NETTOYAGE ===\n")
cat("======================================================================\n")
print(tab_impact)

exporter_excel_csv(tab_impact, file.path(dossier_output, "tableau_impact_nettoyage_bac3_2024.csv"))

# 7. Visualisations graphiques haute définition (AGENTS.md Charte graphique)
# Graphique 1 : Diagramme de flux et distribution des scores (Pre vs Post)
png(file.path(dossier_output, "comparaison_scores_pre_post_bac3_2024.png"),
    width = 3000, height = 2200, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

scores_pre_app  <- pre_paired$note_num
scores_post_app <- post_paired$note_num

# Boxplot élégant
b <- boxplot(list("Pré-test\n(Initial)" = scores_pre_app, 
                  "Post-test\n(Après formation)" = scores_post_app),
             col = c("#4A90E2", "#2E7D32"),
             border = c("#1B365D", "#1B365D"),
             ylim = c(0, 22),
             ylab = "Score obtenu (/20)",
             main = "Évolution des performances d'identification des abeilles (BAC 3 - 2024)",
             cex.main = 1.3, font.main = 2, col.main = "#1B365D",
             cex.lab = 1.1, font.lab = 2,
             outline = FALSE)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
boxplot(list("Pré-test\n(Initial)" = scores_pre_app, 
             "Post-test\n(Après formation)" = scores_post_app),
        col = c("#4A90E2", "#2E7D32"),
        border = c("#1B365D", "#1B365D"),
        add = TRUE, outline = FALSE)

# Ajout des points individuels appariés reliés par un trait
set.seed(42)
jitter_x <- jitter(rep(1, length(scores_pre_app)), amount = 0.05)
jitter_x2 <- jitter(rep(2, length(scores_post_app)), amount = 0.05)

for (i in seq_along(scores_pre_app)) {
  lines(c(jitter_x[i], jitter_x2[i]), c(scores_pre_app[i], scores_post_app[i]), 
        col = "#8E44AD44", lwd = 1.5)
  points(jitter_x[i], scores_pre_app[i], pch = 21, bg = "#4A90E2", col = "#1B365D", cex = 1.3)
  points(jitter_x2[i], scores_post_app[i], pch = 21, bg = "#2E7D32", col = "#1B365D", cex = 1.3)
}

# Annotations directes des moyennes et effectifs
m_pre <- mean(scores_pre_app)
m_post <- mean(scores_post_app)
text(1, 21, sprintf("Moyenne = %.2f/20\n(N = %d)", m_pre, length(scores_pre_app)), 
     col = "#1B365D", font = 2, cex = 1.0)
text(2, 21, sprintf("Moyenne = %.2f/20\n(N = %d)", m_post, length(scores_post_app)), 
     col = "#1B365D", font = 2, cex = 1.0)

# Légende
legend("bottomright", 
       legend = c("Pré-test initial (N = 25)", "Post-test après TP (N = 25)", "Trajectoires individuelles"),
       fill = c("#4A90E2", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", NA),
       lty = c(NA, NA, 1), col = c(NA, NA, "#8E44AD"),
       lwd = c(NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Graphique généré : output/comparaison_scores_pre_post_bac3_2024.png\n")

# Graphique 2 : Profilage de la complétude et anomalies de durées
png(file.path(dossier_output, "profilage_duree_completude_bac3_2024.png"),
    width = 3200, height = 2200, res = 300, bg = "white")

par(mar = c(5, 5, 4, 3), family = "sans", las = 1)

plot(pre_enriched$duree_min, pre_enriched$note_num,
     pch = ifelse(pre_enriched$Decision_Inclusion_Univariee == "Exclure", 4, 21),
     bg = ifelse(pre_enriched$Decision_Inclusion_Univariee == "Exclure", "#C62828", "#4A90E2"),
     col = ifelse(pre_enriched$Decision_Inclusion_Univariee == "Exclure", "#C62828", "#1B365D"),
     cex = ifelse(pre_enriched$Decision_Inclusion_Univariee == "Exclure", 2.2, 1.5),
     lwd = ifelse(pre_enriched$Decision_Inclusion_Univariee == "Exclure", 3, 1),
     log = "x",
     xlab = "Durée de passation (minutes, échelle logarithmique)",
     ylab = "Score obtenu au Pré-test (/20)",
     main = "Audit de qualité : Durée de session vs Score (Pré-test BAC 3 - 2024)",
     cex.main = 1.3, font.main = 2, col.main = "#1B365D",
     ylim = c(0, 20))

grid(col = "grey90", lty = 1)

# Annoter les cas remarquables
# B3_24_27 (Exclu)
idx_27 <- which(pre_enriched$ID == "B3_24_27")
text(pre_enriched$duree_min[idx_27], pre_enriched$note_num[idx_27] + 0.8,
     "B3_24_27 (Exclu : 1/26 répondu, 3j 14h)", col = "#C62828", font = 2, pos = 2, cex = 0.9)

# B3_24_03 (Session laissée ouverte 1j 17h)
idx_03 <- which(pre_enriched$ID == "B3_24_03")
text(pre_enriched$duree_min[idx_03], pre_enriched$note_num[idx_03] + 0.8,
     "B3_24_03 (Session ouverte 1j 17h)", col = "#E67E22", font = 2, pos = 2, cex = 0.9)

# B3_24_13 & B3_24_10 (Speed runs pré-test)
idx_13 <- which(pre_enriched$ID == "B3_24_13")
text(pre_enriched$duree_min[idx_13], pre_enriched$note_num[idx_13] - 0.8,
     "B3_24_13 (3 min 22s)", col = "#1B365D", font = 3, pos = 4, cex = 0.85)

idx_10 <- which(pre_enriched$ID == "B3_24_10")
text(pre_enriched$duree_min[idx_10], pre_enriched$note_num[idx_10] + 0.8,
     "B3_24_10 (3 min 34s, 24 'IDK')", col = "#1B365D", font = 3, pos = 4, cex = 0.85)

legend("topleft",
       legend = c("Participant valide (Complet)", "Anomalie majeure exclue (Abandon/Expiration)", "Session ouverte longue (> 24h)"),
       pch = c(21, 4, 21),
       pt.bg = c("#4A90E2", NA, "#4A90E2"),
       col = c("#1B365D", "#C62828", "#E67E22"),
       pt.lwd = c(1, 3, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Graphique généré : output/profilage_duree_completude_bac3_2024.png\n")

cat("\n======================================================================\n")
cat("=== ÉTAPE 1 TERMINÉE AVEC SUCCÈS POUR BAC 3 (2024) ===\n")
cat("======================================================================\n")
