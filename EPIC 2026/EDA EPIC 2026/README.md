# Phase 2 : Analyse Exploratoire des Données (EDA EPIC 2026)

Ce dossier contient l'ensemble des scripts, jeux de données propres et visualisations haute résolution (300 DPI) réalisés lors de la **Phase 2 (EDA)** pour le test de base du programme EPIC.

---

## 1. Structure du dossier

```text
EDA EPIC 2026/
├── README.md                           # Documentation de l'EDA et synthèse des résultats
├── nettoyage_donnees_epic_basic.R      # Script de filtrage scientifique et préparation
├── eda_performances_participants.R     # Script d'analyse des scores, durées et cohortes
├── eda_taxonomie_genres.R              # Script d'analyse des 37 genres et matrice de confusion
├── EPIC_Basic_clean_wide.csv           # Jeu de données propre format WIDE (N = 172 participants)
├── EPIC_Basic_clean_long.csv           # Jeu de données propre format LONG (5 160 observations)
└── output/                             # Livrables graphiques et tabulaires (300 DPI)
    ├── fig1_distribution_scores_globaux.png
    ├── fig2_comparaison_formation_epic.png
    ├── fig3_duree_vs_score.png
    ├── fig4_scores_par_region.png
    ├── fig5_classement_difficulte_genres.png
    ├── fig6_top5_pieges_vs_faciles.png
    ├── fig7_gain_formation_par_genre.png
    ├── fig8_confusions_taxonomiques_majeures.png
    ├── tableau_difficulte_genres.csv
    └── tableau_confusions_taxonomiques.csv
```

---

## 2. Synthèse des résultats scientifiques

### A. Échantillon propre retenu (N = 172)
* **Score global moyen** : $24.22 \pm 4.81$ sur 30 ($80.7\%$ de réussite).
* **Médiane** : $25.0 / 30$ ($IQR = [22.0 - 28.0]$).
* **Durée moyenne** : $84.2$ minutes (médiane : $89.0$ min).
* **Cohortes** : 64 participants « Formés EPIC » vs 108 « Non formés ».
* **Effet formation** : Les participants formés obtiennent une moyenne supérieure ($24.80 \pm 4.16$) par rapport aux non formés ($23.87 \pm 5.14$), avec une dispersion plus resserrée.

### B. Hiérarchie de difficulté taxonomique (Axe B du mémoire)
* **Top 5 des genres pièges les plus difficiles** :
  1. **`Stelis`** : $70.0\%$ d'erreur ($n=90$). Confondu dans $75\%$ des cas avec *Anthidium* (son hôte cleptoparasité).
  2. **`Tetralonia`** : $55.0\%$ d'erreur ($n=129$). Confondu avec *Melitta* ($22.7\%$), *Eucera* ($15.2\%$) et *Anthophora* ($13.6\%$).
  3. **`Hoplitis`** : $43.5\%$ d'erreur ($n=145$). Confondu avec son genre frère *Osmia* ($25.5\%$) et *Andrena* ($16.4\%$).
  4. **`Trachusa`** : $42.9\%$ d'erreur ($n=140$).
  5. **`Epeoloides`** : $35.6\%$ d'erreur ($n=135$). Confondu avec *Epeolus* ($40.0\%$).
* **Genres les plus faciles ($\ge 95\%$ de réussite)** :
  * `Bombus` ($98.2\%$), `Xylocopa` ($97.0\%$), `Nomada` ($95.3\%$), `Ceratina` ($94.8\%$).

---

## 3. Exécution des scripts

```bash
Rscript nettoyage_donnees_epic_basic.R
Rscript eda_performances_participants.R
Rscript eda_taxonomie_genres.R
```

