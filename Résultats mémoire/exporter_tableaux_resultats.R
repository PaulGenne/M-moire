# ==============================================================================
# Script R d'exportation des tableaux pour Excel Francophone (FR / BE)
# ==============================================================================
# Respecte scrupuleusement la règle 4 de AGENTS.md :
# - Séparateur de colonnes : Point-virgule (;)
# - Séparateur décimal : Virgule (,)
# - Encodage : UTF-8 avec signature BOM (0xEF, 0xBB, 0xBF)
# ==============================================================================

if (!dir.exists("Résultats mémoire/tables")) {
  dir.create("Résultats mémoire/tables", recursive = TRUE)
}

exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
}

message("--> Exportation des tableaux de resultats adaptes pour Excel FR/BE...")

# Tableau 1 : Echantillonnage et attrition
df_tab1 <- data.frame(
  Cohorte = c("EPIC 2025", "BAC 3 (2024)", "BAC 3 (2025)", "EPIC (2026)"),
  Profil_Public = c("Adultes naturalistes", "Etudiants Biologie", "Etudiants Biologie", "Adultes naturalistes"),
  Design_Epreuve = c("Longitudinal (Pre vs Post)", "Longitudinal apparie", "Longitudinal apparie", "Transversal (Formes vs Temoins)"),
  N_Initial = c(56, 32, 23, 172),
  N_Analyse = c("50 Pre / 49 Post", "25 paires", "22 paires", "64 Formes / 108 Temoins"),
  Taux_Retention_Pct = c(87.5, 78.1, 95.7, 100.0),
  Items_Test = c(30, 26, 28, 30),
  stringsAsFactors = FALSE
)
exporter_excel_csv(df_tab1, "Résultats mémoire/tables/Tableau1_echantillonnage_attrition.csv")

# Tableau 2A : Performances descriptives
df_tab2a <- data.frame(
  Cohorte = c("EPIC 2025", "BAC 3 (2024)", "BAC 3 (2025)", "EPIC 2026"),
  Echantillon = c("50 Pre / 49 Post", "25 paires strictes", "22 paires strictes", "64 Formes / 108 Temoins"),
  Score_Pre_Moy_ET = c("10,51 ± 4,69", "6,61 ± 3,21", "9,33 ± 4,33", "15,91 ± 3,43"),
  Score_Post_Moy_ET = c("16,53 ± 2,22", "14,06 ± 2,76", "15,26 ± 2,64", "16,53 ± 2,77"),
  Gain_Brut_Points = c("+6,02 pts", "+7,45 pts", "+5,93 pts", "+0,62 pt"),
  Gain_Relatif_Pct = c("+30,1 %", "+37,2 %", "+29,7 %", "+3,1 %"),
  stringsAsFactors = FALSE
)
exporter_excel_csv(df_tab2a, "Résultats mémoire/tables/Tableau2A_performances_descriptives.csv")

# Tableau 2B : Inferentiel et tailles d'effet
df_tab2b <- data.frame(
  Cohorte = c("EPIC 2025", "BAC 3 (2024)", "BAC 3 (2025)", "EPIC 2026"),
  Test_Inferentiel = c("Wilcoxon W = 2103", "Wilcoxon apparie V = 325", "Wilcoxon apparie V = 252", "GLM multivarie t = -2,02"),
  P_Value = c("< 0,001", "< 0,001", "< 0,001", "0,046"),
  Cohen_d = c(1.64, 2.73, 1.40, 0.19),
  Rosenthal_r = c(0.62, 0.62, 0.61, 0.07),
  Odds_Ratio_Ajuste = c("3,94 [2,74 - 5,66]", "5,54 [3,77 - 8,14]", "4,37 [2,73 - 6,98]", "1,42 [1,01 - 2,01]"),
  stringsAsFactors = FALSE
)
exporter_excel_csv(df_tab2b, "Résultats mémoire/tables/Tableau2B_tests_tailles_effet.csv")

# Tableau 3 : GLM Interaction
tab3_source <- "Synthese Inter-Cohortes/output/tableau_modele_interaction_public_formation.csv"
if (file.exists(tab3_source)) {
  df_tab3 <- read.table(tab3_source, header = TRUE, sep = ";", dec = ",", encoding = "UTF-8", check.names = FALSE)
  exporter_excel_csv(df_tab3, "Résultats mémoire/tables/Tableau3_modele_interaction_public_formation.csv")
}

# Tableau 4 : Consensus 27 genres adapte
tab4_source <- "Synthese Inter-Cohortes/output/tableau_consensus_pieges_taxonomiques.csv"
if (file.exists(tab4_source)) {
  df_raw4 <- read.table(tab4_source, header = TRUE, sep = ";", dec = ",", encoding = "UTF-8", check.names = FALSE)
  df_tab4_clean <- data.frame(
    Categorie = df_raw4$Categorie_Difficulte,
    Genre = df_raw4$Genre,
    Famille = df_raw4$Famille,
    Guilde = df_raw4$Guilde,
    Taux_Succes_Post = sprintf("%.1f %%", df_raw4$Taux_Succes_Post),
    Taux_Erreur_Post = sprintf("%.1f %%", df_raw4$Taux_Erreur_Post),
    IC_Wilson_95 = sprintf("[%.1f - %.1f %%]", df_raw4$IC_Wilson_Err_Inf_Post, df_raw4$IC_Wilson_Err_Sup_Post),
    stringsAsFactors = FALSE
  )
  exporter_excel_csv(df_tab4_clean, "Résultats mémoire/tables/Tableau4_consensus_difficulte_genres.csv")
}

# Tableau 5 : Top confusions
df_tab5 <- data.frame(
  Confusion_Observee = c("Sphecodes -> Nomada", "Anthophora -> Bombus", "Lasioglossum -> Halictus", "Megachile -> Osmia", "Stelis -> Anthidium"),
  Part_Erreurs_Pct = c("58,3 %", "44,1 %", "36,7 %", "31,2 %", "28,9 %"),
  Familles = c("Halictidae -> Apidae", "Apidae -> Apidae", "Halictidae -> Halictidae", "Megachilidae -> Megachilidae", "Megachilidae -> Megachilidae"),
  Critere_Morphologique_Cle = c(
    "Abdomen rouge et corps noir glabre ; nervure basale coudee chez Sphecodes",
    "Habitus trapu et toison dense ; corbicula a corbeille chez Bombus vs scopa chez Anthophora",
    "Taille et habitus proches ; soies abdominales basales (Lasioglossum) vs apicales (Halictus)",
    "Brosse ventrale commune ; cuticule sombre (Megachile) vs reflets metalliques (Osmia)",
    "Macules jaunes sur fond noir ; absence totale de brosse ventrale chez Stelis"
  ),
  stringsAsFactors = FALSE
)
exporter_excel_csv(df_tab5, "Résultats mémoire/tables/Tableau5_top_confusions_taxonomiques.csv")

# Tableau 6 : Synoptique metriques
df_tab6 <- data.frame(
  Axe = c("Axe A", "Axe A", "Axe A", "Axe A", "Axe A", "Axe A", "Axe B", "Axe B", "Axe B"),
  Dimension = c("Progression globale", "Amplitude d'effet", "Cote de reussite", "Vitesse d'apprentissage", "Doute / Evitement", "Facteurs biologiques", "Difficulte extreme", "Confusion majeure", "Maitrise totale"),
  Indicateur = c("Gain brut (Delta) sur 20 pts", "Taille d'effet Rosenthal (r)", "Odds Ratio GLM Formation", "Interaction Public x Formation", "Reduction 'Je ne sais pas'", "Interaction Sexe x Formation", "Genre le plus difficile", "Paire d'erreur predeterminante", "Genre le plus facile"),
  Valeur = c("+5,93 a +7,45 pts", "r ~ 0,61 - 0,62", "OR = 3,94 - 5,54", "p = 0,903 (NS)", "-85,3 % a -92,2 %", "p = 0,393 (NS)", "Stelis (57,4 % err)", "Sphecodes -> Nomada (58,3 %)", "Xylocopa (0,0 % err)"),
  stringsAsFactors = FALSE
)
exporter_excel_csv(df_tab6, "Résultats mémoire/tables/Tableau6_synoptique_metriques_memoire.csv")

message("--> Exportation terminee avec succes dans 'Résultats mémoire/tables/' !")
