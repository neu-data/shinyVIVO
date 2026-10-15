#' List models available on an Ollama server
#'
#' @param url Base URL of the Ollama server.
#' @return A character vector of model names (empty if the server is
#'   unreachable).
#' @export
#' @examples
#' \dontrun{
#' ollama_models()
#' }
ollama_models <- function(url = "http://localhost:11434") {
  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_url_path("/api/tags") |>
      httr2::req_timeout(5) |>
      httr2::req_perform()
    models <- httr2::resp_body_json(resp)$models
    vapply(models, function(m) m$name, character(1))
  }, error = function(e) character(0))
}

#' Code a single text against a set of themes with a local Ollama model
#'
#' Sends the text to Ollama with a JSON schema that forces one boolean per
#' theme, so the model output can be parsed reliably.
#'
#' @param text A single string to code.
#' @param themes Character vector of theme names.
#' @param model Name of an Ollama model (e.g. `"llama3"`).
#' @param url Base URL of the Ollama server.
#' @param timeout Request timeout in seconds.
#' @return A named logical vector, one element per theme. All `NA` if the
#'   request or parsing fails.
#' @export
#' @examples
#' \dontrun{
#' ollama_code_text("The app crashed and I lost my work.",
#'                  c("Frustration", "Bug Report", "Praise"))
#' }
ollama_code_text <- function(text, themes, model = "llama3",
                             url = "http://localhost:11434", timeout = 120) {
  failed <- stats::setNames(rep(NA, length(themes)), themes)
  if (is.na(text) || !nzchar(trimws(text))) return(failed)

  props <- stats::setNames(
    rep(list(list(type = "boolean")), length(themes)),
    themes
  )
  schema <- list(type = "object", properties = props, required = as.list(themes))

  prompt <- paste0(
    "You are a qualitative researcher coding interview data.\n",
    "For each theme below, decide whether it is present in the text.\n",
    "Themes: ", paste(themes, collapse = "; "), "\n\n",
    "Text:\n\"\"\"\n", text, "\n\"\"\"\n\n",
    "Answer with a JSON object mapping each theme to true or false."
  )

  tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_url_path("/api/generate") |>
      httr2::req_body_json(list(
        model   = model,
        prompt  = prompt,
        stream  = FALSE,
        format  = schema,
        options = list(temperature = 0)
      )) |>
      httr2::req_timeout(timeout) |>
      httr2::req_perform()
    parsed <- jsonlite::fromJSON(httr2::resp_body_json(resp)$response)
    out <- failed
    for (th in intersect(themes, names(parsed))) {
      out[[th]] <- as.logical(parsed[[th]])[1]
    }
    out
  }, error = function(e) failed)
}

#' Code every row of a data frame
#'
#' @param df A data frame.
#' @param text_col Name of the column holding the text to code.
#' @param themes Character vector of theme names. One logical column is
#'   added per theme (`NA` where coding failed).
#' @param model,url Passed to [ollama_code_text()].
#' @param progress Optional function called as `progress(i, n)` after each
#'   row, e.g. to drive a progress bar.
#' @param coder The function used to code a single text. Override for
#'   testing or to plug in another backend.
#' @return `df` with one added logical column per theme.
#' @export
code_dataframe <- function(df, text_col, themes, model = "llama3",
                           url = "http://localhost:11434",
                           progress = NULL, coder = ollama_code_text) {
  stopifnot(text_col %in% names(df), length(themes) > 0)
  n <- nrow(df)
  codes <- matrix(NA, nrow = n, ncol = length(themes),
                  dimnames = list(NULL, themes))
  for (i in seq_len(n)) {
    codes[i, ] <- coder(as.character(df[[text_col]][i]), themes,
                        model = model, url = url)[themes]
    if (!is.null(progress)) progress(i, n)
  }
  for (th in themes) df[[th]] <- codes[, th]
  df
}

#' Parse a comma-separated theme string
#'
#' @param x A string such as `"Frustration, Bug Report, Praise"`.
#' @return A character vector of unique, non-empty, trimmed theme names.
#' @export
parse_themes <- function(x) {
  th <- trimws(unlist(strsplit(x, ",", fixed = TRUE)))
  unique(th[nzchar(th)])
}
