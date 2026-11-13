# Kelp Korner — story links + editorial refinements

This is a complete, coordinated set of the currently used R workflow files and HTML/CSS template. It keeps the Google Drive quarterly `cover_photo` convention, Smith Lab branding, volume/issue numbering, one-command private draft, all approved stories, optional third page, and linked story photographs.

## Install

From the RStudio **Terminal** (not R Console):

```bash
cd /Users/jossmith/code_respositories/nerg_newsletter
unzip -o ~/Downloads/kelp-korner-story-links.zip
```

This updates `R/read_google_sheets.R`, `R/draft_with_ai.R`, `R/build_two_page.R`, `R/create_newsletter.R`, `templates/two_page/issue.html`, `templates/two_page/issue.css` and `images/branding/smith-lab-logo.png`. Your local data, Google Drive, Quarto config, and the site are not changed. If desired, commit after testing.

## Add external links to the Google Sheet

In the **Updates** tab, use the existing `Source link` column for an absolute `https://...` or `http://...` URL. In the new `Link text` column enter a short visible label such as **Read the UCSC press release**. Leave Link text blank to display **Read more**. Leave Source link blank to show no link.

Only entries for the selected quarter with `Approved for publication = Yes` are sent to AI drafting. The generated newsletter remains an editorial draft and must still be reviewed before distribution. Links are taken exactly from the source row, not written or changed by AI. They show on both featured and secondary cards. HTML and PDFs printed from Chrome should retain the clickable link targets, provided print-to-PDF preserves hyperlinks.

## Run

From the RStudio **Console**:

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/create_newsletter.R")
```

A private browser preview is generated at `drafts/2026-Q4/two_page/index.html`. This makes API calls; it does **not** publish or email anyone.

## Check

The newsletter output directory contains `link_manifest.csv` with one row per included story and its destination URL and label. `inclusion_report.csv` also records which stories have links. Open the HTML and click the link. In the browser, print with Letter paper, zero margins, background graphics enabled, and verify that the PDF remains at most three pages with no layout warnings. The intro / Looking Ahead prompts discourage duplicate updates but still require human editorial review.
