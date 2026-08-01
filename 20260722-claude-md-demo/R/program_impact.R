# BigQuery authentication
# ------------------------
# From the R console, run bigrquery::bq_auth() once. It opens a browser and
# caches the token for the session.
#
# From the terminal use "gcloud auth login"
#
# It reuses the credentials already on the machine instead. Without it the
# query fails with a confusing malformed-URL error rather than a clear
# "not authenticated" one.

#' Locate a file relative to the repo root
#'
#' Lets the functions below find `sql/` and `figs/` regardless of the working
#' directory the script is sourced from.
#' @keywords internal
repo_path <- function(...) {
  this_file <- NULL
  for (f in sys.frames()) {
    if (!is.null(f$ofile)) this_file <- f$ofile
  }
  if (is.null(this_file)) {
    args <- commandArgs(trailingOnly = FALSE)
    this_file <- sub("^--file=", "", grep("^--file=", args, value = TRUE))
  }
  file.path(dirname(dirname(normalizePath(this_file))), ...)
}

REPO <- repo_path()

#' Program-level emissions impact
#'
#' Runs `sql/program_impact.sql` and returns the single row of program totals.
#'
#' @param project Billing project for the BigQuery job.
#' @return A one-row data.frame.
#' @export
program_impact <- function(project = "emlab-gcp") {
  sql <- readLines(file.path(REPO, "sql", "program_impact.sql"), warn = FALSE)
  sql <- paste(sql, collapse = "\n")

  bigrquery::bq_table_download(
    bigrquery::bq_project_query(project, sql)
  )
}

#' Reshape the one-row program impact into long form
#'
#' @param impact A data.frame from [program_impact()].
#' @return A data.frame of `domain`, `type` and `emissions`.
#' @export
tidy_program_impact <- function(impact) {
  domains <- c(
    "Global (net total)" = "global",
    "Inside VSR zones" = "vsr",
    "Outside VSR zones" = "outside_vsr"
  )

  rows <- lapply(names(domains), function(label) {
    suffix <- domains[[label]]
    col <- function(type) {
      name <- paste0("total_", type, "_", suffix, "_co2e_100yrGWP_mt")
      if (!name %in% names(impact)) {
        stop("Column not found in query result: ", name)
      }
      impact[[name]]
    }
    data.frame(
      domain = label,
      type = c("Actual", "Counterfactual"),
      emissions = c(col("actual"), col("counterfactual")),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  out$domain <- factor(out$domain, levels = names(domains))
  out
}

#' Shared plot theme
#'
#' Matches `theme_bwbs()` in the ocean-ghg-bwbs project so figures here look
#' like the ones in that report.
#' @keywords internal
theme_bwbs <- function() {
  ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 11, color = "gray40"),
      axis.title = ggplot2::element_text(size = 10),
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank()
    )
}

#' Shared palette, copied from the ocean-ghg-bwbs project
#' @keywords internal
BWBS_COLORS <- c(
  actual = "#2E86AB",
  counterfactual = "#A23B72",
  impact_positive = "#E94F37",
  impact_negative = "#44AF69"
)

#' Plot actual vs counterfactual emissions by domain
#'
#' @param impact A data.frame from [program_impact()].
#' @return A ggplot object.
#' @export
plot_program_impact <- function(impact) {
  long <- tidy_program_impact(impact)

  # Plot in thousands of tonnes; the raw figures run to millions.
  long$emissions <- long$emissions / 1000

  ggplot2::ggplot(
    long,
    ggplot2::aes(x = domain, y = emissions, fill = type)
  ) +
    ggplot2::geom_col(position = "dodge", alpha = 0.85) +
    ggplot2::scale_fill_manual(
      values = c(
        Actual = unname(BWBS_COLORS[["actual"]]),
        Counterfactual = unname(BWBS_COLORS[["counterfactual"]])
      )
    ) +
    ggplot2::scale_y_continuous(
      labels = function(x) {
        format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
      }
    ) +
    ggplot2::labs(
      title = "Actual vs. Counterfactual CO2e Emissions",
      subtitle = "Comparison across spatial domains during the 2024 BWBS season",
      y = "CO2e Emissions (thousand mt)",
      x = NULL,
      fill = "Scenario"
    ) +
    theme_bwbs() +
    ggplot2::coord_flip()
}

#' Plot the emissions impact (actual minus counterfactual) by domain
#'
#' @param impact A data.frame from [program_impact()].
#' @return A ggplot object.
#' @export
plot_impact_direction <- function(impact) {
  domains <- c(
    "Global (net total)" = "global",
    "Inside VSR zones" = "vsr",
    "Outside VSR zones" = "outside_vsr"
  )

  col <- function(type, suffix) {
    impact[[paste0("total_", type, "_", suffix, "_co2e_100yrGWP_mt")]]
  }

  df <- data.frame(
    domain = factor(names(domains), levels = names(domains)),
    impact = vapply(domains, function(s) col("impact", s), numeric(1)),
    counterfactual = vapply(
      domains,
      function(s) col("counterfactual", s),
      numeric(1)
    ),
    stringsAsFactors = FALSE
  )
  df$direction <- ifelse(df$impact < 0, "Reduction", "Increase")
  df$pct_change <- df$impact / df$counterfactual * 100
  df$label <- paste0(
    format(abs(round(df$impact)), big.mark = ",", trim = TRUE),
    " mt (",
    ifelse(df$pct_change > 0, "+", ""),
    round(df$pct_change, 1),
    "%)"
  )
  df$hjust <- ifelse(df$impact < 0, 1.1, -0.1)

  ggplot2::ggplot(df, ggplot2::aes(x = domain, y = impact, fill = direction)) +
    ggplot2::geom_col(alpha = 0.85) +
    ggplot2::geom_text(
      ggplot2::aes(label = label, hjust = hjust),
      size = 3
    ) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    ggplot2::scale_fill_manual(
      values = c(
        Reduction = unname(BWBS_COLORS[["impact_negative"]]),
        Increase = unname(BWBS_COLORS[["impact_positive"]])
      ),
      name = "Impact Direction"
    ) +
    ggplot2::scale_y_continuous(
      labels = function(x) {
        format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
      },
      expand = ggplot2::expansion(mult = 0.35)
    ) +
    ggplot2::labs(
      title = "Emissions Impact (Actual - Counterfactual)",
      subtitle = "Negative values indicate emission reductions",
      y = "CO2e Impact (mt)",
      x = NULL
    ) +
    theme_bwbs() +
    ggplot2::coord_flip()
}

#' Save both impact panels to figs/
#'
#' Stacks the actual-vs-counterfactual and impact-direction plots, as the
#' ocean-ghg-bwbs report does.
#'
#' @param impact A data.frame from [program_impact()]. Queried if omitted.
#' @param path Output file. Defaults to `figs/program_impact.png`.
#' @return The path written, invisibly.
#' @export
save_program_impact <- function(
  impact = program_impact(),
  path = file.path(REPO, "figs", "program_impact.png")
) {
  combined <- patchwork::wrap_plots(
    plot_program_impact(impact),
    plot_impact_direction(impact),
    ncol = 1
  )
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(path, combined, width = 9, height = 9, dpi = 150)
  message("Wrote ", path)
  invisible(path)
}
