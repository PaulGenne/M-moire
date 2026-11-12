# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - EPIC 2025
# SCRIPT 2 : Analyse Exploratoire des Performances & de l'Apprentissage (Axe A)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# 0. ENVIRONNEMENT & DOSSIERS --------------------------------------------------
dossier_eda <- "2025/EDA EPIC 2025"
if (!dir.exists(dossier_eda)) dossier_eda <- "."
dossier_output <- file.path(dossier_eda, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat("  -> Fichier CSV exporté :", chemin_fichier, "\n")
}

# 1. CHARGEMENT DES DONNÉES WIDE & LONG ----------------------------------------
f_wide <- file.path(dossier_eda, "EPIC_2025_clean_wide.csv")
f_long <- file.path(dossier_eda, "EPIC_2025_clean_long.csv")

if (!file.exists(f_wide)) {
  f_wide <- "EPIC_2025_clean_wide.csv"
  f_long <- "EPIC_2025_clean_long.csv"
}

df_wide <- read.csv(f_wide, sep = ";", dec = ",", stringsAsFactors = FALSE)
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE)

cat("======================================================================\n")
cat("          ANALYSE EXPLORATOIRE DE L'APPRENTISSAGE (AXE A)             \n")
cat("======================================================================\n\n")

pre_scores  <- df_wide$Score_Note_20[df_wide$Cohorte == "Pré-test"]
post_scores <- df_wide$Score_Note_20[df_wide$Cohorte == "Post-test"]

pre_pct  <- df_wide$Pourcentage_Reussite[df_wide$Cohorte == "Pré-test"]
post_pct <- df_wide$Pourcentage_Reussite[df_wide$Cohorte == "Post-test"]

pre_duree  <- df_wide$Duree_Minutes[df_wide$Cohorte == "Pré-test"]
post_duree <- df_wide$Duree_Minutes[df_wide$Cohorte == "Post-test"]

pre_idk  <- df_wide$Nombre_IDK[df_wide$Cohorte == "Pré-test"]
post_idk <- df_wide$Nombre_IDK[df_wide$Cohorte == "Post-test"]

# 2. STATISTIQUES DESCRIPTIVES COMPARATIVES -----------------------------------
calcul_stats <- function(x, nom_var) {
  c(
    Variable = nom_var,
    N = length(x),
    Moyenne = round(mean(x, na.rm = TRUE), 2),
    Ecart_Type = round(sd(x, na.rm = TRUE), 2),
    Mediane = round(median(x, na.rm = TRUE), 2),
    IQR = round(IQR(x, na.rm = TRUE), 2),
    Q1 = round(quantile(x, 0.25, na.rm = TRUE), 2),
    Q3 = round(quantile(x, 0.75, na.rm = TRUE), 2),
    Min = round(min(x, na.rm = TRUE), 2),
    Max = round(max(x, na.rm = TRUE), 2)
  )
}

tab_comp <- as.data.frame(rbind(
  c(Cohorte = "Pré-test", calcul_stats(pre_scores, "Score (/20)")),
  c(Cohorte = "Post-test", calcul_stats(post_scores, "Score (/20)")),
  c(Cohorte = "Pré-test", calcul_stats(pre_pct, "Réussite (%)")),
  c(Cohorte = "Post-test", calcul_stats(post_pct, "Réussite (%)")),
  c(Cohorte = "Pré-test", calcul_stats(pre_duree, "Durée (minutes)")),
  c(Cohorte = "Post-test", calcul_stats(post_duree, "Durée (minutes)")),
  c(Cohorte = "Pré-test", calcul_stats(pre_idk, "Nombre de 'Je ne sais pas'")),
  c(Cohorte = "Post-test", calcul_stats(post_idk, "Nombre de 'Je ne sais pas'"))
), stringsAsFactors = FALSE)

cat("--- Tableau comparatif synthétique ---\n")
print(tab_comp[, c("Cohorte", "Variable", "N", "Moyenne", "Ecart_Type", "Mediane", "Min", "Max")])
exporter_excel_csv(tab_comp, file.path(dossier_output, "tableau_comparatif_scores_pre_post.csv"))

# 3. ANALYSE SELON LES CARACTÉRISTIQUES DU SPÉCIMEN (SEXE ET GUILDE) -----------
cat("\n--- Taux de succès selon le Sexe du Spécimen ---\n")
agg_sexe <- aggregate(Est_Correct ~ Cohorte + Sexe_Specimen, data = df_long, FUN = function(x) {
  round(c(Taux = mean(x) * 100, N = length(x), Succes = sum(x)), 2)
})
print(agg_sexe)

cat("\n--- Taux de succès selon la Guilde (Non-parasite vs Cléptoparasite) ---\n")
agg_guilde <- aggregate(Est_Correct ~ Cohorte + Guilde_Solution, data = df_long, FUN = function(x) {
  round(c(Taux = mean(x) * 100, N = length(x), Succes = sum(x)), 2)
})
print(agg_guilde)

# ==============================================================================
# 4. VISUALISATIONS GRAPHIQUES CONFORMES CHARTE AGENTS.md (300 DPI)
# ==============================================================================
col_vert_succes   <- "#2E7D32" # Vert émeraude (Post / Succès)
col_rouge_erreur  <- "#C62828" # Rouge rubis (Erreurs / Pièges)
col_bleu_ardoise  <- "#4A90E2" # Bleu ardoise (Pré-test / Comparaison)
col_bleu_nuit     <- "#1B365D" # Bleu nuit foncé (Titres / Structure)
col_orange_diff   <- "#E67E22" # Ambre / Orange
col_violet        <- "#8E44AD" # Violet profond
col_gris_bord     <- "#D0D7DE"

# ------------------------------------------------------------------------------
# FIGURE 1 : Progression des Scores Pré-test vs Post-test
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig1_progression_scores_pre_post.png"), width = 3400, height = 2600, res = 300, bg = "white")
par(mar = c(5, 6, 4, 4), family = "sans")

bp_list <- list("Pré-test (N = 50)" = pre_scores, "Post-test (N = 49)" = post_scores)
bp <- boxplot(bp_list, col = c(col_bleu_ardoise, col_vert_succes), las = 1,
              ylab = "Note obtenue sur 20 (/20)", ylim = c(0, 27),
              main = "Gain d'apprentissage global : Pré-test vs Post-test (EPIC 2025)",
              boxwex = 0.45, border = c(col_bleu_nuit, "#1E5F22"),
              cex.lab = 1.1, font.lab = 2)
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

# Ligne seuil 10/20 et texte direct (sans masque blanc)
abline(h = 10, col = col_rouge_erreur, lty = 2, lwd = 1.2)
text(0.54, 10.4, "Seuil 10/20", col = col_rouge_erreur, adj = 0, cex = 0.85, font = 3)

# Ajout des points individuels (jitter horizontal)
set.seed(42)
stripchart(bp_list, vertical = TRUE, method = "jitter", jitter = 0.15,
           pch = 21, bg = c("#4A90E288", "#2E7D3288"), col = "white", cex = 1.2, add = TRUE)

# Annotations moyennes (losanges dorés sur les boxplots)
moy_pre <- mean(pre_scores)
moy_post <- mean(post_scores)
points(1:2, c(moy_pre, moy_post), pch = 18, col = "gold2", cex = 2.4)

# Textes d'annotation placés EN HAUT DANS L'ESPACE DÉGAGÉ (zéro chevauchement)
rect(0.68, 21.0, 1.32, 23.2, col = "#FFFFFFEE", border = col_gris_bord)
text(1, 22.1, labels = sprintf("Moyenne : %.2f /20\n(ET : %.2f)", moy_pre, sd(pre_scores)),
     font = 2, cex = 0.9, col = "black")

rect(1.68, 21.0, 2.32, 23.2, col = "#FFFFFFEE", border = col_gris_bord)
text(2, 22.1, labels = sprintf("Moyenne : %.2f /20\n(ET : %.2f)", moy_post, sd(post_scores)),
     font = 2, cex = 0.9, col = "black")

# Bracket de gain moyen au sommet (zéro collision avec les données)
segments(1, 24.5, 2, 24.5, col = col_vert_succes, lwd = 2.5)
segments(1, 24.0, 1, 24.5, col = col_vert_succes, lwd = 2.5)
segments(2, 24.0, 2, 24.5, col = col_vert_succes, lwd = 2.5)
rect(1.15, 24.8, 1.85, 26.3, col = "#FFFFFFEE", border = col_vert_succes, lwd = 1.5)
text(1.5, 25.55,
     labels = sprintf("Gain moyen : +%.2f points (+%.1f%%)", moy_post - moy_pre, ((moy_post - moy_pre) / 20) * 100),
     col = "black", font = 2, cex = 0.95)

dev.off()
cat("  -> Figure 1 générée : output/fig1_progression_scores_pre_post.png\n")

# ------------------------------------------------------------------------------
# FIGURE 2 : Distributions et Densités comparatives
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig2_distributions_densites_scores.png"), width = 3600, height = 2400, res = 300, bg = "white")
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2), family = "sans")

# Panneau A : Histogrammes superposés
bks <- seq(0, 20, by = 2)
h_pre <- hist(pre_scores, breaks = bks, plot = FALSE)
h_post <- hist(post_scores, breaks = bks, plot = FALSE)
max_h <- max(c(h_pre$counts, h_post$counts)) + 4

mat_hist <- rbind(h_pre$counts, h_post$counts)
bp_h <- barplot(mat_hist, beside = TRUE, col = c(col_bleu_ardoise, col_vert_succes),
                ylim = c(0, max_h), las = 1, xlab = "Note obtenue (/20, tranches de 2 points)",
                ylab = "Nombre de participants", main = "A. Histogramme comparatif des scores",
                names.arg = paste0("[", bks[-length(bks)], "-", bks[-1], "]"),
                border = "white", cex.names = 0.75)
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
legend("topleft", legend = c("Pré-test (Initial)", "Post-test (Final)"),
       fill = c(col_bleu_ardoise, col_vert_succes), bty = "o", bg = "#FFFFFFEE", box.col = col_gris_bord)

# Panneau B : Densités de probabilité
d_pre <- density(pre_scores, bw = 1.4)
d_post <- density(post_scores, bw = 1.4)

plot(d_post, col = col_vert_succes, lwd = 3.5, las = 1, xlim = c(0, 22), ylim = c(0, 0.22),
     main = "B. Courbes de densité des notes",
     xlab = "Note obtenue (/20)", ylab = "Densité de probabilité",
     cex.lab = 1.0, font.lab = 2)
polygon(d_post, col = rgb(0.18, 0.49, 0.20, 0.3), border = NA)
lines(d_pre, col = col_bleu_ardoise, lwd = 3.5)
polygon(d_pre, col = rgb(0.29, 0.56, 0.89, 0.3), border = NA)
grid(col = "grey90", lty = 1)

abline(v = moy_pre, col = col_bleu_nuit, lty = 2, lwd = 2)
abline(v = moy_post, col = "#1E5F22", lty = 2, lwd = 2)
text(moy_pre - 0.3, 0.20, sprintf("Moy. Pré : %.2f", moy_pre), adj = 1, font = 2, col = col_bleu_nuit, cex = 0.85)
text(moy_post + 0.3, 0.20, sprintf("Moy. Post : %.2f", moy_post), adj = 0, font = 2, col = "#1E5F22", cex = 0.85)

legend("topleft", legend = c("Pré-test (N = 50)", "Post-test (N = 49)"),
       fill = c(rgb(0.29, 0.56, 0.89, 0.5), rgb(0.18, 0.49, 0.20, 0.5)),
       border = c(col_bleu_ardoise, col_vert_succes), bg = "#FFFFFFEE", box.col = col_gris_bord)

dev.off()
cat("  -> Figure 2 générée : output/fig2_distributions_densites_scores.png\n")

# ------------------------------------------------------------------------------
# FIGURE 3 : Durée de Passation vs Performance
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig3_duree_vs_performance_pre_post.png"), width = 3400, height = 2400, res = 300, bg = "white")
par(mar = c(5, 6, 4, 4), family = "sans")

plot(df_wide$Duree_Minutes, df_wide$Score_Note_20, log = "x",
     col = ifelse(df_wide$Cohorte == "Pré-test", col_bleu_ardoise, col_vert_succes),
     pch = ifelse(df_wide$Cohorte == "Pré-test", 16, 17), cex = 1.5, las = 1,
     xlab = "Durée de la tentative (minutes, échelle log)", ylab = "Score obtenu sur 20 (/20)",
     main = "Relation entre temps investi et performance (EPIC 2025)",
     xlim = c(5, 20000), ylim = c(0, 22))
grid(col = "grey90", lty = 1)

# Ligne repère 60 min et 24h
abline(v = 60, col = "grey60", lty = 3)
text(60, 1.0, " 1 heure", adj = 0, cex = 0.8, col = "grey40")
abline(v = 1440, col = "grey60", lty = 3)
text(1440, 1.0, " 24 heures (sessions ouvertes)", adj = 0, cex = 0.8, col = "grey40")

# Droites de tendance linéaires (sur log-durée)
fit_pre <- lm(Score_Note_20 ~ log10(Duree_Minutes), data = df_wide[df_wide$Cohorte == "Pré-test", ])
fit_post <- lm(Score_Note_20 ~ log10(Duree_Minutes), data = df_wide[df_wide$Cohorte == "Post-test", ])
x_grid <- seq(5, 15000, length.out = 100)
lines(x_grid, predict(fit_pre, newdata = data.frame(Duree_Minutes = x_grid)), col = col_bleu_nuit, lwd = 2.5)
lines(x_grid, predict(fit_post, newdata = data.frame(Duree_Minutes = x_grid)), col = "#1E5F22", lwd = 2.5)

legend("topleft",
       legend = c(
         sprintf("Pré-test (r = %.2f)", cor(log10(pre_duree), pre_scores, use = "complete.obs")),
         sprintf("Post-test (r = %.2f)", cor(log10(post_duree), post_scores, use = "complete.obs"))
       ),
       col = c(col_bleu_ardoise, col_vert_succes), pch = c(16, 17), lty = 1, lwd = 2,
       bg = "#FFFFFFEE", box.col = col_gris_bord, cex = 0.9)

dev.off()
cat("  -> Figure 3 générée : output/fig3_duree_vs_performance_pre_post.png\n")

# ------------------------------------------------------------------------------
# FIGURE 4 : Effondrement de l'incertitude (IDK) et effets Sexe / Guilde
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig4_effondrement_idk_omissions.png"), width = 3600, height = 2600, res = 300, bg = "white")
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2), family = "sans")

# Panneau A : Effondrement du "Je ne sais pas"
bp_idk <- boxplot(list("Pré-test" = pre_idk, "Post-test" = post_idk),
                  col = c(col_bleu_ardoise, col_vert_succes), las = 1,
                  ylab = "Nombre de 'Je ne sais pas' choisis (sur 30 questions)",
                  main = "A. Recul massif de l'aveu d'incompétence",
                  boxwex = 0.45, border = c(col_bleu_nuit, "#1E5F22"), ylim = c(0, 33))
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

# Losanges dorés pour moyennes
points(1:2, c(mean(pre_idk), mean(post_idk)), pch = 18, col = "gold2", cex = 2.4)

# Moyennes affichées dans l'espace dégagé du haut (zéro collision)
rect(0.68, 24.5, 1.32, 26.5, col = "#FFFFFFEE", border = col_gris_bord)
text(1, 25.5, sprintf("Moyenne : %.1f", mean(pre_idk)), font = 2, cex = 0.9, col = "black")

rect(1.68, 24.5, 2.32, 26.5, col = "#FFFFFFEE", border = col_gris_bord)
text(2, 25.5, sprintf("Moyenne : %.1f", mean(post_idk)), font = 2, cex = 0.9, col = "black")

# Bracket de réduction au sommet (zéro chevauchement avec la boîte ou les points)
segments(1, 28.5, 2, 28.5, col = col_rouge_erreur, lwd = 2.5)
segments(1, 27.8, 1, 28.5, col = col_rouge_erreur, lwd = 2.5)
segments(2, 27.8, 2, 28.5, col = col_rouge_erreur, lwd = 2.5)

rect(1.05, 29.2, 1.95, 31.8, col = "#FFFFFFEE", border = col_rouge_erreur, lwd = 1.5)
text(1.5, 30.5,
     sprintf("Chute de -%.1f%%\ndes aveux d'incompétence", ((mean(pre_idk) - mean(post_idk)) / mean(pre_idk)) * 100),
     col = "black", font = 2, cex = 0.85)

# Panneau B : Comparaison par Sexe et par Guilde
mat_facteurs <- matrix(c(
  mean(df_long$Est_Correct[df_long$Cohorte == "Pré-test" & df_long$Sexe_Specimen == "Femelle"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Post-test" & df_long$Sexe_Specimen == "Femelle"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Pré-test" & df_long$Sexe_Specimen == "Mâle"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Post-test" & df_long$Sexe_Specimen == "Mâle"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Pré-test" & df_long$Guilde_Solution == "Non parasite"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Post-test" & df_long$Guilde_Solution == "Non parasite"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Pré-test" & df_long$Guilde_Solution == "Cléptoparasite"]) * 100,
  mean(df_long$Est_Correct[df_long$Cohorte == "Post-test" & df_long$Guilde_Solution == "Cléptoparasite"]) * 100
), nrow = 2)

bp_fac <- barplot(mat_facteurs, beside = TRUE, col = c(col_bleu_ardoise, col_vert_succes),
                  ylim = c(0, 120), las = 1, ylab = "Taux de réussite moyen (%)",
                  main = "B. Taux de succès selon Sexe et Guilde",
                  names.arg = c("Femelles", "Mâles", "Non parasites", "Coucous"),
                  border = "white", cex.names = 0.9)
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

# Valeurs textuelles sur barres (en noir, dégagées du sommet)
text(bp_fac[1, ], mat_facteurs[1, ] + 3.5, sprintf("%.1f%%", mat_facteurs[1, ]), font = 2, cex = 0.8, col = "black")
text(bp_fac[2, ], mat_facteurs[2, ] + 3.5, sprintf("%.1f%%", mat_facteurs[2, ]), font = 2, cex = 0.8, col = "black")

# Légende placée en haut à droite avec dégagement (aucun chevauchement)
legend("topright", legend = c("Pré-test", "Post-test"),
       fill = c(col_bleu_ardoise, col_vert_succes), bty = "o", bg = "#FFFFFFEE", box.col = col_gris_bord, cex = 0.9)

dev.off()
cat("  -> Figure 4 générée : output/fig4_effondrement_idk_omissions.png\n")

cat("\nAnalyse Axe A (Performances & Apprentissage) terminée avec succès !\n")
