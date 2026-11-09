# ============================================================
# KELP KORNER
# Read newsletter updates from Google Sheets
# ============================================================

library(googlesheets4)

# Google Sheet URL
sheet_url <- paste0(
  "https://docs.google.com/spreadsheets/d/",
  "1giUh1YgvFGzA0i9iKtP8c0aIyuvlB48nb8SEafhM_8E"
)

# Authenticate using your UCSC Google account
gs4_auth(email = "jogsmith@ucsc.edu")

# Read the Updates worksheet
updates <- read_sheet(
  ss = sheet_url,
  sheet = "Updates",
  col_types = "c"
)

# Standardize column names
names(updates) <- c(
  "quarter",
  "date",
  "category",
  "headline",
  "details",
  "submitted_by",
  "photo_link",
  "photo_credit",
  "source_link",
  "approved_for_ai",
  "editorial_notes"
)

# Display confirmation
cat(
  "\nSuccessfully imported",
  nrow(updates),
  "newsletter updates.\n"
)

print(updates)