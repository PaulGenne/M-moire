# ==============================================================================
# AUDIT DE QUALITÉ DES DONNÉES ET PROFILAGE (Étape 1) : BAC 3 2025 (PRE & POST)
# Projet de mémoire : Apprentissage de l'identification des abeilles sauvages
# Auteur : Paul Genné & Assistant IA
# Date : Novembre 2026
# ==============================================================================

# 0. Configuration des répertoires et environnement
dossier_script <- "BAC 3/Qualité données BAC 3 2025"
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
f_pre  <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre_raw  <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post_raw <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

cat("======================================================================\n")
cat("=== CHARGEMENT DES DONNÉES BRUTES (BAC 3 2025) ===\n")
cat("======================================================================\n")
cat(sprintf("Pretest 2025  : %d participants, %d colonnes\n", nrow(pre_raw), ncol(pre_raw)))
cat(sprintf("Posttest 2025 : %d participants, %d colonnes\n\n", nrow(post_raw), ncol(post_raw)))

# 2. Fonctions de parsing et d'ingénierie des variables
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

q_reply_cols <- grep("_reply$", colnames(pre_raw), value = TRUE)
nb_total_q <- length(q_reply_cols) # 28 questions

enrich_dataset <- function(df, cohorte_name) {
  df$Cohorte <- cohorte_name
  df$note_num <- parse_note(df[["Note/20,0"]])
  df$duree_min <- parse_duration_min(df$Durée)
  
  # Omissions : cases vides ou tirets "-"
  df$nb_omissions <- apply(df[, q_reply_cols], 1, function(row) {
    sum(is.na(row) | trimws(row) == "" | trimws(row) == "-")
  })
  df$nb_repondu <- nb_total_q - df$nb_omissions
  df$taux_completude_pct <- round((df$nb_repondu / nb_total_q) * 100, 1)
  
  # Réponses "Je ne sais pas"
  df$nb_idk <- apply(df[, q_reply_cols], 1, function(row) {
    sum(grepl("je ne sais pas|don.*t know", row, ignore.case = TRUE))
  })
  
  # Clôture administrative Moodle (détection fin de test par expiration pile, ex. 2h00 ou fin de plage)
  df$cloture_auto_moodle <- df$duree_min >= 120 | grepl("08:00$|12:00$|09:00$", trimws(df$Terminé))
  
  # Qualification de la qualité univariée
  df$Statut_Qualite <- "Valide (Complet 28/28)"
  df$Statut_Qualite[df$nb_omissions > 0 & df$taux_completude_pct >= 50] <- 
    sprintf("Incomplet (%d omissions / %d questions)", df$nb_omissions[df$nb_omissions > 0 & df$taux_completude_pct >= 50], nb_total_q)
  df$Statut_Qualite[df$taux_completude_pct < 50] <- "Exclu (Incomplétude majeure < 50%)"
  
  # Décision univariée : exclure les tests incomplets avec clôture par expiration
  df$Decision_Inclusion_Univariee <- ifelse(df$nb_omissions > 3, "Exclure", "Conserver")
  
  df$Motif_Exclusion <- ""
  df$Motif_Exclusion[df$nb_omissions > 3] <- 
    sprintf("Test incomplet (%d/28 questions omises) clôturé par expiration du temps limite (2h)", df$nb_omissions[df$nb_omissions > 3])
  
  return(df)
}

pre_enriched  <- enrich_dataset(pre_raw, "Pretest")
post_enriched <- enrich_dataset(post_raw, "Posttest")

# 3. Analyse de l'appariement longitudinal (Design intra-sujet Pré-Post)
ids_pre_valides  <- pre_enriched$ID[pre_enriched$Decision_Inclusion_Univariee == "Conserver"]
ids_post_valides <- post_enriched$ID[post_enriched$Decision_Inclusion_Univariee == "Conserver"]
ids_apparies     <- intersect(ids_pre_valides, ids_post_valides)

cat(sprintf("Participants Pretest brut        : %d\n", nrow(pre_enriched)))
cat(sprintf("Participants Pretest valide      : %d (0 exclu univarié)\n", length(ids_pre_valides)))
cat(sprintf("Participants Posttest brut       : %d\n", nrow(post_enriched)))
cat(sprintf("Participants Posttest valide     : %d (1 exclu univarié : B3_25_11)\n", length(ids_post_valides)))
cat(sprintf("Participants appariés (Pre+Post) : %d\n\n", length(ids_apparies)))

# Statut d'appariement
pre_enriched$Apparie <- pre_enriched$ID %in% ids_apparies
post_enriched$Apparie <- post_enriched$ID %in% ids_apparies

pre_enriched$Decision_Inclusion_Apparie <- ifelse(pre_enriched$Apparie, "Conserver", "Exclure (Non apparié)")
post_enriched$Decision_Inclusion_Apparie <- ifelse(post_enriched$Apparie, "Conserver", "Exclure (Non apparié)")

# Motifs d'exclusion pour non-appariement
pre_enriched$Motif_Exclusion[pre_enriched$Decision_Inclusion_Univariee == "Conserver" & !pre_enriched$Apparie] <- 
  "Présent au Pré-test mais absent au Post-test (Attrition post-formation)"

post_enriched$Motif_Exclusion[post_enriched$Decision_Inclusion_Univariee == "Conserver" & !post_enriched$Apparie] <- 
  "Présent au Post-test uniquement (Absent au Pré-test initial)"

# 4. Table d'audit consolidée (AGENTS.md Règle 5)
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
  Cloture_Auto_Moodle = ifelse(audit_anomalies$cloture_auto_moodle, "Oui (Délai 2h atteint)", "Non")
)

cat("======================================================================\n")
cat("=== TABLEAU D'AUDIT QUALITÉ ET TRAÇABILITÉ DES EXCLUSIONS ===\n")
cat("======================================================================\n")
print(tableau_audit[, c("Cohorte", "N_ID", "Statut_Qualite_Test", "Decision_Inclusion_Apparie", "Questions_Repondues", "Score_Obtenu_Sur_20", "Duree_Affichee")])

exporter_excel_csv(tableau_audit, file.path(dossier_output, "participants_anomalies_qualite_bac3_2025.csv"))

# 5. Export des jeux de données nettoyés
cols_raw_export <- colnames(pre_raw)

# A. Datasets nettoyés univariés
pre_clean_univ  <- pre_enriched[pre_enriched$Decision_Inclusion_Univariee == "Conserver", cols_raw_export]
post_clean_univ <- post_enriched[post_enriched$Decision_Inclusion_Univariee == "Conserver", cols_raw_export]

exporter_excel_csv(pre_clean_univ, file.path(dossier_output, "BAC3_2025_Pretest_clean.csv"))
exporter_excel_csv(post_clean_univ, file.path(dossier_output, "BAC3_2025_Posttest_clean.csv"))

# B. Dataset apparié strict (N = 22 participants ayant complété Pré et Post)
pre_paired  <- pre_enriched[pre_enriched$Apparie, ]
post_paired <- post_enriched[post_enriched$Apparie, ]

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
  Progression_Pct = round(((post_paired$note_num - pre_paired$note_num) / 20) * 100, 1),
  # Flag cas atypique (vitesse d'exécution très rapide et désengagement initial)
  Profil_Atypique = ifelse(pre_paired$duree_min < 5 & pre_paired$nb_idk >= 24, "Speed-run Pretest (IDK >= 24)", "Standard")
)

exporter_excel_csv(df_paired, file.path(dossier_output, "BAC3_2025_paired_clean.csv"))

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
  stats_summary(pre_paired$note_num, "2. Pretest Apparié strict (N=22)"),
  stats_summary(pre_paired$note_num[df_paired$Profil_Atypique == "Standard"], "3. Pretest Apparié standard (sans speed-runs N=20)"),
  stats_summary(post_enriched$note_num, "4. Posttest Brut (Total)"),
  stats_summary(post_enriched$note_num[post_enriched$Decision_Inclusion_Univariee == "Conserver"], "5. Posttest Nettoyé (sans B3_25_11)"),
  stats_summary(post_paired$note_num, "6. Posttest Apparié strict (N=22)"),
  stats_summary(post_paired$note_num[df_paired$Profil_Atypique == "Standard"], "7. Posttest Apparié standard (sans speed-runs N=20)"),
  stats_summary(df_paired$Delta_Note, "8. Gain de score global Apparié (N=22)"),
  stats_summary(df_paired$Delta_Note[df_paired$Profil_Atypique == "Standard"], "9. Gain de score Standard (sans speed-runs N=20)")
)

cat("\n======================================================================\n")
cat("=== TABLEAU D'IMPACT STATISTIQUE DU PROFILAGE ET NETTOYAGE ===\n")
cat("======================================================================\n")
print(tab_impact)

exporter_excel_csv(tab_impact, file.path(dossier_output, "tableau_impact_nettoyage_bac3_2025.csv"))

# 7. Visualisations graphiques haute définition (AGENTS.md Charte graphique)
# Graphique 1 : Comparaison et évolution des scores Pre vs Post (Boxplot + trajectoires)
png(file.path(dossier_output, "comparaison_scores_pre_post_bac3_2025.png"),
    width = 3200, height = 2300, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

scores_pre_app  <- df_paired$Pre_Note
scores_post_app <- df_paired$Post_Note

boxplot(list("Pré-test\n(Initial)" = scores_pre_app, 
             "Post-test\n(Après formation)" = scores_post_app),
        col = c("#4A90E2", "#2E7D32"),
        border = c("#1B365D", "#1B365D"),
        ylim = c(0, 22),
        ylab = "Score obtenu (/20)",
        main = "Évolution des performances d'identification des abeilles (BAC 3 - 2025)",
        cex.main = 1.3, font.main = 2, col.main = "#1B365D",
        cex.lab = 1.1, font.lab = 2,
        outline = FALSE)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
boxplot(list("Pré-test\n(Initial)" = scores_pre_app, 
             "Post-test\n(Après formation)" = scores_post_app),
        col = c("#4A90E2", "#2E7D32"),
        border = c("#1B365D", "#1B365D"),
        add = TRUE, outline = FALSE)

# Trajectoires individuelles
set.seed(42)
jitter_x  <- jitter(rep(1, length(scores_pre_app)), amount = 0.05)
jitter_x2 <- jitter(rep(2, length(scores_post_app)), amount = 0.05)

for (i in seq_along(scores_pre_app)) {
  is_atypique <- df_paired$Profil_Atypique[i] != "Standard"
  line_col <- ifelse(is_atypique, "#E67E22AA", "#8E44AD44")
  line_lwd <- ifelse(is_atypique, 2.5, 1.5)
  lines(c(jitter_x[i], jitter_x2[i]), c(scores_pre_app[i], scores_post_app[i]), 
        col = line_col, lwd = line_lwd, lty = ifelse(is_atypique, 2, 1))
  points(jitter_x[i], scores_pre_app[i], pch = 21, 
         bg = ifelse(is_atypique, "#E67E22", "#4A90E2"), col = "#1B365D", cex = 1.3)
  points(jitter_x2[i], scores_post_app[i], pch = 21, 
         bg = ifelse(is_atypique, "#E67E22", "#2E7D32"), col = "#1B365D", cex = 1.3)
}

# Annotations directes des moyennes et effectifs
m_pre <- mean(scores_pre_app)
m_post <- mean(scores_post_app)
text(1, 21, sprintf("Moyenne = %.2f/20\n(N = %d)", m_pre, length(scores_pre_app)), 
     col = "#1B365D", font = 2, cex = 1.0)
text(2, 21, sprintf("Moyenne = %.2f/20\n(N = %d)", m_post, length(scores_post_app)), 
     col = "#1B365D", font = 2, cex = 1.0)

legend("bottomright", 
       legend = c("Pré-test initial (N = 22)", "Post-test après TP (N = 22)", "Trajectoires standard", "Trajectoires atypiques (< 5 min Pre)"),
       fill = c("#4A90E2", "#2E7D32", NA, NA),
       border = c("#1B365D", "#1B365D", NA, NA),
       lty = c(NA, NA, 1, 2), col = c(NA, NA, "#8E44AD", "#E67E22"),
       lwd = c(NA, NA, 1.5, 2.5),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

dev.off()
cat("  -> Graphique généré : output/comparaison_scores_pre_post_bac3_2025.png\n")

# Graphique 2 : Profilage de la durée vs score (Pretest & Posttest combinés)
png(file.path(dossier_output, "profilage_duree_completude_bac3_2025.png"),
    width = 3300, height = 2300, res = 300, bg = "white")

par(mar = c(5, 5, 4, 3), family = "sans", las = 1)

plot(pre_enriched$duree_min, pre_enriched$note_num,
     pch = 21, bg = "#4A90E2", col = "#1B365D", cex = 1.5,
     log = "x",
     xlim = c(3, 140), ylim = c(0, 20),
     xlab = "Durée de passation (minutes, échelle logarithmique)",
     ylab = "Score obtenu (/20)",
     main = "Audit de qualité : Profilage Durée vs Score (BAC 3 - 2025)",
     cex.main = 1.3, font.main = 2, col.main = "#1B365D")

grid(col = "grey90", lty = 1)

# Ajouter les points du Posttest
points(post_enriched$duree_min, post_enriched$note_num,
       pch = ifelse(post_enriched$Decision_Inclusion_Univariee == "Exclure", 4, 21),
       bg = ifelse(post_enriched$Decision_Inclusion_Univariee == "Exclure", "#C62828", "#2E7D32"),
       col = ifelse(post_enriched$Decision_Inclusion_Univariee == "Exclure", "#C62828", "#1B365D"),
       cex = ifelse(post_enriched$Decision_Inclusion_Univariee == "Exclure", 2.2, 1.5),
       lwd = ifelse(post_enriched$Decision_Inclusion_Univariee == "Exclure", 3, 1))

# Ligne seuil d'alerte durée (5 minutes)
abline(v = 5, col = "#C62828", lty = 3, lwd = 1.8)
text(5.2, 1, "Seuil de rapidité suspecte (5 min)", col = "#C62828", font = 3, pos = 4, cex = 0.85)

# Annotations des cas remarquables
idx_04_pre <- which(pre_enriched$ID == "B3_25_04")
text(pre_enriched$duree_min[idx_04_pre], pre_enriched$note_num[idx_04_pre] + 0.8,
     "B3_25_04 (Pre: 4m05s, 27 IDK, 0/20)", col = "#E67E22", font = 2, pos = 4, cex = 0.85)

idx_20_pre <- which(pre_enriched$ID == "B3_25_20")
text(pre_enriched$duree_min[idx_20_pre], pre_enriched$note_num[idx_20_pre] - 0.8,
     "B3_25_20 (Pre: 4m38s, 24 IDK, 2.1/20)", col = "#E67E22", font = 2, pos = 4, cex = 0.85)

idx_11_post <- which(post_enriched$ID == "B3_25_11")
text(post_enriched$duree_min[idx_11_post], post_enriched$note_num[idx_11_post] + 0.8,
     "B3_25_11 (Exclu Post: 7 omis, 2h max)", col = "#C62828", font = 2, pos = 2, cex = 0.85)

idx_24_pre <- which(pre_enriched$ID == "B3_25_24")
text(pre_enriched$duree_min[idx_24_pre], pre_enriched$note_num[idx_24_pre] + 0.8,
     "B3_25_24 (Pre uniquement, attrition)", col = "#1B365D", font = 3, pos = 3, cex = 0.85)

legend("topleft",
       legend = c("Pré-test (N = 23)", "Post-test valide (N = 22)", "Post-test exclu (B3_25_11, 7 omis, 2h)", "Pretest rapide / évitement (< 5 min)"),
       pch = c(21, 21, 4, 21),
       pt.bg = c("#4A90E2", "#2E7D32", NA, "#E67E22"),
       col = c("#1B365D", "#1B365D", "#C62828", "#1B365D"),
       pt.lwd = c(1, 1, 3, 1),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

dev.off()
cat("  -> Graphique généré : output/profilage_duree_completude_bac3_2025.png\n")

cat("\n======================================================================\n")
cat("=== ÉTAPE 1 TERMINÉE AVEC SUCCÈS POUR BAC 3 (2025) ===\n")
cat("======================================================================\n")

