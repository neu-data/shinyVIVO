# Neudata brand theme for Shiny (bslib), from neu-data/shiny-app-template.
# The ggplot2 theme and scales live in the package (theme_neudata()).

neudata_cols <- c(
  teal       = "#055F56",
  blue       = "#0B376C",
  navy       = "#04242F",
  teal_light = "#5FA39B",
  blue_light = "#6C8DB8",
  grey       = "#8A99A3",
  mist       = "#EAF2F5"
)

neudata_bs_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = neudata_cols[["teal"]],
    secondary = neudata_cols[["blue"]],
    info = neudata_cols[["blue"]],
    success = neudata_cols[["teal"]],
    fg = "#1F2D33",
    bg = "#FFFFFF",
    base_font = bslib::font_collection("Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif"),
    heading_font = bslib::font_collection("Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif"),
    "navbar-bg" = neudata_cols[["navy"]],
    "link-color" = neudata_cols[["blue"]],
    "headings-color" = neudata_cols[["navy"]],
    "border-radius" = "0.5rem"
  )
}

# Navbar brand: logo + app name
neudata_brand <- function(app_name) {
  htmltools::tags$span(
    class = "neudata-brand",
    htmltools::tags$img(src = "neudata-logo.png", alt = "Neudata"),
    htmltools::tags$span(class = "neudata-app-name", app_name)
  )
}

neudata_footer <- function() {
  htmltools::tags$footer(
    class = "neudata-footer",
    htmltools::tags$span(
      htmltools::tags$strong("Neudata Consulting Ltd"), " · ",
      htmltools::tags$em("Insight. Impact. Innovation.")
    ),
    htmltools::tags$span(
      htmltools::tags$a(href = "https://www.neu-data.com", target = "_blank", "www.neu-data.com"),
      " · ",
      htmltools::tags$a(href = "mailto:contact@neu-data.com", "contact@neu-data.com")
    )
  )
}
