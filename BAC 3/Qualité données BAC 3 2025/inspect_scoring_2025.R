# Vérification scoring Moodle
f_pre <- "BAC 3/UMONS_Pretest_2025.csv"
f_post <- "BAC 3/UMONS_posttest_2025.csv"

pre <- read.csv(f_pre, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
post <- read.csv(f_post, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)

parse_note <- function(x) as.numeric(gsub(",", ".", as.character(x)))
pre$note_num <- parse_note(pre[["Note/20,0"]])
post$note_num <- parse_note(post[["Note/20,0"]])

q_num <- 1:28

# Note sur 20 / (20/28) = nombre de points
pre$points_moodle <- round(pre$note_num / 20 * 28, 2)
post$points_moodle <- round(post$note_num / 20 * 28, 2)

cat("Points Moodle vs Note/20 Pretest:\n")
print(data.frame(ID = pre$ID, Note = pre$note_num, Pts = pre$points_moodle))

cat("\nPoints Moodle vs Note/20 Posttest:\n")
print(data.frame(ID = post$ID, Note = post$note_num, Pts = post$points_moodle))

