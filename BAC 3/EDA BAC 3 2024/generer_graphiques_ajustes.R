# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA - BAC 3 (2024)
# SCRIPT COMPLÉMENTAIRE : Génération des Graphiques Ajustés (Figures 4, 5A, 5B, 6, 7)
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

# 1. CHARGEMENT DES DONNÉES ----------------------------------------------------
f_wide <- file.path(dossier_eda, "BAC3_2024_clean_wide.csv")
f_long <- file.path(dossier_eda, "BAC3_2024_clean_long.csv")

df_wide <- read.csv(f_wide, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# Filtrer sur les 25 participants appariés
df_wide_app <- df_wide[df_wide$Apparie_Strict == TRUE, ]
df_long_app <- df_long[df_long$Apparie_Strict == TRUE, ]

pre_wide_app  <- df_wide_app[df_wide_app$Cohorte == "Pré-test", ]
post_wide_app <- df_wide_app[df_wide_app$Cohorte == "Post-test", ]

pre_wide_app  <- pre_wide_app[order(pre_wide_app$ID_Participant), ]
post_wide_app <- post_wide_app[order(post_wide_app$ID_Participant), ]

pre_idk  <- pre_wide_app$Nombre_IDK
post_idk <- post_wide_app$Nombre_IDK

# Fonction de calcul d'intervalle de confiance de Wilson à 95%
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

cat("======================================================================\n")
cat("=== GÉNÉRATION DES GRAPHIQUES AJUSTÉS (BAC 3 - 2024) ===\n")
cat("======================================================================\n\n")

# ------------------------------------------------------------------------------
# FIGURE 4 AJUSTÉE : Effondrement de l'incertitude (Légende replacée sans chevauchement)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure4_effondrement_incertitude_idk_ajustee.png"),
    width = 3200, height = 2300, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

# Échelle y étendue jusqu'à 32 pour un dégagement total
boxplot(list("Pré-test (Avant formation)" = pre_idk, 
             "Post-test (Après TP)" = post_idk),
        col = c("#E67E22", "#2E7D32"),
        border = "#1B365D",
        ylim = c(0, 32),
        ylab = "Nombre de réponses 'Je ne sais pas' (/26 questions)",
        main = "Évolution de l'incertitude : effondrement des réponses 'Je ne sais pas' (BAC 3 - 2024)",
        cex.main = 1.3, font.main = 2, col.main = "#1B365D",
        cex.lab = 1.1, font.lab = 2, outline = FALSE)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

boxplot(list("Pré-test (Avant formation)" = pre_idk, 
             "Post-test (Après TP)" = post_idk),
        col = c("#E67E22", "#2E7D32"),
        border = "#1B365D",
        add = TRUE, outline = FALSE)

# Trajectoires individuelles
set.seed(42)
jit_idk1 <- jitter(rep(1, length(pre_idk)), amount = 0.04)
jit_idk2 <- jitter(rep(2, length(post_idk)), amount = 0.04)

for (k in seq_along(pre_idk)) {
  lines(c(jit_idk1[k], jit_idk2[k]), c(pre_idk[k], post_idk[k]), 
        col = "#8E44AD44", lwd = 1.8)
  points(jit_idk1[k], pre_idk[k], pch = 21, bg = "#E67E22", col = "#1B365D", cex = 1.3)
  points(jit_idk2[k], post_idk[k], pch = 21, bg = "#2E7D32", col = "#1B365D", cex = 1.3)
}

# Annotations directes des moyennes et médianes (parfaitement dégagées)
# Pour Pré-test (x = 1) : placé à y = 28
text(1, 28, sprintf("Moyenne = %.1f / 26\n(Médiane = %d)", mean(pre_idk), median(pre_idk)), 
     font = 2, col = "#1B365D", cex = 1.0)

# Pour Post-test (x = 2) : placé à y = 14 (car toutes les données post sont <= 10)
text(2, 14, sprintf("Moyenne = %.1f / 26\n(Médiane = %d)", mean(post_idk), median(post_idk)), 
     font = 2, col = "#1B365D", cex = 1.0)

# Légende repositionnée en haut à droite (y = 26 à 31, au-dessus du vide de la colonne 2)
legend("topright",
       legend = c("Pré-test (Forte incertitude)", 
                  "Post-test (Assurance acquise)", 
                  "Trajectoires individuelles (N = 25)"),
       fill = c("#E67E22", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", NA),
       lty = c(NA, NA, 1), col = c(NA, NA, "#8E44AD"), lwd = c(NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95, inset = c(0.02, 0.02))

dev.off()
cat("  -> Figure 4 ajustée générée : output/figure4_effondrement_incertitude_idk_ajustee.png\n")


# ------------------------------------------------------------------------------
# 2. PRÉPARATION DES DONNÉES PAR GENRE
# ------------------------------------------------------------------------------
genres_uniques <- sort(unique(df_long_app$Genre_Solution))
tab_genres_list <- list()

for (g in genres_uniques) {
  sub_pre  <- df_long_app[df_long_app$Genre_Solution == g & df_long_app$Cohorte == "Pré-test", ]
  sub_post <- df_long_app[df_long_app$Genre_Solution == g & df_long_app$Cohorte == "Post-test", ]
  
  n_pre  <- nrow(sub_pre)
  s_pre  <- sum(sub_pre$Est_Correct_Moodle)
  err_pre <- n_pre - s_pre
  tx_succ_pre <- round((s_pre / n_pre) * 100, 1)
  tx_err_pre  <- round((err_pre / n_pre) * 100, 1)
  ic_succ_pre <- calc_wilson(s_pre, n_pre)
  ic_err_pre  <- calc_wilson(err_pre, n_pre)
  
  n_post  <- nrow(sub_post)
  s_post  <- sum(sub_post$Est_Correct_Moodle)
  err_post <- n_post - s_post
  tx_succ_post <- round((s_post / n_post) * 100, 1)
  tx_err_post  <- round((err_post / n_post) * 100, 1)
  ic_succ_post <- calc_wilson(s_post, n_post)
  ic_err_post  <- calc_wilson(err_post, n_post)
  
  fam <- sub_pre$Famille_Solution[1]
  guilde <- sub_pre$Guilde_Solution[1]
  nb_specimens <- length(unique(sub_pre$Question_Num))
  
  cat_diff <- if (tx_err_post >= 35) {
    "Très difficile (>= 35% d'erreur)"
  } else if (tx_err_post >= 20) {
    "Difficultés modérées (20 à 34% d'erreur)"
  } else if (tx_err_post >= 10) {
    "Accessible (10 à 19% d'erreur)"
  } else {
    "Facile (< 10% d'erreur)"
  }
  
  tab_genres_list[[g]] <- data.frame(
    Genre = g,
    Famille = fam,
    Guilde = guilde,
    Nombre_Specimens = nb_specimens,
    # Pré-test
    N_Pre = n_pre,
    Succes_Pre = s_pre,
    Erreurs_Pre = err_pre,
    Taux_Succes_Pre = tx_succ_pre,
    IC_Inf_Succes_Pre = ic_succ_pre["inf"],
    IC_Sup_Succes_Pre = ic_succ_pre["sup"],
    Taux_Erreur_Pre = tx_err_pre,
    IC_Inf_Erreur_Pre = ic_err_pre["inf"],
    IC_Sup_Erreur_Pre = ic_err_pre["sup"],
    # Post-test
    N_Post = n_post,
    Succes_Post = s_post,
    Erreurs_Post = err_post,
    Taux_Succes_Post = tx_succ_post,
    IC_Inf_Succes_Post = ic_succ_post["inf"],
    IC_Sup_Succes_Post = ic_succ_post["sup"],
    Taux_Erreur_Post = tx_err_post,
    IC_Inf_Erreur_Post = ic_err_post["inf"],
    IC_Sup_Erreur_Post = ic_err_post["sup"],
    # Catégorie
    Categorie_Difficulte = cat_diff,
    Gain_Succes_Pct = round(tx_succ_post - tx_succ_pre, 1),
    stringsAsFactors = FALSE
  )
}

df_genres_complet <- do.call(rbind, tab_genres_list)
rownames(df_genres_complet) <- NULL

exporter_excel_csv(df_genres_complet, file.path(dossier_output, "tableau_genres_succes_et_erreurs_wilson.csv"))


# ------------------------------------------------------------------------------
# FIGURE 5A AJUSTÉE : Taux de succès par genre au PRÉ-TEST (Texte moyenne sous 12%)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure5a_taux_succes_par_genre_pretest.png"),
    width = 3800, height = 2600, res = 300, bg = "white")

# Ordre croissant de succès au pré-test
df_plot_pre <- df_genres_complet[order(df_genres_complet$Taux_Succes_Pre, decreasing = FALSE), ]
n_g <- nrow(df_plot_pre)

par(mar = c(5, 13, 4, 4), family = "sans", las = 1)

bp_pre <- barplot(df_plot_pre$Taux_Succes_Pre,
                  horiz = TRUE,
                  names.arg = df_plot_pre$Genre,
                  col = "#4A90E2",
                  border = "#1B365D",
                  xlim = c(0, 115),
                  xlab = "Taux d'identification correcte au Pré-test (%)",
                  main = "Taux de succès par Genre d'Abeille — Pré-test initial (BAC 3 - 2024)",
                  cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                  cex.lab = 1.1, font.lab = 2,
                  cex.names = 1.0, font = 3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp_pre <- barplot(df_plot_pre$Taux_Succes_Pre,
                  horiz = TRUE,
                  names.arg = df_plot_pre$Genre,
                  col = "#4A90E2",
                  border = "#1B365D",
                  add = TRUE,
                  cex.names = 1.0, font = 3)

# Barres d'erreur IC 95% Wilson
for (i in 1:n_g) {
  segments(df_plot_pre$IC_Inf_Succes_Pre[i], bp_pre[i], 
           df_plot_pre$IC_Sup_Succes_Pre[i], bp_pre[i], col = "#1B365D", lwd = 1.6)
  segments(df_plot_pre$IC_Inf_Succes_Pre[i], bp_pre[i] - 0.2, 
           df_plot_pre$IC_Inf_Succes_Pre[i], bp_pre[i] + 0.2, col = "#1B365D", lwd = 1.6)
  segments(df_plot_pre$IC_Sup_Succes_Pre[i], bp_pre[i] - 0.2, 
           df_plot_pre$IC_Sup_Succes_Pre[i], bp_pre[i] + 0.2, col = "#1B365D", lwd = 1.6)
  
  # Labels directs à droite de l'IC supérieur
  pos_x <- max(df_plot_pre$Taux_Succes_Pre[i], df_plot_pre$IC_Sup_Succes_Pre[i]) + 2
  text(pos_x, bp_pre[i],
       sprintf("%.1f%% (n = %d/%d)", df_plot_pre$Taux_Succes_Pre[i], 
               df_plot_pre$Succes_Pre[i], df_plot_pre$N_Pre[i]),
       font = 2, cex = 0.85, col = "#1B365D", pos = 4)
}

# Ligne moyenne globale
moy_pre <- mean(df_plot_pre$Taux_Succes_Pre)
abline(v = moy_pre, col = "#C62828", lwd = 2, lty = 2)

# DEMANDE UTILISATEUR : Texte de la moyenne placé strictement EN DESSOUS de la première barre (12%)
# bp_pre[1] est la position de la barre 1. On place le texte à bp_pre[1] - 0.65 (en-dessous de la barre et de son étiquette)
text(moy_pre, bp_pre[1] - 0.65, 
     sprintf("Moyenne = %.1f%%", moy_pre), 
     col = "#C62828", font = 2, pos = 4, cex = 0.85, xpd = TRUE)

legend("bottomright",
       legend = c("Pré-test initial (N = 25)", "Intervalle de confiance Wilson 95%", "Moyenne du groupe"),
       fill = c("#4A90E2", NA, NA),
       border = c("#1B365D", NA, NA),
       lty = c(NA, 1, 2), col = c(NA, "#1B365D", "#C62828"), lwd = c(NA, 2, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 5A ajustée générée : output/figure5a_taux_succes_par_genre_pretest.png\n")


# ------------------------------------------------------------------------------
# FIGURE 5B AJUSTÉE : Taux de succès par genre au POST-TEST (Zéro chevauchement légende/moyenne)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure5b_taux_succes_par_genre_posttest.png"),
    width = 3800, height = 2600, res = 300, bg = "white")

# Ordre croissant de succès au post-test
df_plot_post <- df_genres_complet[order(df_genres_complet$Taux_Succes_Post, decreasing = FALSE), ]

par(mar = c(5, 13, 4, 4), family = "sans", las = 1)

bp_post <- barplot(df_plot_post$Taux_Succes_Post,
                   horiz = TRUE,
                   names.arg = df_plot_post$Genre,
                   col = "#2E7D32",
                   border = "#1B365D",
                   xlim = c(0, 125),
                   xlab = "Taux d'identification correcte au Post-test (%)",
                   main = "Taux de succès par Genre d'Abeille — Post-test après TP (BAC 3 - 2024)",
                   cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                   cex.lab = 1.1, font.lab = 2,
                   cex.names = 1.0, font = 3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp_post <- barplot(df_plot_post$Taux_Succes_Post,
                   horiz = TRUE,
                   names.arg = df_plot_post$Genre,
                   col = "#2E7D32",
                   border = "#1B365D",
                   add = TRUE,
                   cex.names = 1.0, font = 3)

# Barres d'erreur IC 95% Wilson
for (i in 1:n_g) {
  segments(df_plot_post$IC_Inf_Succes_Post[i], bp_post[i], 
           df_plot_post$IC_Sup_Succes_Post[i], bp_post[i], col = "#1B365D", lwd = 1.6)
  segments(df_plot_post$IC_Inf_Succes_Post[i], bp_post[i] - 0.2, 
           df_plot_post$IC_Inf_Succes_Post[i], bp_post[i] + 0.2, col = "#1B365D", lwd = 1.6)
  segments(df_plot_post$IC_Sup_Succes_Post[i], bp_post[i] - 0.2, 
           df_plot_post$IC_Sup_Succes_Post[i], bp_post[i] + 0.2, col = "#1B365D", lwd = 1.6)
  
  # Labels directs à droite de l'IC supérieur
  pos_x <- max(df_plot_post$Taux_Succes_Post[i], df_plot_post$IC_Sup_Succes_Post[i]) + 2
  text(pos_x, bp_post[i],
       sprintf("%.1f%% (n = %d/%d)", df_plot_post$Taux_Succes_Post[i], 
               df_plot_post$Succes_Post[i], df_plot_post$N_Post[i]),
       font = 2, cex = 0.85, col = "#1B365D", pos = 4)
}

# Ligne moyenne globale
moy_post <- mean(df_plot_post$Taux_Succes_Post)
abline(v = moy_post, col = "#C62828", lwd = 2, lty = 2)

# DEMANDE UTILISATEUR : La légende ne doit pas se superposer au texte de moyenne !
# On place le texte de la moyenne TOUT EN HAUT de la ligne rouge verticale (au-dessus des barres)
text(moy_post, max(bp_post) + 0.9, 
     sprintf("Moyenne = %.1f%%", moy_post), 
     col = "#C62828", font = 2, pos = 3, cex = 0.9, xpd = TRUE)

# Et la légende reste en bas à droite (aucun chevauchement)
legend("bottomright",
       legend = c("Post-test final (N = 25)", "Intervalle de confiance Wilson 95%", "Moyenne du groupe"),
       fill = c("#2E7D32", NA, NA),
       border = c("#1B365D", NA, NA),
       lty = c(NA, 1, 2), col = c(NA, "#1B365D", "#C62828"), lwd = c(NA, 2, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 5B ajustée générée : output/figure5b_taux_succes_par_genre_posttest.png\n")


# ------------------------------------------------------------------------------
# FIGURE 6 AJUSTÉE : Taux d'Erreur, 4 Catégories, IC Wilson (SANS lignes verticales)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure6_taux_erreur_difficultes_genres.png"),
    width = 3800, height = 2800, res = 300, bg = "white")

# Tri par taux d'erreur croissant (du bas vers le haut : facile en bas, très difficile en haut)
df_plot_err <- df_genres_complet[order(df_genres_complet$Taux_Erreur_Post, decreasing = FALSE), ]

# Couleurs des 4 catégories demandées :
couleurs_cat <- ifelse(df_plot_err$Taux_Erreur_Post >= 35, "#C62828",
                ifelse(df_plot_err$Taux_Erreur_Post >= 20, "#E67E22",
                ifelse(df_plot_err$Taux_Erreur_Post >= 10, "#4A90E2",
                       "#2E7D32")))

par(mar = c(5, 13, 4, 4), family = "sans", las = 1)

bp_err <- barplot(df_plot_err$Taux_Erreur_Post,
                  horiz = TRUE,
                  names.arg = df_plot_err$Genre,
                  col = couleurs_cat,
                  border = "#1B365D",
                  xlim = c(0, 115),
                  xlab = "Taux d'erreur d'identification au Post-test (%)",
                  main = "Classification de la difficulté des 19 genres selon le Taux d'Erreur (BAC 3 - 2024)",
                  cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                  cex.lab = 1.1, font.lab = 2,
                  cex.names = 1.0, font = 3)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp_err <- barplot(df_plot_err$Taux_Erreur_Post,
                  horiz = TRUE,
                  names.arg = df_plot_err$Genre,
                  col = couleurs_cat,
                  border = "#1B365D",
                  add = TRUE,
                  cex.names = 1.0, font = 3)

# DEMANDE UTILISATEUR : Pas de lignes pointillés verticales pour les seuils, la couleur suffit !
# (Suppression des abline et des labels "Seuil 10%", "Seuil 20%", "Seuil 35%")

# Barres d'erreur IC 95% Wilson sur les taux d'erreur
for (i in 1:n_g) {
  segments(df_plot_err$IC_Inf_Erreur_Post[i], bp_err[i], 
           df_plot_err$IC_Sup_Erreur_Post[i], bp_err[i], col = "#1B365D", lwd = 1.6)
  segments(df_plot_err$IC_Inf_Erreur_Post[i], bp_err[i] - 0.2, 
           df_plot_err$IC_Inf_Erreur_Post[i], bp_err[i] + 0.2, col = "#1B365D", lwd = 1.6)
  segments(df_plot_err$IC_Sup_Erreur_Post[i], bp_err[i] - 0.2, 
           df_plot_err$IC_Sup_Erreur_Post[i], bp_err[i] + 0.2, col = "#1B365D", lwd = 1.6)
  
  # Labels directs : % d'erreur et effectifs (n = erreurs / total)
  pos_x <- max(df_plot_err$Taux_Erreur_Post[i], df_plot_err$IC_Sup_Erreur_Post[i]) + 2
  text(pos_x, bp_err[i],
       sprintf("%.1f%% (n = %d/%d)", df_plot_err$Taux_Erreur_Post[i], 
               df_plot_err$Erreurs_Post[i], df_plot_err$N_Post[i]),
       font = 2, cex = 0.85, col = "#1B365D", pos = 4)
}

legend("bottomright",
       legend = c("Genre très difficile (>= 35% d'erreur)",
                  "Genre à difficultés modérées (20 à 34% d'erreur)",
                  "Genre accessible (10 à 19% d'erreur)",
                  "Genre facile (< 10% d'erreur)",
                  "Intervalle de confiance Wilson 95%"),
       fill = c("#C62828", "#E67E22", "#4A90E2", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", "#1B365D", "#1B365D", NA),
       lty = c(NA, NA, NA, NA, 1), col = c(NA, NA, NA, NA, "#1B365D"), lwd = c(NA, NA, NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95, inset = c(0.01, 0.01))

dev.off()
cat("  -> Figure 6 ajustée générée : output/figure6_taux_erreur_difficultes_genres.png\n")


# ------------------------------------------------------------------------------
# FIGURE 7 AJUSTÉE : Top confusions (Image agrandie à droite, zéro troncature)
# ------------------------------------------------------------------------------
# Fichier original "figure7_top_confusions_taxonomiques.png" conservé !
# Fichier ajusté généré : "figure7_top_confusions_taxonomiques_ajustee.png"

# Extraire les paires d'erreurs au post-test
post_long <- df_long_app[df_long_app$Cohorte == "Post-test", ]
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
df_err_all <- do.call(rbind, erreurs_list)
top_conf <- as.data.frame(sort(table(df_err_all$Paire), decreasing = TRUE)[1:10])
colnames(top_conf) <- c("Paire_Confusion", "Frequence")
top_conf_plot <- top_conf[order(top_conf$Frequence, decreasing = FALSE), ]

# DEMANDE UTILISATEUR : Agrandir l'image vers la droite et élargir xlim pour éliminer toute troncature
# Largeur passée à 4400 pixels, xlim étendu à max * 1.65, marge droite élargie à 5
png(file.path(dossier_output, "figure7_top_confusions_taxonomiques_ajustee.png"),
    width = 4400, height = 2400, res = 300, bg = "white")

par(mar = c(5, 17, 4, 5), family = "sans", las = 1)

max_freq <- max(top_conf_plot$Frequence)

bp_conf <- barplot(top_conf_plot$Frequence,
                   horiz = TRUE,
                   names.arg = top_conf_plot$Paire_Confusion,
                   col = "#8E44AD",
                   border = "#1B365D",
                   xlim = c(0, max_freq * 1.65), # Dégagement généreux de 65% à droite
                   xlab = "Nombre d'erreurs commises au Post-test",
                   main = "Principales confusions taxonomiques récurrentes post-formation (BAC 3 - 2024)",
                   cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                   cex.lab = 1.1, font.lab = 2, 
                   cex.names = 0.95, font = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

bp_conf <- barplot(top_conf_plot$Frequence,
                   horiz = TRUE,
                   names.arg = top_conf_plot$Paire_Confusion,
                   col = "#8E44AD",
                   border = "#1B365D",
                   add = TRUE, cex.names = 0.95, font = 2)

# Labels numériques parfaitement protégés de la bordure droite
text(top_conf_plot$Frequence + 0.25, bp_conf,
     sprintf("%d erreurs (%.1f%% des confusions)", 
             top_conf_plot$Frequence, 
             (top_conf_plot$Frequence / nrow(df_err_all)) * 100),
     font = 2, cex = 0.88, col = "#1B365D", pos = 4)

legend("bottomright",
       legend = c("Erreur d'identification (Genre attendu -> Genre confondu)"),
       fill = "#8E44AD", border = "#1B365D",
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95, inset = c(0.02, 0.02))

dev.off()
cat("  -> Figure 7 ajustée générée : output/figure7_top_confusions_taxonomiques_ajustee.png\n")

cat("\n======================================================================\n")
cat("=== TOUTES LES DEMANDES D'AJUSTEMENT SONT APPLIQUÉES AVEC SUCCÈS ===\n")
cat("======================================================================\n")
