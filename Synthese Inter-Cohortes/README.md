# Étape 4 : Synthèse Comparative Inter-Cohortes (EPIC vs BAC 3)

Ce dossier rassemble le script d'analyse globale, les visualisations de synthèse (300 DPI) et les tableaux d'exportation conformes aux standards Excel pour la **comparaison inter-cohortes** du mémoire (Adultes EPIC vs Étudiants Universitaires Bac 3).

---

## 1. Structure du dossier

```text
Synthese Inter-Cohortes/
├── README.md                                          # Synthèse scientifique rédigée pour le mémoire
├── synthese_comparative_inter_cohortes.R             # Script R autonome exécutant les modélisations croisées
└── output/                                            # Livrables statistiques et graphiques (300 DPI)
    ├── tableau_comparatif_global_cohortes.csv         # Synthèse multi-cohortes (Axe A : Pré, Post, Gains, d, r, OR, IDK)
    ├── tableau_modele_interaction_public_formation.csv # Modèle GLM Quasibinomial testant l'interaction Public × Formation
    ├── tableau_consensus_pieges_taxonomiques.csv      # Consensus des genres pièges et facteurs morphologiques (Axe B)
    ├── figure1_comparaison_trajectoires_pre_post.png  # Évolution Pré -> Post comparée des 4 cohortes
    ├── figure2_forest_plot_tailles_effet_cohortes.png # Forest Plot des tailles d'effet (d de Cohen et OR GLM)
    └── figure3_consensus_difficulte_genres_intercohortes.png # Gradient de difficulté taxonomique consensuel
```

---

## 2. Résultats Scientifiques — Axe A : Comparaison Globale de l'Apprentissage

### A. Synthèse descriptive des cohortes (sur 20 points)

| Cohorte & Profil | Dispositif d'évaluation | Échantillon analysé | Score Pré (Moy ± ET) | Score Post (Moy ± ET) | Gain brut ($\Delta$) | Gain relatif | Effondrement IDK |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **EPIC 2025** *(Adultes naturalistes)* | Longitudinal Pré vs Post | $N = 50$ Pré / $49$ Post | $10{,}51 \pm 4{,}69$ | $16{,}53 \pm 2{,}22$ | **$+6{,}02$ pts** | $+30{,}1\,\%$ | **$-91{,}0\,\%$** |
| **BAC 3 (2024)** *(Étudiants université)* | Longitudinal apparié | $N = 25$ paires strictes | $6{,}61 \pm 3{,}21$ | $14{,}06 \pm 2{,}76$ | **$+7{,}45$ pts** | $+37{,}2\,\%$ | **$-85{,}3\,\%$** |
| **BAC 3 (2025)** *(Étudiants université)* | Longitudinal apparié | $N = 22$ paires strictes | $9{,}33 \pm 4{,}33$ | $15{,}26 \pm 2{,}64$ | **$+5{,}93$ pts** | $+29{,}7\,\%$ | **$-92{,}2\,\%$** |
| **EPIC Basic (2026)** *(Adultes naturalistes)* | Comparaison Adultes (Formés vs Non) | $N = 64$ Formés / $108$ Non | $15{,}91 \pm 3{,}43$ | $16{,}53 \pm 2{,}77$ | **$+0{,}62$ pt** | $+3{,}1\,\%$ | — |

### B. Modélisation de l'interaction Public $\times$ Formation (GLM Quasibinomial)

Pour tester formellement si les adultes naturalistes apprennent différemment ou plus vite que les étudiants universitaires, un Modèle Linéaire Généralisé Quasibinomial ($\text{logit}(P(\text{Succès})) \sim \text{Public} \times \text{Session}$) a été ajusté sur l'ensemble des données individuelles ($N = 193$ observations) :

1. **Effet du Public en Pré-test** : $\beta = +0{,}5308$, $t = 3{,}417$, **$p = 0{,}00078^{***}$** ($\text{OR} = 1{,}70$ [IC 95 % : $1{,}25 - 2{,}31$]).
   * *Interprétation* : Les adultes naturalistes possèdent un socle de compétences taxonomiques initiales significativement supérieur à celui des étudiants débutant leur TP.
2. **Effet de la Formation** : $\beta = +1{,}4297$, $t = 8{,}524$, **$p = 4{,}85 \times 10^{-15***}$** ($\text{OR} = 4{,}18$ [IC 95 % : $3{,}01 - 5{,}80$]).
   * *Interprétation* : La formation taxonomique apporte un bénéfice massif, multipliant par plus de 4 la cote de réussite des étudiants.
3. **Terme d'Interaction Public $\times$ Formation** : $\beta = +0{,}0299$, $t = 0{,}122$, **$p = 0{,}903$ (Non significatif)** ($\text{OR} = 1{,}03$ [IC 95 % : $0{,}64 - 1{,}66$]).
   * *Conclusion majeure du mémoire* : **Il n'y a aucune différence significative dans le taux de progression entre adultes et étudiants.** Bien que partant d'un niveau initial distinct, les deux publics bénéficient avec une intensité rigoureusement équivalente de l'apprentissage taxonomique.

### C. Déblocage cognitif universel : L'effondrement de l'abstention

Dans toutes les cohortes suivies longitudinalement, la formation produit une chute massive de la réponse d'évitement (*"Je ne sais pas"* / omissions) :
* EPIC 2025 : $27{,}1\,\% \to 2{,}4\,\%$ (réduction de **$-91{,}0\,\%$**).
* BAC 3 2024 : $37{,}7\,\% \to 5{,}5\,\%$ (réduction de **$-85{,}3\,\%$**).
* BAC 3 2025 : $20{,}3\,\% \to 1{,}6\,\%$ (réduction de **$-92{,}2\,\%$**).
La formation ne se contente pas d'affiner la précision : elle débloque l'inhibition initiale et confère aux apprenants l'assurance nécessaire pour poser un diagnostic taxonomique.

---

## 3. Résultats Scientifiques — Axe B : Consensus des Genres Pièges et Morphologie

Le croisement transversal des performances post-formation de l'ensemble des cohortes ($N = 27$ genres évalués) permet d'établir une classification consensuelle rigoureuse selon le **taux d'erreur post-formation** avec intervalles de confiance de Wilson à 95 % :

### A. Les Genres « Très difficiles » (Taux d'erreur $\ge 35\,\%$, soit $\le 65\,\%$ de succès)
1. ***Stelis*** ($57{,}4\,\%$ d'erreur, $\text{IC}_{95\%} = [29{,}5 - 56{,}7\,\%]$) : Abeille coucou mégachilidée glabre ponctuée de jaune, absence de scopa ventrale, confusion avec *Osmia* / *Anthidiini*.
2. ***Trachusa*** ($54{,}5\,\%$ d'erreur, $\text{IC}_{95\%} = [26{,}9 - 65{,}3\,\%]$) : Silhouette d'anthidie sombre à brosse ventrale, confusion fréquente avec *Osmia* et *Eucera*.
3. ***Anthophora*** ($53{,}1\,\%$ d'erreur, $\text{IC}_{95\%} = [37{,}2 - 56{,}8\,\%]$) : Allure trapue et pilosité très dense, vol stationnaire, confusion massive avec *Bombus* et *Andrena*.
4. ***Lasioglossum*** ($45{,}8\,\%$ d'erreur, $\text{IC}_{95\%} = [45{,}3 - 63{,}0\,\%]$) : Taille miniature à moyenne, nervation alaire ténue, sillon anal, confusion avec *Ceratina* et *Halictus*.
5. ***Megachile*** ($43{,}0\,\%$ d'erreur, $\text{IC}_{95\%} = [48{,}1 - 65{,}5\,\%]$) : Brosse de récolte ventrale, silhouette trapue, confusions avec *Osmia*, *Bombus* et *Anthophora*.
6. ***Sphecodes*** ($42{,}2\,\%$ d'erreur, $\text{IC}_{95\%} = [50{,}7 - 64{,}6\,\%]$) : Abdomen rouge vif et noir, cuticule glabre et fortement ponctuée, confusion systématique avec *Nomada*.
7. ***Chelostoma*** ($38{,}8\,\%$ d'erreur, $\text{IC}_{95\%} = [47{,}2 - 73{,}6\,\%]$) : Corps cylindrique très allongé, petite taille, confusion avec *Heriades* et petites osmies.

### B. Les Genres de « Difficulté modérée » (Taux d'erreur entre $20\,\%$ et $34\,\%$)
* ***Andrena*** ($30{,}2\,\%$ err, $\text{IC} = [63{,}0 - 75{,}8\,\%]$) : Fovéas faciales veloutées, scopas fémorales, grand polymorphisme spécifique.
* ***Osmia*** ($28{,}1\,\%$ err, $\text{IC} = [62{,}2 - 79{,}9\,\%]$) : Reflets métalliques sombres, brosse ventrale, confusion avec *Hoplitis* et *Megachile*.
* ***Ammobates*** ($26{,}5\,\%$ err, $\text{IC} = [59{,}7 - 83{,}8\,\%]$) : Abdomen partiellement rouge, habitus allongé de coucou.
* ***Eucera*** ($22{,}0\,\%$ err, $\text{IC} = [69{,}7 - 84{,}5\,\%]$) : Antennes très longues chez les mâles, confusion avec *Dasypoda* et *Tetralonia*.
* ***Hoplitis*** ($20{,}4\,\%$ err, $\text{IC} = [66{,}4 - 88{,}5\,\%]$) : Morphologie intermédiaire entre *Osmia* et *Megachile*.
* ***Melecta*** ($20{,}4\,\%$ err, $\text{IC} = [66{,}4 - 88{,}5\,\%]$) : Habitus trapu noir à taches de poils blanc pur en damier.

### C. Les Genres « Accessibles » (Taux d'erreur entre $10\,\%$ et $19\,\%$)
* ***Nomada*** ($18{,}8\,\%$ err, $\text{IC} = [75{,}1 - 86{,}1\,\%]$) : Habitus guêpe glabre jaune/rouge.
* ***Epeolus*** ($18{,}4\,\%$ err, $\text{IC} = [68{,}6 - 90{,}0\,\%]$) : Motifs d'écailles pileuses blanches en demi-lunes.
* ***Panurgus*** ($17{,}7\,\%$ err, $\text{IC} = [73{,}5 - 88{,}6\,\%]$) : Abeille noire à pilosité dense sur pattes postérieures.
* ***Anthidium*** ($14{,}6\,\%$ err, $\text{IC} = [77{,}0 - 91{,}1\,\%]$) : Motifs jaunes vifs en plaques latérales, brosse ventrale.
* ***Colletes*** ($14{,}6\,\%$ err, $\text{IC} = [77{,}0 - 91{,}1\,\%]$) : Tête triangulaire en cœur, nervure récurrente sinueuse.
* ***Ceratina*** ($11{,}5\,\%$ err, $\text{IC} = [80{,}6 - 93{,}5\,\%]$) : Corps sombre à reflets bleu-vert métalliques, quasi glabre.
* ***Macropis*** ($10{,}2\,\%$ err, $\text{IC} = [78{,}2 - 95{,}6\,\%]$) : Pilosité dense jaune/brune sur pattes postérieures.

### D. Les Genres « Faciles » (Taux d'erreur $< 10\,\%$, soit $> 90\,\%$ de succès)
* ***Coelioxys*** ($8{,}2\,\%$ err, $\text{IC} = [80{,}8 - 96{,}8\,\%]$) : Abdomen conique pointu effilé, taches blanches triangulaires.
* ***Halictus*** ($7{,}6\,\%$ err, $\text{IC} = [86{,}1 - 95{,}9\,\%]$) : Bandes pileuses apicales continues sur tergites.
* ***Hylaeus*** ($7{,}3\,\%$ err, $\text{IC} = [88{,}1 - 95{,}6\,\%]$) : Masque facial blanc/jaune caractéristique, corps noir glabre.
* ***Bombus*** ($6{,}0\,\%$ err, $\text{IC} = [90{,}0 - 96{,}5\,\%]$) : Silhouette volumineuse, corbicula, bourdon universellement reconnu.
* ***Apis*** ($4{,}2\,\%$ err, $\text{IC} = [89{,}8 - 98{,}4\,\%]$) : Abeille mellifère domestique, yeux velus, cellule marginale allongée.
* ***Dasypoda*** ($4{,}2\,\%$ err, $\text{IC} = [89{,}8 - 98{,}4\,\%]$) : Énormes brosses tibiales postérieures jaunes en panache.
* ***Xylocopa*** ($0{,}0\,\%$ err, $\text{IC} = [96{,}2 - 100{,}0\,\%]$) : Grande taille imposante, ailes violacées irisées, corps noir massif.

---

## 4. Statut de la Cohorte Bac 1 et de l'Axe C

* **Cohorte Bac 1** : Les données n'ayant pas encore été récoltées, elles constituent la perspective immédiate du projet de recherche.
* **Axe C (Passage à l'action terrain)** : En attente de l'enquête post-formation de suivi des pratiques naturalistes des participants.

