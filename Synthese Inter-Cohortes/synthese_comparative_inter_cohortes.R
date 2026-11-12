# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 4 : Synthèse Comparative Inter-Cohortes (EPIC vs BAC 3 - 2024 / 2025 / 2026)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. CONFIGURATION DE L'ENVIRONNEMENT ET DOSSIERS
# ------------------------------------------------------------------------------
dossier_module <- "Synthese Inter-Cohortes"
dossier_output <- file.path(dossier_module, "output")
if (!dir.exists(dossier_output)) {
  dir.create(dossier_output, recursive = TRUE)
}

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

# Fonction de calcul d'intervalle de confiance de Wilson (95%)
wilson_ci <- function(k, n, conf = 0.95) {
  if (is.na(n) || n == 0) return(c(0, 0))
  alpha <- 1 - conf
  z <- qnorm(1 - alpha / 2)
  p <- k / n
  denom <- 1 + (z^2) / n
  centre <- (p + (z^2) / (2 * n)) / denom
  demi_larg <- (z * sqrt((p * (1 - p) / n) + (z^2) / (4 * (n^2)))) / denom
  c(max(0, centre - demi_larg), min(1, centre + demi_larg))
}

cat("======================================================================\n")
cat("=== MODULE DE SYNTHÈSE COMPARATIVE GLOBALE INTER-COHORTES ===\n")
cat("======================================================================\n\n")

# ------------------------------------------------------------------------------
# 1. CHARGEMENT ET HARMONISATION DES DONNÉES SOURCES
# ------------------------------------------------------------------------------
# Cohorte 1 : EPIC 2025 (Adultes Pré vs Post)
f_epic2025 <- "2025/EDA EPIC 2025/EPIC_2025_clean_wide.csv"
d_epic2025 <- read.csv(f_epic2025, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# Cohorte 2 : BAC 3 2024 (Étudiants Pré vs Post apparié strict N = 25)
f_bac2024 <- "BAC 3/EDA BAC 3 2024/BAC3_2024_clean_wide.csv"
d_bac2024 <- read.csv(f_bac2024, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
d_bac2024_app <- d_bac2024[d_bac2024$Apparie_Strict == TRUE, ]

# Cohorte 3 : BAC 3 2025 (Étudiants Pré vs Post apparié strict N = 22)
f_bac2025 <- "BAC 3/EDA BAC 3 2025/BAC3_2025_clean_wide.csv"
d_bac2025 <- read.csv(f_bac2025, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
d_bac2025_app <- d_bac2025[d_bac2025$Apparie_Strict == TRUE, ]

# Cohorte 4 : EPIC Basic 2026 (Adultes Formés vs Non formés transversaux N = 172)
f_epic2026 <- "EPIC 2026/EDA EPIC 2026/EPIC_Basic_clean_wide.csv"
sep_epic2026 <- if (grepl(";", readLines(f_epic2026, n = 1))) ";" else ","
dec_epic2026 <- if (sep_epic2026 == ";") "," else "."
d_epic2026 <- read.csv(f_epic2026, sep = sep_epic2026, dec = dec_epic2026, stringsAsFactors = FALSE, check.names = FALSE)
d_epic2026 <- d_epic2026[d_epic2026$Motif_Exclusion == "Inclus", ]

is_forme_epic26 <- d_epic2026$EPIC_courses == "yes"

cat("Chargement terminé :\n")
cat(sprintf("  - EPIC 2025       : %d observations (Pré: %d, Post: %d)\n",
            nrow(d_epic2025), sum(d_epic2025$Cohorte == "Pré-test"), sum(d_epic2025$Cohorte == "Post-test")))
cat(sprintf("  - BAC 3 (2024)    : %d paires appariées strictes\n", nrow(d_bac2024_app) / 2))
cat(sprintf("  - BAC 3 (2025)    : %d paires appariées strictes\n", nrow(d_bac2025_app) / 2))
cat(sprintf("  - EPIC Basic 2026 : %d participants transversaux (Formés: %d, Non formés: %d)\n\n",
            nrow(d_epic2026), sum(is_forme_epic26), sum(!is_forme_epic26)))

# ------------------------------------------------------------------------------
# 2. EXTRACTION ET SYNTHÈSE DES SCORES SUR 20 POINTS (AXE A)
# ------------------------------------------------------------------------------
sc_epic25_pre  <- d_epic2025$Score_Note_20[d_epic2025$Cohorte == "Pré-test"]
sc_epic25_post <- d_epic2025$Score_Note_20[d_epic2025$Cohorte == "Post-test"]

sc_b24_pre  <- d_bac2024_app$Score_Moodle_20[d_bac2024_app$Cohorte == "Pré-test"]
sc_b24_post <- d_bac2024_app$Score_Moodle_20[d_bac2024_app$Cohorte == "Post-test"]

sc_b25_pre  <- d_bac2025_app$Score_Moodle_20[d_bac2025_app$Cohorte == "Pré-test"]
sc_b25_post <- d_bac2025_app$Score_Moodle_20[d_bac2025_app$Cohorte == "Post-test"]

sc_epic26_nf <- (d_epic2026$Score_Total_Propre[!is_forme_epic26] / 30) * 20
sc_epic26_f  <- (d_epic2026$Score_Total_Propre[is_forme_epic26] / 30) * 20

# Taux IDK (% moyen de questions avec "Je ne sais pas" / omissions)
idk_epic25_pre  <- mean(d_epic2025$Nombre_IDK[d_epic2025$Cohorte == "Pré-test"] / 30) * 100
idk_epic25_post <- mean(d_epic2025$Nombre_IDK[d_epic2025$Cohorte == "Post-test"] / 30) * 100

idk_b24_pre  <- mean(d_bac2024_app$Nombre_IDK[d_bac2024_app$Cohorte == "Pré-test"] / 26) * 100
idk_b24_post <- mean(d_bac2024_app$Nombre_IDK[d_bac2024_app$Cohorte == "Post-test"] / 26) * 100

idk_b25_pre  <- mean(d_bac2025_app$Nombre_IDK[d_bac2025_app$Cohorte == "Pré-test"] / 28) * 100
idk_b25_post <- mean(d_bac2025_app$Nombre_IDK[d_bac2025_app$Cohorte == "Post-test"] / 28) * 100

# Synthèse descriptive
df_synth_axe_a <- data.frame(
  Cohorte = c("EPIC 2025", "BAC 3 (2024)", "BAC 3 (2025)", "EPIC Basic (2026)"),
  Public = c("Adultes naturalistes", "Étudiants université (Bac 3)", "Étudiants université (Bac 3)", "Adultes naturalistes"),
  Dispositif = c("Longitudinal (Pré vs Post)", "Longitudinal apparié (Pré vs Post)", "Longitudinal apparié (Pré vs Post)", "Adultes (Formés vs Non formés)"),
  N_Initial = c(56, 32, 23, 172),
  N_Analyse = c("50 Pré / 49 Post", "25 paires", "22 paires", "64 Formés / 108 Non formés"),
  Questions_Test = c(30, 26, 28, 30),
  Score_Pre_Moy_ET = c(
    sprintf("%.2f (± %.2f)", mean(sc_epic25_pre), sd(sc_epic25_pre)),
    sprintf("%.2f (± %.2f)", mean(sc_b24_pre), sd(sc_b24_pre)),
    sprintf("%.2f (± %.2f)", mean(sc_b25_pre), sd(sc_b25_pre)),
    sprintf("%.2f (± %.2f)", mean(sc_epic26_nf), sd(sc_epic26_nf))
  ),
  Score_Pre_Med = c(median(sc_epic25_pre), median(sc_b24_pre), median(sc_b25_pre), round(median(sc_epic26_nf), 2)),
  Score_Post_Moy_ET = c(
    sprintf("%.2f (± %.2f)", mean(sc_epic25_post), sd(sc_epic25_post)),
    sprintf("%.2f (± %.2f)", mean(sc_b24_post), sd(sc_b24_post)),
    sprintf("%.2f (± %.2f)", mean(sc_b25_post), sd(sc_b25_post)),
    sprintf("%.2f (± %.2f)", mean(sc_epic26_f), sd(sc_epic26_f))
  ),
  Score_Post_Med = c(median(sc_epic25_post), median(sc_b24_post), median(sc_b25_post), round(median(sc_epic26_f), 2)),
  Gain_Points = c(
    round(mean(sc_epic25_post) - mean(sc_epic25_pre), 2),
    round(mean(sc_b24_post) - mean(sc_b24_pre), 2),
    round(mean(sc_b25_post) - mean(sc_b25_pre), 2),
    round(mean(sc_epic26_f) - mean(sc_epic26_nf), 2)
  ),
  Gain_Pct = c(
    round((mean(sc_epic25_post) - mean(sc_epic25_pre)) / 20 * 100, 1),
    round((mean(sc_b24_post) - mean(sc_b24_pre)) / 20 * 100, 1),
    round((mean(sc_b25_post) - mean(sc_b25_pre)) / 20 * 100, 1),
    round((mean(sc_epic26_f) - mean(sc_epic26_nf)) / 20 * 100, 1)
  ),
  Test_Inferentiel = c(
    "Wilcoxon W = 2103, p < 0,001",
    "Wilcoxon apparié V = 325, p < 0,001",
    "Wilcoxon apparié V = 252, p < 0,001",
    "GLM ajusté t = -2,02, p = 0,046"
  ),
  Taille_Effet_d = c(1.64, 2.73, 1.40, 0.19),
  Taille_Effet_r = c(0.62, 0.62, 0.61, 0.07),
  GLM_Odds_Ratio_Ajuste = c(3.94, 5.54, 4.37, 1.42),
  GLM_IC_95 = c("[2,74 - 5,66]", "[3,77 - 8,14]", "[2,73 - 6,98]", "[1,01 - 2,01]"),
  IDK_Pre_Pct = c(round(idk_epic25_pre, 1), round(idk_b24_pre, 1), round(idk_b25_pre, 1), NA),
  IDK_Post_Pct = c(round(idk_epic25_post, 1), round(idk_b24_post, 1), round(idk_b25_post, 1), NA),
  IDK_Reduction_Pct = c(
    round((idk_epic25_pre - idk_epic25_post) / idk_epic25_pre * 100, 1),
    round((idk_b24_pre - idk_b24_post) / idk_b24_pre * 100, 1),
    round((idk_b25_pre - idk_b25_post) / idk_b25_pre * 100, 1),
    NA
  ),
  stringsAsFactors = FALSE
)

exporter_excel_csv(df_synth_axe_a, file.path(dossier_output, "tableau_comparatif_global_cohortes.csv"))

# ------------------------------------------------------------------------------
# 3. MODÉLISATION DE L'INTERACTION PUBLIC × FORMATION (GLM QUASIBINOMIAL)
# ------------------------------------------------------------------------------
df_indiv_epic25 <- data.frame(
  ID = d_epic2025$ID_Participant,
  Cohorte = "EPIC 2025",
  Public = "Adultes naturalistes",
  Session = factor(ifelse(d_epic2025$Cohorte == "Pré-test", "Pré-test", "Post-test"), levels = c("Pré-test", "Post-test")),
  Score_20 = d_epic2025$Score_Note_20,
  stringsAsFactors = FALSE
)

df_indiv_b24 <- data.frame(
  ID = d_bac2024_app$ID_Participant,
  Cohorte = "BAC 3 2024",
  Public = "Étudiants université",
  Session = factor(ifelse(d_bac2024_app$Cohorte == "Pré-test", "Pré-test", "Post-test"), levels = c("Pré-test", "Post-test")),
  Score_20 = d_bac2024_app$Score_Moodle_20,
  stringsAsFactors = FALSE
)

df_indiv_b25 <- data.frame(
  ID = d_bac2025_app$ID_Participant,
  Cohorte = "BAC 3 2025",
  Public = "Étudiants université",
  Session = factor(ifelse(d_bac2025_app$Cohorte == "Pré-test", "Pré-test", "Post-test"), levels = c("Pré-test", "Post-test")),
  Score_20 = d_bac2025_app$Score_Moodle_20,
  stringsAsFactors = FALSE
)

df_indiv_all <- rbind(df_indiv_epic25, df_indiv_b24, df_indiv_b25)
df_indiv_all$Public <- factor(df_indiv_all$Public, levels = c("Étudiants université", "Adultes naturalistes"))
df_indiv_all$Prop_Succes <- pmin(pmax(df_indiv_all$Score_20 / 20, 0.001), 0.999)

# Modèle GLM Quasibinomial : Prop_Succes ~ Public * Session
mod_inter_glm <- glm(Prop_Succes ~ Public * Session, data = df_indiv_all, family = quasibinomial(link = "logit"))
sm_glm <- summary(mod_inter_glm)
coef_glm <- sm_glm$coefficients

df_res_inter <- data.frame(
  Parametre = c("Intercept (Étudiants - Pré-test)",
                "Effet Public : Adultes naturalistes",
                "Effet Formation : Post-test",
                "Interaction : Adultes × Post-test"),
  Estimate_Beta = round(coef_glm[, "Estimate"], 4),
  Std_Error = round(coef_glm[, "Std. Error"], 4),
  t_value = round(coef_glm[, "t value"], 3),
  P_Value = coef_glm[, "Pr(>|t|)"],
  Odds_Ratio = round(exp(coef_glm[, "Estimate"]), 3),
  IC_95_Inf = round(exp(coef_glm[, "Estimate"] - 1.96 * coef_glm[, "Std. Error"]), 3),
  IC_95_Sup = round(exp(coef_glm[, "Estimate"] + 1.96 * coef_glm[, "Std. Error"]), 3),
  Significatif_5pct = coef_glm[, "Pr(>|t|)"] < 0.05,
  stringsAsFactors = FALSE
)
rownames(df_res_inter) <- NULL

exporter_excel_csv(df_res_inter, file.path(dossier_output, "tableau_modele_interaction_public_formation.csv"))

# ------------------------------------------------------------------------------
# 4. TABLEAU DE CONSENSUS DES GENRES PIÈGES (AXE B)
# ------------------------------------------------------------------------------
f_g_epic25 <- "2025/EDA EPIC 2025/output/tableau_performances_par_genre.csv"
f_g_bac24  <- "BAC 3/EDA BAC 3 2024/output/tableau_performances_par_genre.csv"
f_g_bac25  <- "BAC 3/EDA BAC 3 2025/output/tableau_performances_par_genre.csv"
f_g_epic26 <- "EPIC 2026/EDA EPIC 2026/output/tableau_difficulte_genres.csv"

g_epic25 <- read.csv(f_g_epic25, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
g_bac24  <- read.csv(f_g_bac24,  sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
g_bac25  <- read.csv(f_g_bac25,  sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
g_epic26 <- read.csv(f_g_epic26, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# Métadonnées morphologiques et systématiques pour les 27 genres évalués en post-test
taxo_meta <- list(
  "Stelis"       = list(Famille = "Megachilidae", Guilde = "Cléptoparasite", Morpho = "Abdomen noir ponctué de taches jaunes, absence de scopa ventrale, confusion avec Osmia / Anthidium"),
  "Trachusa"     = list(Famille = "Megachilidae", Guilde = "Non parasite",    Morpho = "Silhouette d'anthidie sombre à brosse ventrale, confusion fréquente avec Osmia et Eucera"),
  "Anthophora"   = list(Famille = "Apidae",        Guilde = "Non parasite",    Morpho = "Allure trapue, pilosité dense, vol stationnaire, confusion massive avec Bombus et Andrena"),
  "Lasioglossum" = list(Famille = "Halictidae",    Guilde = "Non parasite",    Morpho = "Taille miniature à moyenne, nervation alaire ténue, sillon anal, confusion avec Ceratina et Halictus"),
  "Sphecodes"    = list(Famille = "Halictidae",    Guilde = "Cléptoparasite", Morpho = "Abdomen rouge vif et noir, cuticule glabre et fortement ponctuée, confusion systématique avec Nomada"),
  "Megachile"    = list(Famille = "Megachilidae", Guilde = "Non parasite",    Morpho = "Brosse de récolte ventrale, silhouette trapue, confusions avec Osmia, Bombus et Anthophora"),
  "Chelostoma"   = list(Famille = "Megachilidae", Guilde = "Non parasite",    Morpho = "Corps cylindrique très allongé, petite taille, confusion avec Heriades et petites osmies"),
  "Andrena"      = list(Famille = "Andrenidae",    Guilde = "Non parasite",    Morpho = "Fovéas faciales veloutées, scopas fémorales, grand polymorphisme spécifique"),
  "Osmia"        = list(Famille = "Megachilidae", Guilde = "Non parasite",    Morpho = "Reflets métalliques sombres, brosse ventrale, confusion avec Hoplitis et Megachile"),
  "Ammobates"    = list(Famille = "Apidae",        Guilde = "Cléptoparasite", Morpho = "Abdomen partiellement rouge, habitus allongé de coucou, parasite de Panurgini"),
  "Eucera"       = list(Famille = "Apidae",        Guilde = "Non parasite",    Morpho = "Antennes très longues chez les mâles, confusion avec Dasypoda et Tetralonia"),
  "Hoplitis"     = list(Famille = "Megachilidae", Guilde = "Non parasite",    Morpho = "Morphologie intermédiaire entre Osmia et Megachile, confusion classique avec Osmia"),
  "Melecta"      = list(Famille = "Apidae",        Guilde = "Cléptoparasite", Morpho = "Habitus trapu noir à taches de poils blanc pur en damier, parasite d'Anthophora"),
  "Nomada"       = list(Famille = "Apidae",        Guilde = "Cléptoparasite", Morpho = "Habitus guêpe glabre jaune/rouge, confusion avec Sphecodes et guêpes vespides"),
  "Epeolus"      = list(Famille = "Apidae",        Guilde = "Cléptoparasite", Morpho = "Petite taille, motifs d'écailles pileuses blanches/crème en demi-lunes, parasite de Colletes"),
  "Panurgus"     = list(Famille = "Andrenidae",    Guilde = "Non parasite",    Morpho = "Abeille noire à pilosité dense sur pattes postérieures, confusion avec Halictus"),
  "Anthidium"    = list(Famille = "Megachilidae", Guilde = "Non parasite",    Morpho = "Motifs jaunes vifs en plaques latérales, brosse ventrale, facile après formation"),
  "Colletes"     = list(Famille = "Colletidae",    Guilde = "Non parasite",    Morpho = "Tête triangulaire en cœur, nervure récurrente sinueuse, confusion avec Andrena"),
  "Ceratina"     = list(Famille = "Apidae",        Guilde = "Non parasite",    Morpho = "Corps sombre à reflets bleu-vert métalliques, quasi glabre, taille miniature"),
  "Macropis"     = list(Famille = "Melittidae",    Guilde = "Non parasite",    Morpho = "Pilosité dense jaune/brune sur pattes postérieures, spécialiste des lysimaques"),
  "Coelioxys"    = list(Famille = "Megachilidae", Guilde = "Cléptoparasite", Morpho = "Abdomen conique pointu effilé, taches blanches triangulaires, parasite de Megachile"),
  "Halictus"     = list(Famille = "Halictidae",    Guilde = "Non parasite",    Morpho = "Bandes pileuses apicales continues sur tergites, confusion avec Lasioglossum"),
  "Hylaeus"      = list(Famille = "Colletidae",    Guilde = "Non parasite",    Morpho = "Masque facial blanc/jaune caractéristique, corps noir glabre, facilement identifié formé"),
  "Bombus"       = list(Famille = "Apidae",        Guilde = "Non parasite",    Morpho = "Silhouette très volumineuse, corbeille tibiale (corbicula), bourdon universellement reconnu"),
  "Apis"         = list(Famille = "Apidae",        Guilde = "Non parasite",    Morpho = "Abeille mellifère domestique, yeux velus, cellule marginale allongée, reconnaissance immédiate"),
  "Dasypoda"     = list(Famille = "Melittidae",    Guilde = "Non parasite",    Morpho = "Énormes brosses tibiales postérieures jaunes en panache, silhouette très reconnaissable"),
  "Xylocopa"     = list(Famille = "Apidae",        Guilde = "Non parasite",    Morpho = "Grande taille imposante, ailes violacées irisées, corps noir massif, 100% de réussite post")
)

df_consensus <- data.frame(Genre = names(taxo_meta), stringsAsFactors = FALSE)
df_consensus$Famille <- sapply(df_consensus$Genre, function(g) taxo_meta[[g]]$Famille)
df_consensus$Guilde  <- sapply(df_consensus$Genre, function(g) taxo_meta[[g]]$Guilde)

# Extraction des effectifs de réussite et présentations post-test
k_epic25 <- g_epic25$Succes_Post[match(df_consensus$Genre, g_epic25$Genre)]
n_epic25 <- g_epic25$N_Post[match(df_consensus$Genre, g_epic25$Genre)]

k_bac24 <- g_bac24$Succes_Post[match(df_consensus$Genre, g_bac24$Genre)]
n_bac24 <- g_bac24$N_Post[match(df_consensus$Genre, g_bac24$Genre)]

k_bac25 <- g_bac25$Succes_Post[match(df_consensus$Genre, g_bac25$Genre)]
n_bac25 <- g_bac25$N_Post[match(df_consensus$Genre, g_bac25$Genre)]

df_consensus$N_Total_Post      <- rowSums(cbind(n_epic25, n_bac24, n_bac25), na.rm = TRUE)
df_consensus$Succes_Total_Post <- rowSums(cbind(k_epic25, k_bac24, k_bac25), na.rm = TRUE)

df_consensus$Taux_Succes_Post <- round(df_consensus$Succes_Total_Post / df_consensus$N_Total_Post * 100, 1)
df_consensus$Taux_Erreur_Post <- round(100 - df_consensus$Taux_Succes_Post, 1)

# Calcul des Intervalles de Confiance de Wilson à 95% pour le succès
cis_wilson <- t(mapply(function(k, n) {
  if (n == 0) return(c(0, 0))
  wilson_ci(k, n, conf = 0.95) * 100
}, df_consensus$Succes_Total_Post, df_consensus$N_Total_Post))

df_consensus$IC_Wilson_Inf_Post <- round(cis_wilson[, 1], 1)
df_consensus$IC_Wilson_Sup_Post <- round(cis_wilson[, 2], 1)

# Calcul des Intervalles de Confiance de Wilson à 95% pour l'erreur
cis_wilson_err <- t(mapply(function(k, n) {
  if (n == 0) return(c(0, 0))
  wilson_ci(k, n, conf = 0.95) * 100
}, df_consensus$N_Total_Post - df_consensus$Succes_Total_Post, df_consensus$N_Total_Post))

df_consensus$IC_Wilson_Err_Inf_Post <- round(cis_wilson_err[, 1], 1)
df_consensus$IC_Wilson_Err_Sup_Post <- round(cis_wilson_err[, 2], 1)

# Catégorisation standardisée de la difficulté selon le taux d'erreur :
# - "Très difficile"     : >= 35% d'erreur
# - "Difficulté modérée" : entre 20% et 34% d'erreur
# - "Accessible"         : entre 10% et 19% d'erreur
# - "Facile"             : < 10% d'erreur
df_consensus$Categorie_Difficulte <- ifelse(df_consensus$Taux_Erreur_Post >= 35,
                                           "Très difficile (>= 35% d'erreur)",
                                    ifelse(df_consensus$Taux_Erreur_Post >= 20,
                                           "Difficulté modérée (20 - 34% d'erreur)",
                                    ifelse(df_consensus$Taux_Erreur_Post >= 10,
                                           "Accessible (10 - 19% d'erreur)",
                                           "Facile (< 10% d'erreur)")))

# Taux détaillés par cohorte
df_consensus$Succes_EPIC_2025_Post <- g_epic25$Taux_Succes_Post[match(df_consensus$Genre, g_epic25$Genre)]
df_consensus$Succes_BAC3_2024_Post <- g_bac24$Taux_Post[match(df_consensus$Genre, g_bac24$Genre)]
df_consensus$Succes_BAC3_2025_Post <- g_bac25$Taux_Post[match(df_consensus$Genre, g_bac25$Genre)]
df_consensus$Succes_EPIC_2026_Total <- g_epic26$Taux_Succes[match(df_consensus$Genre, g_epic26$Genre)]

df_consensus$Criteres_Morphologiques <- sapply(df_consensus$Genre, function(g) taxo_meta[[g]]$Morpho)

# Tri par taux d'erreur décroissant (les genres les plus difficiles en premier)
df_consensus <- df_consensus[order(-df_consensus$Taux_Erreur_Post), ]
rownames(df_consensus) <- NULL

exporter_excel_csv(df_consensus, file.path(dossier_output, "tableau_consensus_pieges_taxonomiques.csv"))

# ------------------------------------------------------------------------------
# 5. FIGURES HAUTE DÉFINITION (AGENTS.MD CONFORMES, 300 DPI)
# ------------------------------------------------------------------------------

# Couleurs éditoriales
c_vert   <- "#2E7D32"  # Succès / Post / Facile
c_rouge  <- "#C62828"  # Erreur / Pré / Piège
c_bleu   <- "#4A90E2"  # Neutre / Comparaison
c_nuit   <- "#1B365D"  # Accentuation / Structure
c_ambre  <- "#E67E22"  # Difficulté intermédiaire
c_violet <- "#8E44AD"  # Confusions taxonomiques

# ------------------------------------------------------------------------------
# FIGURE 1 : Comparaison des Trajectoires d'Apprentissage (Pré vs Post par Cohorte)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure1_comparaison_trajectoires_pre_post.png"),
    width = 3300, height = 2300, res = 300, bg = "white")

par(mar = c(5, 5, 4, 3), las = 1, family = "sans", bg = "white")

cohortes_noms <- c("EPIC 2025\n(Adultes)", "BAC 3 - 2024\n(Étudiants)", "BAC 3 - 2025\n(Étudiants)", "EPIC Basic 2026\n(Adultes)")
x_coords <- c(1, 2.5, 4, 5.5)

# Moyennes et écarts-types
moy_pre  <- c(mean(sc_epic25_pre), mean(sc_b24_pre), mean(sc_b25_pre), mean(sc_epic26_nf))
et_pre   <- c(sd(sc_epic25_pre), sd(sc_b24_pre), sd(sc_b25_pre), sd(sc_epic26_nf))
n_pre    <- c(length(sc_epic25_pre), length(sc_b24_pre), length(sc_b25_pre), length(sc_epic26_nf))
ic_pre   <- 1.96 * et_pre / sqrt(n_pre)

moy_post <- c(mean(sc_epic25_post), mean(sc_b24_post), mean(sc_b25_post), mean(sc_epic26_f))
et_post  <- c(sd(sc_epic25_post), sd(sc_b24_post), sd(sc_b25_post), sd(sc_epic26_f))
n_post   <- c(length(sc_epic25_post), length(sc_b24_post), length(sc_b25_post), length(sc_epic26_f))
ic_post  <- 1.96 * et_post / sqrt(n_post)

# Tracé vierge
plot(NULL, xlim = c(0.4, 6.3), ylim = c(0, 22),
     xlab = "", ylab = "Score moyen sur 20 points (± IC 95 %)",
     xaxt = "n", yaxt = "n",
     main = "Comparaison Inter-Cohortes : Efficacité et Progression des Apprentissages",
     col.main = c_nuit, cex.main = 1.3, font.main = 2)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
axis(1, at = x_coords, labels = cohortes_noms, cex.axis = 0.95, font = 2, col.axis = c_nuit)
axis(2, at = seq(0, 20, 2), labels = seq(0, 20, 2), cex.axis = 0.95)

# Seuil académique
abline(h = 10, col = "grey70", lty = 2, lwd = 1.5)
text(6.1, 10.3, "Seuil de réussite (10/20)", cex = 0.75, col = "grey50", adj = 1)

# Tracé des barres d'évolution
offset_x <- 0.22
for (i in 1:4) {
  x_p <- x_coords[i] - offset_x
  x_f <- x_coords[i] + offset_x
  
  # Flèche de gain
  arrows(x_p, moy_pre[i], x_f, moy_post[i], col = c_bleu, length = 0.12, lwd = 3)
  
  # Barre d'erreur Pré
  arrows(x_p, moy_pre[i] - ic_pre[i], x_p, moy_pre[i] + ic_pre[i],
         angle = 90, code = 3, length = 0.05, col = c_rouge, lwd = 2)
  # Point Pré
  points(x_p, moy_pre[i], pch = 21, bg = c_rouge, col = "black", cex = 1.8)
  
  # Barre d'erreur Post
  arrows(x_f, moy_post[i] - ic_post[i], x_f, moy_post[i] + ic_post[i],
         angle = 90, code = 3, length = 0.05, col = c_vert, lwd = 2)
  # Point Post
  points(x_f, moy_post[i], pch = 21, bg = c_vert, col = "black", cex = 1.8)
  
  # Annotations numériques décalées
  text(x_p - 0.08, moy_pre[i], sprintf("%.1f", moy_pre[i]), col = c_rouge, font = 2, cex = 0.85, adj = 1)
  text(x_f + 0.08, moy_post[i], sprintf("%.1f", moy_post[i]), col = c_vert, font = 2, cex = 0.85, adj = 0)
  
  # Gain absolu inscrit au centre
  gain_val <- moy_post[i] - moy_pre[i]
  text(x_coords[i], max(moy_pre[i], moy_post[i]) + 1.8,
       sprintf("+%.1f pts\n(+%.1f %%)", gain_val, (gain_val / 20) * 100),
       col = c_nuit, font = 2, cex = 0.82)
}

# Légende
legend("topleft",
       legend = c("Niveau initial (Pré-test / Non formés)",
                  "Niveau final (Post-test / Formés)",
                  "Gain d'apprentissage moyen"),
       pch = c(21, 21, NA), lty = c(NA, NA, 1), lwd = c(NA, NA, 3),
       pt.bg = c(c_rouge, c_vert, NA), col = c("black", "black", c_bleu),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.85, inset = 0.02)

dev.off()
cat("  -> Figure 1 générée avec succès (300 DPI)\n")

# ------------------------------------------------------------------------------
# FIGURE 2 : Forest Plot des Tailles d'Effet et Odds Ratios (Axe A)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure2_forest_plot_tailles_effet_cohortes.png"),
    width = 4400, height = 2300, res = 300, bg = "white")

layout(matrix(c(1, 2), nrow = 1), widths = c(1.30, 1.0))

# Panel A : Cohen's d
# Marge gauche portée à 15 pour garantir zéro troncature des intitulés de cohortes, marge droite réduite à 1.2 pour rapprocher les deux panneaux
par(mar = c(5, 15, 4, 1.2), las = 1, family = "sans", bg = "white")
y_pos <- c(4, 3, 2, 1)
d_vals <- c(1.64, 2.73, 1.40, 0.19)
d_labels <- c("EPIC 2025 (Adultes)", "BAC 3 - 2024 (Étudiants)", "BAC 3 - 2025 (Étudiants)", "EPIC Basic 2026 (Adultes)")

d_se <- c(sqrt(1/50 + 1/49 + (1.64^2)/(2*99)),
          sqrt(1/25 + (2.73^2)/(2*25)),
          sqrt(1/22 + (1.40^2)/(2*22)),
          sqrt(1/64 + 1/108 + (0.19^2)/(2*172)))
d_inf <- d_vals - 1.96 * d_se
d_sup <- d_vals + 1.96 * d_se

plot(NULL, xlim = c(-0.2, 5.2), ylim = c(0.5, 4.5),
     xlab = "d de Cohen (Taille d'effet standardisée)", ylab = "",
     yaxt = "n", xaxt = "n", main = "A. Magnitude des Gains (d de Cohen)",
     col.main = c_nuit, cex.main = 1.15, font.main = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
axis(1, at = seq(0, 5, by = 1), cex.axis = 0.95)
abline(v = 0.8, col = c_ambre, lty = 2, lwd = 1.5)
text(0.85, 0.7, "Seuil d'effet fort (d = 0.80)", col = c_ambre, cex = 0.75, adj = 0)
axis(2, at = y_pos, labels = d_labels, cex.axis = 0.95, font = 2)

for (i in 1:4) {
  arrows(d_inf[i], y_pos[i], d_sup[i], y_pos[i], angle = 90, code = 3, length = 0.06, col = c_nuit, lwd = 2)
  points(d_vals[i], y_pos[i], pch = 22, bg = c_vert, col = "black", cex = 2.0)
  text(d_sup[i] + 0.12, y_pos[i], sprintf("%.2f [%.2f - %.2f]", d_vals[i], d_inf[i], d_sup[i]),
       font = 2, cex = 0.82, adj = 0)
}

# Panel B : Odds Ratios GLM ajustés
# Marge gauche très réduite à 1.2 pour resserrer l'espace avec le Panel A, marge droite à 5.5 pour les étiquettes
par(mar = c(5, 1.2, 4, 5.5), las = 1, family = "sans", bg = "white")
or_vals <- c(3.94, 5.54, 4.37, 1.42)
or_inf  <- c(2.74, 3.77, 2.73, 1.01)
or_sup  <- c(5.66, 8.14, 6.98, 2.01)

plot(NULL, xlim = c(0.5, 13.5), ylim = c(0.5, 4.5),
     xlab = "Odds Ratio ajusté [IC 95 %] (Modèle GLM Logit)", ylab = "",
     yaxt = "n", xaxt = "n", main = "B. Facteur Multiplicatif de Réussite (OR)",
     col.main = c_nuit, cex.main = 1.15, font.main = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
axis(1, at = seq(1, 13, by = 2), cex.axis = 0.95)
abline(v = 1.0, col = c_rouge, lty = 2, lwd = 1.5)
text(1.1, 0.7, "Absence d'effet (OR = 1)", col = c_rouge, cex = 0.75, adj = 0)

for (i in 1:4) {
  arrows(or_inf[i], y_pos[i], or_sup[i], y_pos[i], angle = 90, code = 3, length = 0.06, col = c_nuit, lwd = 2)
  points(or_vals[i], y_pos[i], pch = 21, bg = c_bleu, col = "black", cex = 2.0)
  text(or_sup[i] + 0.25, y_pos[i], sprintf("OR = %.2f [%.2f - %.2f]", or_vals[i], or_inf[i], or_sup[i]),
       font = 2, cex = 0.82, adj = 0)
}

dev.off()
cat("  -> Figure 2 générée avec succès (300 DPI)\n")

# ------------------------------------------------------------------------------
# FIGURE 3 : Consensus Taxonomique Inter-Cohortes (Axe B : Gradient de Difficulté)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure3_consensus_difficulte_genres_intercohortes.png"),
    width = 3900, height = 3300, res = 300, bg = "white")

df_plot_taxo <- df_consensus[!is.na(df_consensus$Taux_Erreur_Post), ]
# Tri par taux d'erreur croissant (les genres les plus faciles en bas, les plus difficiles en haut)
df_plot_taxo <- df_plot_taxo[order(df_plot_taxo$Taux_Erreur_Post), ]
n_genres <- nrow(df_plot_taxo)

par(mar = c(5, 13.5, 4, 3), las = 1, family = "sans", bg = "white")

y_bars <- seq(1, n_genres * 1.5, by = 1.5)
erreur_vals <- df_plot_taxo$Taux_Erreur_Post
ic_err_inf  <- df_plot_taxo$IC_Wilson_Err_Inf_Post
ic_err_sup  <- df_plot_taxo$IC_Wilson_Err_Sup_Post

# Attribution des couleurs selon les 4 catégories d'erreur demandées :
# - "Très difficile"     (>= 35% d'erreur) : Rouge rubis (#C62828)
# - "Difficulté modérée" (20 à 34% d'erreur) : Ambre (#E67E22)
# - "Accessible"         (10 à 19% d'erreur) : Bleu ardoise (#4A90E2)
# - "Facile"             (< 10% d'erreur) : Vert émeraude (#2E7D32)
bar_cols <- ifelse(erreur_vals >= 35, c_rouge,
            ifelse(erreur_vals >= 20, c_ambre,
            ifelse(erreur_vals >= 10, c_bleu, c_vert)))

plot(NULL, xlim = c(0, 88), ylim = c(0.5, max(y_bars) + 1.2),
     xlab = "Taux d'erreur post-formation (%) avec IC 95 % de Wilson", ylab = "",
     yaxt = "n", xaxt = "n",
     main = "Consensus Inter-Cohortes : Gradient de Difficulté Taxonomique des Genres d'Abeilles",
     col.main = c_nuit, cex.main = 1.25, font.main = 2)

# Grille de repères douce (pas de pointillés délimitant les groupes)
grid(nx = NULL, ny = NA, col = "grey92", lty = 1)
axis(1, at = seq(0, 80, by = 10), labels = paste0(seq(0, 80, by = 10), " %"), cex.axis = 0.9)

for (i in 1:n_genres) {
  # Barre horizontale de taux d'erreur
  rect(0, y_bars[i] - 0.45, erreur_vals[i], y_bars[i] + 0.45, col = bar_cols[i], border = "grey25", lwd = 1.1)
  
  # Barre d'erreur : Intervalle de confiance de Wilson (95%)
  arrows(ic_err_inf[i], y_bars[i], ic_err_sup[i], y_bars[i],
         angle = 90, code = 3, length = 0.04, col = "#1B365D", lwd = 1.4)
  
  # Point sur la valeur moyenne d'erreur
  points(erreur_vals[i], y_bars[i], pch = 21, bg = bar_cols[i], col = "black", cex = 1.05)
  
  # Nom du genre en italique (sans mention de guilde)
  genre_nom <- df_plot_taxo$Genre[i]
  mtext(bquote(italic(.(genre_nom))), side = 2, at = y_bars[i], line = 0.5, cex = 0.9, font = 3)
  
  # Annotation numérique directe décalée à droite de la barre d'erreur : UNIQUEMENT LE POURCENTAGE DE LA BARRE
  annot_txt <- sprintf("%.1f %%", erreur_vals[i])
  text(max(ic_err_sup[i], erreur_vals[i]) + 1.2, y_bars[i], annot_txt, font = 2, cex = 0.82, adj = 0, col = "#1B365D")
}

# Légende professionnelle avec les 4 catégories exactes
legend("bottomright",
       legend = c("Très difficile (≥ 35 % d'erreur)",
                  "Difficulté modérée (20 - 34 % d'erreur)",
                  "Accessible (10 - 19 % d'erreur)",
                  "Facile (< 10 % d'erreur)",
                  "Barres d'erreur : IC 95 % de Wilson"),
       fill = c(c_rouge, c_ambre, c_bleu, c_vert, NA),
       lty = c(NA, NA, NA, NA, 1), lwd = c(NA, NA, NA, NA, 1.4),
       col = c(NA, NA, NA, NA, "#1B365D"),
       border = c("grey25", "grey25", "grey25", "grey25", NA),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.85, inset = 0.02)

dev.off()
cat("  -> Figure 3 générée avec succès (300 DPI)\n\n")

cat("======================================================================\n")
cat("=== LIVRABLES DE SYNTHÈSE GÉNÉRÉS AVEC SUCCÈS DANS OUTPUT/ ===\n")
cat("======================================================================\n")
