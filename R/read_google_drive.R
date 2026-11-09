# ============================================================
# KELP KORNER
# Read media from Google Drive by newsletter quarter
# ============================================================

library(googledrive)

# Authenticate with UCSC account
drive_auth(email = "jogsmith@ucsc.edu")

# Parent media folder
media_folder_url <- paste0(
  "https://drive.google.com/drive/folders/",
  "1O73dmzSjXfKHSZYOzD8fnkQjrhHWibOC"
)

# Newsletter quarter
quarter <- Sys.getenv(
  "NEWSLETTER_QUARTER",
  unset = "2026-Q4"
)

# Convert 2026-Q4 to 2026_Q4
quarter_folder_name <- gsub("-", "_", quarter)

# Find the quarter's folder
media_folder <- as_id(media_folder_url)

quarter_folders <- drive_ls(
  path = media_folder,
  type = "folder"
)

quarter_match <- quarter_folders[
  quarter_folders$name == quarter_folder_name,
]

if (nrow(quarter_match) != 1) {
  stop("Could not find media folder: ", quarter_folder_name)
}

# List photos inside the quarter folder
quarter_media <- drive_ls(
  path = as_id(quarter_match$id[[1]])
)

cat(
  "\nFound",
  nrow(quarter_media),
  "media files for",
  quarter,
  "\n"
)

print(quarter_media)


######################
# ============================================================
# Download photographs linked in the Google Sheet
# ============================================================

# Make sure the Google Sheet has been loaded
if (!exists("updates")) {
  stop("Run R/read_google_sheets.R first.")
}

# Select updates with a photo link
photos <- updates[
  !is.na(updates$photo_link) &
    nzchar(trimws(updates$photo_link)),
]

# Create local media folder for this quarter
local_media_dir <- file.path(
  "images",
  "newsletter",
  gsub("-", "_", quarter)
)

dir.create(
  local_media_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Download each linked photograph
for (i in seq_len(nrow(photos))) {
  
  photo_id <- as_id(photos$photo_link[i])
  
  photo_file <- drive_get(photo_id)
  
  # Keep the original filename
  destination <- file.path(
    local_media_dir,
    photo_file$name[1]
  )
  
  drive_download(
    file = photo_file,
    path = destination,
    overwrite = TRUE
  )
  
  cat("Downloaded:", destination, "\n")
}