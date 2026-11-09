# Kelp Korner — final visual and editorial refinements

This patch is based on the existing November 9 logo-and-editorial workflow. It updates only:

- `templates/two_page/issue.html` — removes duplicate standalone Follow the Research link below the closing panel. Keeps the styled clickable link within the panel.
- `templates/two_page/issue.css` — slightly adjusts the cover logo placement and two-story featured image, and fine-tunes card spacing.
- `R/draft_with_ai.R` — improves instructions for a connected, evidence-grounded quarterly introduction.

**Install from the project folder in RStudio Terminal:**

```bash
cd /Users/jossmith/code_respositories/nerg_newsletter
unzip -o ~/Downloads/kelp-korner-final-refinements.zip
```

**Test in the RStudio Console:**

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/create_newsletter.R")
```

The AI drafting step makes a new billable API call. Nothing is published. The template still draws the quarterly cover from Drive, includes all approved stories, and targets a maximum of three pages. Examine the browser warning and print-page count, especially after adding five or six stories. These edits do not guarantee the full issue will fit if there is too much content.

No changes to Google Drive folder structure or source media. Keep your existing `R/build_two_page.R`, `R/create_newsletter.R`, and Google integration scripts.
