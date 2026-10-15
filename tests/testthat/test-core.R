fake_coder <- function(text, themes, ...) {
  out <- stats::setNames(rep(FALSE, length(themes)), themes)
  if ("Bug Report" %in% themes) out[["Bug Report"]] <- grepl("crash|bug|timeout", text)
  if ("Praise" %in% themes) out[["Praise"]] <- grepl("fantastic|impressed|intuitive", text)
  out
}

test_that("parse_themes trims and drops blanks", {
  expect_equal(parse_themes(" A, B ,,A, C D "), c("A", "B", "C D"))
})

test_that("code_dataframe adds one logical column per theme", {
  df <- vivo_sample_data()
  calls <- 0
  res <- code_dataframe(df, "text", c("Bug Report", "Praise"),
                        coder = fake_coder, progress = function(i, n) calls <<- calls + 1)
  expect_equal(calls, nrow(df))
  expect_type(res[["Bug Report"]], "logical")
  expect_equal(sum(res[["Bug Report"]]), 3)
  expect_equal(sum(res$Praise), 3)
})

test_that("failed coding yields NA, not FALSE", {
  res <- code_dataframe(vivo_sample_data(), "text", "X",
                        coder = function(text, themes, ...) stats::setNames(NA, themes))
  expect_true(all(is.na(res$X)))
})

test_that("ollama_code_text returns NA when server unreachable", {
  out <- ollama_code_text("hello", c("A", "B"), url = "http://127.0.0.1:1", timeout = 2)
  expect_equal(out, c(A = NA, B = NA))
})

test_that("summary and plot handle a theme that is never present", {
  df <- code_dataframe(vivo_sample_data(), "text", c("Bug Report", "Nothing"),
                       coder = function(text, themes, ...) {
                         c(`Bug Report` = grepl("crash", text), Nothing = FALSE)
                       })
  s <- summarise_theme_metric(df, c("Bug Report", "Nothing"), "metric")
  expect_equal(nrow(s), 4)
  expect_equal(s$n[s$Theme == "Nothing" & s$State == "Present"], 0)
  expect_s3_class(plot_theme_metric(df, c("Bug Report", "Nothing"), "metric"), "ggplot")
})
