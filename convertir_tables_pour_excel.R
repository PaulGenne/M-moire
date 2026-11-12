# ==============================================================================
# SCRIPT R : Exportation des tableaux au format Excel Francophone (FR / BE)
# ==============================================================================
# - Délimiteur de colonnes : Point-virgule (;)
# - Séparateur décimal     : Virgule (,)
# - Encodage               : UTF-8 avec signature BOM (accents parfaits dans Excel)
# ==============================================================================

exporter_excel_csv <- function(df, chemin_fichier) {
  # 1. Écriture du BOM UTF-8 (EF BB BF) en binaire
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  
  # 2. Écriture des données avec séparateur ';' et décimale ','
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(
    df,
    file = con_txt,
    sep = ";",
    dec = ",",
    row.names = FALSE,
    col.names = TRUE,
    qmethod = "double"
  )
  close(con_txt)
}

# Liste des tableaux de résultats
fichiers_tableaux <- c(
  "Analyses Stats EPIC 2026/output/tableau_tests_formation.csv",
  "Analyses Stats EPIC 2026/output/tableau_genres_odds_ratios.csv",
  "Analyses Stats EPIC 2026/output/tableau_tests_fisher_formation_genres.csv",
  "EDA EPIC 2026/output/tableau_difficulte_genres.csv",
  "EDA EPIC 2026/output/tableau_confusions_taxonomiques.csv",
  "Qualité données EPIC 2026/output/participants_anomalies_qualite.csv"
)

cat("======================================================================\n")
cat("CONVERSION DES TABLEAUX POUR EXCEL (SÉPARATEUR ';' ET DÉCIMALE ',')\n")
cat("======================================================================\n\n")

for (f in fichiers_tableaux) {
  if (file.exists(f)) {
    # Lecture adaptative
    l1 <- readLines(f, n = 1, encoding = "UTF-8", warn = FALSE)
    sep_lu <- ifelse(grepl(";", l1), ";", ",")
    
    # Chargement
    df_temp <- read.csv(f, sep = sep_lu, dec = ifelse(sep_lu == ";", ",", "."),
                        encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)
    
    # Réécriture propre
    exporter_excel_csv(df_temp, f)
    cat(sprintf("-> Fichier converti avec succès : %s\n", f))
  } else {
    cat(sprintf("Fichier introuvable : %s\n", f))
  }
}

cat("\n======================================================================\n")
cat("OPÉRATION TERMINÉE : Tous les tableaux s'ouvrent directement dans Excel !\n")
cat("======================================================================\n")

