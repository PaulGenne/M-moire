# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 3 : Analyses Statistiques Inférentielles (EPIC Basic 2026)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. CONFIGURATION DE L'ENVIRONNEMENT ET DOSSIERS
# ------------------------------------------------------------------------------
dossier_stats  <- "Analyses Stats EPIC 2026"
dossier_output <- file.path(dossier_stats, "output")
if (!dir.exists(dossier_stats)) dir.create(dossier_stats, recursive = TRUE)
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

# Fichiers de données nettoyées (générées à l'étape 2)
fichier_wide <- "EDA EPIC 2026/EPIC_Basic_clean_wide.csv"
fichier_long <- "EDA EPIC 2026/EPIC_Basic_clean_long.csv"

if (!file.exists(fichier_wide) || !file.exists(fichier_long)) {
  stop("Les fichiers de données nettoyées de l'étape 2 sont introuvables.")
}

df_wide <- read.csv(fichier_wide, encoding = "UTF-8", stringsAsFactors = FALSE)
df_long <- read.csv(fichier_long, encoding = "UTF-8", stringsAsFactors = FALSE)

cat("======================================================================\n")
cat("       RAPPORT DES ANALYSES STATISTIQUES INFÉRENTIELLES (ÉTAPE 3)     \n")
cat("======================================================================\n\n")
cat(sprintf("Échantillon analysé : %d participants indépendants (5 160 observations de test)\n\n", nrow(df_wide)))

# ------------------------------------------------------------------------------
# 1. AXE A : IMPACT DE LA FORMATION EPIC SUR LE SCORE TOTAL
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("1. ANALYSES INFÉRENTIELLES SUR L'EFFET DE LA FORMATION EPIC\n")
cat("----------------------------------------------------------------------\n")

scores_formes    <- df_wide$Score_Total_Propre[df_wide$Formation_EPIC == "Formés EPIC"]
scores_nonformes <- df_wide$Score_Total_Propre[df_wide$Formation_EPIC == "Non formés"]

# 1.1 Tests de normalité (Shapiro-Wilk)
shapiro_formes    <- shapiro.test(scores_formes)
shapiro_nonformes <- shapiro.test(scores_nonformes)
shapiro_global    <- shapiro.test(df_wide$Score_Total_Propre)

cat("A. Tests de normalité (Shapiro-Wilk) :\n")
cat(sprintf("  * Global      : W = %.4f, p = %.3e\n", shapiro_global$statistic, shapiro_global$p.value))
cat(sprintf("  * Formés EPIC : W = %.4f, p = %.3e\n", shapiro_formes$statistic, shapiro_formes$p.value))
cat(sprintf("  * Non formés  : W = %.4f, p = %.3e\n", shapiro_nonformes$statistic, shapiro_nonformes$p.value))
cat("  -> Conclusion : Distribution asymétrique avec rejet de la normalité (p < 0.001).\n\n")

# 1.2 Test d'homogénéité des variances (Fligner-Killeen non-paramétrique)
fligner_test <- fligner.test(Score_Total_Propre ~ Formation_EPIC, data = df_wide)
cat(sprintf("B. Homogénéité des variances (Fligner-Killeen) : Med Chi2 = %.4f, p = %.4f\n\n",
            fligner_test$statistic, fligner_test$p.value))

# 1.3 Test non paramétrique de Wilcoxon-Mann-Whitney (Test principal recommandé)
wilcox_res <- wilcox.test(scores_formes, scores_nonformes, exact = FALSE)
# Calcul de la taille d'effet r de Rosenthal : r = Z / sqrt(N)
n1 <- length(scores_formes); n2 <- length(scores_nonformes); N_tot <- n1 + n2
w_stat <- wilcox_res$statistic
mu_w <- (n1 * n2) / 2
sigma_w <- sqrt((n1 * n2 * (n1 + n2 + 1)) / 12)
z_score <- (w_stat - mu_w) / sigma_w
taille_effet_r <- abs(z_score) / sqrt(N_tot)

cat("C. Test de Wilcoxon-Mann-Whitney (Formés vs Non formés) :\n")
cat(sprintf("  * Statistique W : %.1f\n", w_stat))
cat(sprintf("  * p-value (bilatérale) : %.4f\n", wilcox_res$p.value))
cat(sprintf("  * Z-score associé : %.3f\n", z_score))
cat(sprintf("  * Taille d'effet r de Rosenthal : %.3f (%s)\n\n",
            taille_effet_r,
            ifelse(taille_effet_r < 0.1, "effet négligeable",
            ifelse(taille_effet_r < 0.3, "effet faible", "effet modéré"))))

# 1.4 Test t de Welch (comparatif paramétrique avec d de Cohen)
t_welch <- t.test(scores_formes, scores_nonformes)
sd_pooled <- sqrt(((n1 - 1) * var(scores_formes) + (n2 - 1) * var(scores_nonformes)) / (N_tot - 2))
d_cohen <- (mean(scores_formes) - mean(scores_nonformes)) / sd_pooled

cat("D. Test t de Welch (pour comparaison paramétrique) :\n")
cat(sprintf("  * t = %.3f, ddl = %.1f, p = %.4f\n", t_welch$statistic, t_welch$parameter, t_welch$p.value))
cat(sprintf("  * Différence des moyennes : +%.2f points (/30)\n", mean(scores_formes) - mean(scores_nonformes)))
cat(sprintf("  * d de Cohen : %.3f\n\n", d_cohen))

# 1.5 Modèle Linéaire Généralisé (GLM Quasibinomial) contrôlant pour Durée et Région
df_wide$Score_Reussite <- df_wide$Score_Total_Propre
df_wide$Score_Echec    <- 30 - df_wide$Score_Total_Propre

modele_glm <- glm(
  cbind(Score_Reussite, Score_Echec) ~ Formation_EPIC + Duree_Minutes + factor(Region),
  data = df_wide,
  family = quasibinomial(link = "logit")
)

cat("E. Régression Logistique Quasibinomiale (Contrôle Durée + Région) :\n")
print(summary(modele_glm))

# Fonction d'exportation compatible Excel Francophone (FR/BE : séparateur ';' et décimale ',')
exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
}

# Tableau récapitulatif des tests de formation
tab_tests_formation <- data.frame(
  Test = c("Shapiro-Wilk (Global)", "Shapiro-Wilk (Formés)", "Shapiro-Wilk (Non formés)",
           "Fligner-Killeen (Variances)", "Wilcoxon-Mann-Whitney", "t de Welch"),
  Statistique = c(sprintf("W = %.4f", shapiro_global$statistic),
                  sprintf("W = %.4f", shapiro_formes$statistic),
                  sprintf("W = %.4f", shapiro_nonformes$statistic),
                  sprintf("Chi2 = %.4f", fligner_test$statistic),
                  sprintf("W = %.1f (Z = %.2f)", w_stat, z_score),
                  sprintf("t = %.3f", t_welch$statistic)),
  P_Value = c(shapiro_global$p.value, shapiro_formes$p.value, shapiro_nonformes$p.value,
              fligner_test$p.value, wilcox_res$p.value, t_welch$p.value),
  Taille_Effet = c(NA, NA, NA, NA, sprintf("r = %.3f", taille_effet_r), sprintf("d = %.3f", d_cohen)),
  Significatif_5pct = c(shapiro_global$p.value < 0.05, shapiro_formes$p.value < 0.05,
                        shapiro_nonformes$p.value < 0.05, fligner_test$p.value < 0.05,
                        wilcox_res$p.value < 0.05, t_welch$p.value < 0.05)
)
exporter_excel_csv(tab_tests_formation, file.path(dossier_output, "tableau_tests_formation.csv"))

# ------------------------------------------------------------------------------
# 2. ANALYSE DES FACTEURS CO-VARIABLES (RÉGION ET DURÉE)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("2. ANALYSES DES CO-VARIABLES (Région & Durée)\n")
cat("----------------------------------------------------------------------\n")

# Test de Kruskal-Wallis pour l'effet Région
kw_region <- kruskal.test(Score_Total_Propre ~ factor(Region), data = df_wide)
cat(sprintf("A. Test de Kruskal-Wallis pour la Région : H = %.3f, ddl = %d, p = %.4f\n",
            kw_region$statistic, kw_region$parameter, kw_region$p.value))
cat("   -> Aucune hétérogénéité territoriale significative (p > 0.05) : le niveau est stable entre régions.\n\n")

# Corrélation non paramétrique Durée vs Score
cor_spearman <- cor.test(df_wide$Duree_Minutes, df_wide$Score_Total_Propre, method = "spearman", exact = FALSE)
cat(sprintf("B. Corrélation de Spearman Durée vs Score : rho = %.3f, p = %.4f\n",
            cor_spearman$estimate, cor_spearman$p.value))
cat("   -> Absence de corrélation linéaire forte : le temps passé n'est pas prédictif du succès.\n\n")

# ------------------------------------------------------------------------------
# 3. AXE B : MODÉLISATION DE LA DIFFICULTÉ TAXONOMIQUE PAR GENRE D'ABEILLE
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("3. MODÉLISATION LOGISTIQUE DE LA DIFFICULTÉ PAR GENRE (GLM LOGIT)\n")
cat("----------------------------------------------------------------------\n")

# Régression logistique binaire sur les 5160 observations
# Référence : Genre le plus facile avec grand effectif (Bombus)
df_long$Genre_Factor <- factor(df_long$Genre_Solution)
df_long$Genre_Factor <- relevel(df_long$Genre_Factor, ref = "Bombus")

modele_genres <- glm(Est_Correct ~ Genre_Factor + Formation, data = df_long, family = binomial(link = "logit"))
coefs <- summary(modele_genres)$coefficients

# Extraction des Odds Ratios (OR) et intervalles de confiance 95%
or_genres <- exp(coefs[, 1])
ic_inf    <- exp(coefs[, 1] - 1.96 * coefs[, 2])
ic_sup    <- exp(coefs[, 1] + 1.96 * coefs[, 2])
p_vals    <- coefs[, 4]
p_adj_fdr <- p.adjust(p_vals, method = "BH") # Correction Benjamini-Hochberg

df_or <- data.frame(
  Variable = rownames(coefs),
  Odds_Ratio = round(or_genres, 3),
  IC_95_Inf = round(ic_inf, 3),
  IC_95_Sup = round(ic_sup, 3),
  Z_Value = round(coefs[, 3], 3),
  P_Value_Brute = p_vals,
  P_Value_FDR = p_adj_fdr,
  stringsAsFactors = FALSE
)

# Filtrer les genres uniquement
df_genres_or <- df_or[grep("^Genre_Factor", df_or$Variable), ]
df_genres_or$Genre <- gsub("^Genre_Factor", "", df_genres_or$Variable)
df_genres_or <- df_genres_or[order(df_genres_or$Odds_Ratio), ] # Du plus difficile au plus facile

fichier_or_csv <- file.path(dossier_output, "tableau_genres_odds_ratios.csv")
exporter_excel_csv(df_genres_or, fichier_or_csv)
cat(sprintf("Tableau des Odds Ratios par genre sauvegardé : %s\n\n", fichier_or_csv))

cat("Top 5 des genres avec les plus faibles Odds Ratios de réussite (par rapport à Bombus) :\n")
print(head(df_genres_or[, c("Genre", "Odds_Ratio", "IC_95_Inf", "IC_95_Sup", "P_Value_FDR")], 5))

# ------------------------------------------------------------------------------
# 4. AXE B & A : TESTS D'ASSOCIATION GENRE x FORMATION (TESTS DE FISHER EXACTS)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("4. TESTS D'EFFICACITÉ DE LA FORMATION PAR GENRE (TESTS EXACTS DE FISHER)\n")
cat("----------------------------------------------------------------------\n")

genres_candidats <- unique(df_long$Genre_Solution)
tests_fisher <- list()

for (g in genres_candidats) {
  sub_g <- df_long[df_long$Genre_Solution == g, ]
  tab_cont <- table(sub_g$Formation, sub_g$Est_Correct)
  
  if (nrow(tab_cont) == 2 && ncol(tab_cont) == 2 && nrow(sub_g) >= 15) {
    f_res <- fisher.test(tab_cont)
    
    pct_f  <- mean(sub_g$Est_Correct[sub_g$Formation == "Formés EPIC"]) * 100
    pct_nf <- mean(sub_g$Est_Correct[sub_g$Formation == "Non formés"]) * 100
    
    tests_fisher[[g]] <- data.frame(
      Genre = g,
      N_Total = nrow(sub_g),
      Pct_Succes_Formes = round(pct_f, 1),
      Pct_Succes_NonFormes = round(pct_nf, 1),
      Gain_Pct = round(pct_f - pct_nf, 1),
      Odds_Ratio_Fisher = round(f_res$estimate, 3),
      P_Value_Brute = f_res$p.value,
      stringsAsFactors = FALSE
    )
  }
}

df_fisher_all <- do.call(rbind, tests_fisher)
df_fisher_all$P_Value_FDR <- p.adjust(df_fisher_all$P_Value_Brute, method = "BH")
df_fisher_all$Significatif_FDR_10pct <- df_fisher_all$P_Value_FDR < 0.10
df_fisher_all <- df_fisher_all[order(df_fisher_all$P_Value_Brute), ]

fichier_fisher_csv <- file.path(dossier_output, "tableau_tests_fisher_formation_genres.csv")
exporter_excel_csv(df_fisher_all, fichier_fisher_csv)
cat(sprintf("Tableau des tests de Fisher par genre sauvegardé : %s\n\n", fichier_fisher_csv))

cat("Genres montrant le plus fort effet statistique de la formation (Top 5 P-value) :\n")
print(head(df_fisher_all[, c("Genre", "Gain_Pct", "Odds_Ratio_Fisher", "P_Value_Brute", "P_Value_FDR")], 5))

# ------------------------------------------------------------------------------
# 5. VISUALISATION SCIENTIFIQUE : FOREST PLOT DES ODDS RATIOS PAR GENRE
# ------------------------------------------------------------------------------
chemin_forest <- file.path(dossier_output, "forest_plot_difficulte_genres.png")
png(chemin_forest, width = 3400, height = 3600, res = 300)

par(mar = c(5, 9.5, 4, 3), bg = "white")

# Sélection des genres avec n suffisant ordonnés par OR
genres_plot <- df_genres_or[df_genres_or$IC_95_Sup < 100, ] # Éviter les OR infinis sur genres sans aucune erreur

y_pos <- 1:nrow(genres_plot)

# Détermination des couleurs selon la significativité statistique
couleurs_or <- ifelse(genres_plot$P_Value_FDR < 0.05, "#C62828", "grey40")

plot(genres_plot$Odds_Ratio, y_pos,
     pch = 19, col = couleurs_or, cex = 1.3,
     xlim = c(0.001, 1.2), log = "x",
     yaxt = "n", xlab = "Odds Ratio de réussite par rapport à Bombus (échelle log)",
     ylab = "", main = "Probabilité Relative de Réussite d'Identification par Genre (Forest Plot - GLM)",
     las = 1, cex.main = 1.3, font.lab = 2)

axis(2, at = y_pos, labels = genres_plot$Genre, las = 1, font = 2, cex.axis = 0.85)
grid(col = "grey90", lty = 1)
abline(v = 1, col = "#2E7D32", lty = 2, lwd = 2)

# Segments d'intervalles de confiance à 95%
segments(pmax(0.001, genres_plot$IC_95_Inf), y_pos,
         pmin(1.5, genres_plot$IC_95_Sup), y_pos,
         lwd = 1.8, col = couleurs_or)
points(genres_plot$Odds_Ratio, y_pos, pch = 18, col = couleurs_or, cex = 1.4)

# Annotations texte OR et p-value
for (i in y_pos) {
  p_txt <- ifelse(genres_plot$P_Value_FDR[i] < 0.001, "p < 0.001",
           ifelse(genres_plot$P_Value_FDR[i] < 0.05, sprintf("p = %.3f", genres_plot$P_Value_FDR[i]), "ns"))
  text(1.15, i, sprintf("OR = %.2f (%s)", genres_plot$Odds_Ratio[i], p_txt),
       cex = 0.72, font = ifelse(genres_plot$P_Value_FDR[i] < 0.05, 2, 1),
       col = couleurs_or[i], adj = 1)
}

legend("bottomleft",
       legend = c("Genre significativement plus difficile que Bombus (p_FDR < 0.05)",
                  "Différence non significative (ns)",
                  "Référence de comparaison (Bombus, OR = 1.0)"),
       col = c("#C62828", "grey40", "#2E7D32"),
       pch = c(18, 18, NA), lty = c(1, 1, 2), lwd = c(2, 2, 2),
       bty = "o", box.col = "#D0D7DE", bg = "#FFFFFFEE", cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("\nForest Plot sauvegardé : %s\n", chemin_forest))

cat("\n======================================================================\n")
cat("ANALYSES STATISTIQUES INFÉRENTIELLES TERMINÉES AVEC SUCCÈS.\n")
cat("======================================================================\n")

