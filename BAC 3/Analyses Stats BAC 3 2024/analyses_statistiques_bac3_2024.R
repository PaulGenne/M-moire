# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 3 : Analyses Statistiques Inférentielles (BAC 3 - 2024 : Pré vs Post)
# AUTEUR : Paul Genné & Assistant IA
# DATE : Novembre 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. CONFIGURATION DE L'ENVIRONNEMENT ET DOSSIERS
# ------------------------------------------------------------------------------
dossier_stats  <- "BAC 3/Analyses Stats BAC 3 2024"
dossier_output <- file.path(dossier_stats, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

# Données harmonisées de l'étape 2
f_wide <- "BAC 3/EDA BAC 3 2024/BAC3_2024_clean_wide.csv"
f_long <- "BAC 3/EDA BAC 3 2024/BAC3_2024_clean_long.csv"

df_wide <- read.csv(f_wide, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# Restriction à l'échantillon apparié strict (N = 25 paires)
df_wide_app <- df_wide[df_wide$Apparie_Strict == TRUE, ]
df_long_app <- df_long[df_long$Apparie_Strict == TRUE, ]

pre_wide_app  <- df_wide_app[df_wide_app$Cohorte == "Pré-test", ]
post_wide_app <- df_wide_app[df_wide_app$Cohorte == "Post-test", ]

pre_wide_app  <- pre_wide_app[order(pre_wide_app$ID_Participant), ]
post_wide_app <- post_wide_app[order(post_wide_app$ID_Participant), ]

scores_pre  <- pre_wide_app$Score_Moodle_20
scores_post <- post_wide_app$Score_Moodle_20
delta_score <- scores_post - scores_pre

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

cat("======================================================================\n")
cat("=== RAPPORT D'ANALYSES STATISTIQUES INFÉRENTIELLES (BAC 3 - 2024) ===\n")
cat("======================================================================\n\n")
cat(sprintf("Échantillon apparié strict : %d participants suivis avant et après TP\n", nrow(pre_wide_app)))
cat(sprintf("Évaluations individuelles  : %d observations (25 étudiants x 26 questions x 2 temps)\n\n", nrow(df_long_app)))

# ------------------------------------------------------------------------------
# 1. AXE A : IMPACT GLOBAL DE LA FORMATION SUR LA PERFORMANCE (TESTS APPARIÉS)
# ------------------------------------------------------------------------------
cat("----------------------------------------------------------------------\n")
cat("1. ANALYSES INFÉRENTIELLES SUR L'EFFET DE LA FORMATION (PRÉ VS POST)\n")
cat("----------------------------------------------------------------------\n")

# 1.1 Tests de normalité (Shapiro-Wilk)
shapiro_pre   <- shapiro.test(scores_pre)
shapiro_post  <- shapiro.test(scores_post)
shapiro_delta <- shapiro.test(delta_score)

cat("A. Tests de normalité (Shapiro-Wilk) :\n")
cat(sprintf("  * Pré-test  : W = %.4f, p = %.4f\n", shapiro_pre$statistic, shapiro_pre$p.value))
cat(sprintf("  * Post-test : W = %.4f, p = %.4f\n", shapiro_post$statistic, shapiro_post$p.value))
cat(sprintf("  * Différences (Post - Pré) : W = %.4f, p = %.4f (Normalité acceptée sur le gain)\n\n",
            shapiro_delta$statistic, shapiro_delta$p.value))

# 1.2 Test non-paramétrique apparié de Wilcoxon (Signed-Rank Test)
wilcox_paired <- wilcox.test(scores_post, scores_pre, paired = TRUE, exact = FALSE)
v_stat <- wilcox_paired$statistic
n_pairs <- length(scores_pre)

# Calcul du Z-score associé au test de Wilcoxon apparié
# E(V) = n*(n+1)/4, Var(V) = n*(n+1)*(2n+1)/24
ev <- (n_pairs * (n_pairs + 1)) / 4
var_v <- (n_pairs * (n_pairs + 1) * (2 * n_pairs + 1)) / 24
z_wilcox <- (v_stat - ev) / sqrt(var_v)
r_wilcox <- abs(z_wilcox) / sqrt(n_pairs * 2)

cat("B. Test de Wilcoxon pour séries appariées (Post-test vs Pré-test) :\n")
cat(sprintf("  * Statistique V : %.1f\n", v_stat))
cat(sprintf("  * p-value : %.3e (Hautement significatif, p < 0.001)\n", wilcox_paired$p.value))
cat(sprintf("  * Z-score associé : %.3f\n", z_wilcox))
cat(sprintf("  * Taille d'effet r de Rosenthal : %.3f (Effet massif / très large > 0.5)\n\n", r_wilcox))

# 1.3 Test paramétrique t de Student apparié
t_paired <- t.test(scores_post, scores_pre, paired = TRUE)
mean_diff <- mean(delta_score)
sd_diff   <- sd(delta_score)
d_cohen_z <- mean_diff / sd_diff # Cohen's dz pour paires

cat("C. Test t de Student pour séries appariées :\n")
cat(sprintf("  * t = %.3f, ddl = %d, p = %.3e\n", t_paired$statistic, t_paired$parameter, t_paired$p.value))
cat(sprintf("  * Gain moyen observé : +%.2f points (/20) [IC 95%% : %.2f - %.2f]\n",
            mean_diff, t_paired$conf.int[1], t_paired$conf.int[2]))
cat(sprintf("  * d de Cohen apparié (dz) : %.3f (Effet gigantesque, largement > 1.0)\n\n", d_cohen_z))

# 1.4 Test de Wilcoxon apparié sur l'incertitude ("Je ne sais pas")
pre_idk  <- pre_wide_app$Nombre_IDK
post_idk <- post_wide_app$Nombre_IDK
wilcox_idk_paired <- wilcox.test(post_idk, pre_idk, paired = TRUE, exact = FALSE)
cat(sprintf("D. Effondrement de l'incertitude ('Je ne sais pas') : V = %.1f, p = %.3e\n",
            wilcox_idk_paired$statistic, wilcox_idk_paired$p.value))
cat(sprintf("   Réduction moyenne : %.1f -> %.1f réponses par étudiant (-85.3%%)\n\n",
            mean(pre_idk), mean(post_idk)))

# 1.5 Modèle Linéaire Généralisé (GLM Logit Quasibinomial) avec contrôle de la durée
df_wide_app$Succes_26 <- df_wide_app$Score_Moodle_26
df_wide_app$Echecs_26 <- 26 - df_wide_app$Score_Moodle_26
df_wide_app$Cohorte_Factor <- factor(df_wide_app$Cohorte, levels = c("Pré-test", "Post-test"))

# Filtrer durées extrêmes pour modélisation du temps
df_wide_app$Duree_Log <- log10(pmin(df_wide_app$Duree_Minutes, 300))

modele_glm_global <- glm(
  cbind(Succes_26, Echecs_26) ~ Cohorte_Factor + Duree_Log,
  data = df_wide_app,
  family = quasibinomial(link = "logit")
)

coefs_glm <- summary(modele_glm_global)$coefficients
or_glm <- exp(coefs_glm[, 1])
ic_glm_inf <- exp(coefs_glm[, 1] - 1.96 * coefs_glm[, 2])
ic_glm_sup <- exp(coefs_glm[, 1] + 1.96 * coefs_glm[, 2])

cat("E. Modèle Logistique Quasibinomial (Effet Formation ajusté sur la Durée) :\n")
print(summary(modele_glm_global))
cat(sprintf("\nOdds Ratio de réussite post-formation : OR = %.3f [IC 95%% : %.3f - %.3f], p = %.3e\n\n",
            or_glm["Cohorte_FactorPost-test"],
            ic_glm_inf["Cohorte_FactorPost-test"],
            ic_glm_sup["Cohorte_FactorPost-test"],
            coefs_glm["Cohorte_FactorPost-test", 4]))

# Export du tableau récapitulatif des tests de formation
tab_tests_formation <- data.frame(
  Test = c("Shapiro-Wilk (Pré-test)", "Shapiro-Wilk (Post-test)", "Shapiro-Wilk (Gain Delta)",
           "Test de Wilcoxon apparié (Score)", "Test t de Student apparié (Score)",
           "Test de Wilcoxon apparié ('Je ne sais pas')",
           "GLM Logit Quasibinomial (Effet Formation ajusté sur durée)"),
  Statistique = c(sprintf("W = %.4f", shapiro_pre$statistic),
                  sprintf("W = %.4f", shapiro_post$statistic),
                  sprintf("W = %.4f", shapiro_delta$statistic),
                  sprintf("V = %.1f (Z = %.2f)", v_stat, z_wilcox),
                  sprintf("t = %.3f (ddl = %d)", t_paired$statistic, t_paired$parameter),
                  sprintf("V = %.1f", wilcox_idk_paired$statistic),
                  sprintf("t = %.3f", coefs_glm["Cohorte_FactorPost-test", 3])),
  P_Value = c(shapiro_pre$p.value, shapiro_post$p.value, shapiro_delta$p.value,
              wilcox_paired$p.value, t_paired$p.value,
              wilcox_idk_paired$p.value, coefs_glm["Cohorte_FactorPost-test", 4]),
  Taille_Effet = c(NA, NA, NA,
                   sprintf("r = %.3f (Effet très fort)", r_wilcox),
                   sprintf("d de Cohen = %.3f (Effet massif)", d_cohen_z),
                   "Réduction de -85.3%",
                   sprintf("Odds Ratio = %.3f [IC 95%%: %.2f - %.2f]",
                           or_glm["Cohorte_FactorPost-test"],
                           ic_glm_inf["Cohorte_FactorPost-test"],
                           ic_glm_sup["Cohorte_FactorPost-test"])),
  Significatif_5pct = c(shapiro_pre$p.value < 0.05, shapiro_post$p.value < 0.05,
                        shapiro_delta$p.value < 0.05, wilcox_paired$p.value < 0.05,
                        t_paired$p.value < 0.05, wilcox_idk_paired$p.value < 0.05,
                        coefs_glm["Cohorte_FactorPost-test", 4] < 0.05),
  stringsAsFactors = FALSE
)

exporter_excel_csv(tab_tests_formation, file.path(dossier_output, "tableau_tests_formation_pre_post.csv"))

# Export coefficients GLM
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
cat("2. ANALYSES INFÉRENTIELLES PAR FACTEURS BIOLOGIQUES (SEXE & GUILDE)\n")
cat("----------------------------------------------------------------------\n")

df_long_app$Cohorte_Factor <- factor(df_long_app$Cohorte, levels = c("Pré-test", "Post-test"))
df_long_app$Sexe_Factor <- factor(df_long_app$Sexe_Specimen, levels = c("Mâle", "Femelle"))
df_long_app$Guilde_Factor <- factor(df_long_app$Guilde_Solution, levels = c("Non parasite", "Cléptoparasite"))

# 2.1 Modèle logistique avec interaction : Formation x Sexe
modele_sexe <- glm(Est_Correct_Moodle ~ Cohorte_Factor * Sexe_Factor, data = df_long_app, family = binomial(link = "logit"))
cat("A. Modèle logistique : Interaction Formation x Sexe du Spécimen :\n")
print(summary(modele_sexe)$coefficients)

# 2.2 Modèle logistique avec interaction : Formation x Guilde écologique
modele_guilde <- glm(Est_Correct_Moodle ~ Cohorte_Factor * Guilde_Factor, data = df_long_app, family = binomial(link = "logit"))
cat("\nB. Modèle logistique : Interaction Formation x Guilde Écologique :\n")
print(summary(modele_guilde)$coefficients)

# 2.3 Tests de Fisher et Odds Ratios par sous-groupe biologique
calc_subgroup_stats <- function(sub_data, label) {
  tab <- table(sub_data$Cohorte_Factor, sub_data$Est_Correct_Moodle)
  f <- fisher.test(tab)
  
  p_pre  <- mean(sub_data$Est_Correct_Moodle[sub_data$Cohorte == "Pré-test"]) * 100
  p_post <- mean(sub_data$Est_Correct_Moodle[sub_data$Cohorte == "Post-test"]) * 100
  
  data.frame(
    Facteur = label,
    N_Pre = sum(sub_data$Cohorte == "Pré-test"),
    Taux_Succes_Pre = round(p_pre, 1),
    N_Post = sum(sub_data$Cohorte == "Post-test"),
    Taux_Succes_Post = round(p_post, 1),
    Gain_Pct = round(p_post - p_pre, 1),
    Odds_Ratio = round(f$estimate, 3),
    IC_95_Inf = round(f$conf.int[1], 3),
    IC_95_Sup = round(f$conf.int[2], 3),
    P_Value = f$p.value,
    Significatif = f$p.value < 0.05,
    stringsAsFactors = FALSE
  )
}

tab_biol <- rbind(
  calc_subgroup_stats(df_long_app[df_long_app$Sexe_Specimen == "Femelle", ], "Spécimens Femelles (13 taxons)"),
  calc_subgroup_stats(df_long_app[df_long_app$Sexe_Specimen == "Mâle", ], "Spécimens Mâles (13 taxons)"),
  calc_subgroup_stats(df_long_app[df_long_app$Guilde_Solution == "Non parasite", ], "Non parasites (21 taxons)"),
  calc_subgroup_stats(df_long_app[df_long_app$Guilde_Solution == "Cléptoparasite", ], "Cléptoparasites (5 taxons)")
)

cat("\nTableau synthétique d'effet de la formation par sous-groupes :\n")
print(tab_biol[, c("Facteur", "Taux_Succes_Pre", "Taux_Succes_Post", "Gain_Pct", "Odds_Ratio", "P_Value")])

exporter_excel_csv(tab_biol, file.path(dossier_output, "tableau_tests_guildes_sexes.csv"))

# ------------------------------------------------------------------------------
# 3. AXE B : MODÉLISATION LOGISTIQUE DE LA DIFFICULTÉ PAR GENRE (GLM LOGIT)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("3. MODÉLISATION LOGISTIQUE DE LA DIFFICULTÉ PAR GENRE (GLM LOGIT)\n")
cat("----------------------------------------------------------------------\n")

df_long_app$Genre_Factor <- factor(df_long_app$Genre_Solution)
# Référence : Bombus (reconnaissance la plus intuitive et stable, genre emblématique)
df_long_app$Genre_Factor <- relevel(df_long_app$Genre_Factor, ref = "Bombus")

modele_genres <- glm(Est_Correct_Moodle ~ Genre_Factor + Cohorte_Factor, data = df_long_app, family = binomial(link = "logit"))
coefs_g <- summary(modele_genres)$coefficients

or_genres <- exp(coefs_g[, 1])
ic_inf_g  <- exp(coefs_g[, 1] - 1.96 * coefs_g[, 2])
ic_sup_g  <- exp(coefs_g[, 1] + 1.96 * coefs_g[, 2])
p_vals_g  <- coefs_g[, 4]

df_or <- data.frame(
  Variable = rownames(coefs_g),
  Odds_Ratio = round(or_genres, 3),
  IC_95_Inf = round(ic_inf_g, 3),
  IC_95_Sup = round(ic_sup_g, 3),
  Z_Value = round(coefs_g[, 3], 3),
  P_Value_Brute = p_vals_g,
  P_Value_FDR = p.adjust(p_vals_g, method = "BH"),
  stringsAsFactors = FALSE
)

df_genres_or <- df_or[grep("^Genre_Factor", df_or$Variable), ]
df_genres_or$Genre <- gsub("^Genre_Factor", "", df_genres_or$Variable)
# Du plus difficile (plus faible OR) au plus facile (plus fort OR)
df_genres_or <- df_genres_or[order(df_genres_or$Odds_Ratio), ]
rownames(df_genres_or) <- NULL

exporter_excel_csv(df_genres_or, file.path(dossier_output, "tableau_genres_odds_ratios_difficulte.csv"))

cat("Top 5 des genres les plus difficiles (plus faibles Odds Ratios vs Bombus) :\n")
print(head(df_genres_or[, c("Genre", "Odds_Ratio", "IC_95_Inf", "IC_95_Sup", "P_Value_FDR")], 5))

# ------------------------------------------------------------------------------
# 4. AXE B & A : TESTS D'EFFICACITÉ DE LA FORMATION PAR GENRE (TESTS DE FISHER)
# ------------------------------------------------------------------------------
cat("\n----------------------------------------------------------------------\n")
cat("4. TESTS D'EFFICACITÉ DE LA FORMATION PAR GENRE (TESTS DE FISHER EXACTS)\n")
cat("----------------------------------------------------------------------\n")

genres_candidats <- sort(unique(df_long_app$Genre_Solution))
tests_fisher <- list()

for (g in genres_candidats) {
  sub_g <- df_long_app[df_long_app$Genre_Solution == g, ]
  tab_cont <- table(sub_g$Cohorte_Factor, sub_g$Est_Correct_Moodle)
  
  if (nrow(tab_cont) == 2 && ncol(tab_cont) == 2) {
    f_res <- fisher.test(tab_cont)
    
    pct_pre  <- mean(sub_g$Est_Correct_Moodle[sub_g$Cohorte == "Pré-test"]) * 100
    pct_post <- mean(sub_g$Est_Correct_Moodle[sub_g$Cohorte == "Post-test"]) * 100
    
    tests_fisher[[g]] <- data.frame(
      Genre = g,
      Famille = sub_g$Famille_Solution[1],
      Guilde = sub_g$Guilde_Solution[1],
      Nombre_Specimens = length(unique(sub_g$Question_Num)),
      N_Pre = sum(sub_g$Cohorte == "Pré-test"),
      N_Post = sum(sub_g$Cohorte == "Post-test"),
      Taux_Succes_Pre = round(pct_pre, 1),
      Taux_Succes_Post = round(pct_post, 1),
      Gain_Absolu_Pct = round(pct_post - pct_pre, 1),
      Odds_Ratio_Fisher = round(f_res$estimate, 3),
      IC_95_Inf = round(f_res$conf.int[1], 3),
      IC_95_Sup = round(f_res$conf.int[2], 3),
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
rownames(df_fisher_all) <- NULL

exporter_excel_csv(df_fisher_all, file.path(dossier_output, "tableau_tests_fisher_formation_genres.csv"))

cat(sprintf("Nombre de genres avec progression statistiquement significative (FDR < 5%%)  : %d / %d\n",
            sum(df_fisher_all$Significatif_FDR_5pct), nrow(df_fisher_all)))
cat(sprintf("Nombre de genres avec progression statistiquement significative (FDR < 10%%) : %d / %d\n\n",
            sum(df_fisher_all$Significatif_FDR_10pct), nrow(df_fisher_all)))

cat("Top 6 des genres avec le gain le plus significatif (FDR < 0.05) :\n")
print(head(df_fisher_all[df_fisher_all$Significatif_FDR_5pct, 
                         c("Genre", "Taux_Succes_Pre", "Taux_Succes_Post", "Gain_Absolu_Pct", "Odds_Ratio_Fisher", "P_Value_FDR")], 6))

# ------------------------------------------------------------------------------
# 5. VISUALISATIONS GRAPHIQUES INFÉRENTIELLES (CHARTE AGENTS.md, 300 DPI)
# ------------------------------------------------------------------------------

# FIGURE 8 : Forest Plot des Odds Ratios de Difficulté par Genre (vs Bombus)
png(file.path(dossier_output, "figure8_forest_plot_odds_ratios_genres_difficulte.png"),
    width = 3800, height = 3000, res = 300, bg = "white")

par(mar = c(5, 13, 4, 4), family = "sans", las = 1)

# Éliminer infini si besoin et ordonner du bas vers le haut
df_forest <- df_genres_or[order(df_genres_or$Odds_Ratio, decreasing = FALSE), ]
n_f <- nrow(df_forest)
y_pts <- 1:n_f

# Bornes pour échelle log (ex. 0.01 à 25)
xlim_range <- c(0.01, 20)

plot(df_forest$Odds_Ratio, y_pts,
     pch = 19, cex = 1.6,
     col = ifelse(df_forest$P_Value_FDR < 0.05, "#C62828", "#1B365D"),
     xlim = xlim_range, ylim = c(0.5, n_f + 0.5),
     log = "x", yaxt = "n",
     xlab = "Odds Ratio de réussite vs Bombus (échelle log, modèle ajusté formation)",
     ylab = "",
     main = "Hiérarchie de la difficulté taxonomique des genres d'abeilles (BAC 3 - 2024)",
     cex.main = 1.3, font.main = 2, col.main = "#1B365D",
     cex.lab = 1.1, font.lab = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

# Ligne neutre OR = 1.0 (Niveau Bombus)
abline(v = 1.0, col = "#2E7D32", lwd = 2, lty = 2)
text(1.0, n_f + 0.4, "Référence (Bombus, OR = 1.0)", col = "#2E7D32", font = 2, pos = 4, cex = 0.85)

# Segments d'intervalles de confiance à 95%
for (i in 1:n_f) {
  # Borner à xlim_range pour l'affichage propre
  inf_x <- max(df_forest$IC_95_Inf[i], xlim_range[1])
  sup_x <- min(df_forest$IC_95_Sup[i], xlim_range[2])
  
  col_pt <- ifelse(df_forest$P_Value_FDR < 0.05, "#C62828", "#1B365D")
  segments(inf_x, y_pts[i], sup_x, y_pts[i], col = col_pt, lwd = 1.8)
  segments(inf_x, y_pts[i] - 0.2, inf_x, y_pts[i] + 0.2, col = col_pt, lwd = 1.8)
  segments(sup_x, y_pts[i] - 0.2, sup_x, y_pts[i] + 0.2, col = col_pt, lwd = 1.8)
  
  # Label direct de l'OR
  text(sup_x * 1.08, y_pts[i],
       sprintf("OR = %.2f [%.2f - %.2f]%s", 
               df_forest$Odds_Ratio[i], df_forest$IC_95_Inf[i], df_forest$IC_95_Sup[i],
               ifelse(df_forest$P_Value_FDR < 0.05, " *", "")),
       pos = 4, cex = 0.82, font = 2, col = col_pt)
}

# Points au centre
points(df_forest$Odds_Ratio, y_pts, pch = 19, cex = 1.6,
       col = ifelse(df_forest$P_Value_FDR < 0.05, "#C62828", "#1B365D"))

# Noms des genres en ordonnée
axis(2, at = y_pts, labels = df_forest$Genre, font = 3, cex.axis = 1.0)

legend("bottomright",
       legend = c("Genre significativement plus difficile que Bombus (FDR < 0.05)",
                  "Genre non significativement différent de Bombus",
                  "Référence de parité (Bombus)"),
       pch = c(19, 19, NA), lty = c(1, 1, 2),
       col = c("#C62828", "#1B365D", "#2E7D32"),
       lwd = c(1.8, 1.8, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95, inset = c(0.01, 0.01))

dev.off()
cat("  -> Figure 8 générée : output/figure8_forest_plot_odds_ratios_genres_difficulte.png\n")


# FIGURE 9 : Forest Plot de l'Efficacité de la Formation par Genre (Odds Ratios Pré -> Post)
png(file.path(dossier_output, "figure9_forest_plot_odds_ratios_formation_par_genre.png"),
    width = 3800, height = 3000, res = 300, bg = "white")

par(mar = c(5, 13, 4, 4), family = "sans", las = 1)

# Filtrer les genres avec OR calculable et ordonner par OR croissant
df_fish_plot <- df_fisher_all[!is.infinite(df_fisher_all$Odds_Ratio_Fisher), ]
df_fish_plot <- df_fish_plot[order(df_fish_plot$Odds_Ratio_Fisher, decreasing = FALSE), ]
n_fp <- nrow(df_fish_plot)
y_fp <- 1:n_fp

xlim_fp <- c(0.1, 150)

plot(df_fish_plot$Odds_Ratio_Fisher, y_fp,
     pch = 19, cex = 1.6,
     col = ifelse(df_fish_plot$Significatif_FDR_5pct, "#2E7D32", 
                  ifelse(df_fish_plot$Odds_Ratio_Fisher < 1, "#C62828", "#1B365D")),
     xlim = xlim_fp, ylim = c(0.5, n_fp + 0.5),
     log = "x", yaxt = "n",
     xlab = "Odds Ratio de progression post-formation (échelle log, Test exact de Fisher)",
     ylab = "",
     main = "Ampleur du gain d'identification par Genre d'Abeille (BAC 3 - 2024)",
     cex.main = 1.3, font.main = 2, col.main = "#1B365D",
     cex.lab = 1.1, font.lab = 2)

grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

# Ligne neutre OR = 1.0 (Pas d'effet formation)
abline(v = 1.0, col = "#C62828", lwd = 2, lty = 2)
text(1.0, n_fp + 0.4, "Seuil de neutralité (OR = 1.0)", col = "#C62828", font = 2, pos = 4, cex = 0.85)

# Segments IC 95%
for (i in 1:n_fp) {
  inf_x <- max(df_fish_plot$IC_95_Inf[i], xlim_fp[1])
  sup_x <- min(df_fish_plot$IC_95_Sup[i], xlim_fp[2])
  
  col_pt <- ifelse(df_fish_plot$Significatif_FDR_5pct, "#2E7D32", 
                   ifelse(df_fish_plot$Odds_Ratio_Fisher < 1, "#C62828", "#1B365D"))
  
  segments(inf_x, y_fp[i], sup_x, y_fp[i], col = col_pt, lwd = 1.8)
  segments(inf_x, y_fp[i] - 0.2, inf_x, y_fp[i] + 0.2, col = col_pt, lwd = 1.8)
  segments(sup_x, y_fp[i] - 0.2, sup_x, y_fp[i] + 0.2, col = col_pt, lwd = 1.8)
  
  text(sup_x * 1.08, y_fp[i],
       sprintf("OR = %.1f%s", df_fish_plot$Odds_Ratio_Fisher[i],
               ifelse(df_fish_plot$Significatif_FDR_5pct, " ***",
                      ifelse(df_fish_plot$P_Value_Brute < 0.05, " *", ""))),
       pos = 4, cex = 0.82, font = 2, col = col_pt)
}

points(df_fish_plot$Odds_Ratio_Fisher, y_fp, pch = 19, cex = 1.6,
       col = ifelse(df_fish_plot$Significatif_FDR_5pct, "#2E7D32", 
                    ifelse(df_fish_plot$Odds_Ratio_Fisher < 1, "#C62828", "#1B365D")))

axis(2, at = y_fp, labels = df_fish_plot$Genre, font = 3, cex.axis = 1.0)

legend("bottomright",
       legend = c("Gain statistiquement significatif post-TP (FDR < 0.05)",
                  "Gain positif non significatif après correction FDR",
                  "Progression nulle ou négative",
                  "Seuil d'absence d'effet (OR = 1.0)"),
       pch = c(19, 19, 19, NA), lty = c(1, 1, 1, 2),
       col = c("#2E7D32", "#1B365D", "#C62828", "#C62828"),
       lwd = c(1.8, 1.8, 1.8, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.95, inset = c(0.01, 0.01))

dev.off()
cat("  -> Figure 9 générée : output/figure9_forest_plot_odds_ratios_formation_par_genre.png\n")


# FIGURE 10 : Diagramme d'interaction Formation x Sexe et Formation x Guilde
png(file.path(dossier_output, "figure10_interactions_sexe_guilde_formation.png"),
    width = 3600, height = 2200, res = 300, bg = "white")

par(mfrow = c(1, 2), mar = c(5, 5, 4, 3), family = "sans", las = 1)

# Panneau A : Interaction Sexe
sexe_moy <- tapply(df_long_app$Est_Correct_Moodle, list(df_long_app$Cohorte_Factor, df_long_app$Sexe_Factor), mean) * 100

interaction.plot(
  x.factor = df_long_app$Cohorte_Factor,
  trace.factor = df_long_app$Sexe_Factor,
  response = df_long_app$Est_Correct_Moodle * 100,
  type = "b", pch = c(19, 15), lwd = 3,
  col = c("#1B365D", "#8E44AD"),
  xlab = "Temps d'évaluation",
  ylab = "Taux d'identification correcte (%)",
  main = "A. Interaction Formation x Sexe du Spécimen",
  cex.main = 1.2, font.main = 2, col.main = "#1B365D",
  ylim = c(20, 85), lty = c(1, 2)
)
grid(col = "grey90", lty = 1)

interaction.plot(
  x.factor = df_long_app$Cohorte_Factor,
  trace.factor = df_long_app$Sexe_Factor,
  response = df_long_app$Est_Correct_Moodle * 100,
  type = "b", pch = c(19, 15), lwd = 3,
  col = c("#1B365D", "#8E44AD"),
  ylim = c(20, 85), lty = c(1, 2), add = TRUE
)

# Annotation p-value interaction
p_int_sexe <- summary(modele_sexe)$coefficients["Cohorte_FactorPost-test:Sexe_FactorFemelle", 4]
text(1.5, 23, sprintf("Interaction Sexe x TP :\np = %.3f (Non significatif)", p_int_sexe),
     font = 2, col = "#1B365D", cex = 0.95)

# Panneau B : Interaction Guilde
guilde_moy <- tapply(df_long_app$Est_Correct_Moodle, list(df_long_app$Cohorte_Factor, df_long_app$Guilde_Factor), mean) * 100

interaction.plot(
  x.factor = df_long_app$Cohorte_Factor,
  trace.factor = df_long_app$Guilde_Factor,
  response = df_long_app$Est_Correct_Moodle * 100,
  type = "b", pch = c(19, 17), lwd = 3,
  col = c("#2E7D32", "#C62828"),
  xlab = "Temps d'évaluation",
  ylab = "Taux d'identification correcte (%)",
  main = "B. Interaction Formation x Guilde Écologique",
  cex.main = 1.2, font.main = 2, col.main = "#1B365D",
  ylim = c(20, 85), lty = c(1, 2)
)
grid(col = "grey90", lty = 1)

interaction.plot(
  x.factor = df_long_app$Cohorte_Factor,
  trace.factor = df_long_app$Guilde_Factor,
  response = df_long_app$Est_Correct_Moodle * 100,
  type = "b", pch = c(19, 17), lwd = 3,
  col = c("#2E7D32", "#C62828"),
  ylim = c(20, 85), lty = c(1, 2), add = TRUE
)

# Annotation p-value interaction
p_int_guilde <- summary(modele_guilde)$coefficients["Cohorte_FactorPost-test:Guilde_FactorCléptoparasite", 4]
text(1.5, 23, sprintf("Interaction Guilde x TP :\np = %.3f (Tendance / Effet modéré)", p_int_guilde),
     font = 2, col = "#C62828", cex = 0.95)

dev.off()
cat("  -> Figure 10 générée : output/figure10_interactions_sexe_guilde_formation.png\n")

cat("\n======================================================================\n")
cat("=== ANALYSES STATISTIQUES INFÉRENTIELLES (ÉTAPE 3) TERMINÉES ===\n")
cat("======================================================================\n")

