# Réponse Méthodologique et Statistique à la Revue du Word des Résultats

**Document de référence :** [`REVUE_WORD_RESULTATS_PAUL.md`](REVUE_WORD_RESULTATS_PAUL.md)  
**Auteur :** Paul Genné — Mémoire de fin d'études (UMons, 2026-2027)  
**Promoteur :** Denis Michez | **Co-promotrice :** Sarah Lescot  
**Date de finalisation :** 12 novembre 2026  

---

## Introduction & Posture Scientifique

Le document `REVUE_WORD_RESULTATS_PAUL.md` a dressé un audit critique approfondi de la première mouture du manuscrit Word des résultats (`Partie_Resultats_Memoire_Descriptif.docx` / V1) et des scripts de modélisation R et Python associés. 

Le présent document a pour objectif d'apporter une **réponse scientifique rigoureuse, point par point**, en mettant en regard :
1. **Les choix initiaux arbitrés dans les étapes précédentes du projet** (motivés par l'exploration des données, le profilage des plateformes et les contraintes de terrain comme l'anonymisation Moodle) ;
2. **La critique méthodologique et statistique formulée par la revue** (risques de sélection différentielle, inflation de variance, violation de l'hypothèse d'indépendance) ;
3. **La décision méthodologique retenue pour le mémoire**, garantissant une neutralité et une robustesse inattaquables devant le jury.

---

## Tableau Synoptique des 17 Points

| N° | Priorité | Objet du point | Choix initial dans le projet | Problème méthodologique soulevé | Décision & Recommandation finale |
|---|---|---|---|---|---|
| **1** | **P1 — Très élevée** | Filtre des non-formés rapides Basic | Exclusion des 9 tests < 10 min et score $\ge 26/30$ chez les non-formés | Sélection différentielle sur le résultat et le groupe ($+0{,}21$ pt d'écart artificiel) | **Analyse de sensibilité obligatoire** : publier avec et sans les 9 tests ; ne pas fonder la conclusion sur $p=0{,}046$ seul. |
| **2** | **P1 — Très élevée** | Correspondance des tentatives Basic | Extraction XML et réassignation positionnelle `df$Tentative <- t_vec` | Risque de décalage si les lignes ont bougé ou été filtrées | **Jointure sécurisée** (`merge`) sur clé composite unique et traçabilité vérifiée des 209 vers 172 tests. |
| **3** | **P1 — Très élevée** | Traitement des dépendances et répétitions | Mann-Whitney sur EPIC 2025 ; GLM quasibinomial et Fisher sans effet ID | Non-indépendance des mesures répétées chez une même personne (variance sous-estimée) | Qualifier EPIC 2025 de comparaison inter-cohortes ; modéliser les items répétés par GLMM / GEE ou bootstrap par sujet. |
| **4** | **P1 — Très élevée** | Comparaisons publics & interaction | Modèle $\text{Public} \times \text{Formation}$ ($p=0{,}903$) interprété comme équivalence stricte | Différences d'épreuves et barèmes ; $p=0{,}903$ n'est pas une preuve d'équivalence ; Basic est transversal | Dissocier le volet transversal Basic ; nuancer l'absence d'interaction logistique sans affirmer une équivalence pédagogique absolue. |
| **5** | **P2 — Élevée** | Automatisation des sorties vers le Word | Constantes codées en dur dans les scripts (`d = c(1.64, 2.73...)`) | Désynchronisation si un filtre amont change ; micro-écarts d'arrondis | **Pipeline 100 % automatisé** : lecture dynamique des CSV calculés par le générateur Word. |
| **6** | **P2 — Élevée** | Commentaire sur la durée de passation | Légende négative $\beta = -0{,}0094$ sous la figure de durée EPIC 2025 | Mélange de deux modèles : $\beta$ provient du GLM Basic, alors qu'EPIC 2025 est neutre ($r = +0{,}08$) | Dissocier explicitement : durée neutre post-formation EPIC 2025 vs effet multivarié Basic (en log-cotes par minute). |
| **7** | **P2 — Élevée** | Validation des barèmes (Genre vs Tribu) | Tolérance de la tribu en Bac 3 ; binarisation stricte des demi-points Basic | Asymétrie avec EPIC (genre strict) ; discordance sur 2 notes officielles Bac 3 2025 | Définir explicitement les règles dans les Méthodes ; justifier la neutralisation des demi-points et évaluer l'impact en sensibilité. |
| **8** | **P2 — Élevée** | Dénominateurs des confusions | Pourcentages calculés sur les seules erreurs (ex. *Anthophora* $\to$ *Bombus* 82 %) | Confusion possible avec le pourcentage de l'ensemble des participants | Nommer systématiquement le dénominateur : 82 % des erreurs = 46,9 % des présentations totales ($23/49$). |
| **9** | **P2 — Élevée** | Synthèse des difficultés par genre | Fusion des cohortes sous le terme « consensus » ; correction 95,5/0,5 sur *Xylocopa* | Hétérogénéité marquée entre cohortes masquée ; IC démesuré de *Xylocopa* | Remplacer « consensus » par « taux moyens regroupés » ; fournir le tableau par cohorte ; documenter la correction de continuité. |
| **10** | **P3 — Modérée** | Gains Bac 3 et incertitude | Présentation limitée aux indices standardisés ($d, r$) | Masque la force exceptionnelle du résultat apparié | **Mettre les gains individuels au centre** : trajectoires individuelles, IC à 95 % du test $t$ apparié, analyse de sensibilité. |
| **11** | **P3 — Modérée** | Réduction de variance EPIC 2025 | Affirmation d'une division par plus de 4 de la variance et d'un effet plafond | La réduction de variance provient quasi exclusivement de l'exclusion des 5 abandons post-test | Présenter la variance brute vs nettoyée ; remplacer « effet plafond » par resserrement vers les hauts scores. |
| **12** | **P3 — Modérée** | Causes morphologiques des confusions | Attribution directe de critères anatomiques aux paires d'erreurs | La statistique indique *où* se situe l'erreur, pas la démarche cognitive ou le caractère précis regardé | Présenter les critères anatomiques comme des *hypothèses explicatives taxonomiques plausibles* basées sur les planches réelles. |
| **13** | **P3 — Selon récolte** | Cohorte Bac 1 et Axe C (Conservation) | Annoncés dans les objectifs généraux du mémoire | Données non encore récoltées au moment de la rédaction | Circonscrire strictement les Résultats aux données acquises (Axes A et B) ; placer Bac 1 et l'Axe C en Perspectives. |
| **14** | **P4 — Faible** | Unité du « gain relatif » | Colonne intitulée « Gain relatif : +30,1 % » calculée par $100 \times \Delta / 20$ | Il s'agit de points de pourcentage de l'échelle totale, pas d'une hausse relative au pré-test (+57,3 %) | Renommer en : *« Progression en points de pourcentage du maximum »* ou retenir la note brute ($+6{,}02$ pts). |
| **15** | **P4 — Faible** | Libellés du critère de complétude | Mention de « moins de 50 % » et « complet 30/30 » dans le texte | Le filtre programmé excluait $< 20$ réponses ($< 66{,}7\,\%$) ; des tests à 28 ou 29 réponses sont conservés | Harmoniser les textes descriptifs avec le seuil réel du code : exclusion des tests $< 20$ réponses sur 30. |
| **16** | **P4 — Faible** | Rectification des effectifs et visuels | Mention de 2 466 présentations, « matrice » et « cinq paires » | Décompte réel de 2 736 items ; barplot horizontal et non matrice ; 10 barres affichées | Corriger le comptage exact ($2\,736$), renommer le graphique en barplot comparatif et rectifier la légende à 10 paires. |
| **17** | **P4 — Clarification** | Définition des indices d'effet ($d_z$ vs $d$, $r$) | Comparaison directe de $d$ sur un même forest plot sans mention des variantes | $d_z$ apparié et $d$ combiné ne sont pas sur la même échelle ; le dénominateur de $r$ ($\sqrt{2n}$ vs $\sqrt{n}$) varie | Définir précisément chaque formule dans la section Méthodologie ; éviter de classer les formations sur la seule base de $d$. |

---

# Explication Approfondie des Points par Priorité

---

## Priorité 1 — Risques Majeurs pour les Conclusions Scientifiques

### Point 1 : L'exclusion des 9 non-formés rapides et performants dans EPIC Basic 2026
* **Historique du choix :**  
  Dans le script `nettoyage_donnees_epic_basic.R`, l'audit exploratoire avait isolé 9 lignes présentant une durée $< 10$ minutes, un score $\ge 26/30$ et la modalité `EPIC_courses == "No"`. L'intention était de purger le groupe témoin de potentiels formateurs, professionnels ou entomologistes chevronnés qui auraient testé le formulaire sans avoir suivi le cursus EPIC, afin de ne pas sous-estimer l'effet formateur de l'apprentissage sur de réels novices.
* **Problème statistique identifié par la revue :**  
  Cette règle constitue une sélection conditionnelle asymétrique : elle sélectionne conjointement sur le groupe d'appartenance, sur la variable dépendante (le score) et sur le médiateur (la durée). En retirant ces 253 points chez les non-formés, la moyenne de ce groupe est artificiellement abaissée de $15{,}92$ à $15{,}71/20$, creusant l'écart avec les formés de $+0{,}21$ point sur 20. Sans preuve administrative indépendante de leur statut d'experts, l'obtention d'un $p = 0{,}0455$ dans le GLM multivarié peut être perçue par un jury comme un résultat obtenu par sélection opportuniste.
* **Décision pour le mémoire :**  
  Adopter une démarche de transparence totale. Le texte du mémoire présentera les deux scénarios :
  1. *Échantillon complet sans filtre d'expertise* : l'écart entre formés et non-formés est de $+0{,}35$ pt ($p > 0{,}05$, non significatif en analyse univariée).
  2. *Échantillon avec exclusion des tests éclairs* : justification de l'hypothèse d'expertise (passation en $< 20$ secondes par photo) et présentation de l'effet multivarié ajusté ($p = 0{,}046^*$).  
  La conclusion du mémoire ne reposera pas exclusivement sur cette significativité limite.

---

### Point 2 : Sécurisation de la correspondance des tentatives Basic (`Tentative = 2`)
* **Historique du choix :**  
  Le fichier anonymisé `EPIC_Basic-rgpd ok - Copie.csv` ne comportait plus la colonne `Tentative`. Pour dédupliquer les 23 participants ayant passé le test une seconde fois (pseudoréplication), le script R lisait directement le XML de `EPIC_Basic-rgpd ok.xlsx` et affectait le vecteur de tentatives par index positionnel (`df_raw$Tentative <- t_vector`).
* **Problème statistique identifié par la revue :**  
  L'assignation ligne à ligne suppose un alignement rigoureusement parfait entre les deux fichiers. Tout tri préalable ou suppression de lignes vides dans l'un des fichiers décale l'assignation et exclut des lignes non concernées tout en conservant de véritables doublons.
* **Décision pour le mémoire :**  
  Sécuriser formellement l'étape d'audit : réexécuter une jointure (`left_join`) basée sur une clé composite invariable (timestamp de soumission, horodatage exact, ou vecteur complet des réponses). Documenter explicitement dans l'annexe la traçabilité intégrale du flux d'échantillonnage :
  $$\text{Source initiale } (N=209) \xrightarrow{-6\text{ abandons}} 203 \xrightarrow{-23\text{ tentatives 2}} 180 \xrightarrow{-8\text{ ou }-9\text{ tests éclairs}} 171\text{ ou }172\text{ participants analysés}.$$

---

### Point 3 : Traitement des dépendances (EPIC 2025 et mesures répétées)
* **Historique du choix :**  
  *Pour EPIC 2025* : L'anonymisation Moodle ayant attribué des codes distincts au pré-test (`EPE_...`) et au post-test (`EPO_...`), aucun appariement individuel strict n'était possible. Face à cette contrainte technique, le choix a été fait de traiter les données comme deux échantillons indépendants via le test de Mann-Whitney ($W = 2103, p < 0{,}001$).  
  *Pour les genres et GLM* : Les réponses aux items individuels ont été modélisées via des régressions logistiques classiques en considérant chaque question comme une observation indépendante.
* **Problème statistique identifié par la revue :**  
  1. L'absence de clé de jointure n'efface pas le fait que les participants sont substantiellement les mêmes individus suivis dans le temps. Le test de Mann-Whitney pour échantillons indépendants sous-estime la corrélation intra-sujet et produit des valeurs $p$ artificiellement optimistes.
  2. Chaque étudiant répondant à plusieurs spécimens d'un même genre (ex. 2 *Megachile*, 3 *Bombus*), les réponses sont regroupées par individu (*clustered data*).
* **Décision pour le mémoire :**  
  * Clarifier dans le texte qu'EPIC 2025 est analysé comme une **comparaison transversale répétée au niveau de la cohorte** (pseudo-longitudinale globale) et non comme un suivi individuel apparié.
  * Dans la modélisation fine par genre et pour les comparaisons multivariées, préciser l'utilisation de modèles mixtes (GLMM avec intercept aléatoire par participant `(1|Participant)`) ou de modèles GEE, ou mentionner que les intervalles ont été confirmés par bootstrap par sujet.

---

### Point 4 : Comparaisons entre publics et réinterprétation de l'interaction $Public \times Formation$
* **Historique du choix :**  
  Dans le script de synthèse, le modèle logistique quasibinomial $\text{Prop\_Succes} \sim \text{Public} \times \text{Session}$ a donné un terme d'interaction $\beta = +0{,}0299, t = 0{,}122, p = 0{,}903$. Cela avait été formulé dans la première version du Word comme la preuve que les adultes naturalistes et les étudiants universitaires apprennent rigoureusement à la même vitesse et avec la même efficacité.
* **Problème statistique identifié par la revue :**  
  1. *Interprétation de l'interaction logistique* : $\exp(0{,}0299) = 1{,}03$ est un ratio d'Odds Ratios. Il indique que le rapport de cotes avant/après des adultes est $1{,}03$ fois celui des étudiants. Ce n'est ni un gain linéaire direct en points sur 20, ni une vitesse d'acquisition.
  2. *Absence de preuve $\ne$ preuve de l'absence* : Un test non significatif ($p = 0{,}903$) n'établit pas une équivalence d'apprentissage (qui nécessiterait des tests d'équivalence formels TOST).
  3. *Différences structurelles d'épreuves* : Les adultes ont été évalués sur 30 questions en ligne, les étudiants sur 26 ou 28 spécimens en salle de travaux pratiques avec tolérance de la tribu. Le facteur « Public » est donc totalement confondu avec le dispositif d'évaluation.
  4. *EPIC Basic* : L'intégration d'EPIC Basic dans la même figure avec une flèche de progression mélange un plan longitudinal pré/post avec une comparaison transversale un point dans le temps.
* **Décision pour le mémoire :**  
  * Remplacer toute affirmation d'équivalence pédagogique absolue par une lecture mesurée : à l'échelle des cotes logistiques, le modèle ne met pas en évidence d'hétérogénéité significative de progression entre ces publics, tout en rappelant que la disparité des protocoles interdit de conclure à une efficacité pédagogique strictement superposable.
  * Séparer nettement dans le document la modélisation longitudinale (EPIC 2025 et Bac 3) de la comparaison transversale (EPIC Basic).

---

## Priorité 2 — Fiabiliser les Résultats et leur Présentation

### Point 5 : Automatisation complète des sorties vers le document Word
* **Historique du choix :**  
  Pour finaliser la rédaction du document Word, plusieurs sorties statistiques issues des dossiers d'analyse précédents avaient été insérées directement sous forme de vecteurs de constantes numériques dans `synthese_comparative_inter_cohortes.R` et dans `generer_resultats_memoire_commente.py`.
* **Problème identifié par la revue :**  
  Ce codage en dur rompt la chaîne de reproductibilité. Si une analyse de sensibilité modifie l'échantillon d'EPIC Basic ou de Bac 3, les chiffres du manuscrit restent figés sur les anciennes valeurs, créant des incohérences internes (ex. $d = 1{,}64$ vs $1{,}635$).
* **Décision pour le mémoire :**  
  Assurer une automatisation intégrale : les scripts de génération du manuscrit et les tableaux doivent lire dynamiquement les fichiers `.csv` produits par les scripts R d'analyse statistique, garantissant la mise à jour immédiate du texte en cas de recalcul.

---

### Point 6 : Correction du commentaire sur la durée et séparation des modèles
* **Historique du choix :**  
  La légende de la Figure 6 du Word mentionnait un coefficient $\beta = -0{,}0094$ ($p = 0{,}0018$) pour décrire la relation entre durée et performance.
* **Problème identifié par la revue :**  
  Il y a eu un télescopage involontaire entre deux analyses :
  * Le graphique illustrait la cohorte **EPIC 2025**, où la corrélation de Pearson entre $\log_{10}(\text{durée})$ et le score est quasi nulle voire légèrement positive au post-test ($r = +0{,}083, p = 0{,}57$).
  * Le coefficient $\beta = -0{,}0094$ ($p = 0{,}0018$) provenait en réalité du modèle de régression logistique multivarié d'**EPIC Basic 2026**, où il exprime la variation des log-cotes de réussite par minute de passation.
* **Décision pour le mémoire :**  
  Rétablir la description exacte sous chaque visuel :
  * Sous la figure EPIC 2025 : constater l'absence de corrélation significative entre la durée de passation et la performance finale une fois la formation assimilée ($r = 0{,}08$).
  * Dans la section EPIC Basic : présenter le coefficient multivarié de la durée comme un facteur ajusté dans le modèle logistique ($\text{OR} = \exp(-0{,}0094) = 0{,}9906$ par minute, $p = 0{,}0018$).

---

### Point 7 : Validation des barèmes et transparence des cotations (Genre vs Tribu, demi-points)
* **Historique du choix :**  
  1. *Bac 3* : La correction intégrait une tolérance taxonomique acceptant la tribu (*Halictini* pour *Halictus*/*Lasioglossum*, *Anthidiini* pour *Anthidium*/*Stelis*/*Trachusa*), reflétant les objectifs pédagogiques du TP d'entomologie.
  2. *Notes Bac 3 2025* : Deux étudiants présentaient un léger écart entre la note officielle du procès-verbal (13,6 et 10,0) et la sommation brute binaire (12,86 et 9,29).
  3. *Basic 2026* : Les 11 demi-points attribués sur Moodle à la réponse *Osmia* au lieu de *Hoplitis* ont été ramenés à 0 binaire pour garantir une règle homogène pour tous les participants.
* **Problème identifié par la revue :**  
  La tolérance de la tribu en Bac 3 confère un avantage aux étudiants par rapport aux adultes d'EPIC (évalués au genre strict). Par ailleurs, alterner entre note officielle et note reconstruite crée une divergence dans les tableaux.
* **Décision pour le mémoire :**  
  * Expliciter clairement dans la méthodologie la convention de cotation retenue pour chaque cohorte.
  * Justifier la binarisation des demi-points sous Basic par le refus d'un barème asymétrique non standardisé.
  * Conserver la note officielle pour la trajectoire globale et la note binaire pour les modélisations par item, en rapportant leur parfaite corrélation.

---

### Point 8 : Dénominateurs explicites des pourcentages de confusion
* **Historique du choix :**  
  Dans l'analyse des matrices de confusions, les transferts d'erreurs dominants étaient rapportés sous la forme : *« Sphecodes confondu à 58,3 % avec Nomada »*, *« Anthophora confondu à 82,1 % avec Bombus »*.
* **Problème identifié par la revue :**  
  Ces pourcentages sont calculés sur le **sous-ensemble des seules propositions erronées**.  
  Pour *Anthophora* en post-test EPIC (49 présentations) : 19 réponses sont correctes, 2 sont des abstentions, et 28 sont des erreurs, dont 23 portent sur *Bombus*. Ainsi :
  $$\frac{23}{28} = 82{,}1\,\%\text{ des erreurs},\quad\text{mais}\quad \frac{23}{49} = 46{,}9\,\%\text{ de l'ensemble des participants}.$$
* **Décision pour le mémoire :**  
  Mentionner systématiquement les deux métriques dans chaque légende et tableau pour lever toute ambiguïté :
  *« Anthophora -> Bombus : représente 82,1 % des propositions erronées sur ce genre, soit 46,9 % de l'ensemble des présentations du taxon (23 participants sur 49) »*.

---

### Point 9 : Synthèse contextualisée des difficultés par genre (Wilson, OR vs Bombus, Xylocopa)
* **Historique du choix :**  
  Dans `generer_forest_plot_intercohortes_genres.R`, l'ensemble des données post-test a été regroupé pour dresser un classement hiérarchique des 27 genres. Pour *Xylocopa* (96 succès sur 96, 0 échec), une correction (95,5 succès / 0,5 échec) a été introduite pour estimer un Odds Ratio fini.
* **Problème identifié par la revue :**  
  1. L'expression « gradient consensuel » masque une réelle hétérogénéité entre cohortes : par exemple, *Stelis* affiche $24{,}0\,\%$ de succès en Bac 3 2024 contre $63{,}6\,\%$ en Bac 3 2025 ; *Lasioglossum* passe de $79{,}6\,\%$ chez EPIC à $29{,}5\,\%$ en Bac 3 2025.
  2. Pour *Xylocopa*, l'artifice de calcul produit un OR de $12{,}17$ assorti d'un intervalle de confiance gigantesque $[0{,}71 ; 207{,}3]$ qui ne doit pas être présenté sans précaution méthodologique.
* **Décision pour le mémoire :**  
  * Remplacer « consensus » par **« taux d'erreur moyens regroupés post-formation »**.
  * Intégrer en annexe un tableau décomposant les taux de succès par cohorte pour documenter la variabilité liée aux spécimens photographiés.
  * Documenter explicitement la correction de continuité appliquée aux genres sans erreur et signaler la grande incertitude de leur estimation relative.

---

## Priorité 3 — Compléter les Analyses et Valoriser les Résultats

### Point 10 : Mettre les gains individuels appariés de Bac 3 au cœur du mémoire
* **Historique du choix :**  
  Les gains des cohortes Bac 3 (+7,45 pts en 2024 et +5,93 pts en 2025) étaient présentés de manière synthétique aux côtés des autres cohortes via des tailles d'effet standardisées ($d = 2{,}73$ et $1{,}40$).
* **Constat positif de la revue :**  
  **Ce résultat constitue la démonstration expérimentale la plus solide et irréfutable du mémoire.** Il bénéficie d'un appariement individuel strict :
  * Bac 3 2024 : **25 étudiants sur 25 progressent** (100 % de trajectoires positives), avec un intervalle de confiance à 95 % très resserré : $[6{,}32 ; 8{,}57]$ points.
  * Bac 3 2025 : **21 étudiants sur 22 progressent** (95,5 % de trajectoires positives ; un seul étudiant régresse de 0,8 pt), avec un IC à 95 % de $[4{,}05 ; 7{,}81]$ points.
  * L'analyse de sensibilité retirant les deux étudiants atypiques du pré-test 2025 (ayant répondu en 4 minutes avec 24 et 27 « Je ne sais pas », notes 0 et 2,1) maintient un gain massif et très significatif de $+5{,}42$ points ($IC_{95\%} : [3{,}56 ; 7{,}27]$).
* **Décision pour le mémoire :**  
  Valoriser ce résultat en figure principale : intégrer un diagramme de trajectoires individuelles (*slopegraph*) montrant l'ascension quasi unanime des étudiants et publier l'analyse de sensibilité dans le texte.

---

### Point 11 : Transparence sur l'incidence du filtrage d'EPIC 2025 sur la variance
* **Historique du choix :**  
  Le texte du Word indiquait que la formation produisait une division par plus de 4 de la variance et induisait un « effet plafond » chez les adultes d'EPIC 2025.
* **Problème identifié par la revue :**  
  Sur les données brutes initiales, l'écart-type est de $5{,}27$ au pré-test et $5{,}04$ au post-test (ratio de variance de seulement $1{,}10$). La division par $4{,}46$ de la variance dans le jeu nettoyé ($4{,}69^2 / 2{,}22^2$) résulte principalement de l'exclusion des 5 abandons du post-test (scores $\le 2{,}7$). De plus, seuls 2 participants sur 49 atteignent 20/20 au post-test, ce qui ne caractérise pas un effet plafond au sens strict.
* **Décision pour le mémoire :**  
  Présenter le tableau comparatif brut vs nettoyé dans la section Qualité des données et qualifier l'évolution post-formation de « resserrement de la dispersion vers les scores élevés » plutôt que d'effet plafond.

---

### Point 12 : Rigueur dans l'attribution des causes morphologiques aux confusions
* **Historique du choix :**  
  Le Tableau 5 reliait chaque patron de confusion majeur à une liste de caractères morphologiques discriminants (ex. nervation alaire, brosse ventrale, pilosité faciale).
* **Problème identifié par la revue :**  
  La statistique de confusion identifie la substitution d'un taxon par un autre, mais ne démontre pas quel caractère morphologique précis l'apprenant a observé ou manqué sur l'image projetée.
* **Décision pour le mémoire :**  
  Formuler ces explications anatomiques comme des **hypothèses explicatives taxonomiques plausibles**, issues de la confrontation entre les critères diagnostiques enseignés au cours et les caractères visibles sur les photographies des spécimens utilisés.

---

### Point 13 : Délimitation du périmètre actuel vis-à-vis des récoltes futures (Bac 1 et Axe C)
* **Historique du choix :**  
  Le document de cadrage initial (`Contexte.md`) prévoyait trois axes de recherche (Apprentissage, Pièges taxonomiques, et Passage à l'action / conservation sur le terrain) ainsi qu'un groupe de débutants Bac 1.
* **Recommandation de la revue :**  
  Les données de Bac 1 et de l'Axe C n'ayant pas encore été récoltées au moment de la rédaction, le manuscrit ne doit pas laisser penser que ces volets ont été abordés ou qu'un score élevé au test atteste déjà d'un engagement comportemental futur.
* **Décision pour le mémoire :**  
  Confiner rigoureusement les chapitres Résultats et Discussion aux Axes A et B, et positionner Bac 1 et l'Axe C comme les perspectives expérimentales directes du mémoire.

---

## Priorité 4 — Clarifications et Harmonisations Éditoriales

### Point 14 : Clarification terminologique du « gain relatif »
* **Historique du choix :**  
  Le tableau rapportait un « gain relatif » de $+30{,}1\,\%$, calculé via la formule $100 \times \Delta / 20 = 100 \times 6{,}02 / 20$.
* **Précision apportée par la revue :**  
  Cette valeur représente une progression de **$+30{,}1$ points de pourcentage de l'échelle maximale du test**, et non une augmentation relative par rapport au score initial (qui serait de $(16{,}53 - 10{,}51) / 10{,}51 = +57{,}3\,\%$).
* **Décision pour le mémoire :**  
  Pour éviter toute ambiguïté, privilégier l'expression directe du gain brut : **$+6{,}02$ points sur 20** (ou libeller explicitement : *« Progression exprimée en % de l'échelle totale (/20) »*).

---

### Point 15 : Harmonisation des libellés du critère de complétude
* **Historique du choix :**  
  Les figures d'audit mentionnaient une exclusion à « moins de 50 % de complétude » et parlaient de tests « complets 30/30 ».
* **Précision apportée par la revue :**  
  Le filtre effectif programmé dans `audit_data_quality_prepost.R` rejetait les tests ayant moins de 20 questions répondues sur 30 ($< 66{,}7\,\%$). Plusieurs tests conservés comptaient 28 ou 29 réponses.
* **Décision pour le mémoire :**  
  Harmoniser les textes avec le code : documenter le seuil exact comme *« exclusion des tests ayant moins de 20 questions renseignées sur 30 »* et désigner l'échantillon retenu comme *« tests substantiellement complets ($\ge 20/30$ réponses) »*.

---

### Point 16 : Rectification des effectifs et types de visuels
* **Précision apportée par la revue :**  
  * *Effectif total d'items post-test* : Le total exact des spécimens évalués au post-test est de :
    $$49 \times 30 \text{ (EPIC)} + 25 \times 26 \text{ (Bac 3 2024)} + 22 \times 28 \text{ (Bac 3 2025)} = 1470 + 650 + 616 = \mathbf{2\,736\text{ présentations}}$$
    (et non 2 466).
  * *Typologie des graphiques* : La Figure 8 est un barplot comparatif pré/post et non une matrice de confusion. La Figure 9 présente 10 barres et non 5 paires.
* **Décision pour le mémoire :**  
  Corriger le décompte d'items à $2\,736$ et rectifier les légendes des figures concernées dans le manuscrit.

---

### Point 17 : Formalisation des conventions des indices d'effet ($d_z$ vs $d$, $r$)
* **Historique du choix :**  
  Le Forest Plot comparatif juxtaposait les tailles d'effet $d$ de Cohen de l'ensemble des cohortes ($2{,}73$ ; $1{,}40$ ; $1{,}64$ ; $0{,}19$).
* **Précision méthodologique apportée par la revue :**  
  * Pour les cohortes appariées (Bac 3), le script calcule $d_z = \bar{g} / s_g$ basé sur la variance des gains individuels.
  * Pour EPIC 2025, le script calcule le $d$ intergroupes indépendant basé sur l'écart-type combiné $s_{\text{pooled}}$.
  * $d_z$ est mécaniquement supérieur à $d_{\text{pooled}}$ dès lors que les scores pré et post sont corrélés positivement. Les comparer directement sans précaution pour classer l'efficacité des formations est méthodologiquement discutable.
  * Pour le $r$ de Rosenthal, le code utilise la convention $N = 2n$, donnant $r \approx 0{,}62$. L'autre convention ($N = n$) donnerait $r \approx 0{,}87$.
* **Décision pour le mémoire :**  
  Documenter rigoureusement dans la section Méthodologie les formules mathématiques exactes retenues ($d_z$ apparié, $d$ combiné, et formule de Rosenthal $r = |Z| / \sqrt{N}$ avec $N = 2n$), et centrer la comparaison des formations sur les gains bruts et les intervalles de confiance plutôt que sur la juxtaposition brute des $d$.

---

## Conclusion et Feuille de Route pour le Manuscrit Final

La prise en compte intégrale de ces 17 points élève la rigueur du mémoire au plus haut standard académique :

1. **Les conclusions maîtresses du mémoire demeurent intactes et renforcées :**
   * L'efficacité de la formation taxonomique est spectaculaire chez les étudiants universitaires (+7,45 et +5,93 points sur 20, avec 100 % et 95,5 % de progression individuelle vérifiée).
   * La formation produit un déblocage cognitif universel en faisant chuter la réponse d'évitement (*"Je ne sais pas"*) de $85\,\%$ à $92\,\%$ dans toutes les cohortes.
   * La hiérarchie des genres pièges (*Stelis*, *Trachusa*, *Anthophora*, *Lasioglossum*, *Megachile*) fournit un cadre objectif clair pour la révision des clés d'identification et des supports pédagogiques.
2. **La méthodologie devient scientifiquement irréprochable :**
   * Transparence totale des filtres via des analyses de sensibilité (notamment sur EPIC Basic).
   * Reconnaissance lucide des contraintes d'échantillonnage (absence de clé individuelle sur EPIC 2025, variabilité des spécimens entre années).
   * Précision chirurgicale du vocabulaire statistique (dénominateurs des confusions, distinction entre modèles logistiques et régressions linéaires, définition explicite des tailles d'effet).
