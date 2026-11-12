# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - EPIC 2025
# SCRIPT 1 : Préparation et Harmonisation des Données (Wide & Long)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. ENVIRONNEMENT & DOSSIERS --------------------------------------------------
dossier_eda <- "2025/EDA EPIC 2025"
if (!dir.exists(dossier_eda)) dossier_eda <- "."
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
  cat("  -> Fichier CSV exporté :", chemin_fichier, "\n")
}

# 1. CHARGEMENT DES DONNÉES NETTOYÉES DE L'ÉTAPE 1 -----------------------------
path_pre_clean <- "2025/Qualité données EPIC 2025/output/EPIC_Pretest_clean.csv"
path_post_clean <- "2025/Qualité données EPIC 2025/output/EPIC_Posttest_clean.csv"

if (!file.exists(path_pre_clean)) {
  path_pre_clean <- "../Qualité données EPIC 2025/output/EPIC_Pretest_clean.csv"
  path_post_clean <- "../Qualité données EPIC 2025/output/EPIC_Posttest_clean.csv"
}

pre <- read.csv(path_pre_clean, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(path_post_clean, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

cat(sprintf("Chargement des cohortes nettoyées :\n  - Pré-test  : %d participants\n  - Post-test : %d participants\n\n",
            nrow(pre), nrow(post)))

# 2. STANDARDISATION ET ENRICHISSEMENT WIDE ------------------------------------
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
  res <- data.frame(
    ID_Participant = df[["N°ID"]],
    Cohorte = cohorte_label,
    Date_Debut = df[["Commencé"]],
    Date_Fin = df[["Terminé"]],
    Duree_Texte = df[["Durée"]],
    Duree_Minutes = parse_duree_min(df[["Durée"]]),
    stringsAsFactors = FALSE
  )
  
  # Calcul du score exact sur 30 et sur 20
  q_cols_reply <- paste0("Question_", 1:30, "_reply")
  q_cols_sol   <- paste0("Question_", 1:30, "_solution")
  
  nb_correct <- sapply(1:nrow(df), function(i) {
    reps <- trimws(tolower(as.character(df[i, q_cols_reply])))
    sols <- trimws(tolower(as.character(df[i, q_cols_sol])))
    sum(reps == sols, na.rm = TRUE)
  })
  
  nb_idk <- sapply(1:nrow(df), function(i) {
    reps <- as.character(df[i, q_cols_reply])
    sum(grepl("don.*t know", reps, ignore.case = TRUE))
  })
  
  nb_omis <- sapply(1:nrow(df), function(i) {
    reps <- trimws(as.character(df[i, q_cols_reply]))
    sum(is.na(reps) | reps == "" | reps == "-")
  })
  
  res$Score_Brut_30 <- nb_correct
  res$Score_Note_20 <- round(nb_correct * (20 / 30), 2)
  res$Pourcentage_Reussite <- round((nb_correct / 30) * 100, 2)
  res$Nombre_IDK <- nb_idk
  res$Nombre_Omissions <- nb_omis
  res$Nombre_Repondu <- 30 - nb_omis
  
  # Recopier les 30 réponses
  for (q in 1:30) {
    res[[paste0("Q", sprintf("%02d", q), "_Solution")]] <- df[[paste0("Question_", q, "_solution")]]
    
    # Harmonisation sexe : M = Mâle, FALSE / F = Femelle
    raw_sex <- as.character(df[[paste0("Question_", q, "_sex")]])
    res[[paste0("Q", sprintf("%02d", q), "_Sexe")]] <- ifelse(grepl("M", raw_sex, ignore.case = TRUE), "Mâle", "Femelle")
    
    res[[paste0("Q", sprintf("%02d", q), "_Reponse")]] <- df[[paste0("Question_", q, "_reply")]]
  }
  
  return(res)
}

df_wide_pre  <- prepare_wide_cohort(pre, "Pré-test")
df_wide_post <- prepare_wide_cohort(post, "Post-test")
df_wide_all  <- rbind(df_wide_pre, df_wide_post)

exporter_excel_csv(df_wide_all, file.path(dossier_eda, "EPIC_2025_clean_wide.csv"))

# 3. CRÉATION DU FORMAT LONG (QUESTION x PARTICIPANT) -------------------------
# Référentiel taxonomique des 21 genres
famille_abeille <- function(genre) {
  g <- tools::toTitleCase(tolower(trimws(genre)))
  switch(g,
    "Andrena"      = "Andrenidae",
    "Panurgus"     = "Andrenidae",
    "Apis"         = "Apidae",
    "Bombus"       = "Apidae",
    "Anthophora"   = "Apidae",
    "Eucera"       = "Apidae",
    "Melecta"      = "Apidae",
    "Xylocopa"     = "Apidae",
    "Ceratina"     = "Apidae",
    "Nomada"       = "Apidae",
    "Epeolus"      = "Apidae",
    "Ammobates"    = "Apidae",
    "Colletes"     = "Colletidae",
    "Hylaeus"      = "Colletidae",
    "Halictus"     = "Halictidae",
    "Lasioglossum" = "Halictidae",
    "Sphecodes"    = "Halictidae",
    "Megachile"    = "Megachilidae",
    "Osmia"        = "Megachilidae",
    "Hoplitis"     = "Megachilidae",
    "Chelostoma"   = "Megachilidae",
    "Anthidium"    = "Megachilidae",
    "Coelioxys"    = "Megachilidae",
    "Dasypoda"     = "Melittidae",
    "Macropis"     = "Melittidae",
    "Autre"
  )
}

est_cleptoparasite <- function(genre) {
  g <- tools::toTitleCase(tolower(trimws(genre)))
  g %in% c("Nomada", "Sphecodes", "Epeolus", "Melecta", "Coelioxys", "Ammobates")
}

long_list <- list()
idx_long <- 1

for (i in 1:nrow(df_wide_all)) {
  p_id <- df_wide_all$ID_Participant[i]
  cohorte <- df_wide_all$Cohorte[i]
  duree <- df_wide_all$Duree_Minutes[i]
  score_tot <- df_wide_all$Score_Note_20[i]
  
  for (q in 1:30) {
    sol <- df_wide_all[[paste0("Q", sprintf("%02d", q), "_Solution")]][i]
    sexe <- df_wide_all[[paste0("Q", sprintf("%02d", q), "_Sexe")]][i]
    rep_brute <- df_wide_all[[paste0("Q", sprintf("%02d", q), "_Reponse")]][i]
    
    # Nettoyage de la réponse
    rep_clean <- trimws(rep_brute)
    is_idk <- grepl("don.*t know", rep_clean, ignore.case = TRUE)
    is_omis <- is.na(rep_clean) || rep_clean == "" || rep_clean == "-"
    
    # Standardisation du genre répondu
    rep_genre <- if (is_idk) "Je ne sais pas" else if (is_omis) "Non répondu" else tools::toTitleCase(tolower(rep_clean))
    
    # Statut de succès
    sol_genre <- tools::toTitleCase(tolower(trimws(sol)))
    est_correct <- ifelse(!is_idk && !is_omis && (tolower(sol_genre) == tolower(rep_genre)), 1, 0)
    
    long_list[[idx_long]] <- data.frame(
      ID_Participant = p_id,
      Cohorte = cohorte,
      Question_Num = q,
      Genre_Solution = sol_genre,
      Famille_Solution = famille_abeille(sol_genre),
      Guilde_Solution = ifelse(est_cleptoparasite(sol_genre), "Cléptoparasite", "Non parasite"),
      Sexe_Specimen = sexe,
      Reponse_Brute = rep_brute,
      Genre_Reponse = rep_genre,
      Est_Correct = est_correct,
      Est_IDK = as.integer(is_idk),
      Est_Omis = as.integer(is_omis),
      Duree_Minutes = duree,
      Score_Total_Participant = score_tot,
      stringsAsFactors = FALSE
    )
    idx_long <- idx_long + 1
  }
}

df_long_all <- do.call(rbind, long_list)
cat(sprintf("Format long généré : %d observations (99 participants x 30 questions)\n", nrow(df_long_all)))

exporter_excel_csv(df_long_all, file.path(dossier_eda, "EPIC_2025_clean_long.csv"))

cat("\nÉtape de préparation des données terminée avec succès !\n")

