# Étape 1 : Qualité des Données et Profilage (EPIC Pretest & Posttest 2025)

Ce dossier rassemble l'ensemble des scripts d'audit, des données sources converties, des données nettoyées et des visualisations de contrôle qualité réalisées lors de l'**Étape 1 (Data Quality & Profiling Analyse)** pour la cohorte **EPIC 2025** (`EPIC_Pretest.xlsx` et `EPIC_Posttest.xlsx`).

---

## 1. Contexte méthodologique
* **Nature des données** : Évaluation des capacités d'identification de 30 spécimens d'abeilles sauvages au genre (sur une échelle standardisée de 0 à 20 points).
* **Modalité d'évaluation** : Passation en ligne asynchrone sur la plateforme Moodle (UMons).
* **Contrainte d'anonymisation** : Les identifiants ayant été anonymisés séparément (`EPE_...` pour le Pré-test et `EPO_...` pour le Post-test), aucun appariement individuel strict n'est possible. Les analyses opèrent donc au niveau des distributions globales et des comparaisons de groupes indépendants.

---

## 2. Synthèse des anomalies détectées et critères d'exclusion

Sur les **56 participants du Pré-test** et **54 participants du Post-test**, un total de **11 observations** faussent gravement les résultats et doivent être écartées :

| Catégorie d'anomalie | Critère objectif de détection | Pré-test | Post-test | Impact sur les analyses si non corrigé | Action retenue |
|---|---|:---:|:---:|---|---|
| **Abandons complets** | 0 question répondue (30 omissions `-`), score 0.0/20, fermeture automatique Moodle à l'échéance | 3 cas | 0 cas | Effondrement artificiel de la moyenne, écrasement de la variance | **Exclusion** |
| **Abandons précoces** | $\le 3$ questions tentées sur 30, score $\le 1.3/20$, durée de plusieurs jours clôturée à 12:00 | 1 cas | 4 cas | Biais d'attrition sévère, fausse augmentation du taux d'erreur | **Exclusion** |
| **Incomplétudes majeures** | $< 50\%$ du test réalisé (10 à 14 questions sur 30), clôture administrative automatique au matin | 2 cas | 1 cas | Biais de troncature : pénalise à 100% les taxons situés en fin de test | **Exclusion** |
| **Total Exclusions** | | **6 (10.7%)** | **5 (9.3%)** | | **N_clean = 50 (Pre) et 49 (Post)** |

---

## 3. Profils atypiques analysés et CONSERVÉS (Fausses anomalies)

1. **Omissions ponctuelles ($\ge 28$ questions sur 30 répondues)** :
   - *Pré-test* : 6 participants avec 29/30 questions (`EPE_022`, `EPE_029`, `EPE_030`, `EPE_040`, `EPE_041`, `EPE_044`).
   - *Post-test* : 4 participants avec 28 ou 29/30 questions (`EPO_005`, `EPO_021`, `EPO_026`, `EPO_028`).
   - *Décision* : **Conservés**. Représentent une complétude $\ge 93.3\%$. Le saut de 1 ou 2 questions difficiles relève de l'hésitation normale et ne tronque pas la mesure de compétence.
2. **Passations ultra-rapides ("Speed-runs", ~6 minutes au Pré-test)** :
   - `EPE_2025_024` (6 min 18 s, note 3.3/20) et `EPE_2025_025` (6 min 10 s, note 2.0/20).
   - *Décision* : **Conservés**. L'inspection détaillée montre qu'ils ont activement cliqué sur le bouton explicite *"I don't know"* (22 et 24 fois sur 30). Ce sont de réels novices qui ont répondu honnêtement. Les exclure introduirait un biais de sélection en éliminant les vrais débutants du pré-test.
3. **Sessions longues (> 24h) avec questionnaire complet** :
   - *Décision* : **Conservés**. Le test étant non chronométré, la fenêtre est restée ouverte sur plusieurs jours. Tous ont répondu aux 30 questions avec d'excellents scores.

---

## 4. Impact statistique du nettoyage

| Métrique | Pré-test (Brut) | Pré-test (Nettoyé) | Post-test (Brut) | Post-test (Nettoyé) |
|---|:---:|:---:|:---:|:---:|
| **Effectif (N)** | 56 | **50** | 54 | **49** |
| **Moyenne (/20)** | 9.57 | **10.51** (+0.94) | 15.09 | **16.53** (+1.44) |
| **Écart-type** | 5.27 | **4.70** | 5.04 | **2.22** (divisé par 2.3 !) |
| **Médiane (/20)** | 9.30 | **10.00** | 16.70 | **16.70** |
| **Score Minimum** | 0.0 | **2.0** | 0.0 | **8.7** |
| **Score Maximum** | 20.0 | **20.0** | 20.0 | **20.0** |

---

## 5. Structure des dossiers et fichiers

```text
2025/
└── Qualité données EPIC 2025/
    ├── README.md                              # Ce document de synthèse
    ├── audit_data_quality_prepost.R          # Script R principal autonome d'audit
    ├── EPIC_Pretest.csv                       # Données Pré-test brutes converties UTF-8
    ├── EPIC_Posttest.csv                      # Données Post-test brutes converties UTF-8
    └── output/                                # Dossier des livrables
        ├── EPIC_Pretest_clean.csv             # Données Pré-test nettoyées (N = 50)
        ├── EPIC_Posttest_clean.csv            # Données Post-test nettoyées (N = 49)
        ├── participants_anomalies_qualite_prepost.csv # Registre officiel des 11 exclusions
        ├── tableau_impact_nettoyage_prepost.csv       # Tableau comparatif avant/après
        ├── fig1_diagnostic_qualite_prepost.png        # Planche 4 panneaux de contrôle qualité (300 DPI)
        └── fig2_impact_nettoyage_scores.png           # Distributions et densités comparatives (300 DPI)
```

