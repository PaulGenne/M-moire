# Étape 1 : Qualité des Données et Profilage (EPIC Basic 2026)

Ce dossier rassemble l'ensemble des scripts d'audit, des données intermédiaires et des visualisations de contrôle qualité réalisées lors de l'**Étape 1 (Data Quality & Profiling Analyse)** sur le jeu de données `EPIC_Basic-rgpd ok - Copie.xlsx`.

---

## 1. Structure du dossier

```text
Qualité données EPIC 2026/
├── README.md                              # Synthèse de l'audit et guide d'utilisation
├── audit_data_quality_epic_basic.R       # Script principal d'audit, de classification et d'export
├── data_quality_profiling_epic_basic.R   # Script d'analyse exploratoire exhaustive de la qualité
├── inspect_anomalies_epic.R              # Script d'inspection ciblée des cas atypiques (scores 0, durées)
├── inspect_05.R                          # Script d'analyse des 11 cas avec demi-point (Verif_eval = 0)
├── inspect_hoplitis_osmia.R              # Script d'analyse comparative de la confusion Hoplitis / Osmia
├── check_unanswered.R                    # Script de quantification des tirets ("-") et non-réponses
├── compare_epic_files.R                  # Comparaison structurelle des différents fichiers EPIC
├── match_tentatives.ps1                  # Extraction et audit de la variable 'Tentative'
├── EPIC_Basic-rgpd ok - Copie.csv        # Données converties en encodage UTF-8
└── output/                               # Dossier des livrables graphiques et tabulaires
    ├── diagnostic_data_quality_epic.png  # Planche 4 panneaux de contrôle qualité (300 DPI)
    ├── data_quality_distribution_scores.png # Profils de distribution des scores et durées (300 DPI)
    └── participants_anomalies_qualite.csv   # Table récapitulative des profils suspects
```

---

## 2. Résumé des conclusions de l'audit

| Problématique détectée | Effectif | Impact sur l'analyse | Action recommandée |
|---|---|---|---|
| **Abandons complets / Timeouts** | 6 participants | Scores 0 ou $\le 5$ avec $\ge 25$ tirets non répondus sur 30 | **Exclure** pour l'EDA et l'analyse statistique d'apprentissage |
| **Pseudoréplication masquée** | 23 observations | 2ᵉ passage au test d'un même participant (colonne `Tentative = 2` supprimée de la copie) | **Dédupliquer** en ne gardant que la tentative 1 |
| **Tests éclairs formateurs / experts** | 9 participants | Réalisés en $< 10$ minutes avec scores quasi parfaits ($\ge 26/30$) et tous notés `EPIC_courses = No` | **Isoler** en groupe « Experts / Témoins » ou exclure du public apprenant |
| **Barème asymétrique (+0.5 point)** | 11 participants | Demi-point accordé pour *Osmia* au lieu de *Hoplitis*, mais refusé à 4 autres participants ayant fait la même réponse | **Harmoniser** la règle (binaire strict ou demi-point systématique) |
| **Mélange de cohortes** | 135 "No" vs 74 "Yes" | Participants n'ayant pas suivi la formation mélangés à ceux l'ayant suivie | **Stratifier** obligatoirement selon `EPIC_courses` |

---

## 3. Exécution

Pour réexécuter l'audit complet et régénérer les figures et tables dans `output/` :
```bash
Rscript audit_data_quality_epic_basic.R
```

