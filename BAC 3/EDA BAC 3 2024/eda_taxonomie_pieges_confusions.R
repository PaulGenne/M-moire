# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - BAC 3 (2024)
# SCRIPT 3 : Analyse Taxonomique par Genre, Pièges et Confusions (Axe B)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. ENVIRONNEMENT & DOSSIERS --------------------------------------------------
dossier_eda <- "BAC 3/EDA BAC 3 2024"
dossier_output <- file.path(dossier_eda, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat(sprintf("  -> Fichier CSV exporté : %s\n", chemin_fichier))
}

# 1. CHARGEMENT DU FORMAT LONG -------------------------------------------------
f_long <- file.path(dossier_eda, "BAC3_2024_clean_long.csv")
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# Filtrer sur les participants appariés stricts (N = 25)
df_long_app <- df_long[df_long$Apparie_Strict == TRUE, ]

cat("======================================================================\n")
cat("=== ANALYSE TAXONOMIQUE PAR GENRE, PIÈGES ET CONFUSIONS (AXE B) ===\n")
cat("======================================================================\n")
cat(sprintf("Nombre d'évaluations analysées : %d (25 étudiants x 26 spécimens x 2 tests)\n\n", nrow(df_long_app)))

# 2. CALCUL DES PERFORMANCES PAR GENRE (PRÉ VS POST) --------------------------
calc_wilson <- function(succes, total) {
  if (total == 0) return(c(inf = 0, sup = 0))
  p <- succes / total
  z <- 1.96
  denom <- 1 + (z^2 / total)
  centre <- (p + (z^2 / (2 * total))) / denom
  marge <- (z * sqrt((p * (1 - p) / total) + (z^2 / (4 * total^2)))) / denom
  c(inf = round(max(0, centre - marge) * 100, 1),
    sup = round(min(1, centre + marge) * 100, 1))
}

genres_uniques <- sort(unique(df_long_app$Genre_Solution))
stats_genres_list <- list()

for (g in genres_uniques) {
  sub_pre  <- df_long_app[df_long_app$Genre_Solution == g & df_long_app$Cohorte == "Pré-test", ]
  sub_post <- df_long_app[df_long_app$Genre_Solution == g & df_long_app$Cohorte == "Post-test", ]
  
  n_pre  <- nrow(sub_pre)
  s_pre  <- sum(sub_pre$Est_Correct_Moodle)
  tx_pre <- round((s_pre / n_pre) * 100, 1)
  ic_pre <- calc_wilson(s_pre, n_pre)
  idk_pre <- round((sum(sub_pre$Est_IDK) / n_pre) * 100, 1)
  
  n_post  <- nrow(sub_post)
  s_post  <- sum(sub_post$Est_Correct_Moodle)
  tx_post <- round((s_post / n_post) * 100, 1)
  ic_post <- calc_wilson(s_post, n_post)
  idk_post <- round((sum(sub_post$Est_IDK) / n_post) * 100, 1)
  
  fam <- sub_pre$Famille_Solution[1]
  guilde <- sub_pre$Guilde_Solution[1]
  nb_specimens <- length(unique(sub_pre$Question_Num))
  
  gain_abs <- round(tx_post - tx_pre, 1)
  gain_rel <- ifelse(tx_pre < 100, round(((tx_post - tx_pre) / (100 - tx_pre)) * 100, 1), 0)
  
  # Catégorisation de difficulté au post-test
  classe_diff <- ifelse(tx_post >= 75, "Facile (>= 75%)",
                        ifelse(tx_post >= 50, "Intermédiaire (50-74%)", "Difficile / Piège (< 50%)"))
  
  stats_genres_list[[g]] <- data.frame(
    Genre = g,
    Famille = fam,
    Guilde = guilde,
    Nombre_Specimens = nb_specimens,
    N_Pre = n_pre,
    Succes_Pre = s_pre,
    Taux_Pre = tx_pre,
    IC_Inf_Pre = ic_pre["inf"],
    IC_Sup_Pre = ic_pre["sup"],
    IDK_Pre_Pct = idk_pre,
    N_Post = n_post,
    Succes_Post = s_post,
    Taux_Post = tx_post,
    IC_Inf_Post = ic_post["inf"],
    IC_Sup_Post = ic_post["sup"],
    IDK_Post_Pct = idk_post,
    Gain_Absolu_Pct = gain_abs,
    Gain_Relatif_Pct = gain_rel,
    Classe_Difficulte_Post = classe_diff,
    stringsAsFactors = FALSE
  )
}

df_genres <- do.call(rbind, stats_genres_list)
rownames(df_genres) <- NULL

# Tri par taux post-test décroissant
df_genres <- df_genres[order(df_genres$Taux_Post, decreasing = TRUE), ]

cat("--- Performances taxonomiques par genre (N = 19 genres) ---\n")
print(df_genres[, c("Genre", "Famille", "Guilde", "Taux_Pre", "Taux_Post", "Gain_Absolu_Pct", "Classe_Difficulte_Post")])

exporter_excel_csv(df_genres, file.path(dossier_output, "tableau_performances_par_genre.csv"))

# 3. MATRICES DE CONFUSION TAXONOMIQUE (POST-TEST) ----------------------------
# Filtrer sur le post-test
post_long <- df_long_app[df_long_app$Cohorte == "Post-test", ]

# Table de contingence Genre Attendue x Genre Répondu
mat_conf <- table(Attendu = post_long$Genre_Solution, Repondu = post_long$Genre_Reponse)
df_mat_conf <- as.data.frame.matrix(mat_conf)
df_mat_conf_export <- cbind(Genre_Attendu = rownames(df_mat_conf), df_mat_conf)

exporter_excel_csv(df_mat_conf_export, file.path(dossier_output, "matrice_confusions_taxonomiques_brute.csv"))

# Extraire les paires d'erreurs les plus fréquentes (hors succès strict et hors tribu tolérée)
erreurs_list <- list()
idx_err <- 1

for (k in 1:nrow(post_long)) {
  att <- post_long$Genre_Solution[k]
  rep <- post_long$Genre_Reponse[k]
  is_ok <- post_long$Est_Correct_Moodle[k] == 1
  
  if (!is_ok && rep != "Je ne sais pas" && rep != "Non répondu") {
    erreurs_list[[idx_err]] <- data.frame(
      Paire = paste(att, "->", rep),
      Genre_Attendu = att,
      Genre_Confondi = rep,
      stringsAsFactors = FALSE
    )
    idx_err <- idx_err + 1
  }
}

df_erreurs <- do.call(rbind, erreurs_list)

cat("\n--- Top 10 des erreurs de confusion taxonomique au Post-test ---\n")
top_conf <- as.data.frame(sort(table(df_erreurs$Paire), decreasing = TRUE)[1:10])
colnames(top_conf) <- c("Paire_Confusion", "Frequence")
print(top_conf)

exporter_excel_csv(top_conf, file.path(dossier_output, "top_confusions_taxonomiques.csv"))

# 4. VISUALISATIONS GRAPHIQUES HD (CONFORMES AGENTS.md) ------------------------

# FIGURE 5 : Barplot horizontal comparatif par genre (Pré vs Post avec IC de Wilson)
png(file.path(dossier_output, "figure5_taux_succes_par_genre_pre_post.png"),
    width = 3800, height = 2800, res = 300, bg = "white")

# Ordre d'affichage du bas vers le haut (croissant pour barplot horizontal)
df_plot <- df_genres[order(df_genres$Taux_Post, decreasing = FALSE), ]
n_genres <- nrow(df_plot)

par(mar = c(5, 13, 4, 4), family = "sans", las = 1)

# Matrice pour barplot groupé horizontal
mat_barplot <- rbind(df_plot$Taux_Pre, df_plot$Taux_Post)

bp <- barplot(mat_barplot,
              beside = TRUE,
              horiz = TRUE,
              names.arg = df_plot$Genre,
              col = c("#4A90E2", "#2E7D32"),
              border = "#1B365D",
              xlim = c(0, 125), # Dégagement 25% à droite pour éviter collision
              xlab = "Taux d'identification correcte (%)",
              main = "Efficacité de l'apprentissage par Genre d'Abeille (BAC 3 - 2024)",
              cex.main = 1.3, font.main = 2, col.main = "#1B365D",
              cex.lab = 1.1, font.lab = 2,
              cex.names = 1.0, font = 3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp <- barplot(mat_barplot,
              beside = TRUE,
              horiz = TRUE,
              names.arg = df_plot$Genre,
              col = c("#4A90E2", "#2E7D32"),
              border = "#1B365D",
              add = TRUE,
              cex.names = 1.0, font = 3)

# Ajout des barres d'erreur IC 95% Wilson
for (i in 1:n_genres) {
  # Pré
  segments(df_plot$IC_Inf_Pre[i], bp[1, i], df_plot$IC_Sup_Pre[i], bp[1, i], col = "#1B365D", lwd = 1.5)
  segments(df_plot$IC_Inf_Pre[i], bp[1, i] - 0.2, df_plot$IC_Inf_Pre[i], bp[1, i] + 0.2, col = "#1B365D", lwd = 1.5)
  segments(df_plot$IC_Sup_Pre[i], bp[1, i] - 0.2, df_plot$IC_Sup_Pre[i], bp[1, i] + 0.2, col = "#1B365D", lwd = 1.5)
  
  # Post
  segments(df_plot$IC_Inf_Post[i], bp[2, i], df_plot$IC_Sup_Post[i], bp[2, i], col = "#1B365D", lwd = 1.5)
  segments(df_plot$IC_Inf_Post[i], bp[2, i] - 0.2, df_plot$IC_Inf_Post[i], bp[2, i] + 0.2, col = "#1B365D", lwd = 1.5)
  segments(df_plot$IC_Sup_Post[i], bp[2, i] - 0.2, df_plot$IC_Sup_Post[i], bp[2, i] + 0.2, col = "#1B365D", lwd = 1.5)
  
  # Labels directs à droite de l'IC supérieur
  pos_text_post <- max(df_plot$Taux_Post[i], df_plot$IC_Sup_Post[i]) + 2
  text(pos_text_post, bp[2, i],
       sprintf("%.0f%% (+%.0f)", df_plot$Taux_Post[i], df_plot$Gain_Absolu_Pct[i]),
       font = 2, cex = 0.85, col = "#1B365D", pos = 4)
}

legend("bottomright",
       legend = c("Pré-test initial (N = 25)", "Post-test après TP (N = 25)", "Intervalle Wilson 95%"),
       fill = c("#4A90E2", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", NA),
       lty = c(NA, NA, 1), col = c(NA, NA, "#1B365D"), lwd = c(NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 5 générée : output/figure5_taux_succes_par_genre_pre_post.png\n")

# FIGURE 6 : Classement des genres par niveau de difficulté finale
png(file.path(dossier_output, "figure6_classement_difficulte_genres.png"),
    width = 3600, height = 2600, res = 300, bg = "white")

df_diff <- df_genres[order(df_genres$Taux_Post, decreasing = TRUE), ]

couleurs_diff <- ifelse(df_diff$Taux_Post >= 75, "#2E7D32",       # Facile (Vert)
                        ifelse(df_diff$Taux_Post >= 50, "#E67E22", # Intermédiaire (Orange)
                               "#C62828"))                         # Piège/Difficile (Rouge)

par(mar = c(5, 13, 4, 3), family = "sans", las = 1)

bp_diff <- barplot(df_diff$Taux_Post,
                   horiz = TRUE,
                   names.arg = df_diff$Genre,
                   col = couleurs_diff,
                   border = "#1B365D",
                   xlim = c(0, 120),
                   xlab = "Taux de réussite au Post-test (%)",
                   main = "Typologie de difficulté des 19 genres d'abeilles après formation (BAC 3 - 2024)",
                   cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                   cex.lab = 1.1, font.lab = 2, cex.names = 1.0, font = 3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp_diff <- barplot(df_diff$Taux_Post,
                   horiz = TRUE,
                   names.arg = df_diff$Genre,
                   col = couleurs_diff,
                   border = "#1B365D",
                   add = TRUE, cex.names = 1.0, font = 3)

# Lignes de seuils pédagogiques
abline(v = 75, col = "#2E7D32", lwd = 2, lty = 2)
abline(v = 50, col = "#C62828", lwd = 2, lty = 2)

text(75, 1, "Seuil de maîtrise (75%)", col = "#2E7D32", font = 2, pos = 4, cex = 0.85)
text(50, 1, "Seuil d'alerte (50%)", col = "#C62828", font = 2, pos = 4, cex = 0.85)

# Labels numériques
text(df_diff$Taux_Post + 2, bp_diff,
     sprintf("%.1f%% (n = %d)", df_diff$Taux_Post, df_diff$Succes_Post),
     font = 2, cex = 0.85, col = "#1B365D", pos = 4)

legend("bottomright",
       legend = c("Genre maîtrisé / Facile (>= 75%)", 
                  "Genre intermédiaire (50 à 74%)", 
                  "Genre piège / Difficile (< 50%)"),
       fill = c("#2E7D32", "#E67E22", "#C62828"),
       border = "#1B365D",
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 6 générée : output/figure6_classement_difficulte_genres.png\n")

# FIGURE 7 : Top paires de confusions taxonomiques récurrentes
png(file.path(dossier_output, "figure7_top_confusions_taxonomiques.png"),
    width = 3600, height = 2400, res = 300, bg = "white")

top_conf_plot <- top_conf[order(top_conf$Frequence, decreasing = FALSE), ]

par(mar = c(5, 16, 4, 3), family = "sans", las = 1)

bp_conf <- barplot(top_conf_plot$Frequence,
                   horiz = TRUE,
                   names.arg = top_conf_plot$Paire_Confusion,
                   col = "#8E44AD",
                   border = "#1B365D",
                   xlim = c(0, max(top_conf_plot$Frequence) * 1.35),
                   xlab = "Nombre d'erreurs commises au Post-test",
                   main = "Principales confusions taxonomiques récurrentes post-formation (BAC 3 - 2024)",
                   cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                   cex.lab = 1.1, font.lab = 2, cex.names = 0.95, font = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp_conf <- barplot(top_conf_plot$Frequence,
                   horiz = TRUE,
                   names.arg = top_conf_plot$Paire_Confusion,
                   col = "#8E44AD",
                   border = "#1B365D",
                   add = TRUE, cex.names = 0.95, font = 2)

# Labels numériques
text(top_conf_plot$Frequence + 0.3, bp_conf,
     sprintf("%d erreurs (%.1f%% des confusions)", 
             top_conf_plot$Frequence, 
             (top_conf_plot$Frequence / nrow(df_erreurs)) * 100),
     font = 2, cex = 0.85, col = "#1B365D", pos = 4)

legend("bottomright",
       legend = c("Erreur d'identification (Genre attendu -> Genre confondu)"),
       fill = "#8E44AD", border = "#1B365D",
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 7 générée : output/figure7_top_confusions_taxonomiques.png\n")

cat("\n======================================================================\n")
cat("=== SCRIPT 3 (AXE B - TAXONOMIE & CONFUSIONS) EXÉCUTÉ AVEC SUCCÈS ===\n")
cat("======================================================================\n")

