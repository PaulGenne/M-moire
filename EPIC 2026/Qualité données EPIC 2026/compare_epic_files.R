# Comparaison des fichiers EPIC dans le dossier
Add_Type_Zip <- function() {
  # En R avec unzip
}

fichiers <- c("EPIC_Basic-rgpd ok.xlsx", "EPIC_Basic-rgpd ok - Copie.xlsx", "EPIC_Pretest.xlsx", "EPIC_Posttest.xlsx")

for (f in fichiers) {
  if (file.exists(f)) {
    cat("========================================================\n")
    cat("Fichier :", f, "\n")
    # Liste du contenu du zip
    contenu <- unzip(f, list = TRUE)
    # Chercher les feuilles
    cat("Taille totale :", file.info(f)$size, "octets\n")
    cat("Fichiers internes xml :\n")
    print(contenu$Name[grep("sheet|workbook", contenu$Name)])
  }
}

