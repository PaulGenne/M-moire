# ==============================================================================
# SCRIPT R : Génération du Forest Plot Inter-Cohortes des Odds Ratios par Genre
# Mémoire de Master - Université de Mons (UMons)
# Conforme aux règles AGENTS.md (Base R, 300 DPI, palette éditoriale, BOM Excel)
# ==============================================================================

# 1. Dossiers et fonctions utilitaires
dossier_module <- "Synthese Inter-Cohortes"
dossier_output <- file.path(dossier_module, "output")
if (!dir.exists(dossier_output)) {
  dir.create(dossier_output, recursive = TRUE)
}

exporter_excel_csv <- function(df, chemin_fichier) {
  con_bin <- file(chemin_fichier, open = "wb")
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
  close(con_bin)
  con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
  write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  close(con_txt)
  cat(sprintf("  -> Fichier CSV exporté : %s\n", chemin_fichier))
}

# 2. Chargement des données consensuelles inter-cohortes
f_consensus <- file.path(dossier_output, "tableau_consensus_pieges_taxonomiques.csv")
if (!file.exists(f_consensus)) {
  stop("ERREUR : tableau_consensus_pieges_taxonomiques.csv introuvable dans ", dossier_output)
}

df_taxo <- read.csv(f_consensus, sep = ";", dec = ",", stringsAsFactors = FALSE, check.names = FALSE)

# 3. Préparation du modèle logistique binomial global
# Spécification des succès et échecs
df_taxo$Echecs <- df_taxo$N_Total_Post - df_taxo$Succes_Total_Post

# Correction de continuité de Haldane-Anscombe pour Xylocopa (0 échec) afin d'éviter la division par zéro
df_taxo$Succes_adj <- ifelse(df_taxo$Echecs == 0, df_taxo$Succes_Total_Post - 0.5, df_taxo$Succes_Total_Post)
df_taxo$Echecs_adj <- ifelse(df_taxo$Echecs == 0, 0.5, df_taxo$Echecs)

df_taxo$Genre_Fact <- factor(df_taxo$Genre)
df_taxo$Genre_Fact <- relevel(df_taxo$Genre_Fact, ref = "Bombus")

# Ajustement du modèle GLM Binomial
mod_glm <- glm(cbind(Succes_adj, Echecs_adj) ~ Genre_Fact, data = df_taxo, family = binomial(link = "logit"))
sm <- summary(mod_glm)$coefficients

# Extraction des résultats pour chaque genre
genres_levels <- levels(df_taxo$Genre_Fact)
genres_non_ref <- genres_levels[genres_levels != "Bombus"]

noms_coefs <- paste0("Genre_Fact", genres_non_ref)

df_or <- data.frame(
  Genre = genres_non_ref,
  Estimate = sm[noms_coefs, "Estimate"],
  Std_Error = sm[noms_coefs, "Std. Error"],
  z_value = sm[noms_coefs, "z value"],
  p_value = sm[noms_coefs, "Pr(>|z|)"],
  stringsAsFactors = FALSE
)

# Ajout du genre de référence Bombus
df_bombus <- data.frame(
  Genre = "Bombus",
  Estimate = 0,
  Std_Error = 0,
  z_value = 0,
  p_value = 1.0,
  stringsAsFactors = FALSE
)
df_or <- rbind(df_or, df_bombus)

# Calcul des Odds Ratios et IC 95%
df_or$OR <- exp(df_or$Estimate)
df_or$IC_inf <- exp(df_or$Estimate - 1.96 * df_or$Std_Error)
df_or$IC_sup <- exp(df_or$Estimate + 1.96 * df_or$Std_Error)

# Fusionner avec les métadonnées (Catégorie, Famille, N, Taux d'erreur)
df_or <- merge(df_or, df_taxo[, c("Genre", "Famille", "Guilde", "N_Total_Post", "Succes_Total_Post", "Taux_Succes_Post", "Taux_Erreur_Post", "Categorie_Difficulte")], by = "Genre")

# Correction FDR de Benjamini-Hochberg pour les comparaisons multiples
df_or$p_adj_fdr <- p.adjust(df_or$p_value, method = "BH")

# Tri par ordre croissant d'Odds Ratio (du plus difficile au plus facile)
df_or <- df_or[order(df_or$OR), ]
rownames(df_or) <- NULL

# Export du tableau CSV conforme pour Excel
exporter_excel_csv(df_or, file.path(dossier_output, "tableau_genres_odds_ratios_intercohortes.csv"))
cat("--> Tableau des Odds Ratios inter-cohortes calculé avec succès !\n")

# 4. Tracé du Forest Plot Inter-Cohortes haute définition (300 DPI)
fichier_png <- file.path(dossier_output, "figure4_forest_plot_odds_ratios_genres_intercohortes.png")

png(fichier_png, width = 3600, height = 3000, res = 300, bg = "white")

# Marges optimisées : marge droite resserrée car les étiquettes sont directement accolées aux barres
par(mar = c(5.5, 9.5, 4.5, 3.0), mgp = c(3.2, 0.8, 0), las = 1)

n_genres <- nrow(df_or)
y_pos <- 1:n_genres

# Attribution des couleurs selon la charte AGENTS.md et les 4 catégories
couleurs_cat <- sapply(df_or$Categorie_Difficulte, function(cat) {
  if (grepl("Très difficile", cat)) return("#C62828")       # Rouge rubis
  if (grepl("modérée", cat))       return("#E67E22")       # Ambre / Orange
  if (grepl("Accessible", cat))    return("#4A90E2")       # Bleu ardoise
  return("#2E7D32")                                        # Vert émeraude (Facile)
})
couleurs_cat[df_or$Genre == "Bombus"] <- "#1B365D"          # Bleu nuit pour la référence

# Échelle logarithmique en base 10 pour l'axe des abscisses (dégagement à droite pour les étiquettes)
xlim_log <- c(-2.3, 3.6) # De 10^-2.3 (~0.005) à 10^3.6 (~4000)
log_or <- log10(pmax(df_or$OR, 0.003))
log_ci_inf <- log10(pmax(df_or$IC_inf, 0.003))
log_ci_sup <- log10(pmin(df_or$IC_sup, 300))

# Initialisation du repère graphique
plot(
  NA, NA,
  xlim = xlim_log,
  ylim = c(0.5, n_genres + 0.5),
  type = "n",
  xaxt = "n",
  yaxt = "n",
  xlab = "Odds Ratio de réussite relative vs Bombus (échelle log10)",
  ylab = "",
  main = "Difficulté relative des 27 genres d'abeilles sauvages (Consensus Inter-Cohortes)\nModèle de régression logistique binaire post-formation (Référence : Bombus = 1,00)",
  cex.main = 1.15,
  font.main = 2,
  col.main = "#1B365D",
  cex.lab = 1.05,
  font.lab = 2
)

# Grille discrète
grid(nx = NULL, ny = NA, col = "grey92", lty = 1)
abline(v = log10(c(0.01, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 50, 100, 500, 1000)), col = "grey94", lty = 3)

# Ligne verticale de référence Bombus (OR = 1, log10 = 0)
abline(v = 0, col = "#1B365D", lty = 2, lwd = 2)

# Bandes alternées légères pour faciliter la lecture des lignes
for (i in seq(1, n_genres, by = 2)) {
  rect(xlim_log[1] - 1, i - 0.45, xlim_log[2] + 1, i + 0.45, col = "#F8F9FA88", border = NA)
}

# Segments d'intervalles de confiance (IC 95%) et barres d'arrêt
for (i in 1:n_genres) {
  if (df_or$Genre[i] != "Bombus") {
    # Ligne d'erreur
    segments(log_ci_inf[i], y_pos[i], log_ci_sup[i], y_pos[i], col = couleurs_cat[i], lwd = 2.2)
    # Tiges d'extrémité
    demi_h <- 0.22
    segments(log_ci_inf[i], y_pos[i] - demi_h, log_ci_inf[i], y_pos[i] + demi_h, col = couleurs_cat[i], lwd = 1.5)
    segments(log_ci_sup[i], y_pos[i] - demi_h, log_ci_sup[i], y_pos[i] + demi_h, col = couleurs_cat[i], lwd = 1.5)
  }
}

# Points représentant les Odds Ratios (carrés proportionnels)
points(log_or, y_pos, pch = 15, col = couleurs_cat, cex = 1.3)
# Pour Bombus, point spécifique (diamant bleu nuit)
points(0, y_pos[df_or$Genre == "Bombus"], pch = 18, col = "#1B365D", cex = 2.0)

# Axe des ordonnées : Noms des genres en italique
axis(2, at = y_pos, labels = paste0(df_or$Genre), font = 3, cex.axis = 0.95, tick = FALSE, line = -0.5)

# Axe des abscisses personnalisé sur échelle log10
grad_ticks <- c(0.01, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0)
axis(1, at = log10(grad_ticks), labels = c("0.01", "0.05", "0.1", "0.2", "0.5", "1.0", "2", "5", "10", "50", "100", "500", "1000"), cex.axis = 0.9)

# Étiquettes des Odds Ratios accolées directement à droite de chaque barre (zéro chevauchement)
for (i in 1:n_genres) {
  if (df_or$Genre[i] == "Bombus") {
    txt_annot <- "OR = 1,00 (Réf.)"
    x_text <- 0.08
    text(x_text, y_pos[i], txt_annot, adj = 0, cex = 0.76, font = 2, col = "#1B365D")
  } else {
    p_signif <- ifelse(df_or$p_adj_fdr[i] < 0.001, "***",
                ifelse(df_or$p_adj_fdr[i] < 0.01, "**",
                ifelse(df_or$p_adj_fdr[i] < 0.05, "*", "ns")))
    
    if (df_or$OR[i] < 1) {
      txt_annot <- sprintf("OR = %.3f [%.2f - %.2f] %s", df_or$OR[i], df_or$IC_inf[i], df_or$IC_sup[i], p_signif)
    } else {
      txt_annot <- sprintf("OR = %.2f [%.2f - %.2f] %s", df_or$OR[i], df_or$IC_inf[i], df_or$IC_sup[i], p_signif)
    }
    
    x_text <- log_ci_sup[i] + 0.06
    text(x_text, y_pos[i], txt_annot, adj = 0, cex = 0.74, font = 2, col = "black")
  }
}

# Légende professionnelle avec fond semi-transparent positionnée dans le cadran inférieur droit (zone entièrement dégagée)
legend(
  "bottomright",
  inset = c(0.02, 0.03),
  legend = c("Très difficile (≥ 35% err)", "Difficulté modérée (20-34%)", "Accessible (10-19%)", "Facile (< 10% err)", "Référence (Bombus)"),
  col = c("#C62828", "#E67E22", "#4A90E2", "#2E7D32", "#1B365D"),
  pch = c(15, 15, 15, 15, 18),
  pt.cex = 1.3,
  bty = "o",
  bg = "#FFFFFFEE",
  box.col = "#D0D7DE",
  cex = 0.85,
  title = "Paliers de difficulté"
)

dev.off()
cat(sprintf("--> Forest Plot inter-cohortes généré : %s\n", fichier_png))

# Synchronisation automatique vers le dossier Résultats mémoire
dest_figures <- file.path("Résultats mémoire", "figures", "fig9_forest_plot_or_genres.png")
file.copy(fichier_png, dest_figures, overwrite = TRUE)
cat(sprintf("--> Image copiée vers : %s\n", dest_figures))

