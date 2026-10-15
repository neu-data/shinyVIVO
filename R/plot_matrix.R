#' Summarise a metric by theme presence
#'
#' @param df A coded data frame (see [code_dataframe()]).
#' @param themes Theme column names.
#' @param metric_col Name of a numeric column.
#' @return A data frame with columns `Theme`, `State` (`"Absent"` /
#'   `"Present"`), `n` and `mean`. Rows with `NA` codes are excluded.
#' @export
summarise_theme_metric <- function(df, themes, metric_col) {
  themes <- intersect(themes, names(df))
  rows <- lapply(themes, function(th) {
    code <- df[[th]]
    keep <- !is.na(code)
    state <- factor(ifelse(code[keep], "Present", "Absent"),
                    levels = c("Absent", "Present"))
    vals <- df[[metric_col]][keep]
    data.frame(
      Theme = th,
      State = levels(state),
      n     = as.integer(table(state)),
      mean  = vapply(levels(state), function(s) {
        v <- vals[state == s]
        if (length(v)) mean(v, na.rm = TRUE) else NA_real_
      }, numeric(1)),
      row.names = NULL
    )
  })
  do.call(rbind, rows)
}

#' Plot a metric against theme presence
#'
#' @inheritParams summarise_theme_metric
#' @return A ggplot object.
#' @export
plot_theme_metric <- function(df, themes, metric_col) {
  s <- summarise_theme_metric(df, themes, metric_col)
  s$State <- factor(s$State, levels = c("Absent", "Present"))
  ggplot2::ggplot(s, ggplot2::aes(x = .data$Theme, y = .data$mean,
                                  fill = .data$State)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(preserve = "single"),
                      alpha = 0.9, na.rm = TRUE) +
    ggplot2::geom_text(ggplot2::aes(label = paste0("n=", .data$n)),
                       position = ggplot2::position_dodge(width = 0.9),
                       vjust = -0.4, size = 3.5, na.rm = TRUE) +
    ggplot2::scale_fill_manual(values = c(Absent = "#95a5a6", Present = "#1abc9c"),
                               drop = FALSE) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::labs(
      title = "Theme-Metric Interaction",
      x = "Theme",
      y = paste("Mean", metric_col),
      fill = NULL
    )
}

#' @importFrom ggplot2 .data
NULL
