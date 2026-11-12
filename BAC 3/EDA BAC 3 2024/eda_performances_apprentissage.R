# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - BAC 3 (2024)
# SCRIPT 2 : Analyse Exploratoire des Performances & de l'Apprentissage (Axe A)
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

# 1. CHARGEMENT DES DONNÉES WIDE & LONG ----------------------------------------
f_wide <- file.path(dossier_eda, "BAC3_2024_clean_wide.csv")
f_long <- file.path(dossier_eda, "BAC3_2024_clean_long.csv")

df_wide <- read.csv(f_wide, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

cat("======================================================================\n")
cat("=== ANALYSE EXPLORATOIRE DE L'APPRENTISSAGE (AXE A - BAC 3 2024) ===\n")
cat("======================================================================\n\n")

# Restriction à l'échantillon apparié strict (N = 25)
df_wide_app <- df_wide[df_wide$Apparie_Strict == TRUE, ]
df_long_app <- df_long[df_long$Apparie_Strict == TRUE, ]

# Vecteurs appariés
pre_wide_app  <- df_wide_app[df_wide_app$Cohorte == "Pré-test", ]
post_wide_app <- df_wide_app[df_wide_app$Cohorte == "Post-test", ]

# Tri parfait par ID
pre_wide_app  <- pre_wide_app[order(pre_wide_app$ID_Participant), ]
post_wide_app <- post_wide_app[order(post_wide_app$ID_Participant), ]

pre_scores  <- pre_wide_app$Score_Moodle_20
post_scores <- post_wide_app$Score_Moodle_20
delta_score <- post_scores - pre_scores

# Gain relatif de Dake : (Post - Pre) / (20 - Pre)
gain_relatif_dake <- ifelse(pre_scores < 20, round((delta_score / (20 - pre_scores)) * 100, 1), 0)

pre_idk  <- pre_wide_app$Nombre_IDK
post_idk <- post_wide_app$Nombre_IDK

# Durées sans les outliers extrêmes (> 300 min)
pre_duree_filtree  <- pre_wide_app$Duree_Minutes[pre_wide_app$Duree_Minutes < 300]
post_duree_filtree <- post_wide_app$Duree_Minutes[post_wide_app$Duree_Minutes < 300]

# 2. STATISTIQUES DESCRIPTIVES SYNTHÉTIQUES (TABLEAU AXE A) -------------------
calcul_stats <- function(x, nom_var) {
  data.frame(
    Variable = nom_var,
    N = length(na.omit(x)),
    Moyenne = round(mean(x, na.rm = TRUE), 2),
    Ecart_Type = round(sd(x, na.rm = TRUE), 2),
    Mediane = round(median(x, na.rm = TRUE), 2),
    IQR = round(IQR(x, na.rm = TRUE), 2),
    Q1 = round(quantile(x, 0.25, na.rm = TRUE), 2),
    Q3 = round(quantile(x, 0.75, na.rm = TRUE), 2),
    Min = round(min(x, na.rm = TRUE), 2),
    Max = round(max(x, na.rm = TRUE), 2),
    stringsAsFactors = FALSE
  )
}

tab_stats_app <- rbind(
  data.frame(Cohorte = "Pré-test (Initial)", calcul_stats(pre_scores, "Score (/20)")),
  data.frame(Cohorte = "Post-test (Après TP)", calcul_stats(post_scores, "Score (/20)")),
  data.frame(Cohorte = "Progression (Delta)", calcul_stats(delta_score, "Gain absolu (/20)")),
  data.frame(Cohorte = "Progression (Dake)", calcul_stats(gain_relatif_dake, "Gain relatif (%)")),
  data.frame(Cohorte = "Pré-test (Initial)", calcul_stats(pre_idk, "Nombre de 'Je ne sais pas' (/26)")),
  data.frame(Cohorte = "Post-test (Après TP)", calcul_stats(post_idk, "Nombre de 'Je ne sais pas' (/26)")),
  data.frame(Cohorte = "Pré-test (Session normale)", calcul_stats(pre_duree_filtree, "Durée réaliste (minutes)")),
  data.frame(Cohorte = "Post-test (Session normale)", calcul_stats(post_duree_filtree, "Durée réaliste (minutes)"))
)

cat("--- Tableau synthétique des performances d'apprentissage (N = 25 appariés) ---\n")
print(tab_stats_app[, c("Cohorte", "Variable", "N", "Moyenne", "Ecart_Type", "Mediane", "Min", "Max")])

exporter_excel_csv(tab_stats_app, file.path(dossier_output, "tableau_statistiques_descriptives_axe_a.csv"))

# Tableau des progressions individuelles
tab_individuel <- data.frame(
  ID = pre_wide_app$ID_Participant,
  Pre_Score_20 = pre_scores,
  Post_Score_20 = post_scores,
  Delta_Score = round(delta_score, 2),
  Gain_Relatif_Dake_Pct = gain_relatif_dake,
  Pre_IDK = pre_idk,
  Post_IDK = post_idk,
  Pre_Duree_Min = pre_wide_app$Duree_Minutes,
  Post_Duree_Min = post_wide_app$Duree_Minutes,
  stringsAsFactors = FALSE
)
tab_individuel <- tab_individuel[order(tab_individuel$Delta_Score, decreasing = TRUE), ]

exporter_excel_csv(tab_individuel, file.path(dossier_output, "tableau_progressions_individuelles_axe_a.csv"))

# 3. ANALYSE SELON LES CARACTÉRISTIQUES DU SPÉCIMEN (SEXE & GUILDE) -----------
# Calcul des taux de réussite par spécimen (Mâle vs Femelle, Parasite vs Non parasite)
calc_wilson <- function(succes, total) {
  p <- succes / total
  z <- 1.96
  denom <- 1 + (z^2 / total)
  centre <- (p + (z^2 / (2 * total))) / denom
  marge <- (z * sqrt((p * (1 - p) / total) + (z^2 / (4 * total^2)))) / denom
  c(Taux = round(p * 100, 2),
    IC_Inf = round(max(0, centre - marge) * 100, 2),
    IC_Sup = round(min(1, centre + marge) * 100, 2))
}

analyser_facteur <- function(facteur_col, nom_facteur) {
  modalites <- unique(df_long_app[[facteur_col]])
  res_list <- list()
  for (m in modalites) {
    sub_pre  <- df_long_app[df_long_app$Cohorte == "Pré-test" & df_long_app[[facteur_col]] == m, ]
    sub_post <- df_long_app[df_long_app$Cohorte == "Post-test" & df_long_app[[facteur_col]] == m, ]
    
    n_pre <- nrow(sub_pre); s_pre <- sum(sub_pre$Est_Correct_Moodle)
    n_post <- nrow(sub_post); s_post <- sum(sub_post$Est_Correct_Moodle)
    
    w_pre <- calc_wilson(s_pre, n_pre)
    w_post <- calc_wilson(s_post, n_post)
    
    res_list[[m]] <- data.frame(
      Facteur = nom_facteur,
      Modalite = m,
      N_Specimens = length(unique(sub_pre$Question_Num)),
      N_Obs_Pre = n_pre,
      Succes_Pre = s_pre,
      Taux_Pre = w_pre["Taux"],
      IC_Inf_Pre = w_pre["IC_Inf"],
      IC_Sup_Pre = w_pre["IC_Sup"],
      N_Obs_Post = n_post,
      Succes_Post = s_post,
      Taux_Post = w_post["Taux"],
      IC_Inf_Post = w_post["IC_Inf"],
      IC_Sup_Post = w_post["IC_Sup"],
      Gain_Absolu_Pct = round(w_post["Taux"] - w_pre["Taux"], 2),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, res_list)
}

tab_sexe   <- analyser_facteur("Sexe_Specimen", "Sexe du Spécimen")
tab_guilde <- analyser_facteur("Guilde_Solution", "Guilde Écologique")
tab_facteurs <- rbind(tab_sexe, tab_guilde)
rownames(tab_facteurs) <- NULL

cat("\n--- Taux de succès selon le Sexe et la Guilde écologique ---\n")
print(tab_facteurs[, c("Facteur", "Modalite", "N_Specimens", "Taux_Pre", "Taux_Post", "Gain_Absolu_Pct")])

exporter_excel_csv(tab_facteurs, file.path(dossier_output, "tableau_performances_sexe_guilde_axe_a.csv"))

# 4. VISUALISATIONS GRAPHIQUES HD (CONFORMES AGENTS.md) ------------------------

# FIGURE 1 : Comparaison des distributions et trajectoires de score (Pré vs Post)
png(file.path(dossier_output, "figure1_distributions_scores_pre_post.png"),
    width = 3200, height = 2200, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

b <- boxplot(list("Pré-test (Avant formation)" = pre_scores, 
                  "Post-test (Après TP)" = post_scores),
             col = c("#4A90E2", "#2E7D32"),
             border = c("#1B365D", "#1B365D"),
             ylim = c(0, 22),
             ylab = "Score d'identification (/20)",
             main = "Distribution des scores et trajectoires individuelles (BAC 3 - 2024, N = 25)",
             cex.main = 1.3, font.main = 2, col.main = "#1B365D",
             cex.lab = 1.1, font.lab = 2, outline = FALSE)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

boxplot(list("Pré-test (Avant formation)" = pre_scores, 
             "Post-test (Après TP)" = post_scores),
        col = c("#4A90E2", "#2E7D32"),
        border = c("#1B365D", "#1B365D"),
        add = TRUE, outline = FALSE)

# Trajectoires individuelles
set.seed(123)
jit_1 <- jitter(rep(1, length(pre_scores)), amount = 0.04)
jit_2 <- jitter(rep(2, length(post_scores)), amount = 0.04)

for (k in seq_along(pre_scores)) {
  lines(c(jit_1[k], jit_2[k]), c(pre_scores[k], post_scores[k]), 
        col = "#8E44AD44", lwd = 1.8)
  points(jit_1[k], pre_scores[k], pch = 21, bg = "#4A90E2", col = "#1B365D", cex = 1.3)
  points(jit_2[k], post_scores[k], pch = 21, bg = "#2E7D32", col = "#1B365D", cex = 1.3)
}

# Annotations directes
text(1, 21.2, sprintf("Moyenne = %.2f/20\n(Médiane = %.1f)", mean(pre_scores), median(pre_scores)),
     col = "#1B365D", font = 2, cex = 1.0)
text(2, 21.2, sprintf("Moyenne = %.2f/20\n(Médiane = %.1f)", mean(post_scores), median(post_scores)),
     col = "#1B365D", font = 2, cex = 1.0)

legend("bottomright",
       legend = c("Pré-test initial (N = 25)", "Post-test final (N = 25)", "Progression individuelle"),
       fill = c("#4A90E2", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", NA),
       lty = c(NA, NA, 1), col = c(NA, NA, "#8E44AD"), lwd = c(NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 1 générée : output/figure1_distributions_scores_pre_post.png\n")

# FIGURE 2 : Waterfall barplot des progressions individuelles
png(file.path(dossier_output, "figure2_progressions_individuelles_waterfall.png"),
    width = 3400, height = 2200, res = 300, bg = "white")

par(mar = c(6, 6, 4, 3), family = "sans", las = 1)

# Ordonner par delta croissant
ord <- order(tab_individuel$Delta_Score)
tab_ord <- tab_individuel[ord, ]

couleurs_barres <- ifelse(tab_ord$Delta_Score >= 8, "#2E7D32",
                          ifelse(tab_ord$Delta_Score >= 5, "#4A90E2", "#E67E22"))

bp <- barplot(tab_ord$Delta_Score,
              names.arg = tab_ord$ID,
              las = 2,
              col = couleurs_barres,
              border = "#1B365D",
              ylim = c(0, 16),
              ylab = "Gain de score (Post - Pré, sur 20)",
              main = "Progression individuelle de chaque étudiant (BAC 3 - 2024, N = 25)",
              cex.main = 1.3, font.main = 2, col.main = "#1B365D",
              cex.lab = 1.1, font.lab = 2, cex.names = 0.85)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

bp <- barplot(tab_ord$Delta_Score,
              names.arg = tab_ord$ID,
              las = 2,
              col = couleurs_barres,
              border = "#1B365D",
              add = TRUE, cex.names = 0.85)

# Ligne moyenne
abline(h = mean(tab_ord$Delta_Score), col = "#C62828", lwd = 2.5, lty = 2)
text(2, mean(tab_ord$Delta_Score) + 0.6, 
     sprintf("Gain moyen = +%.2f pts", mean(tab_ord$Delta_Score)),
     col = "#C62828", font = 2, pos = 4, cex = 1.0)

# Labels numériques au bout des barres
text(bp, tab_ord$Delta_Score + 0.5,
     sprintf("+%.1f", tab_ord$Delta_Score),
     cex = 0.75, font = 2, col = "#1B365D")

legend("topleft",
       legend = c("Gain élevé (>= 8 pts)", "Gain intermédiaire (5 à 7.9 pts)", "Gain modéré (< 5 pts)", "Moyenne du groupe (+7.44)"),
       fill = c("#2E7D32", "#4A90E2", "#E67E22", NA),
       border = c("#1B365D", "#1B365D", "#1B365D", NA),
       lty = c(NA, NA, NA, 2), col = c(NA, NA, NA, "#C62828"), lwd = c(NA, NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 2 générée : output/figure2_progressions_individuelles_waterfall.png\n")

# FIGURE 3 : Taux de succès selon le Sexe et la Guilde écologique
png(file.path(dossier_output, "figure3_succes_sexe_guilde.png"),
    width = 3200, height = 2200, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

# Préparation des barres groupées
labels_groupes <- c("Spécimens Femelles\n(12 taxons)", "Spécimens Mâles\n(14 taxons)",
                    "Non parasites\n(21 taxons)", "Cléptoparasites\n(5 taxons)")

taux_pre_grp  <- c(tab_sexe$Taux_Pre[tab_sexe$Modalite == "Femelle"],
                   tab_sexe$Taux_Pre[tab_sexe$Modalite == "Mâle"],
                   tab_guilde$Taux_Pre[tab_guilde$Modalite == "Non parasite"],
                   tab_guilde$Taux_Pre[tab_guilde$Modalite == "Cléptoparasite"])

taux_post_grp <- c(tab_sexe$Taux_Post[tab_sexe$Modalite == "Femelle"],
                   tab_sexe$Taux_Post[tab_sexe$Modalite == "Mâle"],
                   tab_guilde$Taux_Post[tab_guilde$Modalite == "Non parasite"],
                   tab_guilde$Taux_Post[tab_guilde$Modalite == "Cléptoparasite"])

mat_grp <- rbind("Pré-test" = taux_pre_grp, "Post-test" = taux_post_grp)

bp_grp <- barplot(mat_grp,
                  beside = TRUE,
                  col = c("#4A90E2", "#2E7D32"),
                  border = "#1B365D",
                  ylim = c(0, 100),
                  names.arg = labels_groupes,
                  ylab = "Taux de succès moyen (%)",
                  main = "Impact du Sexe et de la Guilde sur l'apprentissage (BAC 3 - 2024)",
                  cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                  cex.lab = 1.1, font.lab = 2)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

bp_grp <- barplot(mat_grp,
                  beside = TRUE,
                  col = c("#4A90E2", "#2E7D32"),
                  border = "#1B365D",
                  add = TRUE)

# Annotations directes des pourcentages
for (col_i in 1:4) {
  # Pré
  text(bp_grp[1, col_i], mat_grp[1, col_i] + 3,
       sprintf("%.1f%%", mat_grp[1, col_i]),
       font = 2, cex = 0.85, col = "#1B365D")
  # Post
  text(bp_grp[2, col_i], mat_grp[2, col_i] + 3,
       sprintf("%.1f%%", mat_grp[2, col_i]),
       font = 2, cex = 0.85, col = "#1B365D")
  # Gain au-dessus
  gain_val <- mat_grp[2, col_i] - mat_grp[1, col_i]
  text(mean(bp_grp[, col_i]), max(mat_grp[, col_i]) + 8,
       sprintf("Gain: +%.1f%%", gain_val),
       font = 2, cex = 0.9, col = "#8E44AD")
}

legend("topleft",
       legend = c("Pré-test initial", "Post-test après TP"),
       fill = c("#4A90E2", "#2E7D32"),
       border = "#1B365D",
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 1.0)

dev.off()
cat("  -> Figure 3 générée : output/figure3_succes_sexe_guilde.png\n")

# FIGURE 4 : Effondrement de l'incertitude ('Je ne sais pas')
png(file.path(dossier_output, "figure4_effondrement_incertitude_idk.png"),
    width = 3000, height = 2200, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

boxplot(list("Pré-test" = pre_idk, "Post-test" = post_idk),
        col = c("#E67E22", "#2E7D32"),
        border = "#1B365D",
        ylim = c(0, 28),
        ylab = "Nombre de réponses 'Je ne sais pas' (/26)",
        main = "Évolution de l'incertitude : effondrement des réponses 'Je ne sais pas'",
        cex.main = 1.3, font.main = 2, col.main = "#1B365D",
        cex.lab = 1.1, font.lab = 2, outline = FALSE)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

boxplot(list("Pré-test" = pre_idk, "Post-test" = post_idk),
        col = c("#E67E22", "#2E7D32"),
        border = "#1B365D",
        add = TRUE, outline = FALSE)

# Trajectoires IDK
set.seed(42)
jit_idk1 <- jitter(rep(1, length(pre_idk)), amount = 0.04)
jit_idk2 <- jitter(rep(2, length(post_idk)), amount = 0.04)

for (k in seq_along(pre_idk)) {
  lines(c(jit_idk1[k], jit_idk2[k]), c(pre_idk[k], post_idk[k]), 
        col = "#8E44AD44", lwd = 1.8)
  points(jit_idk1[k], pre_idk[k], pch = 21, bg = "#E67E22", col = "#1B365D", cex = 1.3)
  points(jit_idk2[k], post_idk[k], pch = 21, bg = "#2E7D32", col = "#1B365D", cex = 1.3)
}

text(1, 27, sprintf("Moyenne = %.1f / 26\n(Médiane = %d)", mean(pre_idk), median(pre_idk)), 
     font = 2, col = "#1B365D", cex = 0.95)
text(2, 27, sprintf("Moyenne = %.1f / 26\n(Médiane = %d)", mean(post_idk), median(post_idk)), 
     font = 2, col = "#1B365D", cex = 0.95)

legend("topright",
       legend = c("Pré-test (Forte incertitude)", "Post-test (Assurance accrue)", "Trajectoires individuelles"),
       fill = c("#E67E22", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", NA),
       lty = c(NA, NA, 1), col = c(NA, NA, "#8E44AD"), lwd = c(NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95)

dev.off()
cat("  -> Figure 4 générée : output/figure4_effondrement_incertitude_idk.png\n")

cat("\n======================================================================\n")
cat("=== SCRIPT 2 (AXE A - PERFORMANCES) EXÉCUTÉ AVEC SUCCÈS ===\n")
cat("======================================================================\n")

