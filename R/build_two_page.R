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
                    "images/branding/smith-lab-logo.png")
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) stop("Required project files missing: ", paste(missing_files, collapse = ", "))

quarter <- Sys.getenv("NEWSLETTER_QUARTER", unset = "2026-Q4")
if (!grepl("^[0-9]{4}-Q[1-4]$", quarter)) stop("Use a quarter like 2026-Q4")
year <- as.integer(substr(quarter, 1, 4))
q <- as.integer(substr(quarter, 7, 7))
season_label <- paste(c("Winter", "Spring", "Summer", "Fall")[q], year)

# Publication convention: inaugural Fall 2026 = Vol. 01, Issue 01.
# Each subsequent calendar year is a new volume, with issues 01-04.
if (year < 2026L || (year == 2026L && q != 4L)) {
  stop("Kelp Korner publication numbering begins with 2026-Q4.")
}
volume_number <- year - 2026L + 1L
issue_number <- if (year == 2026L) 1L else q
volume_label <- sprintf("VOL. %02d", volume_number)
issue_label <- sprintf("ISSUE %02d", issue_number)


# Import the current Google Sheet to match APPROVED stories to real photos.
source("R/read_google_sheets.R")
needed <- c("quarter", "headline", "details", "photo_link", "photo_credit", "approved_for_publication")
missing <- setdiff(needed, names(updates))
if (length(missing)) stop("Google Sheet missing columns: ", paste(missing, collapse = ", "))

approved_flag <- tolower(trimws(as.character(updates$approved_for_publication))) %in% c("yes", "true", "1")
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
if (nrow(stories) < 1L) stop("AI draft contains no stories.")
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

# Explicit completeness contract: ALL approved rows must appear exactly once.
if (nrow(stories) != nrow(sheet) ||
    !setequal(as.character(stories$original_headline), as.character(sheet$headline))) {
  omitted <- setdiff(as.character(sheet$headline), as.character(stories$original_headline))
  unexpected <- setdiff(as.character(stories$original_headline), as.character(sheet$headline))
  stop("Newsletter draft does not cover ALL approved updates. Missing: ",
       paste(omitted, collapse = ", "), "; extra: ",
       paste(unexpected, collapse = ", "), ". Nothing rendered.")
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
if (story_count > 8L) {
  warning(story_count, " stories may not fit in three printed pages. ",
          "All will be rendered, but the layout warning must be resolved before publishing.",
          call. = FALSE)
}
page_count <- if (story_count > 3L) 3L else 2L
s <- lapply(seq_len(story_count), function(i) {
  list(
    title = esc(stories$title[i]),
    body = esc(stories$body[i]),
    category = esc(toupper(stories$category[i]))
  )
})

out_dir <- file.path("drafts", quarter, "two_page")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.copy("images/branding/smith-lab-logo.png", file.path(out_dir, "smith-lab-logo.png"), overwrite = TRUE)) {
  stop("Could not copy the supplied Smith Lab logo to the newsletter output")
}


# ------------------------------------------------------------
# Quarterly cover photograph — required, sourced from Drive
# ------------------------------------------------------------
# Newsletter/media/YYYY_QN/ must contain exactly one image whose
# basename is cover_photo (for example cover_photo.jpg).
# The existing CSS refers to kelp-forest.jpg. We copy the
# selected cover to that local filename, preserving the design.
if (!requireNamespace("googledrive", quietly = TRUE)) {
  stop("Install googledrive: install.packages('googledrive')")
}
googledrive::drive_auth(email = "jogsmith@ucsc.edu")
media_parent_id <- "1O73dmzSjXfKHSZYOzD8fnkQjrhHWibOC"
folder_name <- gsub("-", "_", quarter, fixed = TRUE)
folders <- googledrive::drive_ls(
  path = googledrive::as_id(media_parent_id), type = "folder")
hit <- folders[folders$name == folder_name, , drop = FALSE]
if (nrow(hit) != 1L) {
  stop("Expected exactly one quarterly media folder: media/", folder_name)
}
quarter_files <- googledrive::drive_ls(path = googledrive::as_id(hit$id[[1]]))
quarter_names <- tolower(quarter_files$name)
cover_matches <- grepl("^cover_photo\\.(jpg|jpeg|png|webp)$", quarter_names)
cover_files <- quarter_files[cover_matches, , drop = FALSE]
if (nrow(cover_files) != 1L) {
  stop("Expected exactly one cover_photo.jpg/.jpeg/.png/.webp in media/",
       folder_name, "; found ", nrow(cover_files),
       ". Upload or rename the selected quarterly cover in Google Drive.")
}
cover_ext <- tolower(tools::file_ext(cover_files$name[[1]]))
cover_download <- file.path(out_dir, paste0("cover-original.", cover_ext))
googledrive::drive_download(
  file = cover_files, path = cover_download, overwrite = TRUE)

# CSS uses a JPEG cover with a fixed name. Converting PNG/WebP
# when needed keeps the template and its visual styling unchanged.
cover_output <- file.path(out_dir, "kelp-forest.jpg")
if (cover_ext %in% c("jpg", "jpeg")) {
  if (!file.copy(cover_download, cover_output, overwrite = TRUE)) {
    stop("Failed to copy quarterly cover to newsletter output")
  }
} else {
  if (!requireNamespace("magick", quietly = TRUE)) {
    stop("PNG/WebP cover requires magick. Install with install.packages('magick'), ",
         "or upload a JPG cover_photo instead.")
  }
  magick::image_write(magick::image_read(cover_download),
                      path = cover_output, format = "jpeg", quality = 92)
}
message("Quarterly cover loaded from media/", folder_name, "/", cover_files$name[[1]])

# ------------------------------------------------------------
# Download photos for ALL selected AI stories (not just the feature)
# ------------------------------------------------------------
# A photo is matched through the selected source row in Google Sheets.
# Images are restricted to the quarter's media folder.
# Photo credit comes from photo_credit. Optional photo_caption is
# supported if present in the normalized Google Sheets data.
# No photo or caption is invented.

photo_html <- rep("", story_count)
photo_orientation <- "no-photo"
photo_manifest <- data.frame(
  story = seq_len(story_count),
  headline = as.character(stories$title),
  filename = rep(NA_character_, story_count),
  credit = rep(NA_character_, story_count),
  stringsAsFactors = FALSE
)

for (i in seq_len(story_count)) {
  link <- sheet$photo_link[idx[i]]
  if (is.na(link) || !nzchar(trimws(link))) next

  photo <- googledrive::drive_get(googledrive::as_id(link))
  if (!(as.character(photo$id[[1]]) %in% as.character(quarter_files$id))) {
    stop("Photo for story ", i, " is not directly inside media/", folder_name,
         ": ", stories$title[i])
  }

  ext <- tolower(tools::file_ext(photo$name[[1]]))
  if (!(ext %in% c("jpg", "jpeg", "png", "webp"))) {
    stop("Photo for story ", i, " must be JPG, PNG, or WebP")
  }
  local_name <- sprintf("story-%02d.%s", i, ext)
  path <- file.path(out_dir, local_name)
  googledrive::drive_download(file = photo, path = path, overwrite = TRUE)

  if (i == 1L) {
    if (requireNamespace("magick", quietly = TRUE)) {
      im <- magick::image_info(magick::image_read(path))
      ratio <- im$width[1] / im$height[1]
      photo_orientation <- if (ratio < 0.85) "portrait" else if (ratio > 1.2) "landscape" else "square"
    } else {
      photo_orientation <- "auto-orientation"
    }
  }

  credit <- sheet$photo_credit[idx[i]]
  credit <- if (is.na(credit) || !nzchar(trimws(credit))) "" else trimws(credit)
  description <- ""
  if ("photo_caption" %in% names(sheet)) {
    cap <- sheet$photo_caption[idx[i]]
    if (!is.na(cap) && nzchar(trimws(cap))) description <- trimws(cap)
  }
  # Print only information actually supplied by lab members.
  caption_bits <- c(description, if (nzchar(credit)) paste0("Photo: ", credit) else "Photo credit needed")
  caption_bits <- caption_bits[nzchar(caption_bits)]
  caption_html <- if (length(caption_bits)) {
    paste0("<figcaption>", paste(vapply(caption_bits, esc, character(1)), collapse = " · "), "</figcaption>")
  } else ""

  photo_html[i] <- paste0(
    '<figure class="', if (i == 1L) "feature-photo" else "story-photo", '">',
    '<img src="', esc(local_name), '" alt="Photo accompanying ',
    esc(shorten(stories$title[i], 90L)), '">', caption_html, '</figure>'
  )
  photo_manifest$filename[i] <- local_name
  photo_manifest$credit[i] <- if (nzchar(credit)) credit else NA_character_
  if (!nzchar(credit)) {
    warning("No Photo credit for story ", i, " (", stories$original_headline[i],
            "). Add the photographer's name in the Google Sheet.", call. = FALSE)
  }
}

# Links are editorial metadata from the original approved Google Sheet row.
# Never ask AI to invent or rewrite a link destination.
# Optional Link text defaults to "Read more".
if (!"source_link" %in% names(sheet)) sheet$source_link <- NA_character_
if (!"link_text" %in% names(sheet)) sheet$link_text <- NA_character_

story_links <- rep("", story_count)
link_manifest <- data.frame(
  story = seq_len(story_count),
  source_headline = as.character(stories$original_headline),
  source_url = rep(NA_character_, story_count),
  display_text = rep(NA_character_, story_count),
  stringsAsFactors = FALSE
)

for (i in seq_len(story_count)) {
  url <- sheet$source_link[idx[i]]
  if (is.na(url) || !nzchar(trimws(url))) next
  url <- trimws(url)
  # Reject unsafe / malformed URLs rather than silently inserting them.
  if (!grepl("^https?://[^[:space:]<>\"']+$", url, perl = TRUE)) {
    stop("Invalid Source link for story ", i, " (", stories$original_headline[i],
         "). Use a complete http:// or https:// URL without spaces.")
  }
  label <- sheet$link_text[idx[i]]
  if (is.na(label) || !nzchar(trimws(label))) label <- "Read more"
  label <- trimws(label)
  if (nchar(label) > 90L) {
    stop("Link text exceeds 90 characters for: ", stories$original_headline[i])
  }
  story_links[i] <- paste0(
    '<a class="story-link" href="', esc(url),
    '" target="_blank" rel="noopener noreferrer">',
    esc(label), '<span aria-hidden="true"> ↗</span></a>'
  )
  link_manifest$source_url[i] <- url
  link_manifest$display_text[i] <- label
}

feature_media <- photo_html[1]
message("Downloaded linked photos for ", sum(nzchar(photo_html)), " of ", story_count,
        " selected stories.")
write.csv(photo_manifest, file.path(out_dir, "photo_manifest.csv"), row.names = FALSE, na = "")
write.csv(link_manifest, file.path(out_dir, "link_manifest.csv"), row.names = FALSE, na = "")

# Every story is included. Up to three stories: two pages total.
# Four or more: page 2 has the feature plus up to two cards;
# page 3 receives ALL remaining cards. Never silently discard a row.
page2_indices <- if (story_count >= 2L) {
  seq.int(2L, min(story_count, 3L))
} else integer(0)
page3_indices <- if (story_count >= 4L) seq.int(4L, story_count) else integer(0)

render_card <- function(i) {
  has_photo <- nzchar(photo_html[i])
  paste0(
    '<article class="story', if (i %% 2L) ' sage' else '',
    if (has_photo) ' has-photo' else ' no-photo', '">',
    '<span class="tag"><span class="tag-number">', sprintf("%02d", i),
    '</span><span class="tag-category">', s[[i]]$category, '</span></span>',
    '<div class="rule"></div>',
    '<div class="story-inner">',
    if (has_photo) photo_html[i] else '',
    '<div class="story-copy">',
    '<h3>', s[[i]]$title, '</h3>',
    '<p>', s[[i]]$body, '</p>',
    story_links[i],
    '</div></div></article>'
  )
}

secondary <- if (length(page2_indices)) {
  paste0('<div class="secondary-list">',
         paste(vapply(page2_indices, render_card, character(1)), collapse = "\n"),
         '</div>')
} else ""

# Use the AI issue-level text from the SAME run, not a separate generation.
issue_path <- sub("\\.csv$", "_issue.json", draft_path)
if (!file.exists(issue_path)) stop("Missing AI issue editorial file: ", issue_path)
issue <- jsonlite::read_json(issue_path, simplifyVector = TRUE)
if (!all(c("introduction", "looking_ahead") %in% names(issue))) {
  stop("Issue editorial file is missing introduction/looking_ahead")
}
intro_raw <- trimws(as.character(issue$introduction))
closing_raw <- trimws(as.character(issue$looking_ahead))
if (!nzchar(intro_raw) || !nzchar(closing_raw)) stop("Empty issue introduction/closing")
if (nchar(intro_raw) > 230L || nchar(closing_raw) > 185L) {
  stop("Issue editorial text is too long for the design. Review the AI draft.")
}
intro <- esc(intro_raw)
closing <- esc(closing_raw)
intro_heading <- "This quarter in the nearshore."

# The closing is shown only on the final content page.
make_closing <- function(text) paste0(
  '<div class="closing"><div class="closing-eyebrow">LOOKING AHEAD</div>',
  '<p>', text, '</p><div class="closing-links">',
  '<span>FOLLOW THE RESEARCH</span>',
  '<a href="https://smithlab.ucsc.edu">smithlab.ucsc.edu ↗</a></div></div>'
)
page2_closing <- if (page_count == 2L) make_closing(closing) else ""

extra_page <- ""
if (length(page3_indices)) {
  page3_cards <- paste(vapply(page3_indices, render_card, character(1)), collapse = "\n")
  extra_page <- paste0(
    '<section class="page page-three count-', length(page3_indices), '">',
    '<header class="page-two-head"><div><span class="eyebrow">KELP KORNER / ', esc(toupper(season_label)),
    '</span><h2>More from<br>the field<span class="period">.</span></h2></div>',
    '<div class="header-lab-logo"><img src="smith-lab-logo.png" alt="Smith Lab logo"></div></header>',
    '<div class="third-stories item-count-', length(page3_indices), '">', page3_cards, '</div>',
    make_closing(closing),
    '<footer class="page-two-footer"><span>NEARSHORE ECOLOGY RESEARCH GROUP · UC SANTA CRUZ</span>',
    '<span>03 / 03</span></footer></section>')
}

highlight_indices <- seq_len(min(3L, story_count))
menu <- paste(vapply(highlight_indices, function(i) {
  paste0('<div><b>', sprintf("%02d", i), '</b> ',
         esc(shorten(stories$title[i], 42L)), '</div>')
}, character(1)), collapse = "\n")




replacements <- c(
  ISSUE_TITLE = paste("Kelp Korner |", season_label),
  SEASON = toupper(season_label),
  VOLUME_LABEL = volume_label,
  ISSUE_LABEL = issue_label,
  INTRO = intro,
  INTRO_HEADING = intro_heading,
  ISSUE_MENU = menu,
  FEATURE_CLASS = paste0("story-count-", min(story_count, 3L), " ", photo_orientation),
  FEATURE_MEDIA = feature_media,
  STORY1_TITLE = s[[1]]$title,
  STORY1_BODY = s[[1]]$body,
  STORY1_CATEGORY = s[[1]]$category,
  STORY1_LINK = story_links[1],
  SECONDARY_STORIES = secondary,
  EXTRA_PAGE = extra_page,
  TOTAL_PAGES = sprintf("%02d", page_count),
  CLOSING = closing,
  PAGE2_CLOSING = page2_closing
)

if (!file.copy("templates/two_page/issue.css", file.path(out_dir, "issue.css"), overwrite = TRUE)) {
  stop("Could not copy issue.css")
}
html <- paste(readLines("templates/two_page/issue.html", warn = FALSE), collapse = "\n")
for (key in names(replacements)) {
  html <- gsub(paste0("{{", key, "}}"), replacements[[key]], html, fixed = TRUE)
}
if (grepl("\\{\\{[A-Z0-9_]+\\}\\}", html)) stop("Unfilled HTML placeholders")
output <- file.path(out_dir, "index.html")
writeLines(html, output, useBytes = TRUE)
# Reproducible report of inclusion, independent from AI story ordering.
report <- data.frame(
  source_headline = as.character(sheet$headline[idx]),
  output_title = as.character(stories$title),
  page = ifelse(seq_len(story_count) == 1L, 2L,
                ifelse(seq_len(story_count) %in% page2_indices, 2L, 3L)),
  photo_linked = nzchar(photo_html),
  photo_credit_present = !is.na(sheet$photo_credit[idx]) & nzchar(trimws(sheet$photo_credit[idx])),
  photo_caption_present = !is.na(sheet$photo_caption[idx]) & nzchar(trimws(sheet$photo_caption[idx])),
  source_link_present = nzchar(story_links),
  stringsAsFactors = FALSE
)
write.csv(report, file.path(out_dir, "inclusion_report.csv"), row.names = FALSE)
message("\nAll ", nrow(report), " approved updates included in HTML; ",
        "see inclusion_report.csv. The PDF still requires a visual fit check.")
message("\nKelp Korner PRIVATE preview: ", normalizePath(output),
        "\nStories: ", story_count, " | Pages: ", page_count,
        "\nFeatured photo: ", photo_orientation,
        "\nPrint: US Letter / margins None / background graphics ON.",
        "\nIf the browser displays a layout warning, review before printing.",
        "\nNothing has been published or emailed.")
utils::browseURL(normalizePath(output))
