# HbA1c follow-up analysis: ANCOVA and diagnostics
# Author: Marie-Noelle Nogeant | Independent portfolio adaptation of university coursework
# Run from the project root: source("R/analysis.R")
# Data are read as supplied; decimal commas are deliberately preserved on disk.

if (!file.exists("data/hb.csv")) {
  stop("Run this script from the project root (where data/hb.csv is located).")
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required. Install it with install.packages('ggplot2').")
}

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

# CRITICAL: The CSV is semicolon-delimited and uses COMMAS as decimal marks.
# read.csv2() explicitly handles both conventions.
hb <- read.csv2("data/hb.csv", stringsAsFactors = FALSE,
                check.names = FALSE, na.strings = c("", "NA"))

required <- c("id", "groupe", "hb0", "hb1")
if (!all(required %in% names(hb))) {
  stop("Missing required columns: ", paste(setdiff(required, names(hb)), collapse = ", "))
}
if (!is.numeric(hb$hb0) || !is.numeric(hb$hb1)) {
  stop("HbA1c columns are not numeric: check the decimal-comma import.")
}
if (anyNA(hb[, required]) || any(!is.finite(hb$hb0)) || any(!is.finite(hb$hb1))) {
  stop("Missing or non-finite values detected; review data before analysis.")
}
if (anyDuplicated(hb$id) > 0) stop("Duplicate subject IDs detected.")
if (!setequal(unique(hb$groupe), c("A", "B"))) {
  stop("Expected only treatment groups A and B.")
}
if (any(hb$hb0 < 3 | hb$hb0 > 20 | hb$hb1 < 3 | hb$hb1 > 20)) {
  warning("Some HbA1c values are outside a broad plausibility range; review units.")
}

hb$groupe <- relevel(factor(hb$groupe), ref = "A")
hb$delta <- hb$hb1 - hb$hb0

# Descriptives, by group
summarise_group <- function(x) {
  data.frame(
    group = as.character(x$groupe[1]), n = nrow(x),
    baseline_mean = mean(x$hb0), baseline_sd = sd(x$hb0),
    followup_mean = mean(x$hb1), followup_sd = sd(x$hb1),
    change_mean = mean(x$delta), change_sd = sd(x$delta),
    change_median = median(x$delta), stringsAsFactors = FALSE
  )
}
descriptives <- do.call(rbind, lapply(split(hb, hb$groupe), summarise_group))
row.names(descriptives) <- NULL
write.csv(descriptives, "outputs/tables/descriptives.csv", row.names = FALSE)

# Primary ANCOVA, adjusting three-month HbA1c for baseline HbA1c
ancova <- lm(hb1 ~ groupe + hb0, data = hb)
ancova_summary <- summary(ancova)
ancova_ci <- confint(ancova, level = 0.95)
coef_matrix <- ancova_summary$coefficients
coefficient_table <- data.frame(
  term = rownames(coef_matrix),
  estimate = unname(coef_matrix[, "Estimate"]),
  std_error = unname(coef_matrix[, "Std. Error"]),
  p_value = unname(coef_matrix[, "Pr(>|t|)"]),
  ci_low = unname(ancova_ci[, 1]),
  ci_high = unname(ancova_ci[, 2]),
  row.names = NULL
)
write.csv(coefficient_table, "outputs/tables/ancova_coefficients.csv", row.names = FALSE)

# Robust HC3 standard errors: sensitivity to unequal residual variance.
# Formula: (X'X)^(-1) X' diag(e_i^2 / (1-h_ii)^2) X (X'X)^(-1)
X <- model.matrix(ancova)
e <- residuals(ancova)
h <- hatvalues(ancova)
bread <- solve(crossprod(X))
weighted_X <- X * as.numeric((e / (1 - h))^2)
vcov_hc3 <- bread %*% crossprod(X, weighted_X) %*% bread
hc3_se <- sqrt(diag(vcov_hc3))
hc3_t <- coef(ancova) / hc3_se
hc3_df <- df.residual(ancova)
hc3_ci_width <- qt(0.975, df = hc3_df) * hc3_se
hc3_table <- data.frame(
  term = names(coef(ancova)), estimate = unname(coef(ancova)),
  robust_se = unname(hc3_se),
  ci_low = unname(coef(ancova) - hc3_ci_width),
  ci_high = unname(coef(ancova) + hc3_ci_width),
  p_value = unname(2 * pt(-abs(hc3_t), df = hc3_df)), row.names = NULL
)
write.csv(hc3_table, "outputs/tables/ancova_hc3.csv", row.names = FALSE)

# Check the common-slope assumption with a baseline x group interaction.
ancova_interaction <- lm(hb1 ~ groupe * hb0, data = hb)
interaction_comparison <- anova(ancova, ancova_interaction)
interaction_p <- interaction_comparison$`Pr(>F)`[2]

# Exploratory sensitivity analyses on the unadjusted individual change.
welch_change <- t.test(delta ~ groupe, data = hb, var.equal = FALSE)
wilcoxon_change <- wilcox.test(delta ~ groupe, data = hb, exact = FALSE)
normality_residuals <- shapiro.test(residuals(ancova))
# Fligner-Killeen is a nonparametric check of residual dispersion by group.
fligner_residuals <- fligner.test(residuals(ancova) ~ hb$groupe)

checks <- data.frame(
  check = c("Complete observations", "Duplicate IDs", "Baseline-by-group interaction p",
            "Residual Shapiro-Wilk p", "Residual Fligner-Killeen p",
            "Change Welch t-test p", "Change Wilcoxon rank-sum p"),
  value = c(as.character(nrow(hb)), as.character(anyDuplicated(hb$id)),
            format(interaction_p, digits = 6),
            format(normality_residuals$p.value, digits = 6),
            format(fligner_residuals$p.value, digits = 6),
            format(welch_change$p.value, digits = 6),
            format(wilcoxon_change$p.value, digits = 6))
)
write.csv(checks, "outputs/tables/diagnostic_checks.csv", row.names = FALSE)

# Reproducible figures
library(ggplot2)
plot_followup <- ggplot(hb, aes(x = groupe, y = hb1, fill = groupe)) +
  geom_boxplot(width = 0.55, alpha = 0.75, outlier.alpha = 0.5) +
  geom_jitter(width = 0.12, height = 0, alpha = 0.65, size = 1.7) +
  labs(x = "Group", y = "Follow-up HbA1c (reported units)",
       title = "HbA1c at follow-up by group") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave("outputs/figures/followup_by_group.png", plot_followup,
       width = 7, height = 4.5, dpi = 200)

plot_baseline <- ggplot(hb, aes(x = hb0, y = hb1, colour = groupe)) +
  geom_point(alpha = 0.75) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE) +
  labs(x = "Baseline HbA1c (reported units)",
       y = "Follow-up HbA1c (reported units)",
       colour = "Group", title = "Baseline and follow-up HbA1c") +
  theme_minimal(base_size = 12)
ggsave("outputs/figures/baseline_vs_followup.png", plot_baseline,
       width = 7, height = 4.5, dpi = 200)

png("outputs/figures/ancova_diagnostics.png", width = 1300,
    height = 1000, res = 150)
par(mfrow = c(2, 2))
plot(ancova, which = c(1, 2, 3, 5))
dev.off()

cat("\n=== Validated dataset ===\n")
print(descriptives)
cat("\n=== Primary ANCOVA ===\n")
print(ancova_summary)
cat("\n=== 95% confidence intervals ===\n")
print(ancova_ci)
cat("\n=== Robust HC3 sensitivity ===\n")
print(hc3_table)
cat("\n=== Assumptions and sensitivity ===\n")
print(checks)
