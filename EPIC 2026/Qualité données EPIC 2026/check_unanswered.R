# Détection de tous les participants avec des réponses non fournies ("-", vide ou "I don't know")
fichier_csv <- "EPIC_Basic-rgpd ok - Copie.csv"
df <- read.csv(fichier_csv, encoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)

cols_rep <- paste0("Question_", 1:30, "_reply")

nb_tirets <- apply(df[cols_rep], 1, function(row) sum(trimws(row) == "-" | trimws(row) == ""))
nb_dont_know <- apply(df[cols_rep], 1, function(row) sum(grepl("don't know|ne sais pas|nsp", tolower(row))))

df_abandons <- data.frame(
  Ligne = 1:nrow(df),
  ID = df$"N°ID",
  Region = df$Region,
  EPIC_courses = df$EPIC_courses,
  Duree = df$"Durée",
  Score = df$"Note/30_nbr",
  Nb_Tirets = nb_tirets,
  Nb_Dont_Know = nb_dont_know,
  Nb_Reponses_Reelles = 30 - nb_tirets - nb_dont_know
)

cat("Distribution du nombre de tirets '-' par participant :\n")
print(table(nb_tirets))

cat("\nParticipants ayant au moins 1 tiret '-' (abandon ou question sautée) :\n")
print(df_abandons[df_abandons$Nb_Tirets > 0, ])

cat("\nDistribution des 'I don't know' par participant :\n")
print(table(nb_dont_know))

