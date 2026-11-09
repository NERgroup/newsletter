# Kelp Korner — adaptive second-page layout

Updates ONLY:
- `R/build_two_page.R`
- `templates/two_page/issue.html`
- `templates/two_page/issue.css`

The existing cover design, Google Sheet, Drive access, AI draft script, and master command are preserved.

## Install

Unzip the archive contents into your existing `nerg_newsletter` repository folder, replacing those three files. The exact Terminal command from the repository directory is:

```bash
unzip -o ~/Downloads/kelp-korner-layout-update.zip
```

## Preview in RStudio

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/create_newsletter.R")
```

The script makes an AI call as before. To re-render an existing draft without a new API call, set NEWSLETTER_DRAFT_PATH to the exact latest editorial CSV and run `source("R/build_two_page.R")`.

The number of stories drives the layout automatically (1 / 2 / 3). No empty secondary story boxes. Featured photographs are always uncropped and are placed in an image column whose width follows their orientation. If `magick` is installed, R recognizes the orientation; otherwise the browser does so after the image loads. No photo is generated or modified. 

A visible warning appears in browser preview when page 2 content collides with its footer. The two-page design is retained; always inspect the printed PDF before sharing. Nothing publishes automatically.
