# Vérification de tous les cas Hoplitis / Osmia dans le jeu de données
fichier_csv <- "EPIC_Basic-rgpd ok - Copie.csv"
df <- read.csv(fichier_csv, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)

cols_eval <- paste0("Question_", 1:30, "_evaluation")
cols_sol  <- paste0("Question_", 1:30, "_solution")
cols_rep  <- paste0("Question_", 1:30, "_reply")

cas_hoplitis_osmia <- list()

for (i in 1:nrow(df)) {
  for (q in 1:30) {
    sol <- df[i, cols_sol[q]]
    rep <- df[i, cols_rep[q]]
    ev  <- df[i, cols_eval[q]]
    
    if (!is.na(sol) && tolower(trimws(sol)) == "hoplitis" && !is.na(rep) && tolower(trimws(rep)) == "osmia") {
      cas_hoplitis_osmia[[length(cas_hoplitis_osmia) + 1]] <- data.frame(
        Ligne = i,
        ID = df[i, "N°ID"],
        EPIC_courses = df[i, "EPIC_courses"],
        Question = q,
        Solution = sol,
        Reponse = rep,
        Evaluation = ev,
        Note_30 = df[i, "Note/30_nbr"],
        Somme_eval = df[i, "Somme_eval"],
        Verif_eval = df[i, "Verif_eval"]
      )
    }
  }
}

df_ho <- do.call(rbind, cas_hoplitis_osmia)
cat("Nombre total de réponses 'Osmia' pour la solution 'Hoplitis' :", nrow(df_ho), "\n")
print(df_ho)

