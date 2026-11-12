# Directives pour l'Agent IA (AGENTS.md)

Ce document définit les règles de développement et les conventions à respecter impérativement lors de toute intervention sur ce projet.

---

## 1. Fichiers de code R (.R) et environnement d'exécution
* **Création systématique de scripts** : Tout code R produit ou modifié doit systématiquement être écrit et enregistré dans un fichier de script avec l'extension `.R` dans l'espace de travail (ne pas se limiter à fournir le code dans la conversation).
* **Code propre et documenté** : Chaque script R doit être autonome, propre, rigoureusement structuré et commenté.
* **Exécutable R (Windows)** : Le binaire `Rscript.exe` n'étant pas toujours présent dans le `PATH` système, le chemin d'accès privilégié sous cet environnement est :
  `C:\Program Files\R\R-4.6.2\bin\Rscript.exe` (ou `C:\Program Files\R\R-4.6.1\bin\Rscript.exe`).
* **Autonomie du code (Base R prioritaire)** : Pour éviter les échecs d'installation de packages (droits d'écriture restreints dans `C:\Program Files\`), privilégier systématiquement les fonctions natives de R de base (`stats`, `graphics`, `grDevices`, `utils`). Si des packages tiers sont indispensables, s'assurer au préalable qu'ils sont déjà disponibles dans l'environnement.

---

## 2. Sauvegarde des graphiques dans le dossier `output/`
* **Emplacement dédié** : Tous les graphiques et visualisations générés (notamment via `ggplot2` ou R de base) doivent être automatiquement exportés et enregistrés dans un dossier nommé `output/`.
* **Création automatique du dossier** : Les scripts R doivent inclure la vérification/création automatique de ce dossier s'il n'existe pas :
  ```R
  if (!dir.exists("output")) {
    dir.create("output", recursive = TRUE)
  }
  ```
* **Format et qualité des exports** : Utiliser de préférence `ggsave()` ou les fonctions de base R (`png()`) avec une résolution adaptée aux publications scientifiques / mémoires (ex. `dpi = 300`, format PNG ou PDF) :
  ```R
  ggsave("output/nom_du_graphique.png", plot = mon_graphique, width = 8, height = 6, dpi = 300)
  ```

---

## 3. Charte graphique et homogénéité des visualisations
Pour garantir une parfaite homogénéité visuelle dans l'ensemble des figures du mémoire et entre les différentes sessions, chaque graphique généré doit respecter scrupuleusement les règles suivantes :

### A. Palette de couleurs éditoriale harmonisée
* **Succès / Formés / Facile** : Vert émeraude (`#2E7D32` ou `#27AE60`).
* **Erreur / Non formés / Piège / Difficile** : Rouge rubis (`#C62828` ou `#D9534F`).
* **Neutre / Comparaison / Découpage** : Bleu ardoise (`#4A90E2` ou `#2980B9`).
* **Accentuation / Structure / Titres** : Bleu nuit foncé (`#1B365D` ou `#2C3E50`).
* **Difficulté intermédiaire** : Ambre / Orange (`#E67E22`).
* **Confusions taxonomiques / Analyses croisées** : Violet profond (`#8E44AD`).

### B. Arrière-plan, grilles et lisibilité
* **Fond blanc épuré** : Pas de fond grisâtre (`bg = "white"` en R de base, ou `theme_minimal()` / `theme_classic(base_size = 12)` sous `ggplot2`).
* **Grilles discrètes** : Lignes de repères fines et douces (`grid(col = "grey90", lty = 1)` ou `panel.grid.minor = element_blank()`, `panel.grid.major = element_line(color = "grey92")`).
* **Orientation des axes** : Toujours orienter les étiquettes horizontalement (`las = 1` en base R) pour une lecture naturelle sans inclinaison de tête.

### C. Marges, dimensions et non-troncature
* **Résolution haute définition** : `dpi = 300` systématique.
* **Marges extérieures suffisantes** : Pour les barplots horizontaux avec des étiquettes de taxons ou des paires de noms (ex. `Genre 1 -> Genre 2`), prévoir une marge gauche généreuse (`mar = c(5, 12 à 14, 4, 4)`) et des dimensions larges (ex. `width = 3400 à 3800`, `height = 2400 à 3000` en pixels) pour qu'aucun nom ne soit tronqué.
* **Dégagement à droite (`xlim`)** : L'axe des abscisses (`xlim`) doit toujours être étendu de 15 à 25 % au-delà de la valeur maximale pour que les étiquettes textuelles situées au bout des barres ne soient jamais coupées sur le bord droit de l'image.

### D. Étiquettes de données (labels) directes
* **Annotations numériques directes** : Inscrire directement les pourcentages et effectifs sur ou à côté des barres (ex. `sprintf("%.1f%% (n = %d)", ...)`).
* **Zéro collision** : Les étiquettes ne doivent jamais être recouvertes par les barres d'erreur (intervalles de confiance de Wilson, IC 95 %) ni par la bordure des barres. Placer le texte en noir gras (`font = 2, col = "black"`) décalé à droite de la barre d'erreur.
* **Légendes professionnelles** : Légendes encadrées avec fond blanc semi-transparent (`bg = "#FFFFFFEE"`, `box.col = "#D0D7DE"`), intégrées dans un coin dégagé sans chevaucher les données.

---

## 4. Export des tableaux CSV pour Excel Francophone (FR / BE)
* Pour que tous les tableaux de données générés puissent être ouverts directement par double-clic dans Excel sous Windows en région francophone (sans problème de points décimaux ou d'accents) :
  * Délimiteur de colonnes : **Point-virgule (`;`)**
  * Séparateur décimal : **Virgule (`,`)**
  * Encodage : **UTF-8 avec signature BOM (`0xEF, 0xBB, 0xBF`)**
  ```R
  exporter_excel_csv <- function(df, chemin_fichier) {
    con_bin <- file(chemin_fichier, open = "wb")
    writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con_bin)
    close(con_bin)
    con_txt <- file(chemin_fichier, open = "at", encoding = "UTF-8")
    write.table(df, file = con_txt, sep = ";", dec = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
    close(con_txt)
  }
  ```

---

## 5. Traçabilité des exclusions et qualité des données (Étape 1)
Pour garantir la rigueur scientifique et permettre la traçabilité des effectifs dans le mémoire (diagramme de flux $N_{\text{initial}} \to N_{\text{final}}$) :
* **Journalisation systématique des exclusions** : Toute ligne, tentative ou participant écarté du jeu de données final lors du nettoyage doit être obligatoirement consigné dans un fichier d'audit dédié au format CSV (`participants_anomalies_qualite.csv`).
* **Justification explicite de chaque exclusion** : Le fichier d'audit doit documenter pour chaque individu écarté :
  * L'identifiant unique du participant (`N_ID`),
  * Le statut de la tentative (ex. `Tentative = 2` pour éliminer la pseudoréplication),
  * Le motif d'exclusion précis et objectif (ex. *Abandon précoce $\le 5$ questions*, *Durée aberrante / speed-run expert*, *Données manquantes majeures*),
  * Les métriques associées (durée observée, score obtenu).
* **Conservation des données brutes** : Les données sources ne sont jamais écrasées ; les scripts génèrent un jeu de données nettoyé distinct (ex. `*_clean_wide.csv` et `*_clean_long.csv`).



