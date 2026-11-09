# ============================================================
# KELP KORNER — approve an edited AI editorial draft
#
# Run in RStudio after reviewing/editing an editorial_draft_*.csv:
#   Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
#   source("R/approve_ai_draft.R")
#
# This DOES NOT publish anything. It creates the approved
# input for the existing two-page HTML/PDF generator.
# ============================================================

if (!interactive()) stop("Run this approval script interactively in RStudio.")
if (!file.exists("_quarto.yml")) stop("Open the nerg_newsletter RStudio project first.")

quarter <- Sys.getenv("NEWSLETTER_QUARTER", unset = "2026-Q4")
if (!grepl("^[0-9]{4}-Q[1-4]$", quarter)) stop("Invalid newsletter quarter.")

ai_dir <- file.path("drafts", quarter, "ai")
if (!dir.exists(ai_dir)) stop("No AI drafts found in: ", ai_dir)

candidates <- list.files(ai_dir, pattern = "^editorial_draft_.*\\.csv$", full.names = TRUE)
if (!length(candidates)) stop("No editorial_draft_*.csv files found in ", ai_dir)

cat("\nChoose the AI editorial CSV that you reviewed and edited.\n")
cat("You can edit its title/body/category columns before approval.\n")
cat("Do not edit original_headline or original_details; these are source checks.\n\n")

# Explicitly choose a draft; do not silently select the latest generated one.
selected <- file.choose()
selected <- normalizePath(selected, winslash = "/", mustWork = TRUE)
allowed_dir <- paste0(normalizePath(ai_dir, winslash = "/"), "/")
if (!startsWith(selected, allowed_dir) || !selected %in% normalizePath(candidates, winslash = "/")) {
  stop("Select an editorial_draft_*.csv from ", ai_dir)
}

stories <- read.csv(selected, stringsAsFactors = FALSE, check.names = FALSE,
                    fileEncoding = "UTF-8-BOM", na.strings = c("", "NA"))
required <- c("source_id", "title", "body", "category",
              "original_headline", "original_details")
missing <- setdiff(required, names(stories))
if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "))
if (nrow(stories) < 1L || nrow(stories) > 3L) stop("Expected 1–3 stories.")
if (anyDuplicated(stories$source_id) || anyDuplicated(stories$original_headline)) {
  stop("Story source IDs/headlines must be unique.")
}
for (field in required) {
  if (any(is.na(stories[[field]]) | !nzchar(trimws(stories[[field]])))) {
    stop("Missing value in ", field, ". Edit the CSV and retry.")
  }
}
max_lengths <- c(370L, rep(260L, nrow(stories) - 1L))
if (any(nchar(stories$title) > 74L) || any(nchar(stories$body) > max_lengths)) {
  stop("Story exceeds layout size (title 74 chars; bodies 370/260/260). Edit and retry.")
}

cat("\nPROPOSED APPROVED CONTENT — ", quarter, "\n", sep = "")
for (i in seq_len(nrow(stories))) {
  cat("\n", i, ". ", stories$title[i], "\n", stories$body[i], "\n", sep = "")
  if ("review_notes" %in% names(stories) && !is.na(stories$review_notes[i])) {
    cat("EDITORIAL NOTE: ", stories$review_notes[i], "\n", sep = "")
  }
}
cat("\nApproval means you have fact-checked the copy for use in a PRIVATE layout preview.\n")
cat("This is NOT authorization to publicly publish the newsletter.\n")
answer <- readline("Type APPROVE to create approved_stories.csv (anything else cancels): ")
if (!identical(answer, "APPROVE")) stop("Approval cancelled; no files changed.")

out <- file.path("drafts", quarter, "approved_stories.csv")
if (file.exists(out)) {
  backup <- paste0(out, ".backup_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  if (!file.copy(out, backup)) stop("Could not back up existing approved stories.")
  message("Previous approved copy backed up: ", backup)
}
# Save reviewed values only. Keep original source fields for matching to Drive.
write.csv(stories, out, row.names = FALSE, na = "", fileEncoding = "UTF-8")
message("\nApproved editorial file saved: ", normalizePath(out))
message("Next: source('R/build_two_page.R') to render a PRIVATE preview.")
