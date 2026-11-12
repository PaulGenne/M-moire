# ==============================================================================
# SCRIPT R : Classement des genres d'abeilles par ordre décroissant de difficulté
# FICHIER SOURCE : EPIC_Basic-rgpd ok - Copie.xlsx
# AUTEUR : Expert Data Science R & ggplot2
# ==============================================================================

# 0. CHARGEMENT DES PACKAGES REQUIS --------------------------------------------
packages_requis <- c("readxl", "dplyr", "tidyr", "stringr", "ggplot2", "scales")
a_installer <- packages_requis[!packages_requis %in% installed.packages()[, "Package"]]
if (length(a_installer) > 0) {
  install.packages(a_installer, repos = "https://cloud.r-project.org")
}

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)


# 1. IMPORTATION ET PRÉPARATION DES DONNÉES ------------------------------------

# 1.1 Lecture du fichier Excel
fichier_excel <- "EPIC_Basic-rgpd ok - Copie.xlsx"
df_brut <- read_excel(fichier_excel, sheet = "Correction_Test_Basic")

# 1.2 Restructuration Wide -> Long (regroupement des 30 questions)
df_long <- df_brut %>%
  select(`N°ID`, matches("^Question_\\d+_(solution|evaluation)$")) %>%
  pivot_longer(
    cols = matches("^Question_\\d+_(solution|evaluation)$"),
    names_to = c("question_num", ".value"),
    names_pattern = "^Question_(\\d+)_(solution|evaluation)$"
  )

# 1.3 Nettoyage des genres et conversion de la variable d'évaluation
df_clean <- df_long %>%
  filter(!is.na(solution), solution != "") %>%
  mutate(
    genre      = str_squish(solution),
    genre      = str_to_title(genre),
    evaluation = as.numeric(evaluation)
  )

# 1.4 Calcul des métriques de difficulté par genre
# Difficulté mesurée par le taux d'erreur (% d'échecs = 100 - taux de réussite)
stats_difficulte <- df_clean %>%
  group_by(genre) %>%
  summarise(
    n_total       = n(),
    nb_succes     = sum(evaluation == 1, na.rm = TRUE),
    nb_erreurs    = sum(evaluation == 0, na.rm = TRUE),
    taux_reussite = mean(evaluation, na.rm = TRUE) * 100,
    taux_erreur   = 100 - taux_reussite,
    .groups       = "drop"
  ) %>%
  # Tri par ordre décroissant de difficulté (taux d'erreur le plus élevé en premier)
  arrange(desc(taux_erreur))

cat("--- Top 10 des genres les plus difficiles (taux d'erreur le plus élevé) ---\n")
print(head(stats_difficulte %>% select(genre, n_total, taux_erreur, taux_reussite), 10))


# 2. CRÉATION DU GRAPHIQUE GGPLOT2 ---------------------------------------------

# Taux d'erreur moyen global pour la ligne de référence
taux_erreur_moyen <- mean(df_clean$evaluation == 0, na.rm = TRUE) * 100

# Construction du graphique : les plus difficiles apparaissent en haut
graphique_difficulte <- ggplot(
  stats_difficulte,
  aes(x = taux_erreur, y = reorder(genre, taux_erreur), fill = taux_erreur)
) +
  # Ligne verticale indiquant le taux d'erreur moyen global
  geom_vline(
    xintercept = taux_erreur_moyen,
    linetype   = "dashed",
    color      = "grey40",
    linewidth  = 0.7
  ) +
  annotate(
    "text",
    x        = taux_erreur_moyen + 1,
    y        = stats_difficulte$genre[nrow(stats_difficulte)],  # Premier niveau en bas
    label    = sprintf("Moyenne globale : %.1f%%", taux_erreur_moyen),
    color    = "grey30",
    hjust    = 0,
    vjust    = 0,
    size     = 3.3,
    fontface = "italic"
  ) +
  # Barres horizontales avec dégradé continu de couleur
  geom_col(width = 0.72) +
  # Palette de couleur : du vert (faible erreur / facile) au rouge foncé (forte erreur / très difficile)
  scale_fill_gradient2(
    low      = "#2E7D32",   # Vert (facile)
    mid      = "#FBC02D",   # Jaune / Ambre (intermédiaire)
    high     = "#C62828",   # Rouge vif (très difficile)
    midpoint = 35,
    name     = "Taux d'erreur (%)"
  ) +
  # Étiquettes de données sur chaque barre
  geom_text(
    aes(
      label = sprintf("%.1f%% (n = %d)", taux_erreur, n_total),
      hjust = ifelse(taux_erreur > 15, 1.1, -0.15),
      color = ifelse(taux_erreur > 15, "white", "black")
    ),
    fontface = "bold",
    size     = 3.2,
    show.legend = FALSE
  ) +
  scale_color_identity() +
  scale_x_continuous(
    limits = c(0, 80),
    breaks = seq(0, 80, 10),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.03))
  ) +
  labs(
    title    = "Classement des genres d'abeilles par ordre décroissant de difficulté",
    subtitle = "Difficulté mesurée par le taux d'erreur à l'identification (37 genres testés)",
    x        = "Taux d'erreur / d'échec (%)",
    y        = "Genre d'abeille (du plus difficile au plus facile)",
    caption  = "Source : Données test EPIC | Note : n = nombre d'occurrences testées"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title         = element_text(face = "bold", size = 14, color = "#111111", margin = margin(b = 5)),
    plot.subtitle      = element_text(color = "grey40", size = 10, margin = margin(b = 15)),
    plot.caption       = element_text(color = "grey50", size = 8.5, hjust = 1, margin = margin(t = 12)),
    axis.title.x       = element_text(face = "bold", margin = margin(t = 10)),
    axis.title.y       = element_text(face = "bold", margin = margin(r = 10)),
    axis.text.y        = element_text(face = "bold", color = "grey20", size = 9),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.position    = "right"
  )


# ------------------------------------------------------------------------------
# VARIANTE : GRAPHIQUE AVEC LE TAUX DE RÉUSSITE (ORDRE CROISSANT DU TAUX)
# (Le genre le plus difficile a le taux de réussite le plus bas, en haut)
# ------------------------------------------------------------------------------
graphique_reussite_croissant <- ggplot(
  stats_difficulte,
  aes(x = taux_reussite, y = reorder(genre, -taux_reussite), fill = taux_reussite)
) +
  geom_col(width = 0.72) +
  scale_fill_gradient2(
    low      = "#C62828",   # Rouge (faible réussite = difficile)
    mid      = "#FBC02D",   # Jaune
    high     = "#2E7D32",   # Vert (forte réussite = facile)
    midpoint = 65,
    name     = "Taux de réussite (%)"
  ) +
  geom_text(
    aes(
      label = sprintf("%.1f%% (n = %d)", taux_reussite, n_total),
      hjust = ifelse(taux_reussite > 25, 1.1, -0.15),
      color = ifelse(taux_reussite > 25, "white", "black")
    ),
    fontface = "bold",
    size     = 3.2,
    show.legend = FALSE
  ) +
  scale_color_identity() +
  scale_x_continuous(
    limits = c(0, 108),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title    = "Genres d'abeilles classés par difficulté (Taux de réussite croissant)",
    subtitle = "Le genre le plus difficile (taux de réussite le plus faible) est positionné au sommet",
    x        = "Taux de réussite (%)",
    y        = "Genre d'abeille (du plus difficile au plus facile)",
    caption  = "Source : Données test EPIC"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title         = element_text(face = "bold", size = 14, color = "#111111", margin = margin(b = 5)),
    plot.subtitle      = element_text(color = "grey40", size = 10, margin = margin(b = 15)),
    plot.caption       = element_text(color = "grey50", size = 8.5, hjust = 1, margin = margin(t = 12)),
    axis.title.x       = element_text(face = "bold", margin = margin(t = 10)),
    axis.title.y       = element_text(face = "bold", margin = margin(r = 10)),
    axis.text.y        = element_text(face = "bold", color = "grey20", size = 9),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.position    = "right"
  )


# 3. EXPORTATION DANS LE DOSSIER OUTPUT/ ET AFFICHAGE ---------------------------

dossier_output <- "output"
if (!dir.exists(dossier_output)) {
  dir.create(dossier_output, recursive = TRUE)
}

# Exportation haute résolution (300 DPI) au format PNG
fichier_sauvegarde_1 <- file.path(dossier_output, "classement_difficulte_taux_erreur.png")
fichier_sauvegarde_2 <- file.path(dossier_output, "classement_difficulte_taux_reussite.png")

ggsave(fichier_sauvegarde_1, plot = graphique_difficulte, width = 10, height = 11, dpi = 300)
ggsave(fichier_sauvegarde_2, plot = graphique_reussite_croissant, width = 10, height = 11, dpi = 300)

cat("\n[OK] Graphiques exportés dans :\n -", fichier_sauvegarde_1, "\n -", fichier_sauvegarde_2, "\n")

# Affichage dans RStudio
print(graphique_difficulte)
print(graphique_reussite_croissant)
