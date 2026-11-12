# ==============================================================================
# SCRIPT D'INSPECTION APPROFONDIE DES ANOMALIES DÉTECTÉES
# ==============================================================================

fichier_csv <- "EPIC_Basic-rgpd ok - Copie.csv"
df <- read.csv(fichier_csv, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)

cols_eval <- paste0("Question_", 1:30, "_evaluation")
cols_sol  <- paste0("Question_", 1:30, "_solution")
cols_rep  <- paste0("Question_", 1:30, "_reply")

cat("=== 1. FOCUS SUR LE PARTICIPANT ULTRA-RAPIDE (E_2026_048 : 3 min 15 s, Score 27) ===\n")
p_rapide <- df[df$"N°ID" == "E_2026_048", ]
print(p_rapide[, c("N°ID", "Region", "EPIC_courses", "Commencé", "Terminé", "Durée", "Note/30_nbr")])
# Réponses fournies
reps_rapide <- data.frame(
  Q = 1:30,
  Sol = unlist(p_rapide[cols_sol]),
  Rep = unlist(p_rapide[cols_rep]),
  Eval = unlist(p_rapide[cols_eval])
)
print(reps_rapide)

cat("\n=== 2. FOCUS SUR LES PARTICIPANTS AYANT OBTENU 0 OU 1 (DURÉE 2 HEURES) ===\n")
ids_zero <- c("E_2026_021", "E_2026_063", "E_2026_118", "E_2026_138", "E_2026_140")
for (id_z in ids_zero) {
  pz <- df[df$"N°ID" == id_z, ]
  reps_z <- unlist(pz[cols_rep])
  cat(sprintf("\nParticipant %s (Score = %s, Duree = %s, EPIC_courses = %s) :\n",
              id_z, pz$"Note/30_nbr", pz$"Durée", pz$"EPIC_courses"))
  cat("Aperçu des 10 premières réponses fournies :\n")
  print(head(reps_z, 10))
  cat("Tableau des réponses uniques :\n")
  print(table(reps_z, useNA = "always"))
}

cat("\n=== 3. FOCUS SUR LES 11 PARTICIPANTS AVEC DIFFÉRENCE DE 0.5 (Verif_eval = 0) ===\n")
lignes_05 <- which(df$Verif_eval == 0 | df$Verif_eval == "0")
for (l in lignes_05[1:3]) {
  pl <- df[l, ]
  cat(sprintf("\nLigne %d, ID %s : Note/30 = %s, Somme_eval = %s, Verif_eval = %s\n",
              l, pl$"N°ID", pl$"Note/30_nbr", pl$"Somme_eval", pl$"Verif_eval"))
  
  # Vérifier s'il y a des valeurs décimales dans l'un des Question_x_evaluation
  evals <- unlist(pl[cols_eval])
  cat("Valeurs des évaluations :", paste(evals, collapse = " "), "\n")
  cat("Somme brute calculée :", sum(as.numeric(evals), na.rm = TRUE), "\n")
}

cat("\n=== 4. COMPARAISON ENTRE EPIC_courses == 'yes' ET EPIC_courses == 'No' ===\n")
scores_num <- as.numeric(gsub(",", ".", df$"Note/30_nbr"))
tapply(scores_num, df$EPIC_courses, summary)

cat("\nTest de Wilcoxon / Mann-Whitney entre les deux groupes :\n")
print(wilcox.test(scores_num ~ df$EPIC_courses))

cat("\n=== 5. VÉRIFICATION DU FICHIER ORIGINAL (EPIC_Basic-rgpd ok.xlsx) ===\n")
cat("Y a-t-il une différence de lignes ou de colonnes entre 'EPIC_Basic-rgpd ok.xlsx' et la Copie ?\n")

