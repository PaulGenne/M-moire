# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - BAC 3 (2025)
# SCRIPT 1 : Préparation et Harmonisation des Données (Format Wide & Format Long)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. ENVIRONNEMENT & DOSSIERS --------------------------------------------------
dossier_eda <- "BAC 3/EDA BAC 3 2025"
dossier_output <- file.path(dossier_eda, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

# Fonction d'exportation conforme AGENTS.md (UTF-8 avec BOM, séparateur ';' et décimale ',')
exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat(sprintf("  -> Fichier CSV exporté : %s\n", chemin_fichier))
}

# 1. CHARGEMENT DES DONNÉES NETTOYÉES DE L'ÉTAPE 1 -----------------------------
path_pre_clean  <- "BAC 3/Qualité données BAC 3 2025/output/BAC3_2025_Pretest_clean.csv"
path_post_clean <- "BAC 3/Qualité données BAC 3 2025/output/BAC3_2025_Posttest_clean.csv"
path_paired     <- "BAC 3/Qualité données BAC 3 2025/output/BAC3_2025_paired_clean.csv"

pre_clean  <- read.csv(path_pre_clean, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
post_clean <- read.csv(path_post_clean, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
df_paired  <- read.csv(path_paired, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

ids_apparies <- df_paired$ID

cat("======================================================================\n")
cat("=== CHARGEMENT DES DONNÉES NETTOYÉES (BAC 3 - 2025) ===\n")
cat("======================================================================\n")
cat(sprintf("Pré-test nettoyé  : %d participants valides\n", nrow(pre_clean)))
cat(sprintf("Post-test nettoyé : %d participants valides\n", nrow(post_clean)))
cat(sprintf("Échantillon apparié strict (Pré + Post) : %d paires\n\n", length(ids_apparies)))

# 2. DÉFINITION DU RÉFÉRENTIEL DES 28 QUESTIONS -------------------------------
nb_questions <- 28
q_nums <- 1:nb_questions

# Extraction des solutions et sexes à partir du pré-test
sols_raw <- sapply(q_nums, function(i) unique(pre_clean[[paste0("Question_", i, "_solution")]])[1])
sex_raw  <- sapply(q_nums, function(i) unique(pre_clean[[paste0("Question_", i, "_sex")]])[1])

# Définition des familles
famille_abeille <- function(genre) {
  g <- tools::toTitleCase(tolower(trimws(genre)))
  switch(g,
    "Andrena"      = "Andrenidae",
    "Panurgus"     = "Andrenidae",
    "Apis"         = "Apidae",
    "Bombus"       = "Apidae",
    "Anthophora"   = "Apidae",
    "Eucera"       = "Apidae",
    "Xylocopa"     = "Apidae",
    "Ceratina"     = "Apidae",
    "Nomada"       = "Apidae",
    "Colletes"     = "Colletidae",
    "Hylaeus"      = "Colletidae",
    "Halictus"     = "Halictidae",
    "Lasioglossum" = "Halictidae",
    "Sphecodes"    = "Halictidae",
    "Megachile"    = "Megachilidae",
    "Osmia"        = "Megachilidae",
    "Anthidium"    = "Megachilidae",
    "Trachusa"     = "Megachilidae",
    "Stelis"       = "Megachilidae",
    "Dasypoda"     = "Melittidae",
    "Autre"
  )
}

est_cleptoparasite <- function(genre) {
  g <- tools::toTitleCase(tolower(trimws(genre)))
  g %in% c("Nomada", "Sphecodes", "Stelis")
}

tribu_associee <- function(genre) {
  g <- tools::toTitleCase(tolower(trimws(genre)))
  switch(g,
    "Halictus"     = "Halictini",
    "Lasioglossum" = "Halictini",
    "Anthidium"    = "Anthidinii",
    "Trachusa"     = "Anthidinii",
    "Stelis"       = "Anthidinii",
    NA_character_
  )
}

meta_questions <- data.frame(
  Question_Index = q_nums,
  Question_Code = paste0("Question_", q_nums),
  Genre_Solution = sols_raw,
  Sexe_Code = ifelse(sex_raw == "FALSE", "F", sex_raw),
  Sexe = ifelse(sex_raw == "FALSE" | sex_raw == "F", "Femelle", "Mâle"),
  Famille = sapply(sols_raw, famille_abeille),
  Guilde = ifelse(sapply(sols_raw, est_cleptoparasite), "Cléptoparasite", "Non parasite"),
  Tribu_Valide = sapply(sols_raw, tribu_associee),
  stringsAsFactors = FALSE
)

cat("--- Référentiel des 28 spécimens d'évaluation (BAC 3 2025) ---\n")
print(meta_questions[, c("Question_Index", "Genre_Solution", "Sexe", "Famille", "Guilde", "Tribu_Valide")])

# 3. CRÉATION DU FORMAT WIDE STANDARDISÉ ---------------------------------------
parse_duree_min <- function(dur_str) {
  sapply(dur_str, function(d) {
    if (is.na(d) || d == "") return(NA_real_)
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

prepare_wide_cohort <- function(df, cohorte_label) {
  q_rep_cols <- paste0("Question_", q_nums, "_reply")
  
  res <- data.frame(
    ID_Participant = df$ID,
    Cohorte = cohorte_label,
    Apparie_Strict = df$ID %in% ids_apparies,
    Date_Debut = df$Commencé,
    Date_Fin = df$Terminé,
    Duree_Texte = df$Durée,
    Duree_Minutes = parse_duree_min(df$Durée),
    Note_Officielle_Moodle = as.numeric(gsub(",", ".", as.character(df[["Note/20,0"]]))),
    stringsAsFactors = FALSE
  )
  
  # Calcul des scores stricts (genre exact) et Moodle (genre + tribu tolérée)
  scores_strict <- sapply(1:nrow(df), function(i) {
    reps <- trimws(tolower(as.character(df[i, q_rep_cols])))
    sols <- tolower(meta_questions$Genre_Solution)
    sum(reps == sols, na.rm = TRUE)
  })
  
  scores_moodle_calc <- sapply(1:nrow(df), function(i) {
    reps <- trimws(tolower(as.character(df[i, q_rep_cols])))
    sols <- tolower(meta_questions$Genre_Solution)
    tribus <- tolower(meta_questions$Tribu_Valide)
    sum(reps == sols | (!is.na(tribus) & reps == tribus), na.rm = TRUE)
  })
  
  nb_idk <- sapply(1:nrow(df), function(i) {
    reps <- as.character(df[i, q_rep_cols])
    sum(grepl("je ne sais pas|don.*t know", reps, ignore.case = TRUE))
  })
  
  nb_omis <- sapply(1:nrow(df), function(i) {
    reps <- trimws(as.character(df[i, q_rep_cols]))
    sum(is.na(reps) | reps == "" | reps == "-")
  })
  
  res$Score_Exact_28 <- scores_strict
  res$Score_Moodle_28 <- scores_moodle_calc
  res$Score_Moodle_20 <- round(res$Note_Officielle_Moodle, 2)
  res$Pourcentage_Reussite <- round((scores_moodle_calc / nb_questions) * 100, 2)
  res$Nombre_IDK <- nb_idk
  res$Nombre_Omissions <- nb_omis
  res$Nombre_Repondu <- nb_questions - nb_omis
  
  # Flag cas atypique
  res$Profil_Atypique <- ifelse(res$Duree_Minutes < 5 & res$Nombre_IDK >= 24, "Speed-run Pretest (IDK >= 24)", "Standard")
  
  # Recopie des 28 réponses
  for (j in 1:nb_questions) {
    res[[paste0("Q", sprintf("%02d", j), "_Reponse")]] <- df[[q_rep_cols[j]]]
  }
  
  return(res)
}

df_wide_pre  <- prepare_wide_cohort(pre_clean, "Pré-test")
df_wide_post <- prepare_wide_cohort(post_clean, "Post-test")
df_wide_all  <- rbind(df_wide_pre, df_wide_post)

exporter_excel_csv(df_wide_all, file.path(dossier_eda, "BAC3_2025_clean_wide.csv"))

# 4. CRÉATION DU FORMAT LONG STANDARDISÉ (LIGNE = SPECIMEN x PARTICIPANT) -------
long_list <- list()
idx_long <- 1

for (i in 1:nrow(df_wide_all)) {
  p_id     <- df_wide_all$ID_Participant[i]
  cohorte  <- df_wide_all$Cohorte[i]
  apparie  <- df_wide_all$Apparie_Strict[i]
  duree    <- df_wide_all$Duree_Minutes[i]
  note_tot <- df_wide_all$Score_Moodle_20[i]
  profil   <- df_wide_all$Profil_Atypique[i]
  
  for (j in 1:nb_questions) {
    q_col <- paste0("Question_", j)
    rep_brute <- df_wide_all[[paste0("Q", sprintf("%02d", j), "_Reponse")]][i]
    
    sol_genre  <- meta_questions$Genre_Solution[j]
    sexe       <- meta_questions$Sexe[j]
    famille    <- meta_questions$Famille[j]
    guilde     <- meta_questions$Guilde[j]
    tribu_ok   <- meta_questions$Tribu_Valide[j]
    
    rep_clean <- trimws(rep_brute)
    is_idk  <- grepl("je ne sais pas|don.*t know", rep_clean, ignore.case = TRUE)
    is_omis <- is.na(rep_clean) || rep_clean == "" || rep_clean == "-"
    
    # Standardisation libellé
    rep_genre <- if (is_idk) "Je ne sais pas" else if (is_omis) "Non répondu" else tools::toTitleCase(tolower(rep_clean))
    
    # Évaluation du succès
    correct_strict <- ifelse(!is_idk && !is_omis && (tolower(sol_genre) == tolower(rep_genre)), 1, 0)
    correct_tribu  <- ifelse(!is_idk && !is_omis && !is.na(tribu_ok) && (tolower(tribu_ok) == tolower(rep_genre)), 1, 0)
    correct_moodle <- ifelse(correct_strict == 1 || correct_tribu == 1, 1, 0)
    
    long_list[[idx_long]] <- data.frame(
      ID_Participant = p_id,
      Cohorte = cohorte,
      Apparie_Strict = apparie,
      Profil_Atypique = profil,
      Question_Num = j,
      Question_Code = q_col,
      Genre_Solution = sol_genre,
      Sexe_Specimen = sexe,
      Famille_Solution = famille,
      Guilde_Solution = guilde,
      Tribu_Toleree = ifelse(is.na(tribu_ok), "-", tribu_ok),
      Reponse_Brute = rep_brute,
      Genre_Reponse = rep_genre,
      Est_Correct_Strict = correct_strict,
      Est_Correct_Tribu = correct_tribu,
      Est_Correct_Moodle = correct_moodle,
      Est_IDK = as.integer(is_idk),
      Est_Omis = as.integer(is_omis),
      Duree_Session_Min = duree,
      Score_Total_Participant = note_tot,
      stringsAsFactors = FALSE
    )
    idx_long <- idx_long + 1
  }
}

df_long_all <- do.call(rbind, long_list)
cat(sprintf("Format long généré : %d observations d'identification (%d participants x 28 questions)\n",
            nrow(df_long_all), nrow(df_wide_all)))

exporter_excel_csv(df_long_all, file.path(dossier_eda, "BAC3_2025_clean_long.csv"))

cat("\n======================================================================\n")
cat("=== PRÉPARATION DES DONNÉES EDA (BAC 3 2025) TERMINÉE AVEC SUCCÈS ===\n")
cat("======================================================================\n")

