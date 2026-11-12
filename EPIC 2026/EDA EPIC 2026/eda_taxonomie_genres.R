# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# PHASE 2 : EDA (Exploratory Data Analysis)
# SCRIPT 3 : Analyse Taxonomique par Genre d'Abeille et Matrice de Confusion
# AUTEUR : Paul Genné & Assistant IA
# ==============================================================================

# 0. CONFIGURATION ET ENVIRONNEMENT --------------------------------------------
dossier_eda <- "EDA EPIC 2026"
dossier_output <- file.path(dossier_eda, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

fichier_long <- file.path(dossier_eda, "EPIC_Basic_clean_long.csv")
if (!file.exists(fichier_long)) {
  stop("Le fichier de données propres au format long n'existe pas.")
}

df_long <- read.csv(fichier_long, encoding = "UTF-8", stringsAsFactors = FALSE)
cat(sprintf("Chargement des évaluations : %d observations par question x participant\n\n", nrow(df_long)))

# Normalisation du nom de genre en Title Case (ex. "Andrena", "Lasioglossum")
df_long$Genre_Solution <- tools::toTitleCase(tolower(trimws(df_long$Genre_Solution)))

# ------------------------------------------------------------------------------
# 1. CALCUL DES MÉTRIQUES DE PERFORMANCE PAR GENRE D'ABEILLE
# ------------------------------------------------------------------------------
# Seuil minimum d'occurrences pour une interprétation statistique solide
seuil_n_min <- 10

stats_genres <- aggregate(
  Est_Correct ~ Genre_Solution,
  data = df_long,
  FUN = function(x) {
    n <- length(x)
    reussites <- sum(x == 1, na.rm = TRUE)
    taux_succes <- (reussites / n) * 100
    taux_erreur <- 100 - taux_succes
    
    # Intervalle de confiance Wilson 95% pour proportion binomiale
    p <- reussites / n
    z <- 1.96
    denom <- 1 + (z^2 / n)
    centre <- (p + (z^2 / (2 * n))) / denom
    marge <- (z * sqrt((p * (1 - p) / n) + (z^2 / (4 * n^2)))) / denom
    ic_inf <- max(0, centre - marge) * 100
    ic_sup <- min(1, centre + marge) * 100
    
    c(n = n, reussites = reussites, taux_succes = taux_succes,
      taux_erreur = taux_erreur, ic_inf = ic_inf, ic_sup = ic_sup)
  }
)

# Aplatissement du data.frame
stats_genres_df <- data.frame(
  Genre = stats_genres$Genre_Solution,
  N = stats_genres$Est_Correct[, "n"],
  Nb_Succes = stats_genres$Est_Correct[, "reussites"],
  Taux_Succes = round(stats_genres$Est_Correct[, "taux_succes"], 2),
  Taux_Erreur = round(stats_genres$Est_Correct[, "taux_erreur"], 2),
  IC_Inf = round(stats_genres$Est_Correct[, "ic_inf"], 2),
  IC_Sup = round(stats_genres$Est_Correct[, "ic_sup"], 2),
  stringsAsFactors = FALSE
)

# Fonction d'exportation compatible Excel Francophone (FR/BE : séparateur ';' et décimale ',')
exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
}

# Export du tableau complet de difficulté
stats_genres_df <- stats_genres_df[order(stats_genres_df$Taux_Erreur, decreasing = TRUE), ]
fichier_tab_diff <- file.path(dossier_output, "tableau_difficulte_genres.csv")
exporter_excel_csv(stats_genres_df, fichier_tab_diff)
cat(sprintf("Tableau de difficulté par genre sauvegardé : %s\n\n", fichier_tab_diff))

cat("Aperçu des 10 genres les plus difficiles (taux d'erreur le plus élevé) :\n")
print(head(stats_genres_df[, c("Genre", "N", "Taux_Erreur", "Taux_Succes")], 10))

# ------------------------------------------------------------------------------
# 2. FIGURE 5 : CLASSEMENT COMPLET DE LA DIFFICULTÉ DES GENRES (TAUX D'ERREUR)
# ------------------------------------------------------------------------------
chemin_fig5 <- file.path(dossier_output, "fig5_classement_difficulte_genres.png")
png(chemin_fig5, width = 3200, height = 3800, res = 300)

par(mar = c(5, 8.5, 4, 3), bg = "white")

# Ordonner par taux d'erreur croissant (pour que le plus difficile soit en haut)
df_plot <- stats_genres_df[order(stats_genres_df$Taux_Erreur, decreasing = FALSE), ]

# Couleurs par paliers de difficulté
couleurs_barres <- ifelse(df_plot$Taux_Erreur >= 35, "#C62828",   # Rouge (très difficile)
                   ifelse(df_plot$Taux_Erreur >= 20, "#E67E22",   # Orange (difficulté modérée)
                   ifelse(df_plot$Taux_Erreur >= 10, "#3498DB",   # Bleu (accessible)
                          "#2E7D32")))                            # Vert (très facile)

bp <- barplot(df_plot$Taux_Erreur, horiz = TRUE, names.arg = df_plot$Genre,
              col = couleurs_barres, border = "white",
              xlab = "Taux d'erreur taxonomique (%)",
              main = "Classement de la Difficulté d'Identification des Genres d'Abeilles (N = 172)",
              xlim = c(0, 92), las = 1, cex.names = 0.85, font.axis = 2,
              cex.main = 1.3, font.lab = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(df_plot$Taux_Erreur, horiz = TRUE, col = couleurs_barres, border = "white", add = TRUE, las = 1)

# Lignes d'intervalles de confiance Wilson à 95%
ic_borne_haute <- 100 - df_plot$IC_Inf
ic_borne_basse <- 100 - df_plot$IC_Sup
segments(ic_borne_basse, bp, ic_borne_haute, bp, lwd = 1.8, col = "grey25")
points(df_plot$Taux_Erreur, bp, pch = 18, col = "white", cex = 0.8)

# Annotations texte pourcentage et n : positionnées à droite de la barre de Wilson pour éviter tout chevauchement
pos_texte_x <- pmax(df_plot$Taux_Erreur, ic_borne_haute) + 1.8
text(pos_texte_x, bp,
     sprintf("%.1f%% (n=%d)", df_plot$Taux_Erreur, df_plot$N),
     cex = 0.72, font = 2, col = "grey20", adj = 0)

legend("bottomright",
       legend = c("Critique / Très difficile (≥ 35%)", "Difficulté modérée (20 - 34%)",
                  "Accessible (10 - 19%)", "Facile (< 10%)", "IC 95% Wilson"),
       fill = c("#C62828", "#E67E22", "#3498DB", "#2E7D32", NA),
       border = c("white", "white", "white", "white", NA),
       lty = c(NA, NA, NA, NA, 1), col = c(NA, NA, NA, NA, "grey25"), lwd = c(NA, NA, NA, NA, 2),
       bty = "o", box.col = "#D0D7DE", bg = "#FFFFFFEE", cex = 0.9, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 5 sauvegardée : %s\n", chemin_fig5))

# ------------------------------------------------------------------------------
# 3. FIGURE 6 : TOP 5 GENRES LES PLUS DIFFICILES vs TOP 5 LES PLUS FACILES
# ------------------------------------------------------------------------------
chemin_fig6 <- file.path(dossier_output, "fig6_top5_pieges_vs_faciles.png")
png(chemin_fig6, width = 3000, height = 2000, res = 300)

par(mfrow = c(1, 2), mar = c(4.8, 7.5, 4, 2), bg = "white")

# Top 5 Difficiles (filtre n >= 10)
top5_diff <- head(stats_genres_df[stats_genres_df$N >= seuil_n_min, ], 5)
top5_diff <- top5_diff[order(top5_diff$Taux_Erreur, decreasing = FALSE), ]

bp_diff <- barplot(top5_diff$Taux_Erreur, horiz = TRUE, names.arg = top5_diff$Genre,
                   col = "#C62828", border = "white",
                   xlab = "Taux d'erreur (%)", xlim = c(0, 65), las = 1,
                   main = "Top 5 des Genres Pièges\n(Taux d'erreur le plus élevé)",
                   cex.names = 1, font.lab = 2, cex.main = 1.1)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(top5_diff$Taux_Erreur, horiz = TRUE, col = "#C62828", border = "white", add = TRUE, las = 1)
text(top5_diff$Taux_Erreur - 3, bp_diff,
     sprintf("%.1f%%", top5_diff$Taux_Erreur),
     col = "white", font = 2, cex = 0.95, adj = 1)
text(top5_diff$Taux_Erreur + 2, bp_diff, sprintf("(n=%d)", top5_diff$N), col = "grey30", cex = 0.85, adj = 0)

# Top 5 Faciles
top5_facile <- tail(stats_genres_df[stats_genres_df$N >= seuil_n_min, ], 5)
top5_facile <- top5_facile[order(top5_facile$Taux_Succes, decreasing = FALSE), ]

bp_fac <- barplot(top5_facile$Taux_Succes, horiz = TRUE, names.arg = top5_facile$Genre,
                  col = "#2E7D32", border = "white",
                  xlab = "Taux de réussite (%)", xlim = c(0, 110), las = 1,
                  main = "Top 5 des Genres les Mieux Reconnus\n(Taux de réussite le plus élevé)",
                  cex.names = 1, font.lab = 2, cex.main = 1.1)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(top5_facile$Taux_Succes, horiz = TRUE, col = "#2E7D32", border = "white", add = TRUE, las = 1)
text(top5_facile$Taux_Succes - 4, bp_fac,
     sprintf("%.1f%%", top5_facile$Taux_Succes),
     col = "white", font = 2, cex = 0.95, adj = 1)
text(top5_facile$Taux_Succes + 2, bp_fac, sprintf("(n=%d)", top5_facile$N), col = "grey30", cex = 0.85, adj = 0)

invisible(dev.off())
cat(sprintf("Figure 6 sauvegardée : %s\n", chemin_fig6))

# ------------------------------------------------------------------------------
# 4. FIGURE 7 : GAIN DE PERFORMANCE DE LA FORMATION PAR GENRE D'ABEILLE
# ------------------------------------------------------------------------------
# Calcul du taux de réussite par genre chez Formés vs Non formés
stats_formation <- aggregate(
  Est_Correct ~ Genre_Solution + Formation,
  data = df_long,
  FUN = function(x) c(n = length(x), pct = mean(x) * 100)
)

stats_form_df <- data.frame(
  Genre = stats_formation$Genre_Solution,
  Formation = stats_formation$Formation,
  N = stats_formation$Est_Correct[, "n"],
  Pct_Succes = stats_formation$Est_Correct[, "pct"],
  stringsAsFactors = FALSE
)

# Reshape en format large pour calculer la différence
genres_communs <- intersect(
  stats_form_df$Genre[stats_form_df$Formation == "Formés EPIC"],
  stats_form_df$Genre[stats_form_df$Formation == "Non formés"]
)

gain_df <- data.frame(Genre = genres_communs, stringsAsFactors = FALSE)
gain_df$Pct_Formes <- sapply(genres_communs, function(g) {
  stats_form_df$Pct_Succes[stats_form_df$Genre == g & stats_form_df$Formation == "Formés EPIC"][1]
})
gain_df$Pct_NonFormes <- sapply(genres_communs, function(g) {
  stats_form_df$Pct_Succes[stats_form_df$Genre == g & stats_form_df$Formation == "Non formés"][1]
})
gain_df$N_Total <- sapply(genres_communs, function(g) {
  sum(stats_form_df$N[stats_form_df$Genre == g])
})
gain_df$Gain <- gain_df$Pct_Formes - gain_df$Pct_NonFormes

# Filtrer sur les genres avec au moins 15 occurrences pour éviter les artefacts
gain_df <- gain_df[gain_df$N_Total >= 15, ]
gain_df <- gain_df[order(gain_df$Gain, decreasing = TRUE), ]

chemin_fig7 <- file.path(dossier_output, "fig7_gain_formation_par_genre.png")
png(chemin_fig7, width = 3400, height = 2400, res = 300)

par(mar = c(5, 9, 4, 4), bg = "white")

gain_plot <- gain_df[order(gain_df$Gain, decreasing = FALSE), ]
col_gain <- ifelse(gain_plot$Gain >= 0, "#2E7D32", "#C62828")

# xlim élargi pour garantir qu'aucun pourcentage ne soit tronqué ou masqué
xlim_min <- min(gain_plot$Gain) - 8
xlim_max <- max(gain_plot$Gain) + 12

bp_gain <- barplot(gain_plot$Gain, horiz = TRUE, names.arg = gain_plot$Genre,
                   col = col_gain, border = "white",
                   xlab = "Différence de réussite : Formés EPIC vs Non formés (points de %)",
                   main = "Effet Spécifique de la Formation par Genre d'Abeille",
                   xlim = c(xlim_min, xlim_max),
                   las = 1, cex.names = 0.85, font.axis = 2, font.lab = 2, cex.main = 1.3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
abline(v = 0, col = "black", lwd = 1.5)
barplot(gain_plot$Gain, horiz = TRUE, col = col_gain, border = "white", add = TRUE, las = 1)

# Annotations texte : placées en noir gras net à l'extérieur des barres pour une lisibilité parfaite
pos_gain_x <- ifelse(gain_plot$Gain >= 0, gain_plot$Gain + 1.2, gain_plot$Gain - 1.2)
adj_gain_x <- ifelse(gain_plot$Gain >= 0, 0, 1)

text(pos_gain_x, bp_gain,
     sprintf("%+.1f%%", gain_plot$Gain),
     cex = 0.82, font = 2, col = "black",
     adj = adj_gain_x)

legend("bottomright",
       legend = c("Gain positif (appris lors de la formation)", "Gain négatif ou nul"),
       fill = c("#2E7D32", "#C62828"), border = "white",
       bty = "o", box.col = "#D0D7DE", bg = "#FFFFFFEE", cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 7 sauvegardée : %s\n", chemin_fig7))

# ------------------------------------------------------------------------------
# 5. FIGURE 8 : MATRICE DE CONFUSION TAXONOMIQUE (LES PIÈGES MORPHOLOGIQUES)
# ------------------------------------------------------------------------------
# Pour les genres pièges majeurs, identifier avec quels genres ils sont confondus
genres_cibles_pieges <- c("Hoplitis", "Tetralonia", "Melitta", "Macropis", "Stelis", "Seladonia", "Epeoloides")

df_pieges <- df_long[df_long$Genre_Solution %in% genres_cibles_pieges, ]

# Nettoyage des réponses pour normaliser en Title Case
df_pieges$Reponse_Norm <- tools::toTitleCase(tolower(trimws(df_pieges$Reponse_Fournie)))

# Pour chaque genre piège, identifier le Top 3 des confusions erronées
confusions_liste <- list()

for (g in genres_cibles_pieges) {
  df_g <- df_pieges[df_pieges$Genre_Solution == g, ]
  # Garder les erreurs
  df_err <- df_g[df_g$Est_Correct == 0 & df_g$Reponse_Norm != "-" & !grepl("don't know", tolower(df_g$Reponse_Norm)), ]
  
  if (nrow(df_err) > 0) {
    tab_err <- sort(table(df_err$Reponse_Norm), decreasing = TRUE)
    top_err <- head(tab_err, 4)
    confusions_liste[[g]] <- data.frame(
      Genre_Vrai = g,
      Confusion = names(top_err),
      Nb_Cas = as.numeric(top_err),
      Pct_Erreurs = round(100 * as.numeric(top_err) / nrow(df_err), 1),
      stringsAsFactors = FALSE
    )
  }
}

df_confusions_all <- do.call(rbind, confusions_liste)
fichier_conf <- file.path(dossier_output, "tableau_confusions_taxonomiques.csv")
exporter_excel_csv(df_confusions_all, fichier_conf)
cat(sprintf("Tableau des confusions morphologiques sauvegardé : %s\n", fichier_conf))

# Tracé graphique de la matrice de confusion
chemin_fig8 <- file.path(dossier_output, "fig8_confusions_taxonomiques_majeures.png")
# Image agrandie : 3800 x 2400 avec marge gauche 13.5 et marge droite 5.0 pour éviter toute troncature du texte à droite
png(chemin_fig8, width = 3800, height = 2400, res = 300)

par(mar = c(5, 13.5, 4, 5), bg = "white")

# Regrouper les 10 plus grandes confusions identifiées
top_confusions <- df_confusions_all[order(df_confusions_all$Nb_Cas, decreasing = TRUE), ]
top10_conf <- head(top_confusions, 10)
top10_conf <- top10_conf[order(top10_conf$Nb_Cas, decreasing = FALSE), ]

# Format compact demandé : "Nom 1 -> Nom 2"
labels_conf <- paste0(top10_conf$Genre_Vrai, " -> ", top10_conf$Confusion)

# xlim étendu à max * 1.55 pour laisser largement la place au texte "... cas (..% des erreurs)"
max_cases <- max(top10_conf$Nb_Cas)
bp_conf <- barplot(top10_conf$Nb_Cas, horiz = TRUE, names.arg = labels_conf,
                   col = "#8E44AD", border = "white",
                   xlab = "Nombre total de confusions observées",
                   main = "Top 10 des Confusions Taxonomiques Observées (Axe B du Mémoire)",
                   xlim = c(0, max_cases * 1.55),
                   las = 1, cex.names = 1.0, font.axis = 2, font.lab = 2, cex.main = 1.3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(top10_conf$Nb_Cas, horiz = TRUE, col = "#8E44AD", border = "white", add = TRUE, las = 1)

# Annotations texte
text(top10_conf$Nb_Cas + 1.2, bp_conf,
     sprintf("%d cas (%.1f%% des erreurs)", top10_conf$Nb_Cas, top10_conf$Pct_Erreurs),
     cex = 0.9, font = 2, col = "grey20", adj = 0)

legend("bottomright",
       legend = c("Fréquence de la confusion morphologique"),
       fill = "#8E44AD", border = "white",
       bty = "o", box.col = "#D0D7DE", bg = "#FFFFFFEE", cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 8 sauvegardée : %s\n", chemin_fig8))

cat("\n======================================================================\n")
cat("EDA TAXONOMIQUE TERMINÉE AVEC SUCCÈS. 4 FIGURES + 2 TABLES GÉNÉRÉES.\n")
cat("======================================================================\n")

