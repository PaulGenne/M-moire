# ==============================================================================
# Script R de compilation du document Word (.docx) des Résultats du Mémoire
# ==============================================================================
# Auteur : Analyse de données & Mémoire de Master (UMons)
# Conforme aux directives AGENTS.md (Base R, R-4.6.2, Windows)
# ==============================================================================

message("--> Debut du processus de compilation du document Word des Resultats...")

# 1. Verification du repertoire de travail
dossier_script <- getwd()
dossier_cible <- "Résultats mémoire"

if (dir.exists(dossier_cible)) {
  setwd(dossier_cible)
  message("--> Repertoire de travail positionne sur : ", getwd())
} else {
  message("--> Repertoire de travail actuel : ", dossier_script)
}

# 2. Localisation de l'executable Pandoc
chemins_pandoc_possibles <- c(
  "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools/pandoc.exe",
  "C:/Program Files/RStudio/bin/pandoc/pandoc.exe",
  Sys.which("pandoc")
)

pandoc_exe <- NULL
for (p in chemins_pandoc_possibles) {
  if (nzchar(p) && file.exists(p)) {
    pandoc_exe <- p
    break
  }
}

if (is.null(pandoc_exe)) {
  stop("ERREUR : Executable pandoc introuvable. Veuillez verifier le chemin d'installation de RStudio.")
}

message("--> Executable Pandoc identifie : ", pandoc_exe)

# 3. Fichiers source et destination
fichier_md <- "Partie_Resultats_Memoire.md"
fichier_docx <- "Partie_Resultats_Memoire.docx"

if (!file.exists(fichier_md)) {
  stop("ERREUR : Fichier source markdown introuvable : ", fichier_md)
}

# 4. Arguments de compilation Pandoc
# Incorpore la table des matieres, le formatage des tableaux et l'encapsulation directe des images haute definition
args_pandoc <- c(
  fichier_md,
  "-o", fichier_docx,
  "--standalone",
  "--from=markdown+pipe_tables+implicit_figures",
  "--to=docx",
  "--toc",
  "--toc-depth=2"
)

message("--> Compilation en cours de '", fichier_md, "' vers '", fichier_docx, "'...")

statut <- system2(command = pandoc_exe, args = args_pandoc)

if (statut == 0 && file.exists(fichier_docx)) {
  taille_ko <- round(file.info(fichier_docx)$size / 1024, 1)
  message("--> SUCCES : Le document Word a ete genere avec succes !")
  message("--> Emplacement : ", normalizePath(fichier_docx, winslash = "/"))
  message("--> Taille du fichier Word : ", taille_ko, " Ko")
} else {
  stop("ERREUR : Echec de la generation du fichier Word (.docx). Code retour : ", statut)
}

# Revenir au dossier initial si necessaire
if (basename(getwd()) == "Résultats mémoire") {
  setwd("..")
}

message("--> Fin de l'execution du script de compilation.")

