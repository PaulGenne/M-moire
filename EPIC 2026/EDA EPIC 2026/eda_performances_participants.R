# ==============================================================================
# PROJET : Mémoire de Fin d'Études - Apprentissage Taxonomique des Abeilles
# PHASE 2 : EDA (Exploratory Data Analysis)
# SCRIPT 2 : Analyse Exploratoire des Performances des Participants
# AUTEUR : Paul Genné & Assistant IA
# ==============================================================================

# 0. CONFIGURATION ET ENVIRONNEMENT --------------------------------------------
dossier_eda <- "EDA EPIC 2026"
dossier_output <- file.path(dossier_eda, "output")
if (!dir.exists(dossier_output)) dir.create(dossier_output, recursive = TRUE)

fichier_wide <- file.path(dossier_eda, "EPIC_Basic_clean_wide.csv")
if (!file.exists(fichier_wide)) {
  stop("Le fichier de données propres n'existe pas. Veuillez exécuter nettoyage_donnees_epic_basic.R d'abord.")
}

df <- read.csv(fichier_wide, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)
cat(sprintf("Chargement du jeu de données propre : %d participants retenus\n\n", nrow(df)))

# Charte graphique éditoriale
col_bleu_fonce <- "#1B365D"
col_bleu_clair <- "#4A90E2"
col_vert       <- "#2E7D32"
col_rouge      <- "#C62828"
col_orange     <- "#E67E22"
col_gris_clair <- "#F5F7FA"
col_gris_bord  <- "#D0D7DE"

# ------------------------------------------------------------------------------
# 1. STATISTIQUES DESCRIPTIVES GLOBALES
# ------------------------------------------------------------------------------
scores <- df$Score_Total_Propre
pcts   <- df$Pourcentage_Reussite
durees <- df$Duree_Minutes

stats_desc <- function(x, nom) {
  cat(sprintf("=== Statistiques descriptives : %s ===\n", nom))
  cat(sprintf("Moyenne        : %.2f\n", mean(x, na.rm = TRUE)))
  cat(sprintf("Écart-type     : %.2f\n", sd(x, na.rm = TRUE)))
  cat(sprintf("Médiane        : %.2f\n", median(x, na.rm = TRUE)))
  cat(sprintf("Écart IQR      : %.2f (Q1=%.2f, Q3=%.2f)\n", IQR(x, na.rm = TRUE), quantile(x, 0.25, na.rm = TRUE), quantile(x, 0.75, na.rm = TRUE)))
  cat(sprintf("Min - Max      : %.2f - %.2f\n\n", min(x, na.rm = TRUE), max(x, na.rm = TRUE)))
}

stats_desc(scores, "Score brut (/30)")
stats_desc(pcts, "Pourcentage de réussite (%)")
stats_desc(durees, "Durée de passation (minutes)")

# Comparaison selon le groupe de formation
cat("=== Comparaison des scores selon Formation_EPIC ===\n")
tapply(scores, df$Formation_EPIC, function(x) {
  c(N = length(x), Moyenne = round(mean(x), 2), EcartType = round(sd(x), 2), Mediane = median(x))
})

# ------------------------------------------------------------------------------
# 2. FIGURE 1 : DISTRIBUTION DES SCORES GLOBAUX ET DENSITÉ
# ------------------------------------------------------------------------------
chemin_fig1 <- file.path(dossier_output, "fig1_distribution_scores_globaux.png")
png(chemin_fig1, width = 2800, height = 2000, res = 300)

par(mar = c(4.8, 5, 3.5, 2), bg = "white")
h <- hist(scores, breaks = seq(6.5, 30.5, by = 1), plot = FALSE)

# Tracé de l'histogramme
plot(h, col = col_bleu_clair, border = "white",
     main = "Distribution des Scores d'Identification Taxonomique (N = 172)",
     xlab = "Score obtenu (/30)", ylab = "Effectif (nombre de participants)",
     ylim = c(0, max(h$counts) * 1.15), las = 1,
     cex.main = 1.3, cex.lab = 1.1, font.lab = 2)
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
plot(h, col = col_bleu_clair, border = "white", add = TRUE)

# Lignes repères Moyenne et Médiane
abline(v = mean(scores), col = col_rouge, lwd = 3, lty = 1)
abline(v = median(scores), col = col_vert, lwd = 3, lty = 2)

# Boîte de statistiques descriptive
legend("topleft",
       legend = c(
         sprintf("Moyenne : %.2f ± %.2f", mean(scores), sd(scores)),
         sprintf("Médiane : %.1f", median(scores)),
         sprintf("IQR : [%.1f - %.1f]", quantile(scores, 0.25), quantile(scores, 0.75))
       ),
       col = c(col_rouge, col_vert, NA),
       lty = c(1, 2, NA), lwd = c(3, 3, NA),
       bty = "o", box.col = col_gris_bord, bg = "#FFFFFFEE", cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 1 sauvegardée : %s\n", chemin_fig1))

# ------------------------------------------------------------------------------
# 3. FIGURE 2 : EFFET DE LA FORMATION EPIC (Formés vs Non formés)
# ------------------------------------------------------------------------------
chemin_fig2 <- file.path(dossier_output, "fig2_comparaison_formation_epic.png")
png(chemin_fig2, width = 2800, height = 2100, res = 300)

par(mar = c(5, 5, 4, 2), bg = "white")

scores_formes    <- scores[df$Formation_EPIC == "Formés EPIC"]
scores_nonformes <- scores[df$Formation_EPIC == "Non formés"]

# Boxplot élégant
bp <- boxplot(scores ~ df$Formation_EPIC,
              col = c("#E8F5E9", "#FFEBEE"),
              border = c(col_vert, col_rouge),
              lwd = 2,
              main = "Impact de la Formation EPIC sur le Score d'Identification",
              xlab = "Statut de participation à la formation",
              ylab = "Score d'identification (/30)",
              ylim = c(8, 32), las = 1,
              cex.main = 1.3, cex.lab = 1.1, font.lab = 2)

grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
boxplot(scores ~ df$Formation_EPIC, col = c("#E8F5E9", "#FFEBEE"),
        border = c(col_vert, col_rouge), lwd = 2, add = TRUE, las = 1)

# Ajout des points individuels (jittering)
set.seed(123)
jitter_x1 <- jitter(rep(1, length(scores_formes)), amount = 0.15)
jitter_x2 <- jitter(rep(2, length(scores_nonformes)), amount = 0.15)

points(jitter_x1, scores_formes, pch = 21, bg = "#2E7D3288", col = col_vert, cex = 1.1)
points(jitter_x2, scores_nonformes, pch = 21, bg = "#C6282888", col = col_rouge, cex = 1.1)

# Ajout des moyennes avec point en losange et barre d'erreur IC 95%
m1 <- mean(scores_formes); se1 <- sd(scores_formes) / sqrt(length(scores_formes))
m2 <- mean(scores_nonformes); se2 <- sd(scores_nonformes) / sqrt(length(scores_nonformes))

points(c(1, 2), c(m1, m2), pch = 18, col = "black", cex = 2.2)
arrows(c(1, 2), c(m1 - 1.96 * se1, m2 - 1.96 * se2),
       c(1, 2), c(m1 + 1.96 * se1, m2 + 1.96 * se2),
       angle = 90, code = 3, length = 0.08, lwd = 2.5, col = "black")

# Annotations texte
text(1, 10, sprintf("M = %.2f ± %.2f\n(N = %d)", m1, sd(scores_formes), length(scores_formes)),
     font = 2, col = col_vert, cex = 1)
text(2, 10, sprintf("M = %.2f ± %.2f\n(N = %d)", m2, sd(scores_nonformes), length(scores_nonformes)),
     font = 2, col = col_rouge, cex = 1)

legend("topleft",
       legend = c("Distribution (Médiane & IQR)", "Observations individuelles", "Moyenne ± IC 95%"),
       col = c("black", "grey50", "black"),
       pch = c(NA, 21, 18), lty = c(1, NA, NA), lwd = c(2, NA, NA),
       pt.bg = c(NA, "grey70", "black"), bty = "o", box.col = col_gris_bord, bg = "#FFFFFFEE",
       cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 2 sauvegardée : %s\n", chemin_fig2))

# ------------------------------------------------------------------------------
# 4. FIGURE 3 : RELATION DURÉE DU TEST vs SCORE
# ------------------------------------------------------------------------------
chemin_fig3 <- file.path(dossier_output, "fig3_duree_vs_score.png")
png(chemin_fig3, width = 2800, height = 2000, res = 300)

par(mar = c(5, 5, 4, 2), bg = "white")

couleurs_pts <- ifelse(df$Formation_EPIC == "Formés EPIC", col_vert, col_bleu_fonce)

plot(df$Duree_Minutes, scores, pch = 19, col = adjustcolor(couleurs_pts, alpha.f = 0.7),
     cex = 1.3,
     main = "Relation entre le Temps de Réflexion et la Précision du Test",
     xlab = "Durée totale de passation (minutes)",
     ylab = "Score d'identification (/30)",
     las = 1, cex.main = 1.3, cex.lab = 1.1, font.lab = 2,
     xlim = c(10, 130), ylim = c(8, 31))
grid(col = "grey90", lty = 1)
points(df$Duree_Minutes, scores, pch = 19, col = adjustcolor(couleurs_pts, alpha.f = 0.7), cex = 1.3)

# Courbes de tendance lissées (LOESS)
df_loess <- data.frame(Duree = df$Duree_Minutes, Score = scores)
loess_all <- loess(Score ~ Duree, data = df_loess, span = 0.75)
seq_duree <- seq(min(df$Duree_Minutes, na.rm = TRUE), max(df$Duree_Minutes, na.rm = TRUE), by = 1)
pred_y <- predict(loess_all, newdata = data.frame(Duree = seq_duree))
lines(seq_duree, pred_y, col = "black", lwd = 3)

# Corrélation de Spearman (robuste)
cor_test <- cor.test(df$Duree_Minutes, scores, method = "spearman")

legend("bottomleft",
       legend = c(
         sprintf("Formés EPIC (N = %d)", sum(df$Formation_EPIC == "Formés EPIC")),
         sprintf("Non formés (N = %d)", sum(df$Formation_EPIC == "Non formés")),
         sprintf("Tendance LOESS (r_s = %.2f, p = %.3f)", cor_test$estimate, cor_test$p.value)
       ),
       col = c(col_vert, col_bleu_fonce, "black"),
       pch = c(19, 19, NA), lty = c(NA, NA, 1), lwd = c(NA, NA, 3),
       bty = "o", box.col = col_gris_bord, bg = "#FFFFFFEE", cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 3 sauvegardée : %s\n", chemin_fig3))

# ------------------------------------------------------------------------------
# 5. FIGURE 4 : VARIABILITÉ SELON LES RÉGIONS GÉOGRAPHIQUES
# ------------------------------------------------------------------------------
chemin_fig4 <- file.path(dossier_output, "fig4_scores_par_region.png")
png(chemin_fig4, width = 2800, height = 2000, res = 300)

par(mar = c(5, 5, 4, 2), bg = "white")

table_reg <- table(df$Region)
noms_regions <- paste0("Région ", names(table_reg), "\n(n=", table_reg, ")")

palette_regions <- c("#34495E", "#2980B9", "#27AE60", "#E67E22", "#8E44AD")

boxplot(scores ~ factor(df$Region),
        col = adjustcolor(palette_regions, alpha.f = 0.3),
        border = palette_regions,
        lwd = 2,
        names = noms_regions,
        main = "Scores d'Identification selon la Région d'Origine",
        xlab = "Région géographique",
        ylab = "Score d'identification (/30)",
        ylim = c(8, 32), las = 1,
        cex.main = 1.3, cex.lab = 1.1, font.lab = 2)
grid(nx = NA, ny = NULL, col = "grey90", lty = 1)
boxplot(scores ~ factor(df$Region), col = adjustcolor(palette_regions, alpha.f = 0.3),
        border = palette_regions, lwd = 2, names = noms_regions, add = TRUE, las = 1)

# Points moyens
moyennes_reg <- tapply(scores, df$Region, mean)
points(1:length(moyennes_reg), moyennes_reg, pch = 18, cex = 2, col = "black")
text(1:length(moyennes_reg), moyennes_reg + 1.2, sprintf("%.1f", moyennes_reg), font = 2, cex = 0.9)

legend("bottomleft",
       legend = c("Médiane & IQR par région", "Moyenne régionale"),
       col = c("grey40", "black"), pch = c(NA, 18), lty = c(1, NA), lwd = c(2, NA),
       bty = "o", box.col = col_gris_bord, bg = "#FFFFFFEE", cex = 0.95, inset = 0.02)

invisible(dev.off())
cat(sprintf("Figure 4 sauvegardée : %s\n", chemin_fig4))

cat("\n======================================================================\n")
cat("EDA PARTICIPANTS TERMINÉE AVEC SUCCÈS. 4 FIGURES GÉNÉRÉES.\n")
cat("======================================================================\n")
