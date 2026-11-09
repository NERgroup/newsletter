# ============================================================
# KELP KORNER — ONE-COMMAND PRIVATE NEWSLETTER DRAFT
#
# In RStudio:
# Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
# source("R/create_newsletter.R")
#
# Google Sheets -> OpenAI editorial draft -> existing two-page
# HTML/CSS design -> browser preview. NEVER publishes or emails.
# ============================================================

required_files <- c(
  "_quarto.yml",
  "R/read_google_sheets.R",
  "R/draft_with_ai.R",
  "R/build_two_page.R",
  "templates/two_page/issue.html",
  "templates/two_page/issue.css",
  "images/branding/kelp-forest.jpg"
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop("Missing project files: ", paste(missing_files, collapse = ", "),
       "\nOpen the nerg_newsletter project in RStudio.")
}

quarter <- Sys.getenv("NEWSLETTER_QUARTER", unset = "2026-Q4")
if (!grepl("^[0-9]{4}-Q[1-4]$", quarter)) {
  stop("NEWSLETTER_QUARTER must look like 2026-Q4")
}

cat("\n=== KELP KORNER: PRIVATE PREVIEW FOR ", quarter, " ===\n", sep = "")

# Existing drafting script creates a timestamped CSV and Markdown file.
# It makes a billable API call and does not publish anything.
source("R/draft_with_ai.R", local = FALSE)

if (!exists("csv_path", inherits = TRUE) ||
    !is.character(csv_path) || length(csv_path) != 1L ||
    !file.exists(csv_path)) {
  stop("AI draft script did not produce a valid csv_path.")
}

# Pass the exact newly generated CSV to the layout builder.
# Automatically restore any previous setting when the script ends.
old_path <- Sys.getenv("NEWSLETTER_DRAFT_PATH", unset = NA_character_)
Sys.setenv(NEWSLETTER_DRAFT_PATH = normalizePath(csv_path))
tryCatch(
  source("R/build_two_page.R", local = FALSE),
  finally = {
    if (is.na(old_path)) {
      Sys.unsetenv("NEWSLETTER_DRAFT_PATH")
    } else {
      Sys.setenv(NEWSLETTER_DRAFT_PATH = old_path)
    }
  }
)

cat("\nPreview created. Review the full newsletter and original notes.\n",
    "This process did NOT publish to GitHub or email anyone.\n",
    "The HTML preview is in drafts/", quarter, "/two_page/index.html\n", sep = "")
