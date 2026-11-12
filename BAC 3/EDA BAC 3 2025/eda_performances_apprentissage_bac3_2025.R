# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - BAC 3 (2025)
# SCRIPT 2 : Analyse Exploratoire des Performances & de l'Apprentissage (Axe A)
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

# 1. CHARGEMENT DES DONNÉES WIDE & LONG ----------------------------------------
f_wide <- file.path(dossier_eda, "BAC3_2025_clean_wide.csv")
f_long <- file.path(dossier_eda, "BAC3_2025_clean_long.csv")

df_wide <- read.csv(f_wide, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)
df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

cat("======================================================================\n")
cat("=== ANALYSE EXPLORATOIRE DE L'APPRENTISSAGE (AXE A - BAC 3 2025) ===\n")
cat("======================================================================\n\n")

# Restriction à l'échantillon apparié strict (N = 22)
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

# Gain relatif de Dake : g = (Post - Pre) / (20 - Pre) * 100
gain_relatif_dake <- ifelse(pre_scores < 20, round((delta_score / (20 - pre_scores)) * 100, 1), 0)

pre_idk  <- pre_wide_app$Nombre_IDK
post_idk <- post_wide_app$Nombre_IDK

# Durées
pre_duree  <- pre_wide_app$Duree_Minutes
post_duree <- post_wide_app$Duree_Minutes

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
  data.frame(Cohorte = "Pré-test (Total N=22)", calcul_stats(pre_scores, "Score (/20)")),
  data.frame(Cohorte = "Pré-test (Standard sans speed-runs N=20)", calcul_stats(pre_scores[pre_wide_app$Profil_Atypique == "Standard"], "Score (/20)")),
  data.frame(Cohorte = "Post-test (Total N=22)", calcul_stats(post_scores, "Score (/20)")),
  data.frame(Cohorte = "Post-test (Standard sans speed-runs N=20)", calcul_stats(post_scores[pre_wide_app$Profil_Atypique == "Standard"], "Score (/20)")),
  data.frame(Cohorte = "Progression (Delta brut N=22)", calcul_stats(delta_score, "Gain absolu (/20)")),
  data.frame(Cohorte = "Progression (Delta standard N=20)", calcul_stats(delta_score[pre_wide_app$Profil_Atypique == "Standard"], "Gain absolu (/20)")),
  data.frame(Cohorte = "Progression (Gain relatif Dake N=22)", calcul_stats(gain_relatif_dake, "Gain de Dake (%)")),
  data.frame(Cohorte = "Progression (Gain relatif Dake N=20)", calcul_stats(gain_relatif_dake[pre_wide_app$Profil_Atypique == "Standard"], "Gain de Dake (%)")),
  data.frame(Cohorte = "Pré-test (Incertitude N=22)", calcul_stats(pre_idk, "Nombre de 'Je ne sais pas' (/28)")),
  data.frame(Cohorte = "Post-test (Incertitude N=22)", calcul_stats(post_idk, "Nombre de 'Je ne sais pas' (/28)")),
  data.frame(Cohorte = "Pré-test (Durée N=22)", calcul_stats(pre_duree, "Durée de session (min)")),
  data.frame(Cohorte = "Post-test (Durée N=22)", calcul_stats(post_duree, "Durée de session (min)"))
)

cat("--- Tableau synthétique des performances d'apprentissage (BAC 3 - 2025) ---\n")
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
  Delta_IDK = post_idk - pre_idk,
  Pre_Duree_Min = pre_duree,
  Post_Duree_Min = post_duree,
  Profil = pre_wide_app$Profil_Atypique,
  stringsAsFactors = FALSE
)
tab_individuel <- tab_individuel[order(-tab_individuel$Delta_Score), ]

exporter_excel_csv(tab_individuel, file.path(dossier_output, "tableau_progressions_individuelles_axe_a.csv"))

# 3. ANALYSE SELON LES CARACTÉRISTIQUES DES SPÉCIMENS (SEXE & GUILDE) -----------
# Calcul des taux de réussite au niveau de l'observation (format long apparié)
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

agg_cat <- function(var_name) {
  cats <- unique(df_long_app[[var_name]])
  res_list <- list()
  for (c_val in cats) {
    for (coh in c("Pré-test", "Post-test")) {
      sub_d <- df_long_app[df_long_app[[var_name]] == c_val & df_long_app$Cohorte == coh, ]
      n_tot <- nrow(sub_d)
      n_suc <- sum(sub_d$Est_Correct_Moodle)
      tx <- round((n_suc / n_tot) * 100, 1)
      ic <- calc_wilson(n_suc, n_tot)
      n_idk <- sum(sub_d$Est_IDK)
      tx_idk <- round((n_idk / n_tot) * 100, 1)
      
      res_list[[paste(var_name, c_val, coh)]] <- data.frame(
        Facteur = var_name,
        Modalite = c_val,
        Cohorte = coh,
        N_Observations = n_tot,
        Succes = n_suc,
        Taux_Succes_Pct = tx,
        IC_Wilson_Inf = ic["inf"],
        IC_Wilson_Sup = ic["sup"],
        Nombre_IDK = n_idk,
        Taux_IDK_Pct = tx_idk,
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, res_list)
}

tab_sexe_guilde <- rbind(
  agg_cat("Sexe_Specimen"),
  agg_cat("Guilde_Solution"),
  agg_cat("Famille_Solution")
)

exporter_excel_csv(tab_sexe_guilde, file.path(dossier_output, "tableau_performances_sexe_guilde_axe_a.csv"))

# 4. GÉNÉRATION DES FIGURES HAUTE DÉFINITION (CHARTE AGENTS.md) ----------------

# ------------------------------------------------------------------------------
# FIGURE 1 : Distribution des scores Pré vs Post
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure1_distributions_scores_pre_post.png"),
    width = 3200, height = 2300, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

b <- boxplot(list("Pré-test\n(Avant formation)" = pre_scores, 
                  "Post-test\n(Après formation)" = post_scores),
             col = c("#4A90E2", "#2E7D32"),
             border = "#1B365D",
             ylim = c(0, 23),
             ylab = "Score obtenu (/20)",
             main = "Distribution des scores avant et après formation (BAC 3 - 2025)",
             cex.main = 1.3, font.main = 2, col.main = "#1B365D",
             cex.lab = 1.1, font.lab = 2, outline = FALSE)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)

boxplot(list("Pré-test\n(Avant formation)" = pre_scores, 
             "Post-test\n(Après formation)" = post_scores),
        col = c("#4A90E2", "#2E7D32"),
        border = "#1B365D",
        add = TRUE, outline = FALSE)

# Trajectoires individuelles
set.seed(42)
jit1 <- jitter(rep(1, length(pre_scores)), amount = 0.05)
jit2 <- jitter(rep(2, length(post_scores)), amount = 0.05)

for (i in seq_along(pre_scores)) {
  is_atyp <- pre_wide_app$Profil_Atypique[i] != "Standard"
  line_col <- ifelse(is_atyp, "#E67E22AA", "#8E44AD44")
  line_lwd <- ifelse(is_atyp, 2.5, 1.5)
  lines(c(jit1[i], jit2[i]), c(pre_scores[i], post_scores[i]), col = line_col, lwd = line_lwd)
  points(jit1[i], pre_scores[i], pch = 21, bg = ifelse(is_atyp, "#E67E22", "#4A90E2"), col = "#1B365D", cex = 1.3)
  points(jit2[i], post_scores[i], pch = 21, bg = ifelse(is_atyp, "#E67E22", "#2E7D32"), col = "#1B365D", cex = 1.3)
}

# Annotations directes des moyennes et médianes
m1 <- mean(pre_scores); med1 <- median(pre_scores)
m2 <- mean(post_scores); med2 <- median(post_scores)

text(1, 21.8, sprintf("Moyenne : %.2f/20\nMédiane : %.2f/20\n(N = 22)", m1, med1), 
     col = "#1B365D", font = 2, cex = 0.95)
text(2, 21.8, sprintf("Moyenne : %.2f/20\nMédiane : %.2f/20\n(N = 22)", m2, med2), 
     col = "#1B365D", font = 2, cex = 0.95)

legend("bottomright",
       legend = c("Pré-test (N = 22)", "Post-test (N = 22)", "Trajectoire standard", "Profil atypique (< 5 min Pre)"),
       fill = c("#4A90E2", "#2E7D32", NA, NA),
       border = c("#1B365D", "#1B365D", NA, NA),
       lty = c(NA, NA, 1, 1), col = c(NA, NA, "#8E44AD", "#E67E22"),
       lwd = c(NA, NA, 1.5, 2.5),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

dev.off()
cat("  -> Graphique généré : output/figure1_distributions_scores_pre_post.png\n")

# ------------------------------------------------------------------------------
# FIGURE 2 : Waterfall Plot des progressions individuelles
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure2_progressions_individuelles_waterfall.png"),
    width = 3400, height = 2200, res = 300, bg = "white")

par(mar = c(6, 6, 4, 3), family = "sans", las = 1)

df_waterfall <- tab_individuel[order(tab_individuel$Delta_Score), ]
n_part <- nrow(df_waterfall)

couleurs_waterfall <- ifelse(df_waterfall$Profil == "Speed-run Pretest (IDK >= 24)", "#E67E22",
                             ifelse(df_waterfall$Delta_Score > 0, "#2E7D32", "#C62828"))

bp <- barplot(df_waterfall$Delta_Score,
              names.arg = df_waterfall$ID,
              col = couleurs_waterfall,
              border = "#1B365D",
              ylim = c(-3, 17),
              ylab = "Gain de score individuel (Post - Pré, sur 20)",
              xlab = "",
              main = "Progression individuelle des étudiants (Waterfall Plot - BAC 3 2025)",
              cex.main = 1.3, font.main = 2, col.main = "#1B365D",
              cex.lab = 1.1, font.lab = 2,
              cex.names = 0.85, las = 2)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
abline(h = 0, col = "#1B365D", lwd = 1.5)

# Re-dessiner les barres par-dessus la grille
barplot(df_waterfall$Delta_Score, col = couleurs_waterfall, border = "#1B365D", add = TRUE, axes = FALSE)

# Labels numériques sur les barres
for (i in 1:n_part) {
  val <- df_waterfall$Delta_Score[i]
  pos_y <- ifelse(val >= 0, val + 0.5, val - 0.7)
  txt <- sprintf("%+.1f", val)
  text(bp[i], pos_y, txt, font = 2, cex = 0.75, col = "#1B365D")
}

# Ligne moyenne globale
m_gain <- mean(df_waterfall$Delta_Score)
abline(h = m_gain, col = "#4A90E2", lty = 2, lwd = 2)
text(2, m_gain + 0.8, sprintf("Gain moyen global : %+.2f pts (N = 22)", m_gain), col = "#1B365D", font = 2, pos = 4, cex = 0.9)

legend("topleft",
       legend = c("Progression positive (N = 21)", "Régression ponctuelle (N = 1)", "Profil atypique (< 5 min Pre, N = 2)", "Gain moyen global"),
       fill = c("#2E7D32", "#C62828", "#E67E22", NA),
       border = c("#1B365D", "#1B365D", "#1B365D", NA),
       lty = c(NA, NA, NA, 2), col = c(NA, NA, NA, "#4A90E2"), lwd = c(NA, NA, NA, 2),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

dev.off()
cat("  -> Graphique généré : output/figure2_progressions_individuelles_waterfall.png\n")

# ------------------------------------------------------------------------------
# FIGURE 3 : Taux de succès selon le Sexe de l'abeille et la Guilde (avec IC Wilson)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure3_succes_sexe_guilde.png"),
    width = 3300, height = 2200, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

# Préparation des 4 sous-groupes (Mâle vs Femelle, Non parasite vs Cléptoparasite)
sub_sg <- tab_sexe_guilde[tab_sexe_guilde$Facteur %in% c("Sexe_Specimen", "Guilde_Solution"), ]

# Réorganisation en matrice 2 x 4 (Pré vs Post)
labels_grp <- c("Femelles", "Mâles", "Non parasites", "Cléptoparasites")
tx_pre_sg  <- c(sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Femelle" & sub_sg$Cohorte == "Pré-test"],
                sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Mâle" & sub_sg$Cohorte == "Pré-test"],
                sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Non parasite" & sub_sg$Cohorte == "Pré-test"],
                sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Cléptoparasite" & sub_sg$Cohorte == "Pré-test"])

tx_post_sg <- c(sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Femelle" & sub_sg$Cohorte == "Post-test"],
                sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Mâle" & sub_sg$Cohorte == "Post-test"],
                sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Non parasite" & sub_sg$Cohorte == "Post-test"],
                sub_sg$Taux_Succes_Pct[sub_sg$Modalite == "Cléptoparasite" & sub_sg$Cohorte == "Post-test"])

mat_bar <- rbind(tx_pre_sg, tx_post_sg)

bp_sg <- barplot(mat_bar, beside = TRUE,
                 names.arg = labels_grp,
                 col = c("#4A90E2", "#2E7D32"),
                 border = "#1B365D",
                 ylim = c(0, 105),
                 ylab = "Taux d'identification correcte (%)",
                 main = "Taux de succès selon le sexe du spécimen et la guilde écologique (BAC 3 - 2025)",
                 cex.main = 1.3, font.main = 2, col.main = "#1B365D",
                 cex.lab = 1.1, font.lab = 2, cex.names = 1.0)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
barplot(mat_bar, beside = TRUE, col = c("#4A90E2", "#2E7D32"), border = "#1B365D", add = TRUE, axes = FALSE)

# Ajout des barres d'erreur IC 95% Wilson
ic_inf_mat <- rbind(
  c(sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Femelle" & sub_sg$Cohorte == "Pré-test"],
    sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Mâle" & sub_sg$Cohorte == "Pré-test"],
    sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Non parasite" & sub_sg$Cohorte == "Pré-test"],
    sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Cléptoparasite" & sub_sg$Cohorte == "Pré-test"]),
  c(sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Femelle" & sub_sg$Cohorte == "Post-test"],
    sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Mâle" & sub_sg$Cohorte == "Post-test"],
    sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Non parasite" & sub_sg$Cohorte == "Post-test"],
    sub_sg$IC_Wilson_Inf[sub_sg$Modalite == "Cléptoparasite" & sub_sg$Cohorte == "Post-test"])
)

ic_sup_mat <- rbind(
  c(sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Femelle" & sub_sg$Cohorte == "Pré-test"],
    sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Mâle" & sub_sg$Cohorte == "Pré-test"],
    sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Non parasite" & sub_sg$Cohorte == "Pré-test"],
    sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Cléptoparasite" & sub_sg$Cohorte == "Pré-test"]),
  c(sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Femelle" & sub_sg$Cohorte == "Post-test"],
    sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Mâle" & sub_sg$Cohorte == "Post-test"],
    sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Non parasite" & sub_sg$Cohorte == "Post-test"],
    sub_sg$IC_Wilson_Sup[sub_sg$Modalite == "Cléptoparasite" & sub_sg$Cohorte == "Post-test"])
)

for (r in 1:2) {
  for (c_idx in 1:4) {
    x_pos <- bp_sg[r, c_idx]
    y_val <- mat_bar[r, c_idx]
    y_inf <- ic_inf_mat[r, c_idx]
    y_sup <- ic_sup_mat[r, c_idx]
    
    arrows(x_pos, y_inf, x_pos, y_sup, angle = 90, code = 3, length = 0.05, col = "#1B365D", lwd = 1.5)
    # Texte de pourcentage au-dessus de la barre d'erreur
    text(x_pos, y_sup + 4, sprintf("%.1f%%", y_val), font = 2, cex = 0.85, col = "#1B365D")
  }
}

# Démarcation visuelle entre Sexe et Guilde
abline(v = mean(c(bp_sg[2, 2], bp_sg[1, 3])), col = "#1B365D", lty = 3, lwd = 1.5)
text(mean(bp_sg[, 1:2]), 102, "Dimorphisme sexuel", col = "#1B365D", font = 2, cex = 1.0)
text(mean(bp_sg[, 3:4]), 102, "Guilde écologique", col = "#1B365D", font = 2, cex = 1.0)

legend("topleft",
       legend = c("Pré-test (Avant formation)", "Post-test (Après formation)", "Intervalle de confiance Wilson à 95%"),
       fill = c("#4A90E2", "#2E7D32", NA),
       border = c("#1B365D", "#1B365D", NA),
       lty = c(NA, NA, 1), col = c(NA, NA, "#1B365D"), lwd = c(NA, NA, 1.5),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9)

dev.off()
cat("  -> Graphique généré : output/figure3_succes_sexe_guilde.png\n")

# ------------------------------------------------------------------------------
# FIGURE 4 : Effondrement de l'incertitude (Nombre de 'Je ne sais pas')
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "figure4_effondrement_incertitude_idk.png"),
    width = 3200, height = 2300, res = 300, bg = "white")

par(mar = c(5, 6, 4, 3), family = "sans", las = 1)

boxplot(list("Pré-test (Avant formation)" = pre_idk, 
             "Post-test (Après TP)" = post_idk),
        col = c("#E67E22", "#2E7D32"),
        border = "#1B365D",
        ylim = c(0, 33),
        ylab = "Nombre de réponses 'Je ne sais pas' (/28 questions)",
        main = "Évolution de l'incertitude : effondrement des réponses 'Je ne sais pas' (BAC 3 - 2025)",
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
  is_atyp <- pre_wide_app$Profil_Atypique[k] != "Standard"
  line_col <- ifelse(is_atyp, "#E67E22AA", "#8E44AD44")
  line_lwd <- ifelse(is_atyp, 2.5, 1.5)
  lines(c(jit_idk1[k], jit_idk2[k]), c(pre_idk[k], post_idk[k]), col = line_col, lwd = line_lwd)
  points(jit_idk1[k], pre_idk[k], pch = 21, bg = ifelse(is_atyp, "#E67E22", "#E67E22"), col = "#1B365D", cex = 1.3)
  points(jit_idk2[k], post_idk[k], pch = 21, bg = ifelse(is_atyp, "#E67E22", "#2E7D32"), col = "#1B365D", cex = 1.3)
}

# Annotations des moyennes et médianes (positionnées pour éviter tout chevauchement)
m_idk1 <- mean(pre_idk); med_idk1 <- median(pre_idk)
m_idk2 <- mean(post_idk); med_idk2 <- median(post_idk)

# Pré-test (colonne 1) : placé à y = 28 (au-dessus des points, à gauche de la légende)
text(1, 28, sprintf("Moyenne : %.1f / 28\nMédiane : %.0f / 28\nTotal : %d IDK", m_idk1, med_idk1, sum(pre_idk)), 
     col = "#1B365D", font = 2, cex = 0.95)

# Post-test (colonne 2) : descendu à y = 14 (dans l'espace dégagé, bien en-dessous de la boîte de légende)
text(2, 14, sprintf("Moyenne : %.1f / 28\nMédiane : %.0f / 28\nTotal : %d IDK (-92.2%%)", m_idk2, med_idk2, sum(post_idk)), 
     col = "#1B365D", font = 2, cex = 0.95)

legend("topright",
       legend = c("Pré-test (N = 22)", "Post-test (N = 22)", "Trajectoire standard", "Profil atypique (IDK >= 24)"),
       fill = c("#E67E22", "#2E7D32", NA, NA),
       border = c("#1B365D", "#1B365D", NA, NA),
       lty = c(NA, NA, 1, 1), col = c(NA, NA, "#8E44AD", "#E67E22"),
       lwd = c(NA, NA, 1.5, 2.5),
       bg = "#FFFFFFEE", box.col = "#D0D7DE", cex = 0.9, inset = c(0.02, 0.02))

dev.off()
cat("  -> Graphique généré : output/figure4_effondrement_incertitude_idk.png\n")

cat("\n======================================================================\n")
cat("=== ANALYSE AXE A (BAC 3 2025) TERMINÉE AVEC SUCCÈS ===\n")
cat("======================================================================\n")

