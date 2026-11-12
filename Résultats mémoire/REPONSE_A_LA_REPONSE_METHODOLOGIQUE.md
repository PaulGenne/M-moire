# Réponses à la réponse méthodologique : corrections et vérifications prioritaires

Document examiné : [Réponse_revue_word.md](https://github.com/PaulGenne/M-moire/blob/cb013c144f4225673b6f3dd07a8dc4cdfeb9129b/R%C3%A9sultats%20m%C3%A9moire/R%C3%A9ponse_revue_word.md).

Date : 12 novembre 2026.

## Synthèse des recommandations

La réponse reprend plusieurs orientations pertinentes : examiner le filtre Basic en sensibilité, sécuriser les tentatives, distinguer les plans d'étude, automatiser les chiffres du manuscrit et expliciter les conventions statistiques. Les points suivants nécessitent toutefois une correction ou une vérification avant de retenir les conclusions finales.

| Priorité | Point | Correction ou vérification attendue |
|---|---|---|
| Très élevée | Sensibilité Basic | Comparer les mêmes règles de déduplication et le même modèle, en changeant uniquement le filtre étudié |
| Très élevée | Dépendance EPIC 2025 | Ne pas considérer un changement de vocabulaire comme une justification de l'indépendance |
| Très élevée | Modèles à mesures répétées | Réaliser les analyses proposées et examiner leurs résultats, sans présupposer leur confirmation |
| Élevée | Portée des conclusions | Retirer les affirmations de causalité irréfutable et de mécanisme cognitif universel |
| Élevée | Comparabilité des épreuves | Ne pas remplacer un classement par les d par un classement par les gains bruts sans justification des tests |
| À corriger | Relation entre d_z, d combiné et corrélation | Corriger l'affirmation selon laquelle une corrélation positive implique toujours d_z supérieur au d combiné |
| À préciser | Corrélation entre scores officiels et reconstruits | Remplacer « parfaite corrélation » par la valeur calculée et documenter les écarts de score |

## 1. Basic : isoler réellement l'effet du filtre

### Contexte

EPIC Basic 2026 contient un test par ligne et une variable `EPIC_courses`. Il s'agit d'une comparaison entre formés et non-formés, et non d'une mesure avant/après des mêmes personnes. La copie disponible comporte 209 tests. La réponse annonce un échantillon final de 172 observations après nettoyage et traitement des tentatives.

Le filtre contesté exclut uniquement les non-formés qui répondent en moins de dix minutes avec au moins 26 bonnes réponses sur 30. Les neuf ID concernés dans la copie sont E024, E048, E049, E082, E099, E102, E112, E159 et E187.

### Ce que montrent les calculs disponibles

Les chiffres suivants utilisent les sommes binaires des évaluations, converties sur 20. Ils sont calculés **après retrait des six abandons sévères et avant déduplication des tentatives** :

| Sélection | Formés | Non-formés | Écart des moyennes /20 |
|---|---|---|---:|
| Sans filtre des tests rapides | 74 tests ; moyenne 16,2703 | 129 tests ; moyenne 15,9225 | +0,3478 |
| Avec filtre des tests rapides | 74 tests ; moyenne 16,2703 | 120 tests ; moyenne 15,7111 | +0,5592 |

Les neuf tests retirés totalisent 253 points sur 30. Le total des non-formés passe de 3 081 à 2 828 points :

$$\text{Moyenne sans filtre}=\frac{3081}{129}\times\frac{20}{30}=15,9225.$$

$$\text{Moyenne avec filtre}=\frac{3081-253}{129-9}\times\frac{20}{30}=15,7111.$$

Le filtre accroît donc l'écart de **0,2114 point sur 20 à cette étape**. Cette incidence ne doit pas être assimilée sans recalcul à son effet sur l'échantillon final de 172 observations.

### Ce qu'il faut modifier dans la réponse

La proposition oppose un écart de +0,35 point en analyse univariée à une valeur p de 0,046 issue d'un modèle ajusté sur un autre échantillon. Elle modifie donc à la fois la population et la méthode. Cette comparaison n'isole pas l'effet du filtre.

Pour une sensibilité interprétable, conserver :

- la même source et la même règle de déduplication ;
- les mêmes autres exclusions ;
- le même score ;
- le même modèle, les mêmes variables d'ajustement et le même traitement des valeurs manquantes.

Faire varier uniquement l'inclusion des tests rapides concernés, puis rapporter les effectifs, l'écart ou le coefficient estimé et son intervalle de confiance dans les deux scénarios. Si les comparaisons univariées et ajustées sont toutes deux utiles, les présenter dans chaque scénario.

L'identification comme experts doit reposer sur une information indépendante du score. Une excellente performance rapide ne suffit pas à établir ce statut. La conclusion doit pouvoir changer après réanalyse, y compris perdre une significativité.

Le diagramme « 171 ou 172 participants » doit également être remplacé par des effectifs exacts et des exclusions séquentielles vérifiées : les motifs peuvent se recouper et les comptes globaux ne doivent pas être simplement soustraits les uns après les autres.

## 2. EPIC 2025 : le vocabulaire ne résout pas la dépendance

### Contexte

Les sources EPIC 2025 comprennent 56 prétests et 54 posttests. Après sélection, 50 prétests et 49 posttests sont conservés. Les fichiers disponibles ne permettent pas de relier individuellement les observations entre moments, alors que certaines personnes peuvent être présentes aux deux.

### Recommandation

Qualifier l'analyse de « comparaison transversale répétée » ou de « comparaison au niveau de la cohorte » décrit un mode de présentation. Cela ne démontre pas l'indépendance nécessaire au test de Mann–Whitney utilisé.

La statistique W = 2103 est cohérente avec les scores sélectionnés ; l'interprétation de sa valeur p demande une justification distincte de la structure des observations.

Il faut préciser le recouvrement des participants auprès des responsables du protocole et rechercher une correspondance documentée. À défaut, conserver les écarts descriptifs ou justifier une méthode adaptée à l'information réellement disponible.

### Nuance sur le sens du biais

Éviter l'affirmation générale selon laquelle ignorer l'appariement rend nécessairement les valeurs p trop petites. Par exemple, la variance d'une différence de moyennes contient un terme de covariance :

$$\operatorname{Var}(\bar X_{post}-\bar X_{pré})=\operatorname{Var}(\bar X_{post})+\operatorname{Var}(\bar X_{pré})-2\operatorname{Cov}(\bar X_{post},\bar X_{pré}).$$

La direction de l'erreur dépend de la structure de dépendance et du test considéré. Cette formule n'est pas une correction directe de Mann–Whitney ; elle montre pourquoi une direction universelle ne peut pas être présumée.

Formulation recommandée : **« La dépendance éventuelle entre les observations n'est pas représentée par le test indépendant ; la validité de l'inférence doit être réexaminée. »**

## 3. Modèles mixtes, GEE et bootstrap : vérifier sans présupposer la confirmation

### Contexte

Une personne répond à plusieurs questions et peut être observée avant et après. B3_24_01 fournit ainsi 26 réponses à chacun des deux moments, soit 52 observations liées à une seule personne. Au posttest Bac 3 2024, Megachile fournit 50 réponses pour 25 personnes.

### Recommandation

La proposition de recourir à des modèles mixtes, aux GEE ou au bootstrap par sujet constitue une piste à mettre en œuvre. La formulation doit toutefois rester ouverte au résultat : il faut **estimer et examiner** les intervalles, pas annoncer à l'avance qu'ils confirmeront les précédents.

Formulation recommandée :

> Recalculer les estimations et leur incertitude avec une méthode tenant compte des réponses répétées par personne. Comparer les coefficients, intervalles et conclusions à ceux de l'analyse initiale, puis rapporter les différences observées.

Le choix de méthode doit correspondre à la question, aux effectifs, aux identifiants et aux items disponibles. Une structure par participant ne résout pas automatiquement la variabilité entre spécimens. Pour EPIC, aucune méthode ne permet de recréer une correspondance individuelle inconnue par une simple déclaration de modèle.

## 4. Conclusions : distinguer progression observée, causalité et mécanisme cognitif

### Résultats à conserver

Les progressions Bac 3 sont étayées par les observations appariées :

| Cohorte | Score utilisé | Paires | Gain moyen /20 | IC t à 95 % | Trajectoires positives |
|---|---|---:|---:|---|---:|
| Bac 3 2024 | Reconstruit, arrondi au centième par test | 25 | +7,4464 | [6,3209 ; 8,5719] | 25/25 |
| Bac 3 2025 | Note source | 22 | +5,9318 | [4,0495 ; 7,8142] | 21/22 |

Le seul gain négatif 2025 est celui de B3_25_15 : 12,9 au prétest et 12,1 au posttest, soit −0,8 point. Les lignes Excel sont respectivement 8 et 16 dans les deux fichiers 2025.

### Formulations à corriger

Remplacer « démonstration expérimentale […] irréfutable » par une description de la progression des mêmes ID. L'appariement ne fournit pas à lui seul le scénario contrefactuel nécessaire pour attribuer tout le changement à la formation.

Formulation recommandée :

> Les participants Bac 3 retrouvés aux deux moments présentent une progression moyenne nettement positive. L'absence de groupe témoin et les conditions de passation limitent l'attribution causale de cette progression à la seule formation.

Remplacer également « déblocage cognitif universel » par le résultat effectivement mesuré : la baisse de fréquence des réponses « Je ne sais pas » dans les ensembles analysés. Cette baisse ne démontre ni un mécanisme cognitif universel ni une disparition de toutes les difficultés.

Éviter « scientifiquement irréprochable » et « robustesse inattaquable ». Nommer les choix vérifiés, les sensibilités exécutées et les limites restantes est plus précis que qualifier globalement la méthode.

## 5. Comparer les gains bruts ne rend pas les épreuves équivalentes

Présenter les gains en points sur 20 avec leurs intervalles rend l'analyse plus lisible. Cela ne suffit pas pour classer les formations ou comparer intrinsèquement les publics.

Les tests comportent 30, 26 ou 28 questions. La correction peut accepter une tribu en Bac 3 alors qu'EPIC demande le genre exact. Exemple réel : B3_25_01, posttest 2025, ligne 2, question 2, reçoit la solution Trachusa et répond Anthidinii ; la reconstruction compte cette réponse comme correcte.

Comparer un gain de +7,45 à un gain de +5,93 suppose donc de discuter les spécimens, la difficulté des épreuves, le niveau initial, les ressources autorisées et les délais. Des intervalles de confiance précis ne compensent pas une différence d'instrument de mesure.

Conserver les gains comme résultats propres à chaque cohorte. Toute conclusion comparative sur l'efficacité des dispositifs doit reposer sur une justification supplémentaire de la comparabilité des mesures.

## 6. Corriger la relation annoncée entre d_z, d combiné et corrélation

### L'affirmation à retirer

La réponse indique qu'une corrélation positive entre scores pré et post implique mécaniquement que d_z est supérieur au d combiné. Cette affirmation est fausse.

Les recalculs sur les paires disponibles donnent :

| Cohorte | Corrélation pré/post | d_z | d combiné |
|---|---:|---:|---:|
| Bac 3 2024, scores reconstruits | 0,59175 | 2,73105 | 2,48799 |
| Bac 3 2025, notes source | 0,33526 | 1,39720 | 1,65569 |

En 2025, la corrélation est positive mais d_z est inférieur au d combiné : les données fournissent directement un contre-exemple.

### Pourquoi

Pour les mêmes personnes :

$$s_g^2=s_{pré}^2+s_{post}^2-2r\,s_{pré}s_{post},\qquad d_z=\frac{\bar g}{s_g}.$$

Le d combiné utilise ici :

$$s_c=\sqrt{\frac{s_{pré}^2+s_{post}^2}{2}},\qquad d_c=\frac{\bar g}{s_c}.$$

Avec les notes source 2025 :

$$s_{pré}=4,327232,\quad s_{post}=2,635591,\quad s_g=4,245489,\quad\bar g=5,931818.$$

$$d_z=5,931818/4,245489=1,397205.$$

$$s_c=\sqrt{(4,327232^2+2,635591^2)/2}\approx3,5827,\qquad d_c\approx1,65569.$$

À écarts-types pré et post égaux et pour un gain positif, la relation se simplifie en :

$$\frac{d_z}{d_c}=\frac{1}{\sqrt{2(1-r)}}.$$

Il faut alors **r > 0,5**, et non simplement r > 0, pour obtenir d_z > d_c. Le cas des dispersions inégales dépend aussi de leur rapport.

La recommandation initiale reste valable : définir chaque indice et éviter leur comparaison directe pour classer les formations. Il faut corriger l'explication mathématique, pas abandonner cette précaution.

## 7. Scores officiels et reconstruits : forte corrélation ne signifie pas identité

Pour les notes initiales des 22 paires Bac 3 2025, la corrélation entre score officiel et score reconstruit vaut **0,99882165**. Elle est très forte, mais n'est pas parfaite.

Deux écarts concrets subsistent dans `UMONS_Pretest_2025.xlsx` :

| ID | Ligne Excel | Note source /20 | Score reconstruit /20 |
|---|---:|---:|---:|
| B3_25_03 | 5 | 13,6 | 18 × 20/28 = 12,8571 |
| B3_25_21 | 19 | 10,0 | 13 × 20/28 = 9,2857 |

Une corrélation élevée indique principalement que les classements et variations des scores sont très proches. Elle ne garantit ni leur égalité ni leur interchangeabilité pour chaque analyse.

Recommandations :

- Remplacer « parfaite corrélation » par la valeur calculée, en précisant la population et le moment concernés.
- Faire confirmer le barème et l'origine des deux écarts.
- Identifier la version de score utilisée pour chaque résultat global et chaque modèle par item.
- Présenter une sensibilité lorsque ce choix peut modifier l'estimation ou sa conclusion.

## 8. Critères de validation de la prochaine analyse

La prochaine version doit permettre de vérifier les points suivants :

1. Les scénarios Basic font varier uniquement le filtre étudié, après une déduplication contrôlée.
2. Les effectifs successifs et les recoupements d'exclusions sont établis exactement.
3. Les modèles à réponses répétées sont effectivement estimés, avec leurs diagnostics et leurs résultats.
4. Les tableaux et graphiques lisent les sorties recalculées plutôt que des constantes saisies manuellement.
5. Les résultats nouveaux sont comparés aux anciens, y compris lorsque l'incertitude augmente ou qu'une significativité disparaît.
6. Les conclusions restent à l'échelle des mesures disponibles : progression des scores, différences observées et confusions sur les spécimens évalués.

Les exemples, données sources et calculs détaillés complémentaires figurent dans [la revue classée par priorité](REVUE_WORD_RESULTATS_PAUL.md).
