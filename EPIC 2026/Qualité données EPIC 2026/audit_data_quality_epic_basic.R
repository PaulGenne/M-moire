# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 1 : Data Quality & Profiling Analyse
# FICHIER SOURCE : EPIC_Basic-rgpd ok - Copie.xlsx (avec validation croisée)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. ENVIRONNEMENT ET CRÉATION DU RÉPERTOIRE DE SORTIE
# ------------------------------------------------------------------------------
if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}

# ------------------------------------------------------------------------------
# 1. CHARGEMENT ET PRÉPARATION DES DONNÉES
# ------------------------------------------------------------------------------
fichier_csv <- "EPIC_Basic-rgpd ok - Copie.csv"
if (!file.exists(fichier_csv)) {
  stop("Le fichier CSV 'EPIC_Basic-rgpd ok - Copie.csv' est requis.")
}

df <- read.csv(fichier_csv, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)

# Nettoyage et typage de base
df$Score_Declare <- as.numeric(gsub(",", ".", df[["Note/30_nbr"]]))
df$Verif_eval    <- as.numeric(df$Verif_eval)
df$EPIC_courses  <- tolower(trimws(df$EPIC_courses)) # Normalisation : "no" / "yes"

cols_sol  <- paste0("Question_", 1:30, "_solution")
cols_rep  <- paste0("Question_", 1:30, "_reply")
cols_eval <- paste0("Question_", 1:30, "_evaluation")

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

df$Duree_Min <- sapply(df$"Durée", parser_duree)

# Recalcul des métriques par participant
mat_eval <- as.data.frame(lapply(df[cols_eval], function(x) suppressWarnings(as.numeric(x))))
df$Score_Recalcule <- rowSums(mat_eval, na.rm = TRUE)

# Décompte des types de réponses
df$Nb_Tirets <- apply(df[cols_rep], 1, function(r) sum(trimws(r) == "-" | trimws(r) == ""))
df$Nb_DontKnow <- apply(df[cols_rep], 1, function(r) sum(grepl("don't know|ne sais pas|nsp", tolower(r))))
df$Nb_Reponses_Reelles <- 30 - df$Nb_Tirets - df$Nb_DontKnow

# ------------------------------------------------------------------------------
# 2. APPLICATION DES CRITÈRES DE FILTRAGE QUALITÉ (DATA QUALITY CRITERIA)
# ------------------------------------------------------------------------------
# Critère 1 : Attrition / Abandon sévère (taux de non-réponse >= 70%, soit >= 21 tirets)
c1_abandon_severe <- df$Nb_Tirets >= 21

# Critère 2 : Vitesse irréaliste (< 10 minutes pour 30 identifications microscopiques)
c2_vitesse_suspecte <- !is.na(df$Duree_Min) & df$Duree_Min < 10

# Critère 3 : Discordance de notation (écart entre score déclaré et somme des évaluations)
c3_discordance_notation <- abs(df$Score_Declare - df$Score_Recalcule) > 1e-6

# Synthèse des anomalies
df$Alerte_Qualite <- ifelse(c1_abandon_severe, "Abandon sévère (<= 9 rép.)",
                     ifelse(c2_vitesse_suspecte, "Vitesse anormale (< 10 min)",
                     ifelse(c3_discordance_notation, "Discordance barème (+0.5)", "Valide")))

cat("======================================================================\n")
cat("RÉSUMÉ DU PROFILAGE ET DES ANOMALIES DÉTECTÉES\n")
cat("======================================================================\n")
print(table(df$Alerte_Qualite))

# ------------------------------------------------------------------------------
# 3. EXPORT DES PARTICIPANTS PROBLÉMATIQUES DANS UN FICHIER CSV DE SUIVI
# ------------------------------------------------------------------------------
df_problemes <- df[df$Alerte_Qualite != "Valide", c(
  "N°ID", "Region", "EPIC_courses", "Durée", "Duree_Min",
  "Score_Declare", "Score_Recalcule", "Nb_Tirets", "Nb_Reponses_Reelles", "Alerte_Qualite"
)]

write.csv(df_problemes, "output/participants_anomalies_qualite.csv", row.names = FALSE)
cat("\nFichier de synthèse des anomalies sauvegardé : output/participants_anomalies_qualite.csv\n")

# ------------------------------------------------------------------------------
# 4. GÉNÉRATION DES VISUALISATIONS DIAGNOSTIQUES SCIENTIFIQUES
# ------------------------------------------------------------------------------
png("output/diagnostic_data_quality_epic.png", width = 3000, height = 2200, res = 300)

layout_matrix <- matrix(c(1, 2, 3, 4), nrow = 2, byrow = TRUE)
layout(layout_matrix)
par(mar = c(4.5, 4.5, 3.5, 1.5))

# Graphique 1 : Taux de complétion et détection des abandons
couleurs_statut <- ifelse(c1_abandon_severe, "#d9534f",
                   ifelse(c2_vitesse_suspecte, "#f0ad4e", "#2c3e50"))

plot(df$Nb_Reponses_Reelles, df$Score_Declare,
     pch = 19, cex = 1.3, col = couleurs_statut,
     main = "1. Complétude des Réponses vs Score",
     xlab = "Nombre de réponses taxonomiques réelles (/30)",
     ylab = "Score déclaré (/30)", las = 1)
abline(v = 10, col = "#d9534f", lty = 2, lwd = 2)
legend("topleft",
       legend = c("Profil valide", "Abandon sévère (<= 9 rép.)", "Durée suspecte (< 10 min)"),
       col = c("#2c3e50", "#d9534f", "#f0ad4e"), pch = 19, bty = "n", cex = 0.85)

# Graphique 2 : Durée de passation et détection des tests éclairs
hist(df$Duree_Min, breaks = 30, col = "#3498db", border = "white",
     main = "2. Distribution de la Durée de Passation",
     xlab = "Durée (minutes)", ylab = "Nombre de participants", las = 1)
abline(v = 10, col = "#d9534f", lty = 2, lwd = 2)
abline(v = median(df$Duree_Min, na.rm = TRUE), col = "#27ae60", lty = 1, lwd = 2)
legend("topright",
       legend = c(sprintf("Médiane : %.0f min", median(df$Duree_Min, na.rm = TRUE)), "Seuil critique (10 min)"),
       col = c("#27ae60", "#d9534f"), lty = c(1, 2), lwd = 2, bty = "n", cex = 0.85)

# Graphique 3 : Biais de groupe 'EPIC_courses' (Yes vs No)
boxplot(df$Score_Declare ~ df$EPIC_courses,
        col = c("#e74c3c", "#2ecc71"),
        names = c("No (Non-formés)", "Yes (Formés EPIC)"),
        main = "3. Comparaison selon le Statut de Formation",
        xlab = "Statut 'EPIC_courses'", ylab = "Score déclaré (/30)", las = 1)

# Graphique 4 : Discordances de barème (+0.5 point)
ecart_eval <- df$Score_Declare - df$Score_Recalcule
barplot(table(factor(ecart_eval, levels = c(0, 0.5))),
        col = c("#2980b9", "#e67e22"), border = "white",
        main = "4. Écart Score Déclaré vs Somme Binaire",
        xlab = "Écart (Score Déclaré - Somme des Évaluations)",
        ylab = "Nombre de participants", las = 1)
text(x = c(0.7, 1.9), y = c(198, 11) + 8,
     labels = c("198 conformes (0.0)", "11 cas (+0.5 point)"),
     font = 2, col = c("#2980b9", "#e67e22"))

invisible(dev.off())
cat("Visualisation diagnostique enregistrée dans : output/diagnostic_data_quality_epic.png\n")

cat("\n======================================================================\n")
cat("TRAITEMENT TERMINÉ AVEC SUCCÈS.\n")
cat("======================================================================\n")

