# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - BAC 3 (2025)
# SCRIPT 3 : Analyse Taxonomique par Genre, Pièges et Confusions (Axe B)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. ENVIRONNEMENT & DOSSIERS --------------------------------------------------
dossier_eda <- "BAC 3/EDA BAC 3 2025"
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
f_long <- file.path(dossier_eda, "BAC3_2025_clean_long.csv")
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# Filtrer sur les participants appariés stricts (N = 22)
df_long_app <- df_long[df_long$Apparie_Strict == TRUE, ]

cat("======================================================================\n")
cat("=== ANALYSE TAXONOMIQUE PAR GENRE, PIÈGES ET CONFUSIONS (AXE B) ===\n")
cat("======================================================================\n")
cat(sprintf("Nombre d'évaluations analysées : %d (22 étudiants x 28 spécimens x 2 tests)\n\n", nrow(df_long_app)))

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
  
  err_post_count <- n_post - s_post
  err_post <- round((err_post_count / n_post) * 100, 1)
  ic_err_post <- calc_wilson(err_post_count, n_post)
  
  # Catégorisation de difficulté au post-test selon les 4 classes demandées :
  # - Très difficile : >= 35% d'erreur
  # - Difficulté modérée : entre 20% et 34% d'erreur
  # - Accessible : entre 10% et 19% d'erreur
  # - Facile : moins de 10% d'erreur
  classe_diff <- ifelse(err_post >= 35, "Très difficile (>= 35% erreur)",
                 ifelse(err_post >= 20, "Difficulté modérée (20-34% erreur)",
                 ifelse(err_post >= 10, "Accessible (10-19% erreur)", "Facile (< 10% erreur)")))
  
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
    Erreurs_Post = err_post_count,
    Taux_Post = tx_post,
    IC_Inf_Post = ic_post["inf"],
    IC_Sup_Post = ic_post["sup"],
    IDK_Post_Pct = idk_post,
    Gain_Absolu_Pct = gain_abs,
    Gain_Relatif_Pct = gain_rel,
    Taux_Erreur_Post = err_post,
    IC_Err_Inf_Post = ic_err_post["inf"],
    IC_Err_Sup_Post = ic_err_post["sup"],
    Classe_Difficulte_Post = classe_diff,
    stringsAsFactors = FALSE
  )
}

tab_genres <- do.call(rbind, stats_genres_list)
tab_genres <- tab_genres[order(-tab_genres$Taux_Post), ]

cat("--- Performances taxonomiques par genre (triées par succès Post-test) ---\n")
print(tab_genres[, c("Genre", "Famille", "Nombre_Specimens", "Taux_Pre", "Taux_Post", "Gain_Absolu_Pct", "Classe_Difficulte_Post")])

exporter_excel_csv(tab_genres, file.path(dossier_output, "tableau_performances_par_genre.csv"))
exporter_excel_csv(tab_genres, file.path(dossier_output, "tableau_genres_succes_et_erreurs_wilson.csv"))

# 3. MATRICE DE CONFUSION TAXONOMIQUE (POST-TEST) ------------------------------
# Analyse des confusions au Post-test (pourquoi les erreurs sont-elles commises ?)
post_obs <- df_long_app[df_long_app$Cohorte == "Post-test", ]

# Genres valides + réponses
taxons_candidats <- sort(unique(c(post_obs$Genre_Solution, post_obs$Genre_Reponse)))
# Retirer 'Non répondu'
taxons_candidats <- setdiff(taxons_candidats, c("Non répondu"))

mat_confusion <- table(
  Solution = factor(post_obs$Genre_Solution, levels = genres_uniques),
  Reponse  = factor(post_obs$Genre_Reponse, levels = taxons_candidats)
)

exporter_excel_csv(as.data.frame.matrix(mat_confusion), file.path(dossier_output, "matrice_confusions_taxonomiques_brute.csv"))

# Extraction du Top des erreurs spécifiques (hors bonne réponse et hors 'Je ne sais pas')
conf_df_list <- list()
idx_c <- 1

for (i in seq_along(genres_uniques)) {
  sol_g <- genres_uniques[i]
  for (j in seq_along(taxons_candidats)) {
    rep_g <- taxons_candidats[j]
    if (tolower(sol_g) != tolower(rep_g) && rep_g != "Je ne sais pas" && rep_g != "Non répondu") {
      # Vérifier si ce n'est pas la tribu tolérée (ex: Anthidinii pour Trachusa/Anthidium/Stelis, ou Halictini pour Halictus/Lasioglossum)
      sub_test <- post_obs[post_obs$Genre_Solution == sol_g, ]
      est_tribu_ok <- any(tolower(sub_test$Tribu_Toleree) == tolower(rep_g))
      if (!est_tribu_ok) {
        cnt <- mat_confusion[sol_g, rep_g]
        if (cnt > 0) {
          tot_sol <- sum(post_obs$Genre_Solution == sol_g)
          conf_df_list[[idx_c]] <- data.frame(
            Genre_Reel = sol_g,
            Genre_Confondant = rep_g,
            Paire_Confusion = paste(sol_g, "->", rep_g),
            Nombre_Confusions = as.integer(cnt),
            Total_Presentations = tot_sol,
            Taux_Confusion_Pct = round((cnt / tot_sol) * 100, 1),
            stringsAsFactors = FALSE
          )
          idx_c <- idx_c + 1
        }
      }
    }
  }
}

tab_top_confusions <- do.call(rbind, conf_df_list)
tab_top_confusions <- tab_top_confusions[order(-tab_top_confusions$Nombre_Confusions, -tab_top_confusions$Taux_Confusion_Pct), ]

cat("\n--- Top des confusions taxonomiques erronées au Post-test ---\n")
print(head(tab_top_confusions, 15))

exporter_excel_csv(tab_top_confusions, file.path(dossier_output, "top_confusions_taxonomiques.csv"))

# 4. GÉNÉRATION DES FIGURES HAUTE DÉFINITION (CHARTE AGENTS.md) ----------------

# ------------------------------------------------------------------------------
# FIGURE 5 : Taux de succès comparé Pré vs Post par Genre
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure5_taux_succes_par_genre_pre_post.png"),
    width = 3600, height = 2400, res = 300, bg = "white")

# Ordre décroissant selon le taux Post-test
df_fig5 <- tab_genres[order(tab_genres$Taux_Post), ]
nb_g <- nrow(df_fig5)

par(mar = c(5, 12, 4, 4), family = "sans", las = 1)

# Préparer matrice 2 x nb_g
mat_g5 <- rbind(df_fig5$Taux_Pre, df_fig5$Taux_Post)

bp_g5 <- barplot(mat_g5, beside = TRUE, horiz = TRUE,
                 names.arg = df_fig5$Genre,
                 col = c("#4A90E2", "#2E7D32"),
                 border = "#1B365D",
                 xlim = c(0, 120),
                 xlab = "Taux d'identification correcte (%)",
                 main = "Progression taxonomique par genre d'abeille (Pré-test vs Post-test - BAC 3 2025)",
                 cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                 cex.lab = 1.1, font.lab = 2, cex.names = 0.95)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(mat_g5, beside = TRUE, horiz = TRUE, col = c("#4A90E2", "#2E7D32"), border = "#1B365D", add = TRUE, axes = FALSE)

# Labels de valeurs au bout des barres
for (i in 1:nb_g) {
  # Pre
  x_pre <- df_fig5$Taux_Pre[i]
  y_pre <- bp_g5[1, i]
  text(x_pre + 1.5, y_pre, sprintf("%.0f%%", x_pre), col = "#1B365D", cex = 0.75, font = 1, pos = 4)
  
  # Post
  x_post <- df_fig5$Taux_Post[i]
  y_post <- bp_g5[2, i]
  text(x_post + 1.5, y_post, sprintf("%.0f%%", x_post), col = "#1B365D", cex = 0.8, font = 2, pos = 4)
}

legend("bottomright",
       legend = c("Pré-test (Avant formation)", "Post-test (Après TP)"),
       fill = c("#4A90E2", "#2E7D32"),
       border = "#1B365D",
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Graphique généré : output/figure5_taux_succes_par_genre_pre_post.png\n")

# ------------------------------------------------------------------------------
# FIGURE 5A : Barplot horizontal Pré-test avec IC Wilson
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure5a_taux_succes_par_genre_pretest.png"),
    width = 3500, height = 2400, res = 300, bg = "white")

df_pre_sorted <- tab_genres[order(tab_genres$Taux_Pre), ]
par(mar = c(5, 12, 4, 4), family = "sans", las = 1)

bp_pre <- barplot(df_pre_sorted$Taux_Pre, horiz = TRUE,
                  names.arg = sprintf("%s (n=%d)", df_pre_sorted$Genre, df_pre_sorted$N_Pre),
                  col = "#4A90E2",
                  border = "#1B365D",
                  xlim = c(0, 125),
                  xlab = "Taux d'identification correcte (%)",
                  main = "Taux de succès par genre d'abeille au Pré-test (BAC 3 - 2025)",
                  cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                  cex.lab = 1.1, font.lab = 2, cex.names = 0.95)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(df_pre_sorted$Taux_Pre, horiz = TRUE, col = "#4A90E2", border = "#1B365D", add = TRUE, axes = FALSE)

# IC Wilson et textes
for (i in 1:nrow(df_pre_sorted)) {
  y_p <- bp_pre[i]
  x_val <- df_pre_sorted$Taux_Pre[i]
  x_inf <- df_pre_sorted$IC_Inf_Pre[i]
  x_sup <- df_pre_sorted$IC_Sup_Pre[i]
  
  arrows(x_inf, y_p, x_sup, y_p, angle = 90, code = 3, length = 0.04, col = "#1B365D", lwd = 1.4)
  text(max(x_sup, x_val) + 2, y_p, sprintf("%.1f%%", x_val), col = "#1B365D", font = 2, cex = 0.85, pos = 4)
}

legend("bottomright",
       legend = c("Taux de réussite Pré-test", "Intervalle de confiance Wilson à 95%"),
       fill = c("#4A90E2", NA),
       border = c("#1B365D", NA),
       lty = c(NA, 1), col = c(NA, "#1B365D"), lwd = c(NA, 1.4),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Graphique généré : output/figure5a_taux_succes_par_genre_pretest.png\n")

# ------------------------------------------------------------------------------
# FIGURE 5B : Barplot horizontal Post-test avec IC Wilson
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure5b_taux_succes_par_genre_posttest.png"),
    width = 3500, height = 2400, res = 300, bg = "white")

df_post_sorted <- tab_genres[order(tab_genres$Taux_Post), ]
par(mar = c(5, 12, 4, 4), family = "sans", las = 1)

bp_post <- barplot(df_post_sorted$Taux_Post, horiz = TRUE,
                   names.arg = sprintf("%s (n=%d)", df_post_sorted$Genre, df_post_sorted$N_Post),
                   col = "#2E7D32",
                   border = "#1B365D",
                   xlim = c(0, 125),
                   xlab = "Taux d'identification correcte (%)",
                   main = "Taux de succès par genre d'abeille au Post-test (BAC 3 - 2025)",
                   cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                   cex.lab = 1.1, font.lab = 2, cex.names = 0.95)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(df_post_sorted$Taux_Post, horiz = TRUE, col = "#2E7D32", border = "#1B365D", add = TRUE, axes = FALSE)

for (i in 1:nrow(df_post_sorted)) {
  y_p <- bp_post[i]
  x_val <- df_post_sorted$Taux_Post[i]
  x_inf <- df_post_sorted$IC_Inf_Post[i]
  x_sup <- df_post_sorted$IC_Sup_Post[i]
  
  arrows(x_inf, y_p, x_sup, y_p, angle = 90, code = 3, length = 0.04, col = "#1B365D", lwd = 1.4)
  text(max(x_sup, x_val) + 2, y_p, sprintf("%.1f%%", x_val), col = "#1B365D", font = 2, cex = 0.85, pos = 4)
}

legend("bottomright",
       legend = c("Taux de réussite Post-test", "Intervalle de confiance Wilson à 95%"),
       fill = c("#2E7D32", NA),
       border = c("#1B365D", NA),
       lty = c(NA, 1), col = c(NA, "#1B365D"), lwd = c(NA, 1.4),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Graphique généré : output/figure5b_taux_succes_par_genre_posttest.png\n")

# ------------------------------------------------------------------------------
# FIGURE 6 : Classement de difficulté des genres (Taux d'erreur Post-test)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure6_taux_erreur_difficultes_genres.png"),
    width = 3600, height = 2400, res = 300, bg = "white")

# Trier par taux d'erreur croissant (du moins dur au plus dur)
df_diff <- tab_genres[order(tab_genres$Taux_Erreur_Post), ]
nb_d <- nrow(df_diff)

par(mar = c(5, 12, 4, 4), family = "sans", las = 1)

# Attribution des 4 couleurs conformes à AGENTS.md :
# Vert émeraude (#2E7D32) : Facile (< 10%)
# Bleu ardoise (#4A90E2)   : Accessible (10-19%)
# Ambre/Orange (#E67E22)   : Difficulté modérée (20-34%)
# Rouge rubis (#C62828)    : Très difficile (>= 35%)
col_diff <- ifelse(df_diff$Taux_Erreur_Post >= 35, "#C62828",
            ifelse(df_diff$Taux_Erreur_Post >= 20, "#E67E22",
            ifelse(df_diff$Taux_Erreur_Post >= 10, "#4A90E2", "#2E7D32")))

bp_diff <- barplot(df_diff$Taux_Erreur_Post, horiz = TRUE,
                   names.arg = sprintf("%s (n=%d)", df_diff$Genre, df_diff$N_Post),
                   col = col_diff,
                   border = "#1B365D",
                   xlim = c(0, 120),
                   xlab = "Taux d'erreur au Post-test (%)",
                   main = "Classement de la difficulté des genres d'abeilles après formation (BAC 3 - 2025)",
                   cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                   cex.lab = 1.1, font.lab = 2, cex.names = 0.95)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(df_diff$Taux_Erreur_Post, horiz = TRUE, col = col_diff, border = "#1B365D", add = TRUE, axes = FALSE)

# IC Wilson et annotations numériques sans collision
for (i in 1:nb_d) {
  y_p <- bp_diff[i]
  x_val <- df_diff$Taux_Erreur_Post[i]
  x_inf <- max(0, df_diff$IC_Err_Inf_Post[i])
  x_sup <- min(100, df_diff$IC_Err_Sup_Post[i])
  n_err <- df_diff$Erreurs_Post[i]
  
  arrows(x_inf, y_p, x_sup, y_p, angle = 90, code = 3, length = 0.04, col = "#1B365D", lwd = 1.4)
  text(max(x_sup, x_val) + 2, y_p, sprintf("%.1f%% (n = %d)", x_val, n_err), col = "#1B365D", font = 2, cex = 0.85, pos = 4)
}

# Légende à 4 classes + Wilson IC
legend("bottomright",
       legend = c("Facile (Erreur < 10%)",
                  "Accessible (Erreur 10-19%)",
                  "Difficulté modérée (Erreur 20-34%)",
                  "Très difficile / Piège (Erreur >= 35%)",
                  "Intervalle de confiance Wilson à 95%"),
       fill = c("#2E7D32", "#4A90E2", "#E67E22", "#C62828", NA),
       border = c("#1B365D", "#1B365D", "#1B365D", "#1B365D", NA),
       lty = c(NA, NA, NA, NA, 1), col = c(NA, NA, NA, NA, "#1B365D"), lwd = c(NA, NA, NA, NA, 1.4),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.88)

dev.off()
cat("  -> Graphique généré : output/figure6_taux_erreur_difficultes_genres.png\n")

# ------------------------------------------------------------------------------
# FIGURE 7 : Top des confusions taxonomiques au Post-test
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure7_top_confusions_taxonomiques.png"),
    width = 3600, height = 2400, res = 300, bg = "white")

# Sélection des paires avec au moins 2 confusions observées
df_top_c <- tab_top_confusions[tab_top_confusions$Nombre_Confusions >= 2, ]
# Si moins de 8 paires, prendre le top 8
if (nrow(df_top_c) < 8) df_top_c <- head(tab_top_confusions, 8)

df_top_c <- df_top_c[order(df_top_c$Nombre_Confusions), ]
n_c <- nrow(df_top_c)

par(mar = c(5, 14, 4, 4), family = "sans", las = 1)

bp_c <- barplot(df_top_c$Nombre_Confusions, horiz = TRUE,
                names.arg = df_top_c$Paire_Confusion,
                col = "#8E44AD",
                border = "#1B365D",
                xlim = c(0, max(df_top_c$Nombre_Confusions) * 1.3 + 2),
                xlab = "Nombre d'occurrences de confusion (sur l'échantillon apparié post-test)",
                main = "Top des confusions taxonomiques récurrentes après formation (BAC 3 - 2025)",
                cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                cex.lab = 1.1, font.lab = 2, cex.names = 0.95)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
barplot(df_top_c$Nombre_Confusions, horiz = TRUE, col = "#8E44AD", border = "#1B365D", add = TRUE, axes = FALSE)

# Labels sur les barres : effectif et pourcentage des spécimens du genre réel
for (i in 1:n_c) {
  y_p <- bp_c[i]
  cnt <- df_top_c$Nombre_Confusions[i]
  tx  <- df_top_c$Taux_Confusion_Pct[i]
  text(cnt + 0.2, y_p, sprintf("%d fois (%s des cas)", cnt, sprintf("%.1f%%", tx)), 
       col = "#1B365D", font = 2, cex = 0.85, pos = 4)
}

legend("bottomright",
       legend = c("Confusion taxonomique erronée (Genre réel -> Réponse fournie)"),
       fill = "#8E44AD", border = "#1B365D",
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Graphique généré : output/figure7_top_confusions_taxonomiques.png\n")

cat("\n======================================================================\n")
cat("=== ANALYSE AXE B (BAC 3 2025) TERMINÉE AVEC SUCCÈS ===\n")
cat("======================================================================\n")

