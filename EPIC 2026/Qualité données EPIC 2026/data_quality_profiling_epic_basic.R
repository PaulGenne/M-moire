# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique (EPIC)
# ÉTAPE 1 : Data Quality & Profiling Analyse
# FICHIER CIBLE : EPIC_Basic-rgpd ok - Copie.xlsx (via export CSV)
# AUTEUR : Assistant IA pour Paul Genné
# DATE : Novembre 2026
# ==============================================================================

# Vérification et création du dossier output selon AGENTS.md
if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}

# 1. CHARGEMENT DU JEU DE DONNÉES -----------------------------------------------
fichier_csv <- "EPIC_Basic-rgpd ok - Copie.csv"
if (!file.exists(fichier_csv)) {
  stop("Le fichier CSV n'a pas été trouvé. Veuillez vérifier l'export.")
}

df <- read.csv(fichier_csv, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)

cat("======================================================================\n")
cat("      RAPPORT APPROFONDI DE DATA QUALITY ET PROFILING ANALYSE         \n")
cat("======================================================================\n\n")

# 1.1 Dimensions globales
nb_lignes <- nrow(df)
nb_cols   <- ncol(df)
cat(sprintf("Dimensions du jeu de données brut : %d lignes x %d colonnes\n\n", nb_lignes, nb_cols))

# 2. AUDIT DES IDENTIFIANTS ET DOUBLONS -----------------------------------------
cat("----------------------------------------------------------------------\n")
cat("1. INTÉGRITÉ DES IDENTIFIANTS (ID) ET DOUBLONS\n")
cat("----------------------------------------------------------------------\n")

id_col <- "N°ID"
ids <- df[[id_col]]

# IDs vides ou NA
ids_vides <- which(is.na(ids) | trimws(ids) == "")
cat(sprintf("- Identifiants manquants ou vides : %d\n", length(ids_vides)))
if (length(ids_vides) > 0) {
  cat("  -> Lignes concernées :", paste(ids_vides, collapse = ", "), "\n")
}

# Doublons d'ID
ids_non_vides <- ids[!is.na(ids) & trimws(ids) != ""]
table_ids <- table(ids_non_vides)
doublons_id <- table_ids[table_ids > 1]
cat(sprintf("- Identifiants dupliqués : %d cas\n", length(doublons_id)))
if (length(doublons_id) > 0) {
  print(doublons_id)
  cat("  -> Détail des lignes dupliquées :\n")
  lignes_doublons <- which(ids %in% names(doublons_id))
  print(df[lignes_doublons, c("N°ID", "Region", "EPIC_courses", "Commencé", "Durée", "Note/30_nbr")])
}

# Doublons de lignes stricts (toutes colonnes confondues)
lignes_dupliquees <- which(duplicated(df))
cat(sprintf("- Lignes strictement identiques dupliquées : %d\n\n", length(lignes_dupliquees)))

# 3. AUDIT DES VARIABLES D'EN-TÊTE / MÉTADONNÉES ---------------------------------
cat("----------------------------------------------------------------------\n")
cat("2. AUDIT DES MÉTADONNÉES DU TEST (Région, Cours, Durée, Dates)\n")
cat("----------------------------------------------------------------------\n")

# Region
cat("Distribution de la variable 'Region' :\n")
print(table(df$Region, useNA = "always"))

# EPIC_courses
cat("\nDistribution de la variable 'EPIC_courses' :\n")
print(table(df$EPIC_courses, useNA = "always"))

# Analyse de la durée
# Extraction de la durée en minutes
parser_duree <- function(d_str) {
  if (is.na(d_str) || trimws(d_str) == "") return(NA_real_)
  d_str <- tolower(trimws(d_str))
  
  heures <- 0
  minutes <- 0
  secondes <- 0
  
  # "X heure(s) Y min" ou "X h Y min"
  h_match <- regexec("(\\d+)\\s*(?:heure|h)", d_str)
  h_reg <- regmatches(d_str, h_match)[[1]]
  if (length(h_reg) > 1) heures <- as.numeric(h_reg[2])
  
  m_match <- regexec("(\\d+)\\s*(?:minute|min|m)", d_str)
  m_reg <- regmatches(d_str, m_match)[[1]]
  if (length(m_reg) > 1) minutes <- as.numeric(m_reg[2])
  
  s_match <- regexec("(\\d+)\\s*(?:seconde|sec|s)", d_str)
  s_reg <- regmatches(d_str, s_match)[[1]]
  if (length(s_reg) > 1) secondes <- as.numeric(s_reg[2])
  
  total_min <- heures * 60 + minutes + (secondes / 60)
  if (total_min == 0 && !grepl("0\\s*(?:min|sec|heure)", d_str)) {
    # Tenter conversion directe si nombre brut
    val_num <- suppressWarnings(as.numeric(d_str))
    if (!is.na(val_num)) return(val_num)
  }
  return(total_min)
}

durees_min <- sapply(df$Durée, parser_duree)
df$Duree_Minutes <- durees_min

cat("\nStatistiques sur la durée du test (en minutes) :\n")
print(summary(durees_min))

# Détection de durées aberrantes
durees_tres_courtes <- which(durees_min < 5 & !is.na(durees_min))
durees_tres_longues <- which(durees_min > 240 & !is.na(durees_min))
cat(sprintf("- Durées suspectes < 5 minutes (test bâclé ou test technique) : %d participant(s)\n", length(durees_tres_courtes)))
if (length(durees_tres_courtes) > 0) {
  print(df[durees_tres_courtes, c("N°ID", "EPIC_courses", "Durée", "Note/30_nbr")])
}

cat(sprintf("- Durées très longues > 4 heures : %d participant(s)\n", length(durees_tres_longues)))
if (length(durees_tres_longues) > 0) {
  print(df[durees_tres_longues, c("N°ID", "EPIC_courses", "Durée", "Note/30_nbr")])
}

# 4. AUDIT DE LA COHÉRENCE ET CONCORDANCE DES SCORES ---------------------------
cat("\n----------------------------------------------------------------------\n")
cat("3. CONCORDANCE DES SCORES ET VÉRIFICATION DU BARÈME\n")
cat("----------------------------------------------------------------------\n")

cols_eval <- paste0("Question_", 1:30, "_evaluation")
cols_sol  <- paste0("Question_", 1:30, "_solution")
cols_rep  <- paste0("Question_", 1:30, "_reply")

# Matrice des évaluations numériques
mat_eval <- as.data.frame(lapply(df[cols_eval], function(x) suppressWarnings(as.numeric(x))))

# Recalcul de la somme brute des 30 questions
somme_recalculee <- rowSums(mat_eval, na.rm = TRUE)
nb_questions_eval_remplies <- rowSums(!is.na(mat_eval))

# Note sur 30 déclarée
note_declaree <- suppressWarnings(as.numeric(gsub(",", ".", df[["Note/30_nbr"]])))
somme_eval_declaree <- suppressWarnings(as.numeric(gsub(",", ".", df[["Somme_eval"]])))
note_finale_declaree <- suppressWarnings(as.numeric(gsub(",", ".", df[["Note_finale"]])))

# Comparaison
diff_note <- note_declaree - somme_recalculee
incoherences_note <- which(!is.na(diff_note) & diff_note != 0)

cat(sprintf("- Incohérences entre 'Note/30_nbr' déclarée et somme recalculée des 30 évaluations : %d cas\n", length(incoherences_note)))
if (length(incoherences_note) > 0) {
  print(data.frame(
    Ligne = incoherences_note,
    ID = df[incoherences_note, "N°ID"],
    Note_Declaree = note_declaree[incoherences_note],
    Somme_Recalculee = somme_recalculee[incoherences_note],
    Difference = diff_note[incoherences_note]
  ))
}

# Analyse de la colonne Verif_eval
cat("\nValeurs de la colonne 'Verif_eval' :\n")
print(table(df$Verif_eval, useNA = "always"))

# Évaluations anormales (hors 0 et 1)
valeurs_anormales_eval <- c()
for (c_ev in cols_eval) {
  vals <- df[[c_ev]]
  non_conf <- vals[!is.na(vals) & !vals %in% c(0, 1, "0", "1")]
  if (length(non_conf) > 0) {
    valeurs_anormales_eval <- c(valeurs_anormales_eval, paste0(c_ev, ": ", paste(unique(non_conf), collapse = ", ")))
  }
}
if (length(valeurs_anormales_eval) > 0) {
  cat("\nATTENTION : Évaluations avec valeurs non-binaires :\n")
  print(valeurs_anormales_eval)
} else {
  cat("- Toutes les évaluations de questions sont strictement binaires (0 ou 1 ou NA).\n")
}

# 5. AUDIT DES COMPLÉTIONS, ABANDONS ET PROFILS À ÉCARTER -----------------------
cat("\n----------------------------------------------------------------------\n")
cat("4. ANALYSE DE LA COMPLÉTUDE ET DES CAS D'ABANDON (ATTRITION)\n")
cat("----------------------------------------------------------------------\n")

# Questions répondues par participant
nb_reponses_texte <- rowSums(sapply(df[cols_rep], function(x) !is.na(x) & trimws(x) != ""))

cat("Résumé du nombre de réponses textuelles fournies (sur 30) :\n")
print(summary(nb_reponses_texte))

cat("\nRésumé du score total recalculé (sur 30) :\n")
print(summary(somme_recalculee))

# Participants avec moins de 15 questions répondues (< 50%)
abandons_50 <- which(nb_reponses_texte < 15)
cat(sprintf("- Participants ayant répondu à moins de 50%% du test (< 15 questions) : %d participant(s)\n", length(abandons_50)))
if (length(abandons_50) > 0) {
  print(data.frame(
    Ligne = abandons_50,
    ID = df[abandons_50, "N°ID"],
    EPIC_courses = df[abandons_50, "EPIC_courses"],
    Duree = df[abandons_50, "Durée"],
    Nb_Reponses = nb_reponses_texte[abandons_50],
    Score = somme_recalculee[abandons_50]
  ))
}

# Participants ayant obtenu un score de 0
scores_zero <- which(somme_recalculee == 0)
cat(sprintf("- Participants avec un score total de 0/30 : %d participant(s)\n", length(scores_zero)))
if (length(scores_zero) > 0) {
  print(data.frame(
    Ligne = scores_zero,
    ID = df[scores_zero, "N°ID"],
    EPIC_courses = df[scores_zero, "EPIC_courses"],
    Duree = df[scores_zero, "Durée"],
    Nb_Reponses = nb_reponses_texte[scores_zero],
    Score = somme_recalculee[scores_zero]
  ))
}

# Détection des outliers statistiques sur le score (Méthode de Tukey IQR)
q1 <- quantile(somme_recalculee, 0.25, na.rm = TRUE)
q3 <- quantile(somme_recalculee, 0.75, na.rm = TRUE)
iqr <- q3 - q1
seuil_bas <- max(0, q1 - 1.5 * iqr)
seuil_haut <- min(30, q3 + 1.5 * iqr)

outliers_bas <- which(somme_recalculee < seuil_bas)
cat(sprintf("\n- Outliers de score selon Tukey IQR [Seuil bas = %.1f] : %d participant(s)\n", seuil_bas, length(outliers_bas)))
if (length(outliers_bas) > 0) {
  print(data.frame(
    Ligne = outliers_bas,
    ID = df[outliers_bas, "N°ID"],
    Score = somme_recalculee[outliers_bas],
    EPIC_courses = df[outliers_bas, "EPIC_courses"],
    Duree = df[outliers_bas, "Durée"]
  ))
}

# 6. CONCORDANCE RÉPONSE vs SOLUTION vs ÉVALUATION ------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("5. AUDIT DE LA QUALITÉ DES CORRECTIONS (RÉPONSE vs SOLUTION vs ÉVAL)\n")
cat("----------------------------------------------------------------------\n")

# Recherche de cas où réponse == solution (à la casse près) mais eval == 0
# ou réponse != solution mais eval == 1
faux_negatifs <- list() # Réponse juste mais notée 0
faux_positifs <- list() # Réponse fausse mais notée 1

for (i in 1:30) {
  col_s <- cols_sol[i]
  col_r <- cols_rep[i]
  col_e <- cols_eval[i]
  
  sol <- tolower(trimws(df[[col_s]]))
  rep <- tolower(trimws(df[[col_r]]))
  ev  <- suppressWarnings(as.numeric(df[[col_e]]))
  
  # Faux négatif potentiel : même chaîne mais eval == 0
  fn_idx <- which(!is.na(ev) & ev == 0 & !is.na(rep) & rep != "" & rep == sol)
  if (length(fn_idx) > 0) {
    faux_negatifs[[paste0("Q", i)]] <- data.frame(
      Ligne = fn_idx,
      ID = df[fn_idx, "N°ID"],
      Solution = df[fn_idx, col_s],
      Reponse = df[fn_idx, col_r],
      Eval = ev[fn_idx]
    )
  }
  
  # Faux positif potentiel : réponse vide ou différente mais notée 1
  fp_idx <- which(!is.na(ev) & ev == 1 & (is.na(rep) | rep == "" | rep != sol))
  if (length(fp_idx) > 0) {
    faux_positifs[[paste0("Q", i)]] <- data.frame(
      Ligne = fp_idx,
      ID = df[fp_idx, "N°ID"],
      Solution = df[fp_idx, col_s],
      Reponse = df[fp_idx, col_r],
      Eval = ev[fp_idx]
    )
  }
}

cat(sprintf("- Questions avec faux négatifs potentiels (réponse identique mais eval = 0) : %d\n", length(faux_negatifs)))
if (length(faux_negatifs) > 0) {
  print(faux_negatifs)
}

cat(sprintf("- Questions avec faux positifs potentiels (réponse différente de la solution mais notée 1) : %d\n", length(faux_positifs)))
if (length(faux_positifs) > 0) {
  for (q_name in names(faux_positifs)) {
    cat(sprintf("  * Question %s (%d cas) :\n", q_name, nrow(faux_positifs[[q_name]])))
    print(head(faux_positifs[[q_name]], 5))
  }
}

# 7. AUDIT DE LA TAXONOMIE DES SOLUTIONS (Cohérence des genres testés) -----------
cat("\n----------------------------------------------------------------------\n")
cat("6. TAXONOMIE DES GENRES EN SOLUTIONS\n")
cat("----------------------------------------------------------------------\n")
toutes_solutions <- unlist(df[cols_sol])
toutes_solutions <- toutes_solutions[!is.na(toutes_solutions) & trimws(toutes_solutions) != ""]
table_sol <- sort(table(toutes_solutions), decreasing = TRUE)
cat("Nombre de genres distincts référencés en solution :", length(table_sol), "\n")
print(table_sol)

# 8. GÉNÉRATION DES GRAPHIQUES DIAGNOSTIQUES DANS OUTPUT/ ------------------------
cat("\n----------------------------------------------------------------------\n")
cat("7. GÉNÉRATION DES VISUALISATIONS DE CONTRÔLE QUALITÉ\n")
cat("----------------------------------------------------------------------\n")

# Distribution des scores selon EPIC_courses
png("output/data_quality_distribution_scores.png", width = 2400, height = 1800, res = 300)
par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1))

# 1. Histogramme des scores
hist(somme_recalculee, breaks = 15, col = "#2b5c8f", border = "white",
     main = "Distribution des Scores Totaux (/30)",
     xlab = "Score recalculé", ylab = "Effectif", las = 1)
abline(v = c(seuil_bas, mean(somme_recalculee, na.rm = TRUE), median(somme_recalculee, na.rm = TRUE)),
       col = c("red", "black", "forestgreen"), lty = c(2, 1, 2), lwd = 2)
legend("topleft", legend = c("Seuil Outlier Bas (IQR)", "Moyenne", "Médiane"),
       col = c("red", "black", "forestgreen"), lty = c(2, 1, 2), lwd = 2, bty = "n", cex = 0.8)

# 2. Boxplot selon EPIC_courses
boxplot(somme_recalculee ~ df$EPIC_courses, col = c("#e74c3c", "#2ecc71"),
        main = "Score selon Formation ('EPIC_courses')",
        xlab = "A suivi la formation EPIC ?", ylab = "Score /30", las = 1)

# 3. Durée vs Score
plot(df$Duree_Minutes, somme_recalculee, pch = 19, col = ifelse(df$EPIC_courses == "Yes", "#27ae60", "#c0392b"),
     main = "Relation Durée du Test vs Score",
     xlab = "Durée (minutes)", ylab = "Score /30", las = 1)
abline(v = 10, col = "red", lty = 2)
legend("bottomright", legend = c("Cours = Yes", "Cours = No", "Seuil 10 min"),
       col = c("#27ae60", "#c0392b", "red"), pch = c(19, 19, NA), lty = c(NA, NA, 2), bty = "n", cex = 0.8)

# 4. Nombre de questions répondues
hist(nb_reponses_texte, breaks = 20, col = "#8e44ad", border = "white",
     main = "Questions Répondues par Participant (/30)",
     xlab = "Nombre de réponses textuelles", ylab = "Effectif", las = 1)

invisible(dev.off())
cat("Graphique sauvegardé dans : output/data_quality_distribution_scores.png\n")

cat("\n======================================================================\n")
cat("FIN DU RAPPORT DE DATA QUALITY & PROFILING\n")
cat("======================================================================\n")
