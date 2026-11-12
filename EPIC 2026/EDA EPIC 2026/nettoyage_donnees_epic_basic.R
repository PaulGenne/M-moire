# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# PHASE 2 : EDA (Exploratory Data Analysis)
# SCRIPT 1 : Nettoyage et Préparation du Jeu de Données Propre (Clean Dataset)
# ==============================================================================

# 0. ENVIRONNEMENT & DOSSIERS --------------------------------------------------
dossier_eda <- "EDA EPIC 2026"
dossier_output <- file.path(dossier_eda, "output")

if (!dir.exists(dossier_eda)) dir.create(dossier_eda, recursive = TRUE)
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

# 1. CHARGEMENT DES DONNÉES BRUTES ET DU FICHIER SOURCE DES TENTATIVES ---------
fichier_csv_copie <- "EPIC_Basic-rgpd ok - Copie.csv"
fichier_source_tentatives <- "EPIC_Basic-rgpd ok.xlsx"

df_raw <- read.csv(fichier_csv_copie, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)
cat(sprintf("Chargement initial : %d lignes x %d colonnes\n\n", nrow(df_raw), ncol(df_raw)))

# Extraction de la variable 'Tentative' depuis le fichier d'origine (via décompression XML)
extraire_tentatives <- function(xlsx_path) {
  zip_files <- unzip(xlsx_path, list = TRUE)$Name
  
  # Lecture sharedStrings
  ss_con <- unz(xlsx_path, "xl/sharedStrings.xml")
  ss_txt <- readLines(ss_con, encoding = "UTF-8", warn = FALSE)
  close(ss_con)
  ss_xml <- paste(ss_txt, collapse = "")
  # Extraire le texte de chaque <si>
  si_matches <- regmatches(ss_xml, gregexpr("<si>.*?</si>", ss_xml))[[1]]
  shared_strings <- sapply(si_matches, function(si) {
    # Extraire tout le texte contenu dans <t>
    t_m <- regmatches(si, gregexpr("<t[^>]*>(.*?)</t>", si))[[1]]
    t_clean <- gsub("<t[^>]*>|</t>", "", t_m)
    paste(t_clean, collapse = "")
  })
  names(shared_strings) <- NULL
  
  # Lecture sheet1
  s1_con <- unz(xlsx_path, "xl/worksheets/sheet1.xml")
  s1_txt <- readLines(s1_con, encoding = "UTF-8", warn = FALSE)
  close(s1_con)
  s1_xml <- paste(s1_txt, collapse = "")
  
  # Extraire chaque balise <row>
  row_matches <- regmatches(s1_xml, gregexpr("<row[^>]*>.*?</row>", s1_xml))[[1]]
  
  # Chercher la colonne D dans chaque ligne
  tentatives <- rep(NA_character_, length(row_matches) - 1)
  
  for (i in 2:length(row_matches)) {
    row_xml <- row_matches[i]
    c_m <- regmatches(row_xml, gregexpr('<c r="D\\d+"[^>]*>(?:<v>(\\d+)</v>)?', row_xml))[[1]]
    if (length(c_m) > 0) {
      is_shared <- grepl('t="s"', c_m[1])
      val_idx <- regmatches(c_m[1], regexec('<v>(\\d+)</v>', c_m[1]))[[1]][2]
      if (!is.na(val_idx)) {
        idx_num <- as.numeric(val_idx)
        if (is_shared) {
          tentatives[i - 1] <- shared_strings[idx_num + 1]
        } else {
          tentatives[i - 1] <- val_idx
        }
      }
    }
  }
  return(tentatives)
}

t_vector <- extraire_tentatives(fichier_source_tentatives)
df_raw$Tentative <- t_vector

cat("Distribution initiale de la variable 'Tentative' récupérée :\n")
print(table(df_raw$Tentative, useNA = "always"))

# 2. STANDARDISATION ET ENRICHISSEMENT DES VARIABLES ---------------------------
# Extraction de la durée en minutes
parser_duree <- function(d_str) {
  if (is.na(d_str) || trimws(d_str) == "") return(NA_real_)
  d_str <- tolower(trimws(d_str))
  heures <- 0; minutes <- 0; secondes <- 0
  h_m <- regmatches(d_str, regexec("(\\d+)\\s*(?:heure|h)", d_str))[[1]]
  if (length(h_m) > 1) heures <- as.numeric(h_m[2])
  m_m <- regmatches(d_str, regexec("(\\d+)\\s*(?:minute|min|m)", d_str))[[1]]
  if (length(m_m) > 1) minutes <- as.numeric(m_m[2])
  s_m <- regmatches(d_str, regexec("(\\d+)\\s*(?:seconde|sec|s)", d_str))[[1]]
  if (length(s_m) > 1) secondes <- as.numeric(s_m[2])
  tot <- heures * 60 + minutes + (secondes / 60)
  if (tot == 0 && !grepl("0\\s*(?:min|sec|heure)", d_str)) {
    v <- suppressWarnings(as.numeric(d_str))
    if (!is.na(v)) return(v)
  }
  return(tot)
}

df_raw$Duree_Minutes <- sapply(df_raw$"Durée", parser_duree)

# Décompte des réponses fournies vs tirets "-"
cols_rep  <- paste0("Question_", 1:30, "_reply")
cols_eval <- paste0("Question_", 1:30, "_evaluation")
cols_sol  <- paste0("Question_", 1:30, "_solution")

df_raw$Nb_Tirets <- apply(df_raw[cols_rep], 1, function(r) sum(trimws(r) == "-" | trimws(r) == ""))
df_raw$Nb_Reponses_Fournies <- 30 - df_raw$Nb_Tirets

# Score recalculé strictement binaire sur les 30 questions (0 à 30)
mat_eval <- as.data.frame(lapply(df_raw[cols_eval], function(x) suppressWarnings(as.numeric(x))))
df_raw$Score_Total_Propre <- rowSums(mat_eval, na.rm = TRUE)
df_raw$Pourcentage_Reussite <- round(100 * df_raw$Score_Total_Propre / 30, 2)

# Normalisation de EPIC_courses
df_raw$Formation_EPIC <- ifelse(tolower(trimws(df_raw$EPIC_courses)) == "yes", "Formés EPIC", "Non formés")

# 3. APPLICATION DES 4 RÈGLES DE NETTOYAGE VALIDÉES ----------------------------
cat("\n----------------------------------------------------------------------\n")
cat("APPLICATION DES FILTRES DE NETTOYAGE SCIENTIFIQUE\n")
cat("----------------------------------------------------------------------\n")

# Règle 1 : Exclusion des 6 abandons sévères (<= 5 réponses réelles fournies)
filtre_abandon <- df_raw$Nb_Reponses_Fournies <= 5
cat(sprintf("1. Abandons sévères éliminés (<= 5 réponses / 30) : %d participants\n", sum(filtre_abandon)))

# Règle 2 : Conservation exclusive de la Tentative 1 (suppression des 23 secondes tentatives)
filtre_tentative2 <- !is.na(df_raw$Tentative) & df_raw$Tentative == "2"
cat(sprintf("2. Secondes tentatives éliminées (Tentative = 2)   : %d observations\n", sum(filtre_tentative2)))

# Règle 3 : Exclusion des 9 tests éclairs (< 10 min, score >= 26, EPIC_courses = No)
filtre_eclair <- !is.na(df_raw$Duree_Minutes) & df_raw$Duree_Minutes < 10 & 
                 df_raw$Score_Total_Propre >= 26 & df_raw$Formation_EPIC == "Non formés"
cat(sprintf("3. Tests éclairs éliminés (< 10 min, score >= 26)  : %d participants\n", sum(filtre_eclair)))

# Combinaison des motifs d'exclusion (gestion des éventuels recoupements)
df_raw$Motif_Exclusion <- ifelse(filtre_abandon, "Abandon sévère (<= 5 rép.)",
                          ifelse(filtre_tentative2, "Tentative 2 (Pseudoréplication)",
                          ifelse(filtre_eclair, "Test éclair expert (< 10 min)", "Inclus")))

cat("\nTableau de synthèse des inclusions / exclusions :\n")
print(table(df_raw$Motif_Exclusion))

# 4. CRÉATION DU JEU DE DONNÉES PROPRE (CLEAN DATASET) -------------------------
df_clean <- df_raw[df_raw$Motif_Exclusion == "Inclus", ]
cat(sprintf("\n-> EFFECTIF FINAL DU JEU PROPRE : %d participants retenus (sur 209 initiaux)\n", nrow(df_clean)))
cat("Répartition selon la formation dans le jeu propre :\n")
print(table(df_clean$Formation_EPIC))

# Sauvegarde du format WIDE
fichier_wide <- file.path(dossier_eda, "EPIC_Basic_clean_wide.csv")
write.csv(df_clean, fichier_wide, row.names = FALSE)
cat(sprintf("Jeu propre format large sauvegardé : %s\n", fichier_wide))

# 5. TRANSFORMATION EN FORMAT LONG (PAR QUESTION ET PAR GENRE) -----------------
# Pour chaque participant et chaque question : Genre cible, Réponse, Évaluation (0 ou 1)
liste_long <- list()

for (i in 1:nrow(df_clean)) {
  id_p <- df_clean$"N°ID"[i]
  form <- df_clean$Formation_EPIC[i]
  reg  <- df_clean$Region[i]
  dur  <- df_clean$Duree_Minutes[i]
  sc   <- df_clean$Score_Total_Propre[i]
  
  for (q in 1:30) {
    sol <- df_clean[i, cols_sol[q]]
    rep <- df_clean[i, cols_rep[q]]
    ev  <- suppressWarnings(as.numeric(df_clean[i, cols_eval[q]]))
    
    if (!is.na(sol) && trimws(sol) != "") {
      sol_clean <- trimws(sol)
      rep_clean <- ifelse(is.na(rep) || trimws(rep) == "", "-", trimws(rep))
      
      liste_long[[length(liste_long) + 1]] <- data.frame(
        Participant_ID = id_p,
        Formation = form,
        Region = reg,
        Duree_Min = dur,
        Score_Total_Participant = sc,
        Question_Num = q,
        Genre_Solution = sol_clean,
        Reponse_Fournie = rep_clean,
        Evaluation = ev,
        Est_Correct = ifelse(!is.na(ev) & ev == 1, 1, 0),
        stringsAsFactors = FALSE
      )
    }
  }
}

df_clean_long <- do.call(rbind, liste_long)
fichier_long <- file.path(dossier_eda, "EPIC_Basic_clean_long.csv")
write.csv(df_clean_long, fichier_long, row.names = FALSE)
cat(sprintf("Jeu propre format long sauvegardé  : %s (%d lignes d'évaluations individuelles)\n",
            fichier_long, nrow(df_clean_long)))

cat("\n======================================================================\n")
cat("ÉTAPE DE PRÉPARATION ET DE NETTOYAGE TERMINÉE AVEC SUCCÈS.\n")
cat("======================================================================\n")

