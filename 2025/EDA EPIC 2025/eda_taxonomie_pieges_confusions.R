# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# ÉTAPE 2 : EDA (Exploratory Data Analysis) - EPIC 2025
# SCRIPT 3 : Analyse Taxonomique par Genre, Pièges et Confusions (Axe B)
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

# 1. CHARGEMENT DES DONNÉES FORMAT LONG ----------------------------------------
f_long <- file.path(dossier_eda, "EPIC_2025_clean_long.csv")
if (!file.exists(f_long)) f_long <- "EPIC_2025_clean_long.csv"

df_long <- read.csv(f_long, sep = ";", dec = ",", stringsAsFactors = FALSE)
cat(sprintf("Chargement du format long : %d observations d'évaluation\n\n", nrow(df_long)))

# 2. CALCUL DES PERFORMANCES PAR GENRE (PRÉ VS POST) --------------------------
# Fonction de calcul d'intervalle de confiance de Wilson (95%)
calc_wilson <- function(succes, total) {
  p <- succes / total
  z <- 1.96
  denom <- 1 + (z^2 / total)
  centre <- (p + (z^2 / (2 * total))) / denom
  marge <- (z * sqrt((p * (1 - p) / total) + (z^2 / (4 * total^2)))) / denom
  c(inf = max(0, centre - marge) * 100, sup = min(1, centre + marge) * 100)
}

genres_uniques <- sort(unique(df_long$Genre_Solution))

stats_genres_list <- list()

for (g in genres_uniques) {
  sub_pre <- df_long[df_long$Genre_Solution == g & df_long$Cohorte == "Pré-test", ]
  sub_post <- df_long[df_long$Genre_Solution == g & df_long$Cohorte == "Post-test", ]
  
  n_pre <- nrow(sub_pre)
  succ_pre <- sum(sub_pre$Est_Correct)
  taux_pre <- (succ_pre / n_pre) * 100
  ic_pre <- calc_wilson(succ_pre, n_pre)
  
  n_post <- nrow(sub_post)
  succ_post <- sum(sub_post$Est_Correct)
  taux_post <- (succ_post / n_post) * 100
  ic_post <- calc_wilson(succ_post, n_post)
  
  fam <- sub_pre$Famille_Solution[1]
  guilde <- sub_pre$Guilde_Solution[1]
  nb_questions <- length(unique(sub_pre$Question_Num))
  
  stats_genres_list[[g]] <- data.frame(
    Genre = g,
    Famille = fam,
    Guilde = guilde,
    Questions_Test = nb_questions,
    N_Pre = n_pre,
    Succes_Pre = succ_pre,
    Taux_Succes_Pre = round(taux_pre, 2),
    IC_Inf_Pre = round(ic_pre["inf"], 2),
    IC_Sup_Pre = round(ic_pre["sup"], 2),
    N_Post = n_post,
    Succes_Post = succ_post,
    Taux_Succes_Post = round(taux_post, 2),
    IC_Inf_Post = round(ic_post["inf"], 2),
    IC_Sup_Post = round(ic_post["sup"], 2),
    Gain_Absolu_Pct = round(taux_post - taux_pre, 2),
    Gain_Relatif_Pct = round(((taux_post - taux_pre) / (100 - taux_pre)) * 100, 2),
    stringsAsFactors = FALSE
  )
}

df_genres <- do.call(rbind, stats_genres_list)
rownames(df_genres) <- NULL

# Tri par difficulté au Pré-test (croissant = du plus difficile au plus facile)
df_genres <- df_genres[order(df_genres$Taux_Succes_Pre), ]

cat("=== Classement des genres par taux de réussite au Pré-test ===\n")
print(df_genres[, c("Genre", "Famille", "Taux_Succes_Pre", "Taux_Succes_Post", "Gain_Absolu_Pct")])

exporter_excel_csv(df_genres, file.path(dossier_output, "tableau_performances_par_genre.csv"))

# 3. ANALYSE DES CONFUSIONS TAXONOMIQUES MAJEURES -----------------------------
# On extrait les erreurs où Genre_Reponse != Genre_Solution et != "Je ne sais pas" et != "Non répondu"
df_erreurs <- df_long[df_long$Est_Correct == 0 & 
                      df_long$Genre_Reponse != "Je ne sais pas" & 
                      df_long$Genre_Reponse != "Non répondu", ]

# Paires de confusion
df_erreurs$Paire_Confusion <- paste0(df_erreurs$Genre_Solution, " -> ", df_erreurs$Genre_Reponse)

compter_confusions <- function(sub_df, label_cohorte) {
  tab <- as.data.frame(table(sub_df$Paire_Confusion), stringsAsFactors = FALSE)
  colnames(tab) <- c("Paire_Confusion", "Frequence")
  tab$Cohorte <- label_cohorte
  parts <- strsplit(tab$Paire_Confusion, " -> ")
  tab$Genre_Solution <- sapply(parts, `[`, 1)
  tab$Genre_Confus <- sapply(parts, `[`, 2)
  # Proportion d'erreurs relatives au nombre total de présentations de ce genre
  n_total_genre <- sapply(tab$Genre_Solution, function(g) sum(sub_df$Genre_Solution == g))
  tab$Pourcentage_Erreur_Du_Genre <- round((tab$Frequence / n_total_genre) * 100, 2)
  tab <- tab[order(-tab$Frequence), ]
  return(tab)
}

conf_pre  <- compter_confusions(df_erreurs[df_erreurs$Cohorte == "Pré-test", ], "Pré-test")
conf_post <- compter_confusions(df_erreurs[df_erreurs$Cohorte == "Post-test", ], "Post-test")
conf_all  <- rbind(conf_pre, conf_post)

cat("\n=== Top 10 des confusions taxonomiques les plus fréquentes en Pré-test ===\n")
print(head(conf_pre[, c("Paire_Confusion", "Frequence", "Pourcentage_Erreur_Du_Genre")], 10))

cat("\n=== Top 10 des confusions taxonomiques les plus fréquentes en Post-test ===\n")
print(head(conf_post[, c("Paire_Confusion", "Frequence", "Pourcentage_Erreur_Du_Genre")], 10))

exporter_excel_csv(conf_all, file.path(dossier_output, "tableau_confusions_taxonomiques_detail.csv"))

# ==============================================================================
# 4. VISUALISATIONS GRAPHIQUES HAUTE DÉFINITION (CHARTE AGENTS.md, 300 DPI)
# ==============================================================================
col_vert_succes   <- "#2E7D32" # Vert émeraude (Post-test / Succès)
col_rouge_erreur  <- "#C62828" # Rouge rubis (Pré-test / Erreurs / Pièges)
col_bleu_ardoise  <- "#4A90E2" # Bleu ardoise (Comparaison / Neutre)
col_bleu_nuit     <- "#1B365D" # Bleu nuit foncé (Structure / Titres)
col_orange_diff   <- "#E67E22" # Ambre / Orange (Difficulté intermédiaire)
col_violet        <- "#8E44AD" # Violet profond (Confusions taxonomiques)
col_gris_bord     <- "#D0D7DE"

# ------------------------------------------------------------------------------
# FIGURE 5 : Classement de la Difficulté par Genre (Diptyque Pré-test & Post-test)
# ------------------------------------------------------------------------------
# 5.1 Diptyque côte à côte (2 panneaux nets et distincts)
png(file.path(dossier_output, "fig5_classement_difficulte_genres_pre_post.png"),
    width = 4400, height = 2800, res = 300, bg = "white")
par(mfrow = c(1, 2), mar = c(5, 11, 4, 3), family = "sans")

# Panneau A : Pré-test
df_pre_sort <- df_genres[order(df_genres$Taux_Succes_Pre), ]
bp5_pre <- barplot(df_pre_sort$Taux_Succes_Pre, horiz = TRUE,
                   col = col_bleu_ardoise, xlim = c(0, 120),
                   names.arg = df_pre_sort$Genre, las = 1,
                   xlab = "Taux de réussite (%) [IC Wilson 95%]",
                   main = "A. Pré-test (Avant formation)",
                   border = "white", cex.names = 0.9, font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
abline(v = 50, col = col_rouge_erreur, lty = 2, lwd = 1.2)
text(50, nrow(df_pre_sort) * 1.2 + 1, "Seuil 50%", col = col_rouge_erreur, cex = 0.8, adj = 0.5)

for (i in 1:nrow(df_pre_sort)) {
  y <- bp5_pre[i]
  x <- df_pre_sort$Taux_Succes_Pre[i]
  segments(df_pre_sort$IC_Inf_Pre[i], y, df_pre_sort$IC_Sup_Pre[i], y, col = col_bleu_nuit, lwd = 1.5)
  segments(df_pre_sort$IC_Inf_Pre[i], y - 0.2, df_pre_sort$IC_Inf_Pre[i], y + 0.2, col = col_bleu_nuit, lwd = 1.5)
  segments(df_pre_sort$IC_Sup_Pre[i], y - 0.2, df_pre_sort$IC_Sup_Pre[i], y + 0.2, col = col_bleu_nuit, lwd = 1.5)
  max_x <- max(x, df_pre_sort$IC_Sup_Pre[i])
  text(max_x + 1.5, y, labels = sprintf("%.1f%%", x), col = "black", font = 2, cex = 0.8, adj = 0)
}

# Panneau B : Post-test
df_post_sort <- df_genres[order(df_genres$Taux_Succes_Post), ]
bp5_post <- barplot(df_post_sort$Taux_Succes_Post, horiz = TRUE,
                    col = col_vert_succes, xlim = c(0, 120),
                    names.arg = df_post_sort$Genre, las = 1,
                    xlab = "Taux de réussite (%) [IC Wilson 95%]",
                    main = "B. Post-test (Après formation)",
                    border = "white", cex.names = 0.9, font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
abline(v = 50, col = col_rouge_erreur, lty = 2, lwd = 1.2)
text(50, nrow(df_post_sort) * 1.2 + 1, "Seuil 50%", col = col_rouge_erreur, cex = 0.8, adj = 0.5)

for (i in 1:nrow(df_post_sort)) {
  y <- bp5_post[i]
  x <- df_post_sort$Taux_Succes_Post[i]
  segments(df_post_sort$IC_Inf_Post[i], y, df_post_sort$IC_Sup_Post[i], y, col = "#1E5F22", lwd = 1.5)
  segments(df_post_sort$IC_Inf_Post[i], y - 0.2, df_post_sort$IC_Inf_Post[i], y + 0.2, col = "#1E5F22", lwd = 1.5)
  segments(df_post_sort$IC_Sup_Post[i], y - 0.2, df_post_sort$IC_Sup_Post[i], y + 0.2, col = "#1E5F22", lwd = 1.5)
  max_x <- max(x, df_post_sort$IC_Sup_Post[i])
  text(max_x + 1.5, y, labels = sprintf("%.1f%%", x), col = "black", font = 2, cex = 0.8, adj = 0)
}

dev.off()
cat("  -> Figure 5 générée (Diptyque Pré/Post) : output/fig5_classement_difficulte_genres_pre_post.png\n")

# 5.2 Export additionnel : Graphique individuel Pré-test
png(file.path(dossier_output, "fig5a_classement_difficulte_genres_pretest.png"),
    width = 3600, height = 2800, res = 300, bg = "white")
par(mar = c(5, 12, 4, 4), family = "sans")
bp5a <- barplot(df_pre_sort$Taux_Succes_Pre, horiz = TRUE,
                col = col_bleu_ardoise, xlim = c(0, 115),
                names.arg = df_pre_sort$Genre, las = 1,
                xlab = "Taux de réussite (%) [IC Wilson 95%]",
                main = "Difficulté d'identification par genre : Pré-test (Avant formation)",
                border = "white", cex.names = 0.95, font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
abline(v = 50, col = col_rouge_erreur, lty = 2, lwd = 1.2)
text(50, nrow(df_pre_sort) * 1.2 + 1, "Seuil 50%", col = col_rouge_erreur, cex = 0.85, adj = 0.5)
for (i in 1:nrow(df_pre_sort)) {
  y <- bp5a[i]
  x <- df_pre_sort$Taux_Succes_Pre[i]
  segments(df_pre_sort$IC_Inf_Pre[i], y, df_pre_sort$IC_Sup_Pre[i], y, col = col_bleu_nuit, lwd = 1.5)
  segments(df_pre_sort$IC_Inf_Pre[i], y - 0.2, df_pre_sort$IC_Inf_Pre[i], y + 0.2, col = col_bleu_nuit, lwd = 1.5)
  segments(df_pre_sort$IC_Sup_Pre[i], y - 0.2, df_pre_sort$IC_Sup_Pre[i], y + 0.2, col = col_bleu_nuit, lwd = 1.5)
  max_x <- max(x, df_pre_sort$IC_Sup_Pre[i])
  text(max_x + 1.5, y, labels = sprintf("%.1f%%", x), col = "black", font = 2, cex = 0.85, adj = 0)
}
dev.off()
cat("  -> Figure 5A (Pré-test seul) : output/fig5a_classement_difficulte_genres_pretest.png\n")

# 5.3 Export additionnel : Graphique individuel Post-test
png(file.path(dossier_output, "fig5b_classement_difficulte_genres_posttest.png"),
    width = 3600, height = 2800, res = 300, bg = "white")
par(mar = c(5, 12, 4, 4), family = "sans")
bp5b <- barplot(df_post_sort$Taux_Succes_Post, horiz = TRUE,
                col = col_vert_succes, xlim = c(0, 115),
                names.arg = df_post_sort$Genre, las = 1,
                xlab = "Taux de réussite (%) [IC Wilson 95%]",
                main = "Difficulté d'identification par genre : Post-test (Après formation)",
                border = "white", cex.names = 0.95, font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
abline(v = 50, col = col_rouge_erreur, lty = 2, lwd = 1.2)
text(50, nrow(df_post_sort) * 1.2 + 1, "Seuil 50%", col = col_rouge_erreur, cex = 0.85, adj = 0.5)
for (i in 1:nrow(df_post_sort)) {
  y <- bp5b[i]
  x <- df_post_sort$Taux_Succes_Post[i]
  segments(df_post_sort$IC_Inf_Post[i], y, df_post_sort$IC_Sup_Post[i], y, col = "#1E5F22", lwd = 1.5)
  segments(df_post_sort$IC_Inf_Post[i], y - 0.2, df_post_sort$IC_Inf_Post[i], y + 0.2, col = "#1E5F22", lwd = 1.5)
  segments(df_post_sort$IC_Sup_Post[i], y - 0.2, df_post_sort$IC_Sup_Post[i], y + 0.2, col = "#1E5F22", lwd = 1.5)
  max_x <- max(x, df_post_sort$IC_Sup_Post[i])
  text(max_x + 1.5, y, labels = sprintf("%.1f%%", x), col = "black", font = 2, cex = 0.85, adj = 0)
}
dev.off()
cat("  -> Figure 5B (Post-test seul) : output/fig5b_classement_difficulte_genres_posttest.png\n")

# ------------------------------------------------------------------------------
# FIGURE 6 : Gain d'Apprentissage par Genre (Delta = Post - Pré)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig6_gain_apprentissage_par_genre.png"),
    width = 3800, height = 2800, res = 300, bg = "white")
par(mar = c(5, 12, 4, 4), family = "sans")

df_plot6 <- df_genres[order(df_genres$Gain_Absolu_Pct), ]
col_gain <- ifelse(df_plot6$Gain_Absolu_Pct >= 35, col_vert_succes,
            ifelse(df_plot6$Gain_Absolu_Pct >= 20, col_bleu_ardoise, col_orange_diff))

bp6 <- barplot(df_plot6$Gain_Absolu_Pct, horiz = TRUE, col = col_gain,
               names.arg = df_plot6$Genre, las = 1,
               xlim = c(0, max(df_plot6$Gain_Absolu_Pct) * 1.25),
               xlab = "Gain absolu de réussite (points de pourcentage : Post - Pré)",
               main = "Progression taxonomique par genre après formation",
               border = "white", cex.names = 0.95, font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)

# Annotations directes des valeurs : affichage simple du gain +XX.X% en noir
for (i in 1:nrow(df_plot6)) {
  val <- df_plot6$Gain_Absolu_Pct[i]
  text(val + 1.2, bp6[i], labels = sprintf("+%.1f%%", val),
       col = "black", font = 2, cex = 0.85, adj = 0)
}

legend("bottomright", legend = c("Progression majeure (>= +35%)", "Progression modérée (+20 à +35%)", "Progression limitée (< +20%)"),
       fill = c(col_vert_succes, col_bleu_ardoise, col_orange_diff), bty = "o", bg = "#FFFFFFEE", box.col = col_gris_bord, cex = 0.9)

dev.off()
cat("  -> Figure 6 générée : output/fig6_gain_apprentissage_par_genre.png\n")

# ------------------------------------------------------------------------------
# FIGURE 7 : Top des Pièges Persistants en Post-test et Rôle des Familles
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig7_top_pieges_persistants_post.png"),
    width = 3600, height = 2600, res = 300, bg = "white")
par(mfrow = c(1, 2), mar = c(5, 10, 4, 3), family = "sans")

# Panneau A : Les 7 genres avec le plus fort taux d'échec post-formation
df_pieges <- df_genres[order(df_genres$Taux_Succes_Post), ][1:7, ]
bp_p <- barplot(100 - df_pieges$Taux_Succes_Post, horiz = TRUE, col = col_rouge_erreur,
                names.arg = df_pieges$Genre, las = 1,
                xlim = c(0, 70), xlab = "Taux d'erreur résiduel au Post-test (%)",
                main = "A. Top 7 des pièges persistants", border = "white", font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
text(100 - df_pieges$Taux_Succes_Post + 2, bp_p,
     labels = sprintf("%.1f%% d'erreur", 100 - df_pieges$Taux_Succes_Post), font = 2, cex = 0.85, adj = 0)

# Panneau B : Performances par Famille d'abeilles
agg_fam <- aggregate(Est_Correct ~ Famille_Solution + Cohorte, data = df_long, FUN = function(x) round(mean(x) * 100, 2))
fam_names <- unique(agg_fam$Famille_Solution)
fam_pre <- sapply(fam_names, function(f) agg_fam$Est_Correct[agg_fam$Famille_Solution == f & agg_fam$Cohorte == "Pré-test"])
fam_post <- sapply(fam_names, function(f) agg_fam$Est_Correct[agg_fam$Famille_Solution == f & agg_fam$Cohorte == "Post-test"])

df_fam <- data.frame(Famille = fam_names, Pre = fam_pre, Post = fam_post, stringsAsFactors = FALSE)
df_fam <- df_fam[order(df_fam$Pre), ]

mat_fam <- rbind(df_fam$Pre, df_fam$Post)
bp_fam <- barplot(mat_fam, beside = TRUE, horiz = TRUE,
                  col = c(col_bleu_ardoise, col_vert_succes),
                  names.arg = df_fam$Famille, las = 1,
                  xlim = c(0, 115), xlab = "Taux de réussite moyen (%)",
                  main = "B. Taux de succès par Famille", border = "white", font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
text(df_fam$Pre + 2, bp_fam[1, ], sprintf("%.1f%%", df_fam$Pre), font = 2, cex = 0.75, col = col_bleu_nuit, adj = 0)
text(df_fam$Post + 2, bp_fam[2, ], sprintf("%.1f%%", df_fam$Post), font = 2, cex = 0.75, col = "#1E5F22", adj = 0)
legend("bottomright", legend = c("Pré-test", "Post-test"),
       fill = c(col_bleu_ardoise, col_vert_succes), bty = "o", bg = "#FFFFFFEE", box.col = col_gris_bord)

dev.off()
cat("  -> Figure 7 générée : output/fig7_top_pieges_persistants_post.png\n")

# ------------------------------------------------------------------------------
# FIGURE 8 : Top 10 des Confusions Taxonomiques Majeures (Pré vs Post)
# ------------------------------------------------------------------------------
png(file.path(dossier_output, "fig8_matrice_confusions_taxonomiques.png"),
    width = 3800, height = 2800, res = 300, bg = "white")
par(mfrow = c(1, 2), mar = c(5, 13, 4, 3), family = "sans")

# Top 8 Pré-test
top_pre <- head(conf_pre, 8)
top_pre <- top_pre[order(top_pre$Frequence), ]
bp_cpre <- barplot(top_pre$Frequence, horiz = TRUE, col = col_rouge_erreur,
                   names.arg = top_pre$Paire_Confusion, las = 1,
                   xlim = c(0, max(top_pre$Frequence) * 1.35),
                   xlab = "Nombre d'occurrences de confusion",
                   main = "A. Top confusions au Pré-test", border = "white", font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
text(top_pre$Frequence + 0.8, bp_cpre,
     labels = sprintf("%d (%d%%)", top_pre$Frequence, round(top_pre$Pourcentage_Erreur_Du_Genre)),
     font = 2, cex = 0.85, adj = 0)

# Top 8 Post-test
top_post <- head(conf_post, 8)
top_post <- top_post[order(top_post$Frequence), ]
bp_cpost <- barplot(top_post$Frequence, horiz = TRUE, col = col_violet,
                    names.arg = top_post$Paire_Confusion, las = 1,
                    xlim = c(0, max(top_post$Frequence) * 1.35),
                    xlab = "Nombre d'occurrences de confusion",
                    main = "B. Top confusions résiduelles au Post-test", border = "white", font.lab = 2)
grid(nx = NULL, ny = NA, col = "grey90", lty = 1)
text(top_post$Frequence + 0.5, bp_cpost,
     labels = sprintf("%d (%d%%)", top_post$Frequence, round(top_post$Pourcentage_Erreur_Du_Genre)),
     font = 2, cex = 0.85, adj = 0)

dev.off()
cat("  -> Figure 8 générée : output/fig8_matrice_confusions_taxonomiques.png\n")

cat("\nAnalyse Axe B (Taxonomie & Confusions) terminée avec succès !\n")

