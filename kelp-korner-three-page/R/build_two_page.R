# ============================================================
# KELP KORNER — AI draft -> two- or three-page PRIVATE newsletter preview
#
# Called by R/create_newsletter.R after AI drafting.
# No intermediate approval or editing of CSV files is required.
#
# Run:
#   Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
#   source("R/build_two_page.R")
#
# This is a PRIVATE preview only. It does not publish or email.
# Existing issue.html and issue.css are left unchanged.
# ============================================================

required_files <- c("_quarto.yml", "R/read_google_sheets.R",
                    "templates/two_page/issue.html",
                    "templates/two_page/issue.css",
                    "images/branding/kelp-forest.jpg")
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) stop("Required project files missing: ", paste(missing_files, collapse = ", "))

quarter <- Sys.getenv("NEWSLETTER_QUARTER", unset = "2026-Q4")
if (!grepl("^[0-9]{4}-Q[1-4]$", quarter)) stop("Use a quarter like 2026-Q4")
year <- as.integer(substr(quarter, 1, 4))
q <- as.integer(substr(quarter, 7, 7))
season_label <- paste(c("Winter", "Spring", "Summer", "Fall")[q], year)

# Import the current Google Sheet to match APPROVED stories to real photos.
source("R/read_google_sheets.R")
needed <- c("quarter", "headline", "details", "photo_link", "photo_credit", "approved_for_ai")
missing <- setdiff(needed, names(updates))
if (length(missing)) stop("Google Sheet missing columns: ", paste(missing, collapse = ", "))

approved_flag <- tolower(trimws(as.character(updates$approved_for_ai))) %in% c("yes", "true", "1")
valid_quarter <- !is.na(updates$quarter) & trimws(updates$quarter) == quarter
sheet <- updates[valid_quarter & approved_flag, , drop = FALSE]

# The master script supplies the exact AI draft produced in this run.
# This file is NOT a publication approval; it is source material for preview only.
draft_path <- Sys.getenv("NEWSLETTER_DRAFT_PATH", unset = "")
if (!nzchar(draft_path) || !file.exists(draft_path)) {
  stop("No AI draft specified. Run source('R/create_newsletter.R') instead.")
}
stories <- read.csv(draft_path, stringsAsFactors = FALSE, check.names = FALSE,
                    fileEncoding = "UTF-8-BOM", na.strings = c("", "NA"))
required <- c("title", "body", "category", "original_headline", "original_details")
missing <- setdiff(required, names(stories))
if (length(missing)) stop("AI draft missing columns: ", paste(missing, collapse = ", "))
if (nrow(stories) < 1L || nrow(stories) > 6L) stop("AI draft must have 1–6 stories; page limit is three.")
if (anyDuplicated(stories$original_headline)) stop("Duplicate source headlines in AI draft.")

# Link AI draft to the original Google Sheet record for photo retrieval.
# Stop if the original source changed since this draft was generated.
idx <- match(stories$original_headline, sheet$headline)
if (anyNA(idx) || anyDuplicated(sheet$headline[!is.na(sheet$headline)])) {
  stop("Cannot uniquely match AI story headlines to approved Google Sheet records. ",
       "Re-draft after any headline edits; duplicate headlines are unsupported.")
}
same_details <- !is.na(sheet$details[idx]) & !is.na(stories$original_details) &
  (sheet$details[idx] == stories$original_details)
if (!all(same_details)) {
  stop("Google Sheet source details have changed since AI drafting. ",
       "Please regenerate the draft with source('R/create_newsletter.R').")
}

# ------------------------------------------------------------
# Editorial text, media, and adaptive story layout
# ------------------------------------------------------------
shorten <- function(x, max_chars) {
  if (length(x) == 0L || is.na(x) || !nzchar(trimws(x))) return("")
  x <- trimws(gsub("[[:space:]]+", " ", as.character(x)))
  if (nchar(x, type = "chars") <= max_chars) return(x)
  cut <- substr(x, 1, max_chars)
  cut <- sub("[[:space:]][^[:space:]]*$", "", cut)
  paste0(cut, "…")
}
esc <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

story_count <- nrow(stories)
page_count <- if (story_count > 3L) 3L else 2L
s <- lapply(seq_len(story_count), function(i) {
  list(
    title = esc(shorten(stories$title[i], 74L)),
    body = esc(shorten(stories$body[i], if (i == 1L) 370L else 260L)),
    category = esc(toupper(shorten(stories$category[i], 32L)))
  )
})

out_dir <- file.path("drafts", quarter, "two_page")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Only the first/featured story currently supports a linked photograph.
# No photo is fabricated for stories that don't have one.
feature_media <- ""
photo_orientation <- "no-photo"
link <- sheet$photo_link[idx[1]]
if (!is.na(link) && nzchar(trimws(link))) {
  if (!requireNamespace("googledrive", quietly = TRUE)) {
    stop("Install googledrive: install.packages('googledrive')")
  }
  googledrive::drive_auth(email = "jogsmith@ucsc.edu")
  media_parent_id <- "1O73dmzSjXfKHSZYOzD8fnkQjrhHWibOC"
  folder_name <- gsub("-", "_", quarter, fixed = TRUE)
  folders <- googledrive::drive_ls(
    path = googledrive::as_id(media_parent_id), type = "folder")
  hit <- folders[folders$name == folder_name, , drop = FALSE]
  if (nrow(hit) != 1L) stop("Missing or duplicate media folder: ", folder_name)
  quarter_files <- googledrive::drive_ls(path = googledrive::as_id(hit$id[[1]]))
  photo <- googledrive::drive_get(googledrive::as_id(link))
  if (!(as.character(photo$id[[1]]) %in% as.character(quarter_files$id))) {
    stop("Featured photograph must be inside media/", folder_name)
  }
  ext <- tolower(tools::file_ext(photo$name[[1]]))
  if (!(ext %in% c("jpg", "jpeg", "png", "webp"))) {
    stop("Featured photograph must be JPG, PNG, or WebP")
  }
  local_name <- paste0("feature-photo.", ext)
  path <- file.path(out_dir, local_name)
  googledrive::drive_download(file = photo, path = path, overwrite = TRUE)

  # magick is optional; native CSS sizing never crops the photograph.
  if (requireNamespace("magick", quietly = TRUE)) {
    im <- magick::image_info(magick::image_read(path))
    ratio <- im$width[1] / im$height[1]
    photo_orientation <- if (ratio < 0.85) "portrait" else if (ratio > 1.2) "landscape" else "square"
  } else {
    photo_orientation <- "auto-orientation"
  }
  credit <- sheet$photo_credit[idx[1]]
  caption <- if (is.na(credit) || !nzchar(trimws(credit))) {
    "Photo credit to be confirmed"
  } else paste0("Photo: ", esc(credit))
  feature_media <- paste0(
    '<figure class="feature-photo"><img src="', local_name,
    '" alt="Photograph accompanying ', esc(shorten(stories$title[1], 90L)),
    '"><figcaption>', caption, '</figcaption></figure>')
}

# Spread stories over no more than two content pages.
# Four stories: feature + one on page 2; two on page 3.
# Five or six stories: feature + two on page 2; remaining on page 3.
page2_indices <- if (story_count <= 3L) seq.int(2L, story_count) else if (story_count == 4L) 2L else 2:3
page2_indices <- page2_indices[page2_indices >= 2L & page2_indices <= story_count]
page3_indices <- if (story_count > 3L) setdiff(seq.int(2L, story_count), page2_indices) else integer(0)

render_card <- function(i) {
  paste0('<article class="story', if (i %% 2L) ' sage' else '', '">',
         '<span class="tag">', sprintf("%02d", i), ' / LAB UPDATES</span>',
         '<div class="rule"></div>',
         '<h3>', s[[i]]$title, '</h3>',
         '<p>', s[[i]]$body, '</p>',
         '<p class="note">', s[[i]]$category, '</p>',
         '</article>')
}
secondary <- if (length(page2_indices)) {
  paste0('<div class="secondary-list">',
         paste(vapply(page2_indices, render_card, character(1)), collapse = "\n"),
         '</div>')
} else ""

extra_page <- ""
if (length(page3_indices)) {
  page3_cards <- paste(vapply(page3_indices, render_card, character(1)), collapse = "\n")
  extra_page <- paste0(
    '<section class="page page-three">',
    '<header class="page-two-head"><div><span class="eyebrow">KELP KORNER / ', esc(toupper(season_label)),
    '</span><h2>More from<br>the field<span class="period">.</span></h2></div>',
    '<div class="circle-mark">N<br>E<br>R<br>G</div></header>',
    '<div class="third-stories">', page3_cards, '</div>',
    '<div class="closing"><div class="closing-eyebrow">LOOKING AHEAD</div>',
    '<p>More field notes, more voices, and more discoveries—one quarter at a time.</p>',
    '<div class="closing-links"><span>FOLLOW THE RESEARCH</span>',
    '<a href="https://smithlab.ucsc.edu">smithlab.ucsc.edu ↗</a></div></div>',
    '<footer class="page-two-footer"><span>NEARSHORE ECOLOGY RESEARCH GROUP · UC SANTA CRUZ</span>',
    '<span>03 — 03</span></footer></section>')
}

menu <- paste(vapply(seq_len(story_count), function(i) {
  paste0('<div><b>0', i, '</b> ', esc(shorten(stories$title[i], 28L)), '</div>')
}, character(1)), collapse = "\n")

intro <- paste0(
  "Welcome to <em>Kelp Korner</em>, the quarterly newsletter of the Nearshore Ecology Research Group. ",
  "Explore selected updates from ", esc(season_label),
  "—from fieldwork and research to the people making it happen.")

replacements <- c(
  ISSUE_TITLE = paste("Kelp Korner |", season_label),
  SEASON = toupper(season_label),
  ISSUE_STATUS = "AI EDITORIAL DRAFT — REVIEW BEFORE SHARING",
  INTRO = intro,
  ISSUE_MENU = menu,
  FEATURE_CLASS = paste0("story-count-", min(story_count, 3L), " ", photo_orientation),
  FEATURE_MEDIA = feature_media,
  STORY1_TITLE = s[[1]]$title,
  STORY1_BODY = s[[1]]$body,
  STORY1_CATEGORY = s[[1]]$category,
  SECONDARY_STORIES = secondary,
  EXTRA_PAGE = extra_page,
  TOTAL_PAGES = as.character(page_count),
  CLOSING = "More field notes, more voices, and more discoveries—one quarter at a time."
)

if (!file.copy("templates/two_page/issue.css", file.path(out_dir, "issue.css"), overwrite = TRUE)) {
  stop("Could not copy issue.css")
}
if (!file.copy("images/branding/kelp-forest.jpg", file.path(out_dir, "kelp-forest.jpg"), overwrite = TRUE)) {
  stop("Could not copy cover photo")
}
html <- paste(readLines("templates/two_page/issue.html", warn = FALSE), collapse = "\n")
for (key in names(replacements)) {
  html <- gsub(paste0("{{", key, "}}"), replacements[[key]], html, fixed = TRUE)
}
if (grepl("\\{\\{[A-Z0-9_]+\\}\\}", html)) stop("Unfilled HTML placeholders")
output <- file.path(out_dir, "index.html")
writeLines(html, output, useBytes = TRUE)
message("\nKelp Korner PRIVATE preview: ", normalizePath(output),
        "\nStories: ", story_count, " | Pages: ", page_count,
        "\nFeatured photo: ", photo_orientation,
        "\nPrint: US Letter / margins None / background graphics ON.",
        "\nIf the browser displays a layout warning, review before printing.",
        "\nNothing has been published or emailed.")
utils::browseURL(normalizePath(output))
