# Kelp Korner — optional third page

This package builds on the current one-command workflow. It replaces:

- `R/draft_with_ai.R` — AI can select up to **six** stories rather than three.
- `R/build_two_page.R` — builds **2 or 3 pages** depending on story count.
- `templates/two_page/issue.html` — optional content page, cover preserved.
- `templates/two_page/issue.css` — styles page 3 consistent with page 2.

No changes to `R/create_newsletter.R`, Google Sheets credentials, Drive folders, or the cover photograph.

In the RStudio Console:

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/create_newsletter.R")
```

The Google Sheet must have approved entries with at least 40 characters in `Details / notes`. One to three drafted stories produces **two pages**; four to six produces **three pages**. The third page is not inserted for a shorter issue. No more than six stories are selected. More than six source entries can remain in the Sheet for later issues.

**Editorial safety:** The result is private preview HTML only. Nothing is emailed or published. AI-generated claims must be checked before public release.

**Print:** Open `drafts/<quarter>/two_page/index.html`, then Print > Save as PDF, US Letter, no margins, background graphics on. Check the page-count preview and make sure no yellow overflow warning appears. If the content does not fit, do not publish. Browser printing remains a manual step.

**Photo support:** The featured story retains the current, original photograph from its linked Google Drive media. This version does not yet display separate photos for the secondary stories.
