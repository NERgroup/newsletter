# From the Kelp Forest — newsletter workflow

Quarterly newsletter starter for the Nearshore Ecology Research Group (NERG), UC Santa Cruz.

**Two outputs:** a public Quarto website/archive and a separate email draft (Markdown + HTML). AI drafts are **never** committed automatically or sent.

## 1. Open the repo in RStudio

1. Install [Quarto](https://quarto.org/docs/get-started/), R, RStudio, and Git.
2. Clone: `git clone https://github.com/NERgroup/newsletter.git` (once these starter files have been added to the repository).
3. Open the repository folder as an RStudio Project (File > New Project > Existing Directory), or run RStudio from this directory.
4. In the R Console: `install.packages(c("ellmer", "jsonlite", "commonmark"))`.

## 2. Configure the AI key locally

Use `usethis::edit_r_environ()` or edit your user-level `~/.Renviron` and add:

```text
OPENAI_API_KEY=your_api_key_here
OPENAI_MODEL=gpt-5.6-luna
```

Restart RStudio. The key must never be checked into Git. OpenAI API access is billed separately from ChatGPT subscriptions. Change `OPENAI_MODEL` to any model available on your API account.

## 3. Maintain the updates log

Edit `data/updates.csv` (or import equivalent rows from a Google Form/Sheet later). Columns:

| column | example | meaning |
| --- | --- | --- |
| date | `2026-10-12` | date of activity |
| category | `Fieldwork` | section candidate |
| headline | `Kelp surveys continue` | working headline |
| details | `Description of work and confirmed facts` | factual source notes |
| source_url | `https://...` | optional verification URL |
| approved_for_ai | `TRUE` | explicit permission to send this record to the configured AI provider |

Only approved records in the selected quarter are sent to the model. Keep personal information and confidential research out of this log. **AI permission is not publication permission.**

## 4. Draft a newsletter

In the **R Console** from the repository root:

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/build_newsletter.R")
```

Omit `Sys.setenv(...)` to draft for the most recently *completed* calendar quarter.

Draft files appear at `drafts/2026-Q4/`:

- `index.qmd` — Quarto website article with `draft: true`
- `email.md` — email text for editing
- `email.html` — email-client-friendly HTML to import into a mailing platform
- `sources.json` — exact source records provided to AI

`drafts/` is Git-ignored. Review all claims, especially unpublished research, grants, publication status, attributions, and links. The script does not perform an independent fact check.

## 5. Preview and publish

To preview the existing public site, run **in the Terminal**:

```sh
quarto preview
```

After reviewing the AI draft, in the **R Console**:

```r
Sys.setenv(NEWSLETTER_QUARTER = "2026-Q4")
source("R/publish_issue.R")
```

Type `PUBLISH` when asked. This copies the approved draft to `posts/2026-Q4/index.qmd`. Then from the Terminal:

```sh
quarto render
git add .
git commit -m "Publish quarterly newsletter"
git push origin main
```

**Important:** `git add .` stages all non-ignored material. Review with `git status` before committing, especially the CSV data log. Do not commit sensitive information. Email delivery is manual: import the reviewed `drafts/2026-Q4/email.html` into an approved mailing service, test, then send. There is no automatic emailing.

## 6. Configure GitHub Pages once

In GitHub repository **Settings > Pages**, set **Build and deployment > Source = GitHub Actions**. On every push to `main`, `.github/workflows/publish.yml` will render and deploy the Quarto site. The intended default URL is https://nergroup.github.io/newsletter/ once Pages is enabled and the first deployment succeeds.

If GitHub reports a permissions or Pages environment issue, consult [GitHub Pages via Quarto](https://quarto.org/docs/publishing/github-pages.html). This workflow uses GitHub's first-party Pages deployment actions and does not require `quarto publish` locally.

## Roadmap

**MVP (included):** curated update log → AI newsletter draft → editorial review → Quarto website + email HTML.

**Later:** Google Form/Sheet intake, publication DOI fetching, authenticated GitHub activity summaries, approved photo collection, a source-review dashboard, mailing-platform API integration, and scheduled draft reminders. These integrations are **not** enabled yet.
