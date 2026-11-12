# Dossier des Résultats du Mémoire de Fin d'Études

Ce dossier rassemble l'ensemble des livrables de la **Partie Résultats** du mémoire de Master :
- Évaluation de l'apprentissage taxonomique de l'identification des abeilles sauvages (*Hymenoptera : Apoidea*),
- Comparaison multi-cohortes : Adultes naturalistes (programme EPIC) vs Étudiants universitaires (Bac 3 Biologie),
- Recueil structuré des visualisations scientifiques (300 DPI), tableaux académiques et descriptions méthodologiques.

---

## 1. Documents Word (.docx) disponibles

* 📄 **[`Partie_Resultats_Memoire_Descriptif.docx`](Partie_Resultats_Memoire_Descriptif.docx)** : **Version recommandée pour le mémoire.**  
  * *Contenu* : Description strictement factuelle et neutre des résultats (sans interprétations subjectives, réservées au chapitre Discussion).  
  * *Agencement en double page* : 19 pages au total (9 doubles pages vis-à-vis).  
    * **Page de gauche (pages paires)** : Tableaux et Figures haute définition (300 DPI).  
    * **Page de droite (pages impaires)** : Description factuelle détaillée des chiffres, tests ($W, V, t, \beta, p$), Odds Ratios, intervalles de confiance et caractères anatomiques.  
  * *Exclusions appliquées* : Point 1 (échantillonnage initial) et premier tableau du Point 3 (tableau initial des 27 genres) supprimés.
* 📄 **[`Partie_Resultats_Memoire.docx`](Partie_Resultats_Memoire.docx)** : Version épurée visuelle (uniquement les titres, graphiques et tableaux sans commentaires textuels).
* 📄 **[`Partie_Resultats_Memoire_Commente.docx`](Partie_Resultats_Memoire_Commente.docx)** : Première version commentée intégrant des éléments de discussion pédagogique.

---

## 2. Structure des 9 doubles pages en regard (vis-à-vis)

| Double page | Page de GAUCHE (Données & Visuels) | Page de DROITE (Description factuelle des résultats) |
| :---: | :--- | :--- |
| **Spread 1** *(p. 2-3)* | **Tableau 1A** (Performances Pré vs Post) + **Figure 1** (Trajectoires des 4 cohortes) | **Description de l'évolution des scores** : Présentation des moyennes, écarts-types, médianes, gains bruts (+5,93 à +7,45 pts) et progression collective. |
| **Spread 2** *(p. 4-5)* | **Tableau 1B** (Tests inférentiels) + **Figure 2** (Forest Plot tailles d'effet $d$, $r$, OR) | **Description des tests d'hypothèses et tailles d'effet** : Tests de Wilcoxon ($p < 0,001$), convergence du $r$ de Rosenthal ($r = 0,61 - 0,62$) et Odds Ratios ajustés. |
| **Spread 3** *(p. 6-7)* | **Figure 3** (Distributions et densités) + **Figure 4** (Effondrement du *"Je ne sais pas"*) | **Description de la forme des distributions et de l'abstention** : Effet plafond (Shapiro-Wilk $p < 0,01$), division de la variance par 4 (Fligner-Killeen $p < 0,001$) et chute de l'évitement (-85 % à -92 %). |
| **Spread 4** *(p. 8-9)* | **Figure 5** (Durée vs score) + **Figure 6** (Facteurs biologiques : sexe & guilde) | **Description de la durée et des facteurs biologiques** : Pente négative de la durée en post-test ($\beta = -0,0094, p = 0,0018$), équivalence stricte selon le sexe ($p = 0,393$) et gain accru sur les coucous (+37,1 % vs +27,6 %). |
| **Spread 5** *(p. 10-11)* | **Tableau 2** (Modèle GLM interaction Public $\times$ Formation) | **Description du modèle GLM d'interaction** : Effet public initial significatif ($\text{OR} = 1,70, p = 0,00078$), effet formation massif ($\text{OR} = 4,18, p < 10^{-14}$) et terme d'interaction non significatif ($p = 0,903$). |
| **Spread 6** *(p. 12-13)* | **Figure 7** (Gradient de difficulté) + **Figure 8** (Forest Plot OR vs *Bombus*) | **Description du gradient de difficulté taxonomique** : Échelonnement des 27 genres (de 0,0 % à 57,4 % d'erreur) et Odds Ratios logistiques relatifs par rapport à *Bombus*. |
| **Spread 7** *(p. 14-15)* | **Figure 9** (Volcano Plot gains ciblés) + **Figure 10** (Matrice de confusion globale) | **Description des gains ciblés et de la matrice** : Taxons à gain significatif après FDR (*Seladonia*, *Nomada*, *Hylaeus*, *Anthidium*...) et distribution des transferts d'erreurs hors diagonale. |
| **Spread 8** *(p. 16-17)* | **Figure 11** (Top confusions) + **Tableau 3** (Critères morphologiques discriminants) | **Description des paires de confusions dominantes** : Quantification des transferts prédominants (*Sphecodes* $\to$ *Nomada* 58,3 %, *Anthophora* $\to$ *Bombus* 44,1 %...) et description des critères anatomiques discriminants. |
| **Spread 9** *(p. 18-19)* | **Tableau 4** (Tableau synoptique récapitulatif du mémoire) | **Description de la synthèse transversale** : Récapitulation chiffrée de l'ensemble des métriques des Axes A et B. |

---

## 3. Scripts et dossiers

* 🐍 `generer_resultats_memoire_commente.py` : Script Python générant le document avec mise en page double page et descriptions.
* 🐍 `generer_resultats_memoire.py` : Script Python générant la version visuelle épurée.
* 📁 `figures/` : Les 12 graphiques haute définition (300 DPI).
* 📁 `tables/` : Les tables exportées au format CSV pour Excel Francophone (délimiteur `;`, virgule `,`, signature UTF-8 BOM).
