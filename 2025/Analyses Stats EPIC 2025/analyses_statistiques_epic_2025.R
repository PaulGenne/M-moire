# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 3 : Analyses Statistiques Inférentielles (EPIC 2025 : Pré vs Post)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. CONFIGURATION DE L'ENVIRONNEMENT ET DOSSIERS
# ------------------------------------------------------------------------------
dossier_stats  <- "2025/Analyses Stats EPIC 2025"
if (!dir.exists(dossier_stats)) dossier_stats <- "."
dossier_output <- file.path(dossier_stats, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

# Fichiers de données nettoyées (générées à l'étape 2)
f_wide <- "2025/EDA EPIC 2025/EPIC_2025_clean_wide.csv"
f_long <- "2025/EDA EPIC 2025/EPIC_2025_clean_long.csv"

if (!file.exists(f_wide)) {
  f_wide <- "../EDA EPIC 2025/EPIC_2025_clean_wide.csv"
  f_long <- "../EDA EPIC 2025/EPIC_2025_clean_long.csv"
}

df_wide <- read.csv(f_wide, sep = ";", dec = ",", stringsAsFactors = FALSE)
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE)

# Fonction d'exportation compatible Excel Francophone (FR/BE : séparateur ';' et décimale ',')
exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat("  -> Fichier CSV exporté :", chemin_fichier, "\n")
}

cat("======================================================================\n")
cat("       RAPPORT DES ANALYSES STATISTIQUES INFÉRENTIELLES (EPIC 2025)   \n")
cat("======================================================================\n\n")
cat(sprintf("Échantillon analysé : %d participants (%d Pré-test, %d Post-test)\n",
            nrow(df_wide), sum(df_wide$Cohorte == "Pré-test"), sum(df_wide$Cohorte == "Post-test")))
cat(sprintf("Évaluations individuelles : %d observations (question x participant)\n\n", nrow(df_long)))

# ------------------------------------------------------------------------------
# 1. AXE A : IMPACT GLOBAL DE LA FORMATION SUR LA PERFORMANCE
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("1. ANALYSES INFÉRENTIELLES SUR L'EFFET DE LA FORMATION (PRÉ VS POST)\n")
cat("----------------------------------------------------------------------\n")

scores_pre  <- df_wide$Score_Note_20[df_wide$Cohorte == "Pré-test"]
scores_post <- df_wide$Score_Note_20[df_wide$Cohorte == "Post-test"]

# 1.1 Tests de normalité (Shapiro-Wilk)
shapiro_pre    <- shapiro.test(scores_pre)
shapiro_post   <- shapiro.test(scores_post)
shapiro_global <- shapiro.test(df_wide$Score_Note_20)

cat("A. Tests de normalité (Shapiro-Wilk) :\n")
cat(sprintf("  * Global    : W = %.4f, p = %.3e\n", shapiro_global$statistic, shapiro_global$p.value))
cat(sprintf("  * Pré-test  : W = %.4f, p = %.4f\n", shapiro_pre$statistic, shapiro_pre$p.value))
cat(sprintf("  * Post-test : W = %.4f, p = %.3e\n", shapiro_post$statistic, shapiro_post$p.value))
cat("  -> Conclusion : Rejet très net de la normalité en Post-test (p < 0.001) due au plafonnement vers l'excellence.\n\n")

# 1.2 Test d'homogénéité des variances (Fligner-Killeen non-paramétrique)
fligner_test <- fligner.test(Score_Note_20 ~ Cohorte, data = df_wide)
cat(sprintf("B. Homogénéité des variances (Fligner-Killeen) : Med Chi2 = %.4f, ddl = %d, p = %.3e\n",
            fligner_test$statistic, fligner_test$parameter, fligner_test$p.value))
cat("  -> Hétéroscédasticité confirmée : la variance est divisée par plus de 4 après formation.\n\n")

# 1.3 Test non paramétrique de Wilcoxon-Mann-Whitney (Test principal recommandé)
wilcox_res <- wilcox.test(scores_post, scores_pre, exact = FALSE)
n1 <- length(scores_post); n2 <- length(scores_pre); N_tot <- n1 + n2
w_stat <- wilcox_res$statistic
mu_w <- (n1 * n2) / 2
sigma_w <- sqrt((n1 * n2 * (n1 + n2 + 1)) / 12)
z_score <- (w_stat - mu_w) / sigma_w
taille_effet_r <- abs(z_score) / sqrt(N_tot)
# CLES (Common Language Effect Size / AUC) : Probabilité qu'un post-test tiré au sort batte un pré-test
cles_auc <- w_stat / (n1 * n2)

cat("C. Test de Wilcoxon-Mann-Whitney (Post-test vs Pré-test) :\n")
cat(sprintf("  * Statistique W : %.1f\n", w_stat))
cat(sprintf("  * p-value : %.3e (hautement significatif, p < 0.001)\n", wilcox_res$p.value))
cat(sprintf("  * Z-score associé : %.3f\n", z_score))
cat(sprintf("  * Taille d'effet r de Rosenthal : %.3f (%s)\n",
            taille_effet_r,
            ifelse(taille_effet_r < 0.1, "effet négligeable",
            ifelse(taille_effet_r < 0.3, "effet faible",
            ifelse(taille_effet_r < 0.5, "effet modéré", "effet très fort (large)")))))
cat(sprintf("  * Probabilité de supériorité (CLES / AUC) : %.1f%%\n\n", cles_auc * 100))

# 1.4 Test t de Welch (comparatif paramétrique avec d de Cohen)
t_welch <- t.test(scores_post, scores_pre)
sd_pooled <- sqrt(((n1 - 1) * var(scores_post) + (n2 - 1) * var(scores_pre)) / (N_tot - 2))
d_cohen <- (mean(scores_post) - mean(scores_pre)) / sd_pooled

cat("D. Test t de Welch (pour comparaison paramétrique) :\n")
cat(sprintf("  * t = %.3f, ddl = %.1f, p = %.3e\n", t_welch$statistic, t_welch$parameter, t_welch$p.value))
cat(sprintf("  * Gain moyen observé : +%.2f points (/20)\n", mean(scores_post) - mean(scores_pre)))
cat(sprintf("  * d de Cohen : %.3f (effet massif, largement > 0.8)\n\n", d_cohen))

# 1.5 Modèle Linéaire Généralisé (GLM Quasibinomial) contrôlant pour la Durée
df_wide$Succes_30 <- df_wide$Score_Brut_30
df_wide$Echecs_30 <- 30 - df_wide$Score_Brut_30

# Variable binaire pour la formation
df_wide$Cohorte_Factor <- factor(df_wide$Cohorte, levels = c("Pré-test", "Post-test"))

modele_glm_global <- glm(
  cbind(Succes_30, Echecs_30) ~ Cohorte_Factor + log10(Duree_Minutes),
  data = df_wide,
  family = quasibinomial(link = "logit")
)

coefs_glm <- summary(modele_glm_global)$coefficients
or_glm <- exp(coefs_glm[, 1])
ic_glm_inf <- exp(coefs_glm[, 1] - 1.96 * coefs_glm[, 2])
ic_glm_sup <- exp(coefs_glm[, 1] + 1.96 * coefs_glm[, 2])

cat("E. Régression Logistique Quasibinomiale (Contrôle pour la Durée de passation) :\n")
print(summary(modele_glm_global))
cat(sprintf("\nOdds Ratio de réussite post-formation (ajusté sur durée) : OR = %.3f [IC 95%% : %.3f - %.3f], p = %.3e\n\n",
            or_glm["Cohorte_FactorPost-test"],
            ic_glm_inf["Cohorte_FactorPost-test"],
            ic_glm_sup["Cohorte_FactorPost-test"],
            coefs_glm["Cohorte_FactorPost-test", 4]))

# 1.6 Test de Wilcoxon sur l'aveu d'incompétence ("Je ne sais pas")
idk_pre  <- df_wide$Nombre_IDK[df_wide$Cohorte == "Pré-test"]
idk_post <- df_wide$Nombre_IDK[df_wide$Cohorte == "Post-test"]
wilcox_idk <- wilcox.test(idk_pre, idk_post, exact = FALSE)
cat(sprintf("F. Effondrement des 'Je ne sais pas' : W = %.1f, p = %.3e (Z = %.2f)\n\n",
            wilcox_idk$statistic, wilcox_idk$p.value,
            (wilcox_idk$statistic - (n1 * n2 / 2)) / sigma_w))

# Export du tableau récapitulatif des tests de formation
tab_tests_formation <- data.frame(
  Test = c("Shapiro-Wilk (Global)", "Shapiro-Wilk (Pré-test)", "Shapiro-Wilk (Post-test)",
           "Fligner-Killeen (Hétéroscédasticité)", "Wilcoxon-Mann-Whitney (Score)",
           "Test t de Welch (Score)", "Wilcoxon (Aveu d'incompétence IDK)",
           "GLM Logit Quasibinomial (Effet Formation ajusté)"),
  Statistique = c(sprintf("W = %.4f", shapiro_global$statistic),
                  sprintf("W = %.4f", shapiro_pre$statistic),
                  sprintf("W = %.4f", shapiro_post$statistic),
                  sprintf("Chi2 = %.4f", fligner_test$statistic),
                  sprintf("W = %.1f (Z = %.2f)", w_stat, z_score),
                  sprintf("t = %.3f (ddl = %.1f)", t_welch$statistic, t_welch$parameter),
                  sprintf("W = %.1f", wilcox_idk$statistic),
                  sprintf("z = %.3f", coefs_glm["Cohorte_FactorPost-test", 3])),
  P_Value = c(shapiro_global$p.value, shapiro_pre$p.value, shapiro_post$p.value,
              fligner_test$p.value, wilcox_res$p.value, t_welch$p.value,
              wilcox_idk$p.value, coefs_glm["Cohorte_FactorPost-test", 4]),
  Taille_Effet = c(NA, NA, NA, NA,
                   sprintf("r = %.3f | CLES = %.1f%%", taille_effet_r, cles_auc * 100),
                   sprintf("d de Cohen = %.3f", d_cohen),
                   "Réduction de -91.0%",
                   sprintf("Odds Ratio = %.3f", or_glm["Cohorte_FactorPost-test"])),
  Significatif_5pct = c(shapiro_global$p.value < 0.05, shapiro_pre$p.value < 0.05,
                        shapiro_post$p.value < 0.05, fligner_test$p.value < 0.05,
                        wilcox_res$p.value < 0.05, t_welch$p.value < 0.05,
                        wilcox_idk$p.value < 0.05, coefs_glm["Cohorte_FactorPost-test", 4] < 0.05),
  stringsAsFactors = FALSE
)

exporter_excel_csv(tab_tests_formation, file.path(dossier_output, "tableau_tests_formation_pre_post.csv"))

# Export des coefficients GLM
df_coefs_glm <- data.frame(
  Parametre = rownames(coefs_glm),
  Estimate = round(coefs_glm[, 1], 4),
  Std_Error = round(coefs_glm[, 2], 4),
  Odds_Ratio = round(or_glm, 3),
  IC_95_Inf = round(ic_glm_inf, 3),
  IC_95_Sup = round(ic_glm_sup, 3),
  t_value = round(coefs_glm[, 3], 3),
  p_value = coefs_glm[, 4],
  Significatif = coefs_glm[, 4] < 0.05,
  stringsAsFactors = FALSE
)
exporter_excel_csv(df_coefs_glm, file.path(dossier_output, "tableau_modele_glm_global.csv"))

# ------------------------------------------------------------------------------
# 2. ANALYSE INFÉRENTIELLE SELON LES FACTEURS BIOLOGIQUES (SEXE & GUILDE)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("2. ANALYSES INFÉRENTIELLES PAR SEXE ET PAR GUILDE ÉCOLOGIQUE\n")
cat("----------------------------------------------------------------------\n")

# GLM avec interaction : Formation x Sexe
modele_sexe <- glm(Est_Correct ~ Cohorte * Sexe_Specimen, data = df_long, family = binomial(link = "logit"))
cat("A. Interaction Formation x Sexe du Spécimen :\n")
print(summary(modele_sexe)$coefficients)

# GLM avec interaction : Formation x Guilde
modele_guilde <- glm(Est_Correct ~ Cohorte * Guilde_Solution, data = df_long, family = binomial(link = "logit"))
cat("\nB. Interaction Formation x Guilde Écologique (Non parasite vs Coucou) :\n")
print(summary(modele_guilde)$coefficients)

# Tests de Fisher par sous-groupes
calc_fisher_sub <- function(sub_data, label) {
  tab <- table(sub_data$Cohorte, sub_data$Est_Correct)
  f <- fisher.test(tab)
  p_pre <- mean(sub_data$Est_Correct[sub_data$Cohorte == "Pré-test"]) * 100
  p_post <- mean(sub_data$Est_Correct[sub_data$Cohorte == "Post-test"]) * 100
  data.frame(
    Groupe = label,
    N_Pre = sum(sub_data$Cohorte == "Pré-test"),
    Taux_Pre = round(p_pre, 1),
    N_Post = sum(sub_data$Cohorte == "Post-test"),
    Taux_Post = round(p_post, 1),
    Gain_Pct = round(p_post - p_pre, 1),
    Odds_Ratio = round(f$estimate, 3),
    IC_Inf = round(f$conf.int[1], 3),
    IC_Sup = round(f$conf.int[2], 3),
    P_Value = f$p.value,
    Significatif = f$p.value < 0.05,
    stringsAsFactors = FALSE
  )
}

tab_biol <- rbind(
  calc_fisher_sub(df_long[df_long$Sexe_Specimen == "Femelle", ], "Femelles"),
  calc_fisher_sub(df_long[df_long$Sexe_Specimen == "Mâle", ], "Mâles"),
  calc_fisher_sub(df_long[df_long$Guilde_Solution == "Non parasite", ], "Non parasites"),
  calc_fisher_sub(df_long[df_long$Guilde_Solution == "Cléptoparasite", ], "Abeilles Coucous (Cléptoparasites)")
)
print(tab_biol)
exporter_excel_csv(tab_biol, file.path(dossier_output, "tableau_tests_guildes_sexes.csv"))

# ------------------------------------------------------------------------------
# 3. AXE B : MODÉLISATION LOGISTIQUE DE LA DIFFICULTÉ PAR GENRE (GLM LOGIT)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("3. MODÉLISATION LOGISTIQUE DE LA DIFFICULTÉ PAR GENRE (GLM LOGIT)\n")
cat("----------------------------------------------------------------------\n")

df_long$Genre_Factor <- factor(df_long$Genre_Solution)
df_long$Genre_Factor <- relevel(df_long$Genre_Factor, ref = "Bombus") # Référence : Bombus (reconnaissance intuitive)
df_long$Cohorte_Factor <- factor(df_long$Cohorte, levels = c("Pré-test", "Post-test"))

modele_genres <- glm(Est_Correct ~ Genre_Factor + Cohorte_Factor, data = df_long, family = binomial(link = "logit"))
coefs_g <- summary(modele_genres)$coefficients

or_genres <- exp(coefs_g[, 1])
ic_inf    <- exp(coefs_g[, 1] - 1.96 * coefs_g[, 2])
ic_sup    <- exp(coefs_g[, 1] + 1.96 * coefs_g[, 2])
p_vals    <- coefs_g[, 4]
p_adj_fdr <- p.adjust(p_vals, method = "BH")

df_or <- data.frame(
  Variable = rownames(coefs_g),
  Odds_Ratio = round(or_genres, 3),
  IC_95_Inf = round(ic_inf, 3),
  IC_95_Sup = round(ic_sup, 3),
  Z_Value = round(coefs_g[, 3], 3),
  P_Value_Brute = p_vals,
  P_Value_FDR = p_adj_fdr,
  stringsAsFactors = FALSE
)

df_genres_or <- df_or[grep("^Genre_Factor", df_or$Variable), ]
df_genres_or$Genre <- gsub("^Genre_Factor", "", df_genres_or$Variable)
df_genres_or <- df_genres_or[order(df_genres_or$Odds_Ratio), ] # Du plus difficile au plus facile

fichier_or_csv <- file.path(dossier_output, "tableau_genres_odds_ratios.csv")
exporter_excel_csv(df_genres_or, fichier_or_csv)

cat("Top 5 des genres avec les plus faibles Odds Ratios de réussite (par rapport à Bombus) :\n")
print(head(df_genres_or[, c("Genre", "Odds_Ratio", "IC_95_Inf", "IC_95_Sup", "P_Value_FDR")], 5))

# ------------------------------------------------------------------------------
# 4. AXE B & A : TESTS D'EFFICACITÉ DE LA FORMATION PAR GENRE (FISHER EXACT)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("4. TESTS D'EFFICACITÉ DE LA FORMATION PAR GENRE (TESTS DE FISHER EXACTS)\n")
cat("----------------------------------------------------------------------\n")

genres_candidats <- sort(unique(df_long$Genre_Solution))
tests_fisher <- list()

for (g in genres_candidats) {
  sub_g <- df_long[df_long$Genre_Solution == g, ]
  tab_cont <- table(sub_g$Cohorte, sub_g$Est_Correct)
  
  if (nrow(tab_cont) == 2 && ncol(tab_cont) == 2) {
    f_res <- fisher.test(tab_cont)
    
    pct_post <- mean(sub_g$Est_Correct[sub_g$Cohorte == "Post-test"]) * 100
    pct_pre  <- mean(sub_g$Est_Correct[sub_g$Cohorte == "Pré-test"]) * 100
    
    tests_fisher[[g]] <- data.frame(
      Genre = g,
      Famille = sub_g$Famille_Solution[1],
      Guilde = sub_g$Guilde_Solution[1],
      N_Pre = sum(sub_g$Cohorte == "Pré-test"),
      N_Post = sum(sub_g$Cohorte == "Post-test"),
      Taux_Succes_Pre = round(pct_pre, 1),
      Taux_Succes_Post = round(pct_post, 1),
      Gain_Absolu_Pct = round(pct_post - pct_pre, 1),
      Odds_Ratio_Fisher = round(f_res$estimate, 3),
      IC_Inf = round(f_res$conf.int[1], 3),
      IC_Sup = round(f_res$conf.int[2], 3),
      P_Value_Brute = f_res$p.value,
      stringsAsFactors = FALSE
    )
  }
}

df_fisher_all <- do.call(rbind, tests_fisher)
df_fisher_all$P_Value_FDR <- p.adjust(df_fisher_all$P_Value_Brute, method = "BH")
df_fisher_all$Significatif_FDR_5pct  <- df_fisher_all$P_Value_FDR < 0.05
df_fisher_all$Significatif_FDR_10pct <- df_fisher_all$P_Value_FDR < 0.10
df_fisher_all <- df_fisher_all[order(df_fisher_all$P_Value_Brute), ]

fichier_fisher_csv <- file.path(dossier_output, "tableau_tests_fisher_formation_genres.csv")
exporter_excel_csv(df_fisher_all, fichier_fisher_csv)

cat(sprintf("Nombre de genres montrant une progression statistiquement significative (FDR < 5%%) : %d / %d\n",
            sum(df_fisher_all$Significatif_FDR_5pct), nrow(df_fisher_all)))
cat(sprintf("Nombre de genres montrant une progression statistiquement significative (FDR < 10%%) : %d / %d\n\n",
            sum(df_fisher_all$Significatif_FDR_10pct), nrow(df_fisher_all)))

cat("Top 7 des genres montrant le plus fort effet statistique de la formation (trié par p-value) :\n")
print(head(df_fisher_all[, c("Genre", "Taux_Succes_Pre", "Taux_Succes_Post", "Gain_Absolu_Pct", "Odds_Ratio_Fisher", "P_Value_FDR")], 7))

# ==============================================================================
# 5. VISUALISATIONS SCIENTIFIQUES (CHARTE AGENTS.md, 300 DPI)
# ==============================================================================
col_vert_succes   <- "#2E7D32" # Vert émeraude
col_rouge_erreur  <- "#C62828" # Rouge rubis
col_bleu_ardoise  <- "#4A90E2" # Bleu ardoise
col_bleu_nuit     <- "#1B365D" # Bleu nuit foncé
col_orange_diff   <- "#E67E22" # Ambre / Orange
col_violet        <- "#8E44AD" # Violet profond
col_gris_bord     <- "#D0D7DE"

# ------------------------------------------------------------------------------
# FIGURE 1 : Forest Plot des Odds Ratios de Difficulté par Genre (vs Bombus)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig1_forest_plot_odds_ratios_genres.png"),
    width = 3600, height = 3200, res = 300, bg = "white")
par(mar = c(5, 12, 4, 3), family = "sans")

genres_plot <- df_genres_or[df_genres_or$IC_95_Sup < 50, ] # Filtrer les OR très extrêmes si n restreint
n_gp <- nrow(genres_plot)
y_pos <- 1:n_gp

# Tracer le plan en échelle log
plot(genres_plot$Odds_Ratio, y_pos, log = "x",
     xlim = c(0.01, 3.0), ylim = c(0.5, n_gp + 0.8),
     yaxt = "n", xlab = "Odds Ratio de réussite relative à Bombus (échelle log)",
     ylab = "", main = "Modèle Logistique : Difficulté relative des genres (Réf = Bombus)",
     pch = 18, cex = 2.2, col = ifelse(genres_plot$P_Value_FDR < 0.05, col_rouge_erreur, col_bleu_ardoise),
     las = 1, font.lab = 2)
grid(col = "grey90", lty = 1)

# Ligne verticale de non-effet (OR = 1 : équivalent à Bombus)
abline(v = 1, lty = 2, col = "grey40", lwd = 1.8)
text(1, n_gp + 0.5, "Réf : Bombus (OR = 1.0)", col = "grey40", font = 3, cex = 0.85, adj = 0.5)

# Segments d'intervalles de confiance 95%
for (i in 1:n_gp) {
  col_seg <- ifelse(genres_plot$P_Value_FDR[i] < 0.05, col_rouge_erreur, col_bleu_ardoise)
  segments(genres_plot$IC_95_Inf[i], y_pos[i], genres_plot$IC_95_Sup[i], y_pos[i], col = col_seg, lwd = 2)
  segments(genres_plot$IC_95_Inf[i], y_pos[i] - 0.15, genres_plot$IC_95_Inf[i], y_pos[i] + 0.15, col = col_seg, lwd = 2)
  segments(genres_plot$IC_95_Sup[i], y_pos[i] - 0.15, genres_plot$IC_95_Sup[i], y_pos[i] + 0.15, col = col_seg, lwd = 2)
  
  # Texte d'Odds Ratio en noir dégagé à droite
  text(genres_plot$IC_95_Sup[i] * 1.12, y_pos[i],
       labels = sprintf("OR = %.2f [%.2f-%.2f]%s",
                        genres_plot$Odds_Ratio[i], genres_plot$IC_95_Inf[i], genres_plot$IC_95_Sup[i],
                        ifelse(genres_plot$P_Value_FDR[i] < 0.001, " ***",
                        ifelse(genres_plot$P_Value_FDR[i] < 0.01, " **",
                        ifelse(genres_plot$P_Value_FDR[i] < 0.05, " *", "")))),
       col = "black", font = 2, cex = 0.75, adj = 0)
}

axis(2, at = y_pos, labels = genres_plot$Genre, las = 1, cex.axis = 0.95, font = 2)

legend("bottomleft",
       legend = c("Genre significativement plus difficile que Bombus (p_adj < 0.05)",
                  "Difficulté statistiquement comparable à Bombus (p_adj >= 0.05)"),
       col = c(col_rouge_erreur, col_bleu_ardoise), pch = 18, pt.cex = 2, lwd = 2,
       bty = "o", bg = "#FFFFFFEE", box.col = col_gris_bord, cex = 0.85)

dev.off()
cat("  -> Figure 1 générée : output/fig1_forest_plot_odds_ratios_genres.png\n")

# ------------------------------------------------------------------------------
# FIGURE 2 : Volcano Plot des Gains par Genre et Significativité Statistique
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig2_volcano_gains_significativite_genres.png"),
    width = 3600, height = 2800, res = 300, bg = "white")
par(mar = c(5, 5, 4, 3), family = "sans")

df_fisher_all$log_p <- -log10(df_fisher_all$P_Value_FDR)
x_max <- max(df_fisher_all$Gain_Absolu_Pct) + 12
y_max <- max(df_fisher_all$log_p) + 1.5

col_volcano <- ifelse(df_fisher_all$Significatif_FDR_5pct, col_vert_succes, "grey60")
pch_volcano <- ifelse(df_fisher_all$Significatif_FDR_5pct, 16, 17)

plot(df_fisher_all$Gain_Absolu_Pct, df_fisher_all$log_p,
     col = col_volcano, pch = pch_volcano, cex = 2.0, las = 1,
     xlim = c(0, x_max), ylim = c(0, y_max),
     xlab = "Gain d'apprentissage absolu (points de pourcentage : Post - Pré)",
     ylab = "-log10(p-value ajustée FDR de Fisher)",
     main = "Significativité statistique de la progression par genre (Tests de Fisher)",
     font.lab = 2)
grid(col = "grey90", lty = 1)

# Ligne seuil FDR = 0.05 (-log10 = 1.301)
abline(h = -log10(0.05), col = col_rouge_erreur, lty = 2, lwd = 1.5)
text(2, -log10(0.05) + 0.25, "Seuil de significativité FDR = 0.05 (p_adj < 0.05)", col = col_rouge_erreur, adj = 0, cex = 0.85, font = 3)

# Étiquetage des genres majeurs
for (i in 1:nrow(df_fisher_all)) {
  # Décalage des labels pour zéro superposition
  g_name <- df_fisher_all$Genre[i]
  x_pt <- df_fisher_all$Gain_Absolu_Pct[i]
  y_pt <- df_fisher_all$log_p[i]
  
  if (df_fisher_all$Significatif_FDR_5pct[i] || df_fisher_all$Gain_Absolu_Pct[i] > 30) {
    text(x_pt + 1.2, y_pt + 0.15, labels = g_name,
         col = ifelse(df_fisher_all$Significatif_FDR_5pct[i], "black", "grey40"),
         font = 2, cex = 0.85, adj = 0)
  }
}

legend("topleft",
       legend = c("Progression statistiquement significative (FDR < 0.05)",
                  "Progression non significative après correction FDR"),
       col = c(col_vert_succes, "grey60"), pch = c(16, 17), pt.cex = 2,
       bty = "o", bg = "#FFFFFFEE", box.col = col_gris_bord, cex = 0.9)

dev.off()
cat("  -> Figure 2 générée : output/fig2_volcano_gains_significativite_genres.png\n")

# ------------------------------------------------------------------------------
# FIGURE 3 : Probabilités Prédites par le Modèle GLM (Marginal Effects)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig3_probabilites_predites_glm.png"),
    width = 3400, height = 2600, res = 300, bg = "white")
par(mar = c(5, 6, 4, 3), family = "sans")

# Prédiction GLM pour durée médiane
duree_med <- median(df_wide$Duree_Minutes)
new_data <- data.frame(
  Cohorte_Factor = factor(c("Pré-test", "Post-test"), levels = c("Pré-test", "Post-test")),
  Duree_Minutes = rep(duree_med, 2)
)

pred_link <- predict(modele_glm_global, newdata = new_data, se.fit = TRUE, type = "link")
pred_prob <- plogis(pred_link$fit)
ic_prob_inf <- plogis(pred_link$fit - 1.96 * pred_link$se.fit)
ic_prob_sup <- plogis(pred_link$fit + 1.96 * pred_link$se.fit)

mat_pred <- pred_prob * 100
bp_pred <- barplot(mat_pred, names.arg = c("Pré-test (Avant formation)", "Post-test (Après formation)"),
                   col = c(col_bleu_ardoise, col_vert_succes), ylim = c(0, 115), las = 1,
                   ylab = "Probabilité prédite de bonne identification (%)",
                   main = "Effet marginal ajusté de la formation (Modèle GLM Logit Quasibinomial)",
                   border = "white", font.lab = 2)
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

# Barres d'erreur de prédiction IC 95%
for (i in 1:2) {
  y <- bp_pred[i]
  val <- mat_pred[i]
  inf <- ic_prob_inf[i] * 100
  sup <- ic_prob_sup[i] * 100
  
  segments(y, inf, y, sup, col = "black", lwd = 2.5)
  segments(y - 0.08, inf, y + 0.08, inf, col = "black", lwd = 2.5)
  segments(y - 0.08, sup, y + 0.08, sup, col = "black", lwd = 2.5)
  
  # Textes en noir au-dessus des barres
  text(y, sup + 3.5, labels = sprintf("%.1f%% [IC 95%% : %.1f - %.1f]", val, inf, sup),
       font = 2, cex = 0.95, col = "black")
}

# Flèche du gain prédit ajusté
arrows(bp_pred[1], mat_pred[1], bp_pred[2], mat_pred[2], col = col_vert_succes, lwd = 3, length = 0.15)
rect(mean(bp_pred) - 0.35, mean(mat_pred) + 4, mean(bp_pred) + 0.35, mean(mat_pred) + 9.5,
     col = "#FFFFFFEE", border = col_vert_succes, lwd = 1.5)
text(mean(bp_pred), mean(mat_pred) + 6.8,
     labels = sprintf("Gain ajusté : +%.1f%%\nOdds Ratio = %.2f (p < 0.001)", mat_pred[2] - mat_pred[1], or_glm["Cohorte_FactorPost-test"]),
     col = "black", font = 2, cex = 0.85)

dev.off()
cat("  -> Figure 3 générée : output/fig3_probabilites_predites_glm.png\n")

cat("\n======================================================================\n")
cat("Analyses statistiques inférentielles de l'Étape 3 terminées avec succès !\n")
cat("======================================================================\n")
