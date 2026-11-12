# ==============================================================================
# Script R : Lecture du fichier EPIC_Basic-rgpd ok - Copie.xlsx
# ==============================================================================

# 1. Vérification et chargement du package nécessaire (readxl)
if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl")
}
library(readxl)

# 2. Définition du chemin du fichier
fichier_excel <- "EPIC_Basic-rgpd ok - Copie.xlsx"

# 3. Liste des feuilles disponibles
feuilles <- excel_sheets(fichier_excel)
cat("Feuilles disponibles dans le fichier Excel :\n")
print(feuilles)

# 4. Lecture des données de la première feuille ("Correction_Test_Basic")
df_epic <- read_excel(fichier_excel, sheet = "Correction_Test_Basic")

# 5. Affichage des informations sur les données
cat("\n--- Dimensions du jeu de données ---\n")
cat("Nombre de lignes   :", nrow(df_epic), "\n")
cat("Nombre de colonnes :", ncol(df_epic), "\n")

cat("\n--- Aperçu des premières lignes ---\n")
print(head(df_epic[, 1:10]))

cat("\n--- Résumé des premières variables ---\n")
summary(df_epic[, 1:10])

