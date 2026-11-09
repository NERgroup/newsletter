# Run from the repository root in RStudio:
# source("R/build_newsletter.R")
# For a specific quarter: Sys.setenv(NEWSLETTER_QUARTER="2026-Q4") first.

required <- c("ellmer", "jsonlite", "commonmark")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages: install.packages(c(",
                          paste(sprintf('"%s"', missing), collapse = ", "), "))")
if (!file.exists("_quarto.yml")) stop("Run this script from the repository root.")
if (!nzchar(Sys.getenv("OPENAI_API_KEY"))) {
  stop("Set OPENAI_API_KEY in your user-level .Renviron (never in this repository).")
}

get_quarter <- function(date) paste0(format(date, "%Y"), "-Q", (as.integer(format(date, "%m")) - 1L) %/% 3L + 1L)
quarter <- Sys.getenv("NEWSLETTER_QUARTER", unset = "")
if (!nzchar(quarter)) quarter <- get_quarter(as.Date(format(Sys.Date(), "%Y-%m-01")) - 1L)
if (!grepl("^[0-9]{4}-Q[1-4]$", quarter)) stop("NEWSLETTER_QUARTER must look like 2026-Q4")
year <- as.integer(substr(quarter, 1, 4))
q <- as.integer(substr(quarter, 7, 7))
start <- as.Date(sprintf("%04d-%02d-01", year, (q - 1L) * 3L + 1L))
end <- as.Date(sprintf("%04d-%02d-01", if (q == 4L) year + 1L else year,
                       if (q == 4L) 1L else q * 3L + 1L)) - 1L

records <- utils::read.csv("data/updates.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
expected <- c("date", "category", "headline", "details", "source_url", "approved_for_ai")
if (!all(expected %in% names(records))) stop("data/updates.csv must include: ", paste(expected, collapse = ", "))
records$date <- as.Date(records$date)
if (any(is.na(records$date))) stop("Every update needs a valid date (YYYY-MM-DD).")
approved <- tolower(trimws(as.character(records$approved_for_ai))) %in% c("true", "yes", "1")
records <- records[records$date >= start & records$date <= end & approved, , drop = FALSE]
if (!nrow(records)) stop("No approved records for ", quarter, ". Add updates to data/updates.csv and set approved_for_ai=TRUE.")
records$source_id <- sprintf("U%03d", seq_len(nrow(records)))
records <- records[, c("source_id", "date", "category", "headline", "details", "source_url")]

sys <- paste(readLines("prompts/editorial_system.txt", warn = FALSE), collapse = "\n")
chat <- ellmer::chat_openai(system_prompt = sys,
                            model = Sys.getenv("OPENAI_MODEL", unset = "gpt-5.6-luna"))
source_data <- jsonlite::toJSON(records, dataframe = "rows", auto_unbox = TRUE, na = "null", pretty = TRUE)
website_prompt <- paste0(
  "Write the body of the ", quarter, " newsletter covering ", start, " through ", end, ". ",
  "Aim for about 500-800 words, but shorter is fine if sources are limited. ",
  "Start with a welcoming 1-2 sentence introduction, then use ## headings for 2-5 sections. ",
  "End with an 'Around the lab' or 'Looking ahead' section ONLY if supported. ",
  "For specific claims, include a source identifier such as [U001] near the relevant sentence. ",
  "Do not output a title or YAML; those are added separately. Here are the source records:\n", source_data)
body <- as.character(chat$chat(website_prompt))

# Separate conversation prevents the email from inheriting the prior draft as a factual source.
email_chat <- ellmer::chat_openai(system_prompt = sys,
                                  model = Sys.getenv("OPENAI_MODEL", unset = "gpt-5.6-luna"))
email_prompt <- paste0(
  "Draft a concise 200-350 word EMAIL newsletter for ", quarter, ". ",
  "Include a greeting, 2-4 short news highlights with headings, and an invitation to read the full issue. ",
  "Use [READ_FULL_ISSUE] as the placeholder for the public full-issue link. ",
  "Do not include source IDs in the email. Do not invent a subscription link. ",
  "Write Markdown only. Source records:\n", source_data)
email_body <- as.character(email_chat$chat(email_prompt))

issue_dir <- file.path("drafts", quarter)
dir.create(issue_dir, recursive = TRUE, showWarnings = FALSE)
qmd <- file.path(issue_dir, "index.qmd")
qmd_header <- c("---", paste0("title: ", jsonlite::toJSON(paste0("From the Kelp Forest · ", quarter), auto_unbox = TRUE)),
                paste0("date: ", end),
                paste0("description: ", jsonlite::toJSON(paste0("Quarterly lab news for ", quarter), auto_unbox = TRUE)),
                "draft: true", "---", "")
valid_links <- !is.na(records$source_url) & grepl("^https?://", records$source_url)
source_lines <- if (any(valid_links)) {
  c("", "## Source links for fact-checking", "",
    paste0("- [", records$source_id[valid_links], "](", records$source_url[valid_links], ") — ",
           records$headline[valid_links]))
} else c("", "*No source links supplied; check source records before publishing.*")
writeLines(c(qmd_header, body, "", "---", "", source_lines), qmd)

# An email-safe HTML document for importing or copying into an email platform.
# Human approval and actual sending are separate steps.
issue_url <- paste0("https://nergroup.github.io/newsletter/posts/", quarter, "/")
email_body <- gsub("[READ_FULL_ISSUE]", issue_url, email_body, fixed = TRUE)
writeLines(email_body, file.path(issue_dir, "email.md"))
email_content <- commonmark::markdown_html(email_body)
html <- paste0(
  '<!doctype html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>',
  '<body style="margin:0;padding:24px;background:#f5f7f6;font-family:Arial,sans-serif;color:#233b35;">',
  '<div style="max-width:620px;margin:0 auto;background:#ffffff;padding:30px;border-top:5px solid #176b60;line-height:1.6;">',
  '<p style="font-size:12px;letter-spacing:1.5px;color:#176b60;">NEARSHORE ECOLOGY RESEARCH GROUP</p>',
  '<h1 style="font-size:28px;line-height:1.2;">From the Kelp Forest</h1>',
  email_content,
  '<hr><p style="font-size:12px;color:#65746f;">Nearshore Ecology Research Group · UC Santa Cruz</p>',
  '</div></body></html>')
writeLines(html, file.path(issue_dir, "email.html"))
writeLines(jsonlite::toJSON(records, dataframe = "rows", auto_unbox = TRUE,
                            na = "null", pretty = TRUE), file.path(issue_dir, "sources.json"))
message("Drafts created in ", issue_dir,
        "\nReview index.qmd, email.md, email.html, and sources.json.",
        "\nThese files are NOT published. Publish only after fact-checking and approval.")
