# Étape 3 : Analyses Statistiques Inférentielles (EPIC Basic 2026)

Ce dossier rassemble l'ensemble des scripts de modélisation statistique, des tables de résultats inférentiels et des visualisations de modélisation (300 DPI) pour l'**Étape 3** du mémoire.

---

## 1. Structure du dossier

```text
Analyses Stats EPIC 2026/
├── README.md                                 # Documentation des méthodes et interprétations statistiques
├── analyses_statistiques_epic_basic.R        # Script maître de modélisation et tests d'hypothèses
└── output/                                   # Livrables statistiques (tableaux CSV & figures 300 DPI)
    ├── tableau_tests_formation.csv           # Tests d'hypothèses univariés (Shapiro, Wilcoxon, Welch)
    ├── tableau_genres_odds_ratios.csv        # Modèle logistique GLM : Odds Ratios par genre d'abeille
    ├── tableau_tests_fisher_formation_genres.csv # Tests de Fisher exacts (gain de formation par genre)
    └── forest_plot_difficulte_genres.png     # Forest Plot des Odds Ratios avec IC 95% (300 DPI)
```

---

## 2. Synthèse des résultats statistiques

### A. Effet de la formation EPIC (Axe A du mémoire)
* **Distribution des scores** : Asymétrie négative marquée avec rejet formel de la normalité (Shapiro-Wilk $W = 0.896$, $p < 0.001$).
* **Comparaison univariée brute** :
  * Test non paramétrique de Wilcoxon-Mann-Whitney : $W = 3749.5$, $p = 0.352$ ($r = 0.071$).
  * Test $t$ de Welch : $t = 1.291$, $p = 0.199$ ($d = 0.193$, écart brut de $+0.93$ point).
* **Modélisation multivariée contrôlée (GLM Quasibinomial)** :
  * En contrôlant pour la durée du test et la région d'origine, le statut **Non formé** est associé à une probabilité de réussite significativement inférieure à celle des Formés EPIC ($\beta = -0.353$, $t = -2.015$, **$p = 0.0455^*$**).
  * La **durée** montre un effet négatif significatif ($\beta = -0.0094$, $t = -3.167$, **$p = 0.0018^{**}$**) : au-delà du temps optimal, un temps de passation prolongé traduit des hésitations et majore le risque d'erreur.

### B. Modélisation de la difficulté par genre d'abeille (Axe B du mémoire)
* Modèle de régression logistique binaire ($N = 5\,160$ observations, référence : *Bombus*) :
  * La difficulté varie de manière **extrêmement significative** entre genres ($p < 0.001$).
  * **Top genres pièges statistiquement confirmés** :
    1. ***Stelis*** : $OR = 0.001$ ($IC_{95\%} = [0.000 - 0.011]$, $p_{FDR} = 9.05 \times 10^{-9}$).
    2. ***Tetralonia*** : $OR = 0.003$ ($IC_{95\%} = [0.000 - 0.021]$, $p_{FDR} = 1.21 \times 10^{-7}$).
    3. ***Hoplitis*** : $OR = 0.005$ ($IC_{95\%} = [0.001 - 0.034]$, $p_{FDR} = 1.06 \times 10^{-6}$).
    4. ***Trachusa*** : $OR = 0.005$ ($IC_{95\%} = [0.001 - 0.035]$, $p_{FDR} = 1.06 \times 10^{-6}$).
    5. ***Epeoloides*** : $OR = 0.006$ ($IC_{95\%} = [0.001 - 0.047]$, $p_{FDR} = 4.53 \times 10^{-6}$).

### C. Genres cibles d'un apprentissage significatif (Tests exacts de Fisher)
* ***Seladonia*** : $+35.8\%$ de réussite chez les formés ($p = 0.0085$, $OR = 0.140$).
* ***Ammobates*** : $+22.4\%$ de réussite chez les formés ($p = 0.0074$, $OR = 0.223$).
* ***Megachile*** : $+13.2\%$ de réussite chez les formés ($p = 0.0253$, $OR = 0.419$).

---

## 3. Exécution du script

```bash
Rscript analyses_statistiques_epic_basic.R
```

