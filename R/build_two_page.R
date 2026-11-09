# Kelp Korner: print-ready two-page layout from the existing update spreadsheet.
# In RStudio: Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4"); source("R/build_two_page.R")
# No AI API calls or additional R packages required.

if (!file.exists("_quarto.yml") || !file.exists("data/updates.csv")) {
  stop("Open the nerg_newsletter RStudio project before running this script.")
}

quarter <- Sys.getenv("NEWSLETTER_QUARTER", "2026-Q4")
if (!grepl("^[0-9]{4}-Q[1-4]$", quarter)) stop("Use a quarter like 2026-Q4")
year <- as.integer(substr(quarter, 1, 4))
q <- as.integer(substr(quarter, 7, 7))
start <- as.Date(sprintf("%d-%02d-01", year, 1 + 3 * (q - 1)))
end <- seq(start, by = "3 months", length.out = 2)[2] - 1
season <- c("Winter", "Spring", "Summer", "Fall")[q]
season_label <- paste(season, year)

updates <- read.csv("data/updates.csv", stringsAsFactors = FALSE,
                    na.strings = c("", "NA"))
needed <- c("date", "category", "headline", "details", "source_url", "approved_for_ai")
if (!all(needed %in% names(updates))) stop("Missing expected columns in data/updates.csv")
updates$date <- as.Date(updates$date)
ok <- !is.na(updates$date) & updates$date >= start & updates$date <= end &
  tolower(trimws(as.character(updates$approved_for_ai))) %in% c("true", "yes", "1")
updates <- updates[ok, , drop = FALSE]
updates <- updates[order(updates$date, decreasing = TRUE), , drop = FALSE]

# The template intentionally displays up to three stories (not every CSV row).
# Additional approved updates remain available to the AI drafting process.
preview <- nrow(updates) == 0
if (preview) {
  updates <- data.frame(
    category = c("FIELDWORK", "RESEARCH", "PEOPLE"),
    headline = c("Field notes from the kelp forest", "Studying ecosystem recovery", "The people behind the science"),
    details = c(
      "Sample layout text: this space will feature a verified fieldwork update once records are approved for the quarter.",
      "Sample layout text: this space will feature a verified research update once records are approved for the quarter.",
      "Sample layout text: this space will highlight lab members, teaching, publications, or upcoming opportunities."
    ), stringsAsFactors = FALSE)
}

# Shorten long contributions so they fit on exactly two printed pages.
shorten <- function(x, max_chars) {
  x <- trimws(gsub("[[:space:]]+", " ", ifelse(is.na(x), "", x)))
  if (nchar(x) <= max_chars) return(x)
  cut <- substr(x, 1, max_chars)
  cut <- sub("[[:space:]][^[:space:]]*$", "", cut)
  paste0(cut, "…")
}
esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

story <- function(i) {
  if (nrow(updates) < i) return(list(title = "More to come", body = "Additional lab updates will appear here in a future issue.", category = "LAB NEWS"))
  list(title = esc(shorten(updates$headline[i], 74)),
       body = esc(shorten(updates$details[i], if (i == 1) 370 else 260)),
       category = esc(toupper(shorten(updates$category[i], 32))))
}
s <- lapply(1:3, story)
intro <- if (preview) {
  "This is a design preview of <em>Kelp Korner</em>. Add approved updates to the spreadsheet to populate the quarterly edition."
} else {
  paste0("Welcome to <em>Kelp Korner</em>, the quarterly newsletter of the Nearshore Ecology Research Group. ",
         "Explore selected updates from ", esc(season_label), "—from fieldwork and research to the people making it happen.")
}

replacements <- c(
  ISSUE_TITLE = paste("Kelp Korner |", season_label),
  SEASON = toupper(season_label),
  ISSUE_STATUS = if (preview) "LAYOUT PREVIEW" else "EDITORIAL DRAFT — REVIEW BEFORE SHARING",
  INTRO = intro,
  STORY1_TITLE = s[[1]]$title, STORY1_BODY = s[[1]]$body,
  STORY1_CATEGORY = s[[1]]$category,
  STORY2_TITLE = s[[2]]$title, STORY2_BODY = s[[2]]$body,
  STORY2_NOTE = if (preview) "Design preview · no new results reported" else "Check factual claims before publication",
  STORY3_TITLE = s[[3]]$title, STORY3_BODY = s[[3]]$body,
  STORY3_NOTE = if (preview) "Replace with an approved update" else "Edited from lab update records",
  MENU1 = esc(shorten(if (nrow(updates) >= 1) updates$headline[1] else "Field notes", 24)),
  MENU2 = esc(shorten(if (nrow(updates) >= 2) updates$headline[2] else "Research updates", 24)),
  MENU3 = esc(shorten(if (nrow(updates) >= 3) updates$headline[3] else "People and news", 24)),
  CLOSING = "More field notes, more voices, and more discoveries—one quarter at a time."
)

out_dir <- file.path("drafts", quarter, "two_page")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
file.copy("templates/two_page/issue.css", file.path(out_dir, "issue.css"), overwrite = TRUE)
file.copy("images/branding/kelp-forest.jpg", file.path(out_dir, "kelp-forest.jpg"), overwrite = TRUE)
html <- paste(readLines("templates/two_page/issue.html", warn = FALSE), collapse = "\n")
for (key in names(replacements)) {
  html <- gsub(paste0("{{", key, "}}"), replacements[[key]], html, fixed = TRUE)
}
if (grepl("\\{\\{[A-Z0-9_]+\\}\\}", html)) stop("One or more template placeholders were not filled")
output <- file.path(out_dir, "index.html")
writeLines(html, output, useBytes = TRUE)
message("Two-page newsletter preview created at: ", normalizePath(output),
        if (preview) "\nNo approved updates found: showing demo text." else
          paste0("\nPopulated with ", min(nrow(updates), 3L), " of ", nrow(updates), " approved updates."),
        "\nOpen in your browser; Print -> Save as PDF (paper: Letter, margins: None, backgrounds: ON).")
utils::browseURL(normalizePath(output))
