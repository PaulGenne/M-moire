# Inspection détaillée des colonnes des 11 participants avec Verif_eval == 0
fichier_csv <- "EPIC_Basic-rgpd ok - Copie.csv"
df <- read.csv(fichier_csv, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)

lignes_05 <- which(df$Verif_eval == 0 | df$Verif_eval == "0")

cat("Vérification des 11 participants avec Verif_eval == 0 :\n")
for (l in lignes_05) {
  row_data <- df[l, ]
  id <- row_data$"N°ID"
  note_30 <- row_data$"Note/30_nbr"
  somme_eval <- row_data$"Somme_eval"
  
  # Chercher dans toutes les colonnes Question_i_evaluation s'il y a un 0.5 ou virgule
  cols_eval <- paste0("Question_", 1:30, "_evaluation")
  evals <- unlist(row_data[cols_eval])
  evals_num <- suppressWarnings(as.numeric(gsub(",", ".", evals)))
  
  # Trouver si une question a une réponse spéciale
  cols_rep <- paste0("Question_", 1:30, "_reply")
  cols_sol <- paste0("Question_", 1:30, "_solution")
  reps <- unlist(row_data[cols_rep])
  sols <- unlist(row_data[cols_sol])
  
  # Vérifier s'il y a des questions où solution et réponse sont presque identiques (ex: sous-genre, faute de frappe)
  cat(sprintf("\nID: %s | Ligne: %d | Note: %s | Somme_eval: %s\n", id, l, note_30, somme_eval))
  cat("Questions où eval == 0 :\n")
  zeros <- which(evals_num == 0)
  for (z in zeros) {
    cat(sprintf("  Q%02d -> Solution: '%s' | Reponse: '%s'\n", z, sols[z], reps[z]))
  }
}

