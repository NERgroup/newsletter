# Kelp Korner — Cover copy and volume/issue numbering

This update changes only **two files**. It preserves the existing Google Sheet / Drive media / OpenAI workflow, cover photograph, Smith Lab logo, CSS, and two-/three-page design.

## Install

In your RStudio **Terminal**:

```bash
cd /Users/jossmith/code_respositories/nerg_newsletter
unzip -o ~/Downloads/kelp-korner-cover-copy-numbering.zip
```

The ZIP replaces:

- `R/build_two_page.R`
- `templates/two_page/issue.html`

## Cover wording

- `THE QUARTERLY EDITION · FALL 2026`
- `Research, people & stories / from California's nearshore.`
- `VOL. 01 / ISSUE 01`

The phrase `AI EDITORIAL DRAFT — REVIEW BEFORE SHARING` is removed from the **cover**. The generated newsletter is **still a private draft**, not a public release.

## Automatic numbering

- 2026-Q4 → Vol. 01 / Issue 01 (inaugural issue)
- 2027-Q1 → Vol. 02 / Issue 01
- 2027-Q2 → Vol. 02 / Issue 02
- 2027-Q3 → Vol. 02 / Issue 03
- 2027-Q4 → Vol. 02 / Issue 04
- 2028-Q1 → Vol. 03 / Issue 01

Pre-inaugural quarters are intentionally rejected to prevent accidental misnumbering.

## Test

In the RStudio **Console**:

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/create_newsletter.R")
```

This regenerates the private preview and makes the usual AI API call. No publication occurs.
