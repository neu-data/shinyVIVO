#' Launch the shinyVIVO workbench
#'
#' Opens the point-and-click app for uploading mixed-methods data, coding
#' text with a local Ollama model, and plotting codes against metrics.
#'
#' @param ... Passed to [shiny::runApp()] (e.g. `port`, `launch.browser`).
#' @return Called for its side effect of running the app.
#' @export
#' @importFrom bslib bs_theme
#' @importFrom DT DTOutput
#' @importFrom readxl read_excel
#' @examples
#' \dontrun{
#' shinyVIVO::launch_app()
#' }
launch_app <- function(...) {
  app_dir <- system.file("shiny-apps", "shinyVIVO", package = "shinyVIVO")
  if (app_dir == "") {
    stop("Could not find the shinyVIVO app directory. Try reinstalling the package.",
         call. = FALSE)
  }
  shiny::runApp(app_dir, display.mode = "normal", ...)
}
