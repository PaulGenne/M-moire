# Étape 3 : Analyses Statistiques Inférentielles (EPIC 2025)

Ce dossier rassemble l'ensemble des scripts de modélisation statistique, des tests d'hypothèses, des tableaux d'exportation conformes aux standards Excel et des figures haute définition (300 DPI) pour la cohorte **EPIC 2025** (Pré-test vs Post-test).

---

## 1. Structure du dossier

```text
2025/Analyses Stats EPIC 2025/
├── README.md                                 # Synthèse inférentielle et interprétation pour le mémoire
├── analyses_statistiques_epic_2025.R         # Script R autonome exécutant l'ensemble des modélisations
└── output/                                   # Dossier des livrables statistiques et graphiques
    ├── tableau_tests_formation_pre_post.csv  # Synthèse des tests globaux (Shapiro, Fligner, Wilcoxon, Welch, GLM)
    ├── tableau_modele_glm_global.csv         # Paramètres, Odds Ratios et IC 95% du GLM Quasibinomial
    ├── tableau_genres_odds_ratios.csv        # Modélisation logistique de la difficulté par genre (vs Bombus)
    ├── tableau_tests_fisher_formation_genres.csv # Tests de Fisher par genre avec correction FDR Benjamini-Hochberg
    ├── tableau_tests_guildes_sexes.csv       # Tests inférentiels sur l'effet du Sexe et de la Guilde
    ├── fig1_forest_plot_odds_ratios_genres.png   # Forest plot des Odds Ratios par genre (300 DPI)
    ├── fig2_volcano_gains_significativite_genres.png # Volcano plot gains vs -log10(p_adj) (300 DPI)
    └── fig3_probabilites_predites_glm.png        # Probabilités marginales prédites ajustées (300 DPI)
```

---

## 2. Résultats Inférentiels — Axe A : Efficacité Globale de la Formation

### A. Non-normalité et hétéroscédasticité
* **Shapiro-Wilk** : Rejet très net de la normalité en Post-test ($W = 0{,}9338$, $p = 8{,}5 \times 10^{-3}$) et au niveau global ($p < 0{,}001$), en raison de la concentration des notes vers le haut (effet plafond de l'apprentissage).
* **Fligner-Killeen** : $\chi^2 = 17{,}21$, $p = 3{,}35 \times 10^{-5}$. L'hypothèse d'homogénéité des variances est formellement rejetée : la variance est divisée par plus de 4 après formation (homogénéisation des compétences).

### B. Test principal non paramétrique : Wilcoxon-Mann-Whitney
* **Statistique $W$** : $2\,103{,}0$ ($Z = 6{,}145$)
* **Valeur $p$** : **$p = 7{,}69 \times 10^{-10}$ ($p < 0{,}001$)**
* **Taille d'effet de Rosenthal ($r$)** : **$r = 0{,}618$** (taille d'effet **très forte / large**, largement au-delà du seuil conventionnel de $0{,}50$).
* **Probabilité de supériorité (CLES / AUC)** : **$85{,}8\,\%$** (un participant tiré au hasard en Post-test a $85{,}8\,\%$ de chances d'obtenir une note supérieure à un participant du Pré-test).

### C. Test paramétrique comparatif : Test $t$ de Welch
* $t = 8{,}185$, $\text{ddl} = 70{,}2$, **$p = 8{,}13 \times 10^{-12}$**.
* **Gain moyen observé** : $+6{,}02$ points sur 20 points ($+30{,}1\,\%$).
* **$d$ de Cohen** : **$d = 1{,}635$** (effet massif, très supérieur au seuil d'effet fort de $0{,}80$).

### D. Modèle Linéaire Généralisé (GLM Quasibinomial Logit) avec contrôle de la durée
* Modélisation de $\text{logit}(P(\text{Succès})) \sim \text{Formation} + \log_{10}(\text{Durée})$.
* **Effet de la formation** : $\beta = 1{,}3704 \pm 0{,}1850$, $t = 7{,}408$, **$p = 4{,}97 \times 10^{-11}$**.
* **Odds Ratio ajusté de réussite** : **$\text{OR} = 3{,}937$ [IC 95 % : $2{,}740 - 5{,}657$]**.
* *Interprétation* : À temps de passation égal, la cote de réussite d'une identification est multipliée par près de **4** après la formation.

---

## 3. Résultats Inférentiels — Facteurs Biologiques (Sexe & Guilde)

* **Absence d'interaction Formation $\times$ Sexe** ($p = 0{,}393$) : Le bénéfice de la formation s'applique de manière égale aux spécimens mâles ($+28{,}8\,\%$, $\text{OR} = 0{,}250$, $p = 4{,}2 \times 10^{-33}$) et femelles ($+31{,}4\,\%$, $\text{OR} = 0{,}216$, $p = 2{,}9 \times 10^{-39}$).
* **Effet Guilde** : Les abeilles coucous (cléptoparasites) présentent un gain absolu significativement plus marqué ($+37{,}1\,\%$, $\text{OR} = 0{,}196$, $p = 8{,}9 \times 10^{-27}$) que les pollinisateurs non-parasites ($+27{,}6\,\%$), démontrant que la formation compense le déficit initial sur les formes mimétiques de guêpes.

---

## 4. Résultats Inférentiels — Axe B : Modélisation par Genre et Tests de Fisher

### A. Modèle logistique de difficulté par genre (Référence : *Bombus*)
Les genres les plus difficiles à identifier (Odds Ratios les plus faibles par rapport à *Bombus*, tous $p_{\text{FDR}} < 0{,}001$) sont :
1. **`Anthophora`** : $\text{OR} = 0{,}030$ [IC 95 % : $0{,}015 - 0{,}060$] ($p_{\text{FDR}} = 1{,}58 \times 10^{-21}$)
2. **`Megachile`** : $\text{OR} = 0{,}033$ [IC 95 % : $0{,}016 - 0{,}067$] ($p_{\text{FDR}} = 8{,}72 \times 10^{-21}$)
3. **`Sphecodes`** : $\text{OR} = 0{,}046$ [IC 95 % : $0{,}025 - 0{,}085$] ($p_{\text{FDR}} = 2{,}04 \times 10^{-21}$)
4. **`Chelostoma`** : $\text{OR} = 0{,}052$ [IC 95 % : $0{,}026 - 0{,}103$] ($p_{\text{FDR}} = 2{,}42 \times 10^{-16}$)
5. **`Hoplitis`** : $\text{OR} = 0{,}057$ [IC 95 % : $0{,}029 - 0{,}114$] ($p_{\text{FDR}} = 1{,}87 \times 10^{-15}$)

### B. Tests exacts de Fisher par genre (Correction FDR Benjamini-Hochberg)
* Sur les 21 genres analysés (25 spécimens/questions avec effectif suffisant), **20 genres ($80{,}0\,\%$) montrent une progression statistiquement significative à $p_{\text{FDR}} < 0{,}05$**, et **22 genres ($88{,}0\,\%$) à $p_{\text{FDR}} < 0{,}10$**.
* Top 5 des progressions les plus significatives :
  1. *Hylaeus* ($p_{\text{FDR}} = 6{,}24 \times 10^{-10}$) : $68{,}0\,\% \to 100{,}0\,\%$
  2. *Hoplitis* ($p_{\text{FDR}} = 6{,}86 \times 10^{-9}$) : $18{,}0\,\% \to 79{,}6\,\%$ (Gain net $+61{,}6\,\%$)
  3. *Nomada* ($p_{\text{FDR}} = 4{,}22 \times 10^{-7}$) : $54{,}0\,\% \to 88{,}8\,\%$
  4. *Macropis* ($p_{\text{FDR}} = 1{,}22 \times 10^{-6}$) : $40{,}0\,\% \to 89{,}8\,\%$
  5. *Epeolus* ($p_{\text{FDR}} = 8{,}57 \times 10^{-6}$) : $34{,}0\,\% \to 81{,}6\,\%$

