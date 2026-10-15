#' Sample mixed-methods dataset
#'
#' Ten short user-feedback comments with a behavioural metric (session
#' minutes), written so that `Frustration`, `Bug Report` and `Praise` are
#' easy for a model to pick up. Useful for trying out the app.
#'
#' @param path Optional file path. If given, the data is also written there
#'   as CSV.
#' @return A data frame with columns `user_id`, `text` and `metric`
#'   (invisibly if `path` is given).
#' @export
#' @examples
#' head(vivo_sample_data())
vivo_sample_data <- function(path = NULL) {
  df <- data.frame(
    user_id = paste0("USR-", 100 + 1:10),
    text = c(
      "The page completely locked up when I hit submit. It is full of bugs.",
      "This new update is fantastic! Saved me at least two hours of manual entry.",
      "I can't find the export setting anywhere. The navigation structure is garbage.",
      "The application crashed on step 3 and wiped out my unsaved changes.",
      "Extremely intuitive workflow. The interface looks incredibly polished and clean.",
      "System throws a database timeout warning every single time I upload a file.",
      "The load times are slightly slower today, but it is working as expected.",
      "I am thoroughly impressed by how quickly the support team patched this feature.",
      "It keeps rejecting my valid password. This interface is driving me crazy.",
      "Logged in to check my current monthly metrics dashboard and closed the tab."
    ),
    metric = c(42.5, 12.1, 38.4, 55.0, 8.4, 31.2, 18.5, 14.2, 49.3, 10.5),
    stringsAsFactors = FALSE
  )
  if (is.null(path)) return(df)
  utils::write.csv(df, path, row.names = FALSE)
  invisible(df)
}
