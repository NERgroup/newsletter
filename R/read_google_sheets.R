# KELP KORNER — current Google Sheet reader
# Keep the Google Sheet as the single source of original lab updates.
if (!requireNamespace("googlesheets4", quietly = TRUE)) {
  stop("Install googlesheets4: install.packages('googlesheets4')")
}
googlesheets4::gs4_auth(email = "jogsmith@ucsc.edu")
sheet_url <- "https://docs.google.com/spreadsheets/d/1giUh1YgvFGzA0i9iKtP8c0aIyuvlB48nb8SEafhM_8E/edit"
updates <- googlesheets4::read_sheet(ss = sheet_url, sheet = "Updates", col_types = "c")
# Normalize names by HEADER, not by column position, so new columns work.
canonical <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_|_$", "", x)
}
names(updates) <- vapply(names(updates), canonical, character(1))
names(updates)[names(updates) == "details_notes"] <- "details"
if (anyDuplicated(names(updates))) stop("Duplicate column names after normalization.")
required <- c("quarter", "headline", "category", "details", "approved_for_ai")
missing <- setdiff(required, names(updates))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
for (nm in c("date", "submitted_by", "photo_link", "photo_credit", "photo_caption", "source_link", "editorial_notes")) {
  if (!nm %in% names(updates)) updates[[nm]] <- rep(NA_character_, nrow(updates))
}
message("Imported ", nrow(updates), " Google Sheet updates (with optional photo_caption).")
