# Mémoire de Fin d'Études — Apprentissage de la Taxonomie des Abeilles Sauvages (Hymenoptera: Anthophila)

Ce dépôt rassemble l'ensemble des scripts de traitement, de contrôle qualité, d'analyse exploratoire (EDA), de modélisation statistique et de synthèse comparative inter-cohortes développés dans le cadre du mémoire de Master en Biologie des Organismes et Écologie (Université de Mons - UMONS).

---

## 🎯 Contexte et Objectifs de Recherche

L'identification des pollinisateurs sauvages constitue un enjeu fondamental face au déclin de la biodiversité. Ce projet évalue l'impact de formations pédagogiques sur l'acquisition de compétences taxonomiques, compare les trajectoires d'apprentissage entre différents profils d'apprenants, et identifie les genres d'abeilles sources d'erreurs récurrentes (*genres pièges*).

### Groupes d'études (Cohortes analysées)
1. **Cohorte EPIC (Adultes & Passionnés)** : Formation dédiée aux naturalistes et au grand public engagé (suivis 2025 et 2026).
2. **Cohorte BAC 3 (Étudiants Universitaires)** : Étudiants en sciences biologiques suivis dans le cadre de leurs travaux pratiques d'entomologie (suivis 2024 et 2025).
3. **Synthèse Inter-Cohortes** : Modélisation comparative globale du différentiel de progression et consensus taxonomique sur la difficulté relative des genres.

---

## 📁 Architecture du Dépôt

Le pipeline d'analyse est structuré de façon modulaire et reproductible :

```text
├── 2025/                                # Cohorte EPIC 2025
│   ├── Qualité données EPIC 2025/       # Audit des données, détection des anomalies et pseudoréplications
│   ├── EDA EPIC 2025/                   # Nettoyage, calcul des scores et analyse exploratoire
│   └── Analyses Stats EPIC 2025/        # Tests d'hypothèses, Wilcoxon apparié, tailles d'effet
│
├── EPIC 2026/                           # Cohorte EPIC 2026
│   ├── Qualité données EPIC 2026/       # Audit qualité, flux N_initial -> N_final
│   ├── EDA EPIC 2026/                   # Nettoyage et exploration des trajectoires pré/post
│   └── Analyses Stats EPIC 2026/        # Modèles statistiques et inférence
│
├── BAC 3/                               # Cohorte Étudiants de Bachelier (UMONS)
│   ├── Qualité données BAC 3 2024/      # Audit et contrôles de cohérence 2024
│   ├── EDA BAC 3 2024/                  # Analyses exploratoires et graphiques 2024
│   ├── Analyses Stats BAC 3 2024/       # Statistiques inférentielles 2024
│   ├── Qualité données BAC 3 2025/      # Audit et contrôles de cohérence 2025
│   ├── EDA BAC 3 2025/                  # Analyses exploratoires et graphiques 2025
│   └── Analyses Stats BAC 3 2025/       # Statistiques inférentielles 2025
│
├── Synthese Inter-Cohortes/             # Métastatistiques et comparaisons globales
│   ├── synthese_comparative_inter_cohortes.R        # Trajectoires, gains, GLM d'interaction
│   ├── generer_forest_plot_intercohortes_genres.R   # Forest plots & Odds Ratios par genre
│   └── output/                                      # Figures de synthèse haute résolution (300 DPI)
│
├── Résultats mémoire/                   # Outils de compilation et d'exportation pour le manuscrit
│   ├── compiler_document_resultats.R    # Synthèse des résultats pour rédaction
│   └── exporter_tableaux_memoire.R      # Exports au format Excel francophone (BOM, ';', ',')
│
├── Contexte.md                          # Note de cadrage et hypothèses de recherche
├── AGENTS.md                            # Charte graphique, conventions R et directives méthodologiques
└── .gitignore                           # Exclusion stricte des données individuelles brutes (RGPD)
```

---

## 🔬 Méthodologie et Principes d'Analyse

Les scripts respectent les standards méthodologiques suivants :
1. **Autonomie et pérennité (Base R prioritaire)** : Réduction maximale des dépendances externes pour garantir la reproductibilité à long terme sous tout environnement R (`stats`, `graphics`, `grDevices`, `utils`).
2. **Contrôle Qualité et Traçabilité (Étape 1)** :
   - Élimination des pseudoréplications (tentatives multiples).
   - Détection des abandons précoces et durées de passation aberrantes (*speed-runs*).
   - Traçabilité complète du diagramme de flux d'inclusion ($N_{\text{initial}} \to N_{\text{final}}$).
3. **Statistiques Inférentielles** :
   - Tests de normalité (Shapiro-Wilk) et tests non-paramétriques appariés (Wilcoxon signed-rank).
   - Estimation robuste des tailles d'effet (Cohen's $d$, $r$ de Wilcoxon) et intervalles de confiance (Wilson score 95 %).
   - Modélisation linéaire généralisée (GLM binomial / logistique) pour tester l'interaction Groupe $\times$ Temps.
4. **Charte Graphique Harmonisée** :
   - Graphiques exportés à 300 DPI (`output/`).
   - Palette éditoriale cohérente (Vert succès `#2E7D32`, Rouge difficulté `#C62828`, Bleu neutre `#1B365D`).
   - Aucune troncature des étiquettes taxonomiques, marges dynamiques et lisibilité maximale.

---

## ⚙️ Prérequis et Exécution

* **R version** : $\ge 4.2.0$ (recommandé : `R 4.6.x`).
* **Packages complémentaires** (optionnels selon les scripts de modélisation avancée) :
  ```R
  # La majorité des scripts fonctionnent nativement avec Base R.
  # Packages utiles pour certains graphiques ou régressions avancées :
  install.packages(c("readxl", "ggplot2"))
  ```
* **Exécution d'un script** :
  ```bash
  Rscript "Synthese Inter-Cohortes/synthese_comparative_inter_cohortes.R"
  ```

---

## 🔒 Confidentialité et Données Brutes

Conformément au RGPD et aux exigences éthiques de recherche universitaire de l'UMONS, **aucune donnée brute nominative ou individuelle n'est stockée sur ce dépôt public**. Seuls les codes sources, scripts de traitement, architectures méthodologiques et visualisations consolidées y sont partagés.

---

## 👤 Auteur

* **Paul Genne** — Faculté des Sciences, Université de Mons (UMONS), Belgique.
