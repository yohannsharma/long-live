# Hand-tests: polished figures and interpretations (issue #7)

Run these after the hand-tests for #3–#6 pass. They check that `EDA-Findings.md` matches the figures and is ready for the check-in.

- [ ] Open `EDA-Findings.md` in GitHub's preview, or RStudio's Markdown preview, and check that all 3 images display. They only appear after the PNGs are created and committed.
- [ ] Figure 1: the r values quoted (−0.91) match the panel titles in `scatter_predictors.png`, and the curved mortality line and the points below the curve are visible as described.
- [ ] Figure 2: the 2000 and 2019 numbers quoted match the console table from `R/03_eda_trends.R`, and the narrowing high–low gap is visible.
- [ ] Figure 3: the r values quoted match `output/tables/correlation_matrix.csv`.
- [ ] Each figure has a title, axis labels with units, and a source caption, and is readable when shrunk to half a slide.
- [ ] Each interpretation is a paragraph you'd be happy to paste into the check-in summary (issue #18) or slides. Edit the wording to your own voice where needed.
