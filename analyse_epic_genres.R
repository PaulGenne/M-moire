# ==============================================================================
# PROJET : Analyse de l'identification des genres d'abeilles (Test EPIC)
# OBJECTIF : Restructuration (Wide -> Long), métriques et visualisation ggplot2
# AUTEUR : Expert Data Science R
# ==============================================================================

# 0. CHARGEMENT / INSTALLATION DES PACKAGES REQUIS -----------------------------
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


# 1. PRÉPARATION ET RESTRUCTURATION DES DONNÉES --------------------------------

# 1.1 Importation des données
fichier_excel <- "EPIC_Basic-rgpd ok - Copie.xlsx"
df_brut <- read_excel(fichier_excel, sheet = "Correction_Test_Basic")

# 1.2 Pivotement : Passage du format large (Wide) au format long (Long)
# On extrait le numéro de question et on regroupe 'solution' et 'evaluation'
df_long <- df_brut %>%
  select(`N°ID`, matches("^Question_\\d+_(solution|evaluation)$")) %>%
  pivot_longer(
    cols = matches("^Question_\\d+_(solution|evaluation)$"),
    names_to = c("question_num", ".value"),
    names_pattern = "^Question_(\\d+)_(solution|evaluation)$"
  )

# 1.3 Nettoyage des données
df_clean <- df_long %>%
  filter(!is.na(solution), solution != "") %>%
  mutate(
    # Suppression des espaces superflus et normalisation en Title Case (Ex: " osmies " -> "Osmies")
    genre = str_squish(solution),
    genre = str_to_title(genre),
    # Conversion de l'évaluation en numérique binaire (0 ou 1)
    evaluation = as.numeric(evaluation)
  )

# 1.4 Calcul des indicateurs par genre et filtrage statistique
seuil_min_tests <- 10  # Seuil pour éviter les biais sur petits échantillons

stats_genres <- df_clean %>%
  group_by(genre) %>%
  summarise(
    n_total       = n(),
    nb_reussites  = sum(evaluation == 1, na.rm = TRUE),
    taux_reussite = mean(evaluation, na.rm = TRUE) * 100,
    .groups       = "drop"
  ) %>%
  filter(n_total >= seuil_min_tests)

# Extraction des Top 5
top5_faciles <- stats_genres %>%
  slice_max(order_by = taux_reussite, n = 5, with_ties = FALSE)

top5_difficiles <- stats_genres %>%
  slice_min(order_by = taux_reussite, n = 5, with_ties = FALSE)


# 2. VISUALISATION AVEC GGPLOT2 ------------------------------------------------

# Configuration de la charte graphique
couleur_facile     <- "#2E7D32"  # Vert émeraude
couleur_difficile  <- "#C62828"  # Rouge rubis
theme_personnalise <- theme_minimal(base_size = 12) +
  theme(
    plot.title         = element_text(face = "bold", size = 13, margin = margin(b = 5)),
    plot.subtitle      = element_text(color = "grey40", size = 10, margin = margin(b = 15)),
    plot.caption       = element_text(color = "grey50", size = 8, hjust = 1, margin = margin(t = 10)),
    axis.title.y       = element_text(face = "bold", margin = margin(r = 10)),
    axis.title.x       = element_text(face = "bold", margin = margin(t = 10)),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_blank()
  )

# ------------------------------------------------------------------------------
# GRAPHIQUE A : Top 5 des genres les plus faciles (Taux de réussite le plus élevé)
# ------------------------------------------------------------------------------
graphique_A <- ggplot(top5_faciles, aes(x = taux_reussite, y = reorder(genre, taux_reussite))) +
  geom_col(fill = couleur_facile, width = 0.6) +
  geom_text(
    aes(label = sprintf("%.1f%% (n = %d)", taux_reussite, n_total)),
    hjust = 1.1, color = "white", fontface = "bold", size = 3.8
  ) +
  scale_x_continuous(
    limits = c(0, 105),
    expand = expansion(mult = c(0, 0.02)),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Top 5 des genres d'abeilles les plus faciles à identifier",
    subtitle = paste0("Taux de réussite moyen (genres testés au moins ", seuil_min_tests, " fois)"),
    x        = "Taux de réussite",
    y        = "Genre d'abeille",
    caption  = "Source : Test EPIC"
  ) +
  theme_personnalise

# ------------------------------------------------------------------------------
# GRAPHIQUE B : Top 5 des genres les plus difficiles (Taux de réussite le plus bas)
# ------------------------------------------------------------------------------
graphique_B <- ggplot(top5_difficiles, aes(x = taux_reussite, y = reorder(genre, -taux_reussite))) +
  geom_col(fill = couleur_difficile, width = 0.6) +
  geom_text(
    aes(label = sprintf("%.1f%% (n = %d)", taux_reussite, n_total)),
    hjust = -0.15, color = "grey20", fontface = "bold", size = 3.8
  ) +
  scale_x_continuous(
    limits = c(0, 100),
    expand = expansion(mult = c(0, 0.08)),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Top 5 des genres d'abeilles les plus difficiles à identifier",
    subtitle = paste0("Taux de réussite moyen (genres testés au moins ", seuil_min_tests, " fois)"),
    x        = "Taux de réussite",
    y        = "Genre d'abeille",
    caption  = "Source : Test EPIC"
  ) +
  theme_personnalise

# ------------------------------------------------------------------------------
# (BONUS) GRAPHIQUE C : Lollipop Chart combiné (Contraste Faciles vs Difficiles)
# ------------------------------------------------------------------------------
df_extremes <- bind_rows(
  top5_faciles    %>% mutate(groupe = "Plus faciles (Top 5)"),
  top5_difficiles %>% mutate(groupe = "Plus difficiles (Top 5)")
)

taux_global <- mean(df_clean$evaluation, na.rm = TRUE) * 100
premier_genre <- top5_difficiles$genre[1]  # Genre de référence pour l'annotation

graphique_C <- ggplot(df_extremes, aes(x = taux_reussite, y = reorder(genre, taux_reussite), color = groupe)) +
  # Ligne de référence : moyenne générale du test
  geom_vline(xintercept = taux_global, linetype = "dashed", color = "grey50", linewidth = 0.7) +
  annotate(
    "text", x = taux_global + 1.5, y = premier_genre,
    label = sprintf("Moyenne générale : %.1f%%", taux_global),
    color = "grey40", hjust = 0, size = 3.4, fontface = "italic"
  ) +
  # Segments et points du Lollipop Chart
  geom_segment(aes(x = 0, xend = taux_reussite, yend = genre), linewidth = 1.2) +
  geom_point(size = 4.5) +
  geom_text(
    aes(label = sprintf("%.1f%% (n=%d)", taux_reussite, n_total)),
    hjust = -0.2, size = 3.6, fontface = "bold", show.legend = FALSE
  ) +
  scale_color_manual(
    values = c("Plus faciles (Top 5)" = couleur_facile, "Plus difficiles (Top 5)" = couleur_difficile)
  ) +
  scale_x_continuous(
    limits = c(0, 115),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Contraste taxonomique : Genres d'abeilles aux extrêmes de réussite",
    subtitle = "Comparaison entre les 5 genres les mieux et les moins bien identifiés",
    x        = "Taux de réussite (%)",
    y        = "Genre d'abeille",
    color    = "Catégorie :",
    caption  = "Source : Test EPIC"
  ) +
  theme_personnalise +
  theme(
    legend.position = "top",
    legend.title    = element_text(face = "bold")
  )


# 3. SAUVEGARDE ET AFFICHAGE DES GRAPHIQUES -----------------------------------

# 3.1 Création automatique du dossier output
dossier_output <- "output"
if (!dir.exists(dossier_output)) {
  dir.create(dossier_output, recursive = TRUE)
}

# 3.2 Exportation des graphiques en haute résolution (300 DPI)
ggsave(file.path(dossier_output, "graphique_A_top5_faciles.png"),
       plot = graphique_A, width = 8, height = 5, dpi = 300)

ggsave(file.path(dossier_output, "graphique_B_top5_difficiles.png"),
       plot = graphique_B, width = 8, height = 5, dpi = 300)

ggsave(file.path(dossier_output, "graphique_C_contrastes_extremes.png"),
       plot = graphique_C, width = 9, height = 6, dpi = 300)

cat("Graphiques sauvegardés avec succès dans le dossier :", dossier_output, "\n")

# 3.3 Affichage interactif dans RStudio
print(graphique_A)
print(graphique_B)
print(graphique_C)
