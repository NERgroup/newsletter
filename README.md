# Kelp Korner: two-page RStudio newsletter design

This is an **add-on** to the existing `NERgroup/newsletter` repo, not a replacement. It preserves the Quarto website, GitHub workflow, `data/updates.csv`, and `R/build_newsletter.R`.

## Installation (from Mac Terminal)

Unzip into your existing repository folder, e.g.:

```bash
cd /Users/jossmith/code_respositories/nerg_newsletter
unzip -o ~/Downloads/kelp-korner-r-workflow.zip
```

The archive adds `R/build_two_page.R`, `templates/two_page/issue.html`, `templates/two_page/issue.css`, and `images/branding/kelp-forest.jpg`.

## Generate preview (in RStudio Console)

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/build_two_page.R")
```

It opens `drafts/2026-Q4/two_page/index.html` in your browser. On the browser's Print dialog choose **Save as PDF**, **Letter**, **No margins**, **Print backgrounds** (and disable headers/footers). The CSS uses exactly two Letter-sized pages. If updates are long, the script limits text length to protect the layout; review the final preview for truncation.

When `data/updates.csv` contains approved records in that quarter, the template uses the three most recent approved records for its three stories. If there are none, a distinctly labeled layout preview is used. This preview does **not** invoke OpenAI or incur API costs, and it does **not** automatically publish or send anything. `drafts/` is already Git-ignored.

## Existing AI workflow

`R/build_newsletter.R` remains the AI-assisted long-form Quarto newsletter and email drafting script. The two-page design is an additional, spreadsheet-driven **print/PDF layout** alongside it. Connecting AI-edited story summaries directly into this print layout is a future integration, not yet implemented.

## Images

Your uploaded real kelp forest photo is the cover. Do not use generated imagery; replace `images/branding/kelp-forest.jpg` with your own licensed photograph if desired. Add photo credit before sharing. The layout deliberately avoids pretending other photographs exist.

## Publishing

Review and publish only factual, approved stories. This preview is a local HTML/PDF layout and does not appear on the public Quarto website unless you explicitly upload or link it later.
