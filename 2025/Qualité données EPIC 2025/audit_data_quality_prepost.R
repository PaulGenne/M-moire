# ==============================================================================
# AUDIT DE QUALITÉ DES DONNÉES ET PROFILAGE (Étape 1) : EPIC 2025 (PRE & POST)
# Projet de mémoire : Apprentissage de l'identification des abeilles sauvages
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. Configuration de l'environnement et dossiers
if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}

# Fonction d'export conforme AGENTS.md (UTF-8 avec BOM, séparateur ';' et décimale ',')
exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat("  -> Fichier CSV exporté avec succès :", chemin_fichier, "\n")
}

# 1. Chargement des données brutes
f_pre  <- if (file.exists("EPIC_Pretest.csv")) "EPIC_Pretest.csv" else "../../EPIC_Pretest.csv"
f_post <- if (file.exists("EPIC_Posttest.csv")) "EPIC_Posttest.csv" else "../../EPIC_Posttest.csv"

pre_raw  <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post_raw <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

cat("=== Chargement des données brutes (EPIC 2025) ===\n")
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

q_reply_cols <- paste0("Question_", 1:30, "_reply")
q_sol_cols   <- paste0("Question_", 1:30, "_solution")

enrich_dataset <- function(df, cohorte_name) {
  df$Cohorte <- cohorte_name
  df$note_num <- parse_note(df[["Note/20,0"]])
  df$duree_min <- parse_duration_min(df$Durée)
  
  df$nb_omissions <- apply(df[, q_reply_cols], 1, function(row) {
    sum(is.na(row) | trimws(row) == "" | trimws(row) == "-")
  })
  df$nb_repondu <- 30 - df$nb_omissions
  df$taux_completude_pct <- round((df$nb_repondu / 30) * 100, 1)
  
  df$nb_idk <- apply(df[, q_reply_cols], 1, function(row) {
    sum(grepl("don.*t know", row, ignore.case = TRUE))
  })
  
  df$nb_correct_exact <- sapply(1:nrow(df), function(i) {
    reps <- trimws(as.character(df[i, q_reply_cols]))
    sols <- trimws(as.character(df[i, q_sol_cols]))
    sum(tolower(reps) == tolower(sols), na.rm = TRUE)
  })
  
  df$cloture_auto_moodle <- grepl("12:00$|09:00$", trimws(df$Terminé))
  
  # Classification objective
  df$Statut_Qualite <- "Valide (Complet 30/30)"
  df$Statut_Qualite[df$nb_repondu >= 28 & df$nb_repondu < 30] <- "Valide (Omission ponctuelle 28-29/30)"
  df$Statut_Qualite[df$nb_repondu > 3 & df$nb_repondu < 20]  <- "Exclu (Incomplétude majeure < 50%)"
  df$Statut_Qualite[df$nb_repondu >= 1 & df$nb_repondu <= 3] <- "Exclu (Abandon précoce <= 3 questions)"
  df$Statut_Qualite[df$nb_repondu == 0]                      <- "Exclu (Abandon complet 0 question)"
  
  df$Decision_Inclusion <- ifelse(grepl("^Exclu", df$Statut_Qualite), "Exclure", "Conserver")
  
  df$Motif_Exclusion <- ""
  df$Motif_Exclusion[df$Statut_Qualite == "Exclu (Abandon complet 0 question)"] <- 
    "Aucune question tentée (0/30) ; clôture automatique Moodle par expiration de délai"
  df$Motif_Exclusion[df$Statut_Qualite == "Exclu (Abandon précoce <= 3 questions)"] <- 
    "Abandon quasi-immédiat (1 à 3 questions tentées sur 30) ; clôture automatique Moodle"
  df$Motif_Exclusion[df$Statut_Qualite == "Exclu (Incomplétude majeure < 50%)"] <- 
    "Test incomplet arrêté en cours (< 50% répondu) ; clôture automatique administrative au matin"
  
  return(df)
}

pre_enriched  <- enrich_dataset(pre_raw, "Pretest")
post_enriched <- enrich_dataset(post_raw, "Posttest")

# 3. Tableau d'audit et traçabilité des anomalies (AGENTS.md Règle 5)
audit_anomalies <- rbind(
  pre_enriched[pre_enriched$Decision_Inclusion == "Exclure", ],
  post_enriched[post_enriched$Decision_Inclusion == "Exclure", ]
)

tableau_audit <- data.frame(
  Cohorte = audit_anomalies$Cohorte,
  N_ID = audit_anomalies[["N°ID"]],
  Statut_Tentative = "Tentative unique",
  Statut_Qualite = audit_anomalies$Statut_Qualite,
  Motif_Exclusion = audit_anomalies$Motif_Exclusion,
  Questions_Repondues = audit_anomalies$nb_repondu,
  Questions_Omises = audit_anomalies$nb_omissions,
  Taux_Completude_Pct = audit_anomalies$taux_completude_pct,
  Duree_Affichee = audit_anomalies$Durée,
  Duree_Minutes = audit_anomalies$duree_min,
  Score_Obtenu_Sur_20 = audit_anomalies$note_num,
  Date_Debut = audit_anomalies$Commencé,
  Date_Fin = audit_anomalies$Terminé,
  Cloture_Auto_Moodle = ifelse(audit_anomalies$cloture_auto_moodle, "Oui (Expiration délai)", "Non")
)

cat("=== Synthèse des 11 exclusions identifiées ===\n")
print(tableau_audit[, c("Cohorte", "N_ID", "Statut_Qualite", "Questions_Repondues", "Score_Obtenu_Sur_20", "Duree_Affichee")])

exporter_excel_csv(tableau_audit, "output/participants_anomalies_qualite_prepost.csv")

# 4. Export des jeux de données nettoyés
pre_clean <- pre_enriched[pre_enriched$Decision_Inclusion == "Conserver", ]
post_clean <- post_enriched[post_enriched$Decision_Inclusion == "Conserver", ]

cols_a_garder <- c("N°ID", "Commencé", "Terminé", "Durée", "Note/20,0", "Feedback",
                   as.vector(rbind(q_sol_cols, paste0("Question_", 1:30, "_sex"), q_reply_cols)))

exporter_excel_csv(pre_clean[, cols_a_garder], "output/EPIC_Pretest_clean.csv")
exporter_excel_csv(post_clean[, cols_a_garder], "output/EPIC_Posttest_clean.csv")

# 5. Tableau comparatif d'impact statistique
stats_summary <- function(vals, cohorte, statut) {
  data.frame(
    Cohorte = cohorte,
    Etape_Nettoyage = statut,
    N_Effectif = length(vals),
    Moyenne_Score = round(mean(vals), 2),
    Ecart_Type = round(sd(vals), 2),
    Mediane = round(median(vals), 2),
    Q1 = round(quantile(vals, 0.25), 2),
    Q3 = round(quantile(vals, 0.75), 2),
    Min = round(min(vals), 2),
    Max = round(max(vals), 2)
  )
}

tab_stats <- rbind(
  stats_summary(pre_enriched$note_num, "Pretest", "Données brutes (avec abandons)"),
  stats_summary(pre_clean$note_num, "Pretest", "Données nettoyées (sans abandons)"),
  stats_summary(post_enriched$note_num, "Posttest", "Données brutes (avec abandons)"),
  stats_summary(post_clean$note_num, "Posttest", "Données nettoyées (sans abandons)")
)

cat("\n=== Comparaison statistique avant / après nettoyage ===\n")
print(tab_stats)
exporter_excel_csv(tab_stats, "output/tableau_impact_nettoyage_prepost.csv")

# 6. Visualisations haute définition (300 DPI)
col_vert_succes   <- "#2E7D32"
col_rouge_erreur  <- "#C62828"
col_bleu_ardoise  <- "#4A90E2"
col_bleu_nuit     <- "#1B365D"

# Figure 1 : Diagnostic
png("output/fig1_diagnostic_qualite_prepost.png", width = 3600, height = 2800, res = 300, bg = "white")
par(mfrow = c(2, 2), mar = c(5, 5, 4, 2), family = "sans")

# Panneau A : Distribution questions répondues
hist_pre <- table(factor(pre_enriched$nb_repondu, levels = 0:30))
hist_post <- table(factor(post_enriched$nb_repondu, levels = 0:30))
max_freq <- max(c(hist_pre, hist_post)) + 5
mat_rep <- rbind(hist_pre, hist_post)
bp <- barplot(mat_rep, beside = TRUE, col = c(col_bleu_ardoise, col_vert_succes),
        ylim = c(0, max_freq), las = 1, cex.names = 0.8,
        xlab = "Nombre de questions répondues (sur 30)", ylab = "Effectif de participants",
        main = "A. Complétude des tests et zone d'abandon", border = "white")
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
rect(0, 0, bp[2, 16], max_freq, col = rgb(0.9, 0.2, 0.2, 0.1), border = "red", lty = 2)
text(bp[1, 8], max_freq * 0.85, "Zone d'abandon\n(< 50% répondu)\n-> EXCLUSION", col = col_rouge_erreur, font = 2, cex = 0.9)
legend("topleft", legend = c("Pretest (Initial)", "Posttest (Initial)"),
       fill = c(col_bleu_ardoise, col_vert_succes), bty = "o", bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

# Panneau B : Flux de sélection
flux_labels <- c("Pretest\nInitial", "Pretest\nExclus", "Pretest\nNettoyé",
                 "Posttest\nInitial", "Posttest\nExclus", "Posttest\nNettoyé")
flux_vals <- c(nrow(pre_enriched), sum(pre_enriched$Decision_Inclusion == "Exclure"), nrow(pre_clean),
               nrow(post_enriched), sum(post_enriched$Decision_Inclusion == "Exclure"), nrow(post_clean))
flux_cols <- c(col_bleu_ardoise, col_rouge_erreur, col_bleu_nuit,
               col_vert_succes, col_rouge_erreur, "#1E5F22")
bp2 <- barplot(flux_vals, names.arg = flux_labels, col = flux_cols, ylim = c(0, 65), las = 1,
               ylab = "Nombre de participants (N)", main = "B. Diagramme de flux d'inclusion", border = "white")
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
text(bp2, flux_vals + 2.5, labels = sprintf("N = %d", flux_vals), font = 2, cex = 0.9, col = "black")
text(bp2[2], flux_vals[2] + 7, labels = sprintf("-%.1f%%", (flux_vals[2]/flux_vals[1])*100), col = col_rouge_erreur, font = 2, cex = 0.85)
text(bp2[5], flux_vals[5] + 7, labels = sprintf("-%.1f%%", (flux_vals[5]/flux_vals[4])*100), col = col_rouge_erreur, font = 2, cex = 0.85)

# Panneau C : Timeouts Moodle
all_comb <- rbind(
  data.frame(Cohorte = "Pretest", Note = pre_enriched$note_num, Duree = pre_enriched$duree_min,
             Exclu = pre_enriched$Decision_Inclusion == "Exclure"),
  data.frame(Cohorte = "Posttest", Note = post_enriched$note_num, Duree = post_enriched$duree_min,
             Exclu = post_enriched$Decision_Inclusion == "Exclure")
)
col_pts <- ifelse(all_comb$Exclu, col_rouge_erreur, ifelse(all_comb$Cohorte == "Pretest", col_bleu_ardoise, col_vert_succes))
pch_pts <- ifelse(all_comb$Exclu, 4, ifelse(all_comb$Cohorte == "Pretest", 16, 17))
plot(all_comb$Duree, all_comb$Note, log = "x", col = col_pts, pch = pch_pts, cex = 1.4, lwd = ifelse(all_comb$Exclu, 2, 1),
     xlab = "Durée de la tentative (minutes, échelle log)", ylab = "Note obtenue (/20)",
     main = "C. Détection des Timeouts Moodle et Abandons", las = 1, xlim = c(5, 30000), ylim = c(-0.5, 20.5))
grid(col = "grey90", lty = 1)
abline(v = 1440, col = "grey50", lty = 3, lwd = 1.5)
text(1440, 1.5, " Seuil 24h\n (Sessions ouvertes)", adj = 0, cex = 0.8, col = "grey40")
rect(500, -0.5, 25000, 3.5, border = col_rouge_erreur, lty = 2, col = rgb(0.9, 0.2, 0.2, 0.08))
text(2500, 3.8, "Timeouts Moodle (Abandons)", col = col_rouge_erreur, font = 2, cex = 0.85)
legend("topleft", legend = c("Pretest (Valide)", "Posttest (Valide)", "Exclu (Abandon / Incomplet)"),
       col = c(col_bleu_ardoise, col_vert_succes, col_rouge_erreur), pch = c(16, 17, 4), pt.lwd = c(1, 1, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.85)

# Panneau D : I don't know
idk_pre_clean <- pre_clean$nb_idk
idk_post_clean <- post_clean$nb_idk
bp_idk <- boxplot(list("Pretest\n(Validés)" = idk_pre_clean, "Posttest\n(Validés)" = idk_post_clean),
                  col = c(col_bleu_ardoise, col_vert_succes), las = 1, ylab = "Nombre de 'I don't know' cochés (sur 30)",
                  main = "D. Fréquence d'aveu d'incompétence taxonomique",
                  boxwex = 0.45, border = c(col_bleu_nuit, "#1E5F22"))
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
points(1:2, c(mean(idk_pre_clean), mean(idk_post_clean)), pch = 18, col = "gold2", cex = 2)
text(1, mean(idk_pre_clean) + 1.8, labels = sprintf("Moy: %.1f", mean(idk_pre_clean)), font = 2, cex = 0.85)
text(2, mean(idk_post_clean) + 1.8, labels = sprintf("Moy: %.1f", mean(idk_post_clean)), font = 2, cex = 0.85)

dev.off()
cat("  -> Graphique 1 généré : output/fig1_diagnostic_qualite_prepost.png\n")

# Figure 2 : Scores
png("output/fig2_impact_nettoyage_scores.png", width = 3600, height = 2400, res = 300, bg = "white")
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2), family = "sans")

groupes_liste <- list(
  "Pretest\nBrut (N=56)"     = pre_enriched$note_num,
  "Pretest\nNettoyé (N=50)"  = pre_clean$note_num,
  "Posttest\nBrut (N=54)"    = post_enriched$note_num,
  "Posttest\nNettoyé (N=49)" = post_clean$note_num
)
couleurs_bp <- c("grey80", col_bleu_ardoise, "grey80", col_vert_succes)

boxplot(groupes_liste, col = couleurs_bp, las = 1, ylab = "Note obtenue sur 20 (/20)",
        main = "Distribution des scores : Brut vs Nettoyé", ylim = c(-1, 22),
        boxwex = 0.5, border = c("grey40", col_bleu_nuit, "grey40", "#1E5F22"))
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
moyennes <- sapply(groupes_liste, mean)
points(1:4, moyennes, pch = 18, col = "gold2", cex = 2)
for (i in 1:4) {
  text(i, moyennes[i] + 1.2, labels = sprintf("Moy: %.1f\n(ET: %.1f)", moyennes[i], sd(groupes_liste[[i]])),
       font = 2, cex = 0.8, col = "black")
}
abline(h = 10, col = col_rouge_erreur, lty = 2, lwd = 1.2)
text(0.6, 10.5, "Seuil 10/20", col = col_rouge_erreur, adj = 0, cex = 0.8, font = 3)

d_pre <- density(pre_clean$note_num, bw = 1.5)
d_post <- density(post_clean$note_num, bw = 1.5)

plot(d_post, col = col_vert_succes, lwd = 3, las = 1, xlim = c(0, 22), ylim = c(0, 0.22),
     main = "Densité de probabilité des scores nettoyés",
     xlab = "Note obtenue (/20)", ylab = "Densité")
polygon(d_post, col = rgb(0.18, 0.49, 0.20, 0.25), border = NA)
lines(d_pre, col = col_bleu_ardoise, lwd = 3)
polygon(d_pre, col = rgb(0.29, 0.56, 0.89, 0.25), border = NA)
grid(col = "grey90", lty = 1)

abline(v = mean(pre_clean$note_num), col = col_bleu_nuit, lty = 2, lwd = 2)
abline(v = mean(post_clean$note_num), col = "#1E5F22", lty = 2, lwd = 2)

text(mean(pre_clean$note_num) - 0.3, 0.20, sprintf("Moy Pré: %.1f", mean(pre_clean$note_num)),
     adj = 1, col = col_bleu_nuit, font = 2, cex = 0.85)
text(mean(post_clean$note_num) + 0.3, 0.20, sprintf("Moy Post: %.1f", mean(post_clean$note_num)),
     adj = 0, col = "#1E5F22", font = 2, cex = 0.85)

legend("topleft", legend = c("Pretest nettoyé (N=50)", "Posttest nettoyé (N=49)"),
       fill = c(rgb(0.29, 0.56, 0.89, 0.5), rgb(0.18, 0.49, 0.20, 0.5)),
       border = c(col_bleu_ardoise, col_vert_succes), bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

dev.off()
cat("  -> Graphique 2 généré : output/fig2_impact_nettoyage_scores.png\n")

cat("\nAudit EPIC 2025 terminé avec succès !\n")

