# Étape 2 : Analyse Exploratoire des Données (EDA EPIC 2025)

Ce dossier rassemble l'ensemble des scripts de modélisation, des jeux de données structurés (`wide` et `long`), des visualisations haute définition (300 DPI) et des tableaux d'analyse exploratoire pour la cohorte **EPIC 2025** (Pré-test vs Post-test).

Les analyses sont articulées directement autour des deux grands axes de recherche définis dans le mémoire (`Contexte.md`).

---

## 1. Structure du dossier

```text
2025/EDA EPIC 2025/
├── README.md                              # Synthèse complète des résultats de l'EDA
├── preparation_donnees_eda_2025.R         # Script 1 : Structuration en formats wide et long
├── eda_performances_apprentissage.R       # Script 2 : Analyse de l'Axe A (Apprentissage et scores)
├── eda_taxonomie_pieges_confusions.R      # Script 3 : Analyse de l'Axe B (Taxonomie et confusions)
├── EPIC_2025_clean_wide.csv               # Format Wide (1 ligne par participant, N = 99)
├── EPIC_2025_clean_long.csv               # Format Long (1 ligne par question x participant, N = 2 970)
└── output/                                # Livrables graphiques et tabulaires
    ├── fig1_progression_scores_pre_post.png          # Boxplots et gain moyen (+6.02 pts)
    ├── fig2_distributions_densites_scores.png        # Histogrammes et courbes de densité
    ├── fig3_duree_vs_performance_pre_post.png        # Relation durée de passation vs score
    ├── fig4_effondrement_idk_omissions.png           # Chute des "Je ne sais pas" et effets Sexe/Guilde
    ├── fig5_classement_difficulte_genres_pre_post.png# Classement des 21 genres avec IC 95% Wilson
    ├── fig6_gain_apprentissage_par_genre.png         # Gains d'apprentissage par genre (Delta Post - Pré)
    ├── fig7_top_pieges_persistants_post.png          # Top des pièges résiduels et analyse par famille
    ├── fig8_matrice_confusions_taxonomiques.png      # Top confusions Pré vs Post
    ├── tableau_comparatif_scores_pre_post.csv        # Métriques descriptives comparatives
    ├── tableau_performances_par_genre.csv            # Taux de succès, IC Wilson et gains par genre
    └── tableau_confusions_taxonomiques_detail.csv    # Fréquence de toutes les paires d'erreurs
```

---

## 2. Synthèse de l'Axe A — Évaluation de l'efficacité de l'apprentissage

| Métrique d'évaluation | Pré-test ($N = 50$) | Post-test ($N = 49$) | Évolution ($\Delta$) | Interprétation pédagogique |
|---|:---:|:---:|:---:|---|
| **Score moyen (/20)** | **10,51** ($\pm 4{,}69$) | **16,53** ($\pm 2{,}22$) | **+6,02 pts** (+30,1 %) | Gain de compétence massif et significatif |
| **Score médian (/20)** | 10,00 | 16,67 | +6,67 pts | 50 % des participants dépassent 16,7/20 en Post |
| **Taux de réussite (%)** | 52,5 % | 82,7 % | +30,1 % | Passage du niveau moyen à un niveau expert |
| **Dispersion ($\sigma$)** | 4,69 | 2,22 | **Divisée par 2,1** | Forte homogénéisation du groupe vers le haut |
| **Aveu d'incompétence (« IDK »)** | 8,14 / 30 | 0,73 / 30 | **-91,0 %** | Disparition de l'hésitation, confiance accrue |
| **Succès Spécimens Femelles** | 52,0 % | 83,4 % | +31,4 % | Détermination facilitée par les organes de collecte |
| **Succès Spécimens Mâles** | 53,1 % | 81,9 % | +28,8 % | Progrès remarquable malgré le dimorphisme |
| **Succès Abeilles Coucous** | 41,0 % | 78,1 % | **+37,1 %** | Progression record sur les guildes parasites |

---

## 3. Synthèse de l'Axe B — Difficulté taxonomique, Pièges et Confusions

### A. Les genres à progression spectaculaire (Top gains)
* ***Hoplitis*** : $18{,}0\,\% \to 79{,}6\,\%$ (**gain record de $+61{,}6\,\%$**).
* ***Macropis*** : $40{,}0\,\% \to 89{,}8\,\%$ ($+49{,}8\,\%$).
* ***Ammobates*** : $26{,}0\,\% \to 73{,}5\,\%$ ($+47{,}5\,\%$).
* ***Epeolus*** : $34{,}0\,\% \to 81{,}6\,\%$ ($+47{,}6\,\%$).
* ***Lasioglossum*** : $34{,}0\,\% \to 79{,}6\,\%$ ($+45{,}6\,\%$).

### B. Les « Pièges persistants » post-formation
Trois genres restent sous la barre des 65 % de réussite même après formation :
1. **`Anthophora` (38,8 % de réussite en Post, 61,2 % d'échec)** :
   * *Confusion dominante* : Pris pour un bourdon (*Bombus*) dans 82,1 % des cas d'erreur ($23$ participants sur $49$).
   * *Cause morphologique* : Spécimen trapu à toison hirsute dense mimant l'habitus d'un bourdon. Les participants négligent la nervation alaire (cellules submarginales) et la brosse tibiale.
2. **`Megachile` (53,1 % de réussite en Post, 46,9 % d'échec)** :
   * *Confusion dominante* : Pris pour *Osmia* ($15$ fois au Post-test).
   * *Cause morphologique* : Même famille (Megachilidae) et même brosse de récolte sous l'abdomen. La distinction repose sur des critères microscopiques discrets (arolia entre les griffes, forme mandibulaire).
3. **`Sphecodes` (60,2 % de réussite en Post, 39,8 % d'échec)** :
   * *Confusion dominante* : Pris pour *Nomada* ($14$ fois) et *Lasioglossum* ($10$ fois).
   * *Cause morphologique* : Abdomen rouge vif d'abeille coucou incitant à répondre *Nomada*, ou nervation d'Halictidae incitant à répondre *Lasioglossum*.

---

## 4. Instructions de reproduction
Pour régénérer l'ensemble de l'EDA et réexporter toutes les figures :
```bash
Rscript preparation_donnees_eda_2025.R
Rscript eda_performances_apprentissage.R
Rscript eda_taxonomie_pieges_confusions.R
```

