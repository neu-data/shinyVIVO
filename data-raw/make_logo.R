# ---------------------------------------------------------------------------
# Builds the shinyVIVO hex logo and the pkgdown favicons.
#
# The motif is the app at work: an app window holding lines of text, two of
# them highlighted as coded themes, with coding stripes in the margin as in
# NVivo, and a pointer clicking (point-and-click, no code). The hex follows
# the Neudata sticker family shared with llmCoder and quant2qual: navy fill,
# teal border, white name, neu-data.com beneath.
#
# Run from the package root:  source("data-raw/make_logo.R")
# ---------------------------------------------------------------------------

library(grid)

navy <- "#04242F"
teal <- "#055F56"
teal_mid <- "#2E8B7F"
teal_light <- "#5FA39B"
seafoam <- "#9FD3CB"
blue <- "#6C8DB8"
grey <- "#C9D3D8"
white <- "#FFFFFF"

family <- if ("Segoe UI" %in% systemfonts::system_fonts()$family) "Segoe UI" else "sans"

hex_xy <- function(r, cx = 0.5, cy = 0.5) {
  a <- (seq(90, 390, by = 60)[1:6]) * pi / 180
  list(x = cx + r * cos(a) * (600 / 518), y = cy + r * sin(a))
}

draw_logo <- function() {
  grid.newpage()
  outer <- hex_xy(0.5)
  inner <- hex_xy(0.468)
  grid.polygon(outer$x, outer$y, gp = gpar(fill = teal, col = NA))
  grid.polygon(inner$x, inner$y, gp = gpar(fill = navy, col = NA))

  # --- app window
  wx <- 0.47
  wy <- 0.57
  ww <- 0.44
  wh <- 0.27
  grid.roundrect(x = wx, y = wy, width = ww, height = wh, r = unit(0.03, "npc"),
                 gp = gpar(fill = white, col = NA))
  # title bar with three dots
  bar_y <- wy + wh / 2 - 0.028
  grid.lines(c(wx - ww / 2 + 0.01, wx + ww / 2 - 0.01), c(bar_y - 0.026, bar_y - 0.026),
             gp = gpar(col = grey, lwd = 2))
  for (i in 0:2) {
    grid.circle(x = wx - ww / 2 + 0.035 + i * 0.03, y = bar_y, r = 0.0105,
                gp = gpar(fill = c(teal, teal_light, blue)[i + 1], col = NA))
  }

  # --- text lines; two carry a highlight (a coded theme)
  x0 <- wx - ww / 2 + 0.035
  line_y <- bar_y - 0.026 - c(0.04, 0.08, 0.12, 0.16)
  line_w <- c(0.29, 0.25, 0.30, 0.18)
  hl <- c(NA, seafoam, NA, teal_light)
  for (i in seq_along(line_y)) {
    if (!is.na(hl[i])) {
      grid.lines(c(x0 - 0.008, x0 + line_w[i] + 0.008), c(line_y[i], line_y[i]),
                 gp = gpar(col = hl[i], lwd = 17, lineend = "round"))
    }
    grid.lines(c(x0, x0 + line_w[i]), c(line_y[i], line_y[i]),
               gp = gpar(col = if (is.na(hl[i])) grey else navy, lwd = 6, lineend = "round"))
  }

  # --- coding stripes in the right margin, aligned with the coded lines
  sx <- wx + ww / 2 - 0.045
  grid.lines(c(sx, sx), c(line_y[2] + 0.02, line_y[2] - 0.02),
             gp = gpar(col = teal_mid, lwd = 8, lineend = "round"))
  grid.lines(c(sx, sx), c(line_y[4] + 0.02, line_y[4] - 0.02),
             gp = gpar(col = teal, lwd = 8, lineend = "round"))

  # --- pointer clicking the first highlight
  px <- 0.49
  py <- line_y[2] - 0.005
  arrow_x <- c(0, 0, 0.022, 0.034, 0.046, 0.034, 0.062)
  arrow_y <- c(0, -0.105, -0.078, -0.115, -0.108, -0.072, -0.072)
  grid.polygon(px + arrow_x * (600 / 518), py + arrow_y,
               gp = gpar(fill = navy, col = white, lwd = 3, linejoin = "round"))

  # --- name and address
  grid.text("shinyVIVO", x = 0.5, y = 0.285,
            gp = gpar(col = white, fontsize = 60, fontface = "bold", fontfamily = family))
  grid.text("neu-data.com", x = 0.5, y = 0.175,
            gp = gpar(col = seafoam, fontsize = 22, fontfamily = family))
}

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
ragg::agg_png("man/figures/logo.png", width = 518, height = 600, background = "transparent", res = 72)
draw_logo()
invisible(grDevices::dev.off())

svglite_ok <- requireNamespace("svglite", quietly = TRUE)
if (svglite_ok) {
  svglite::svglite("man/figures/logo.svg", width = 518 / 72, height = 600 / 72, bg = "transparent")
  draw_logo()
  invisible(grDevices::dev.off())
}

# Favicons, cut from the PNG with magick so they match it exactly.
dir.create("pkgdown/favicon", showWarnings = FALSE, recursive = TRUE)
logo <- magick::image_read("man/figures/logo.png")
square <- function(size) {
  img <- magick::image_resize(logo, paste0("x", size))
  magick::image_extent(img, paste0(size, "x", size), color = "none", gravity = "center")
}
magick::image_write(square(180), "pkgdown/favicon/apple-touch-icon.png", format = "png")
magick::image_write(square(96), "pkgdown/favicon/favicon-96x96.png", format = "png")
magick::image_write(square(192), "pkgdown/favicon/web-app-manifest-192x192.png", format = "png")
magick::image_write(square(512), "pkgdown/favicon/web-app-manifest-512x512.png", format = "png")
magick::image_write(magick::image_join(square(16), square(32), square(48)),
                    "pkgdown/favicon/favicon.ico", format = "ico")
b64 <- function(path) {
  raw <- readBin(path, "raw", file.info(path)$size)
  paste0("data:image/png;base64,", jsonlite::base64_enc(raw))
}
writeLines(sprintf(paste0(
  '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">',
  '<image width="96" height="96" href="%s"/></svg>'), b64("pkgdown/favicon/favicon-96x96.png")),
  "pkgdown/favicon/favicon.svg")
writeLines(c(
  "{",
  '  "name": "shinyVIVO",',
  '  "short_name": "shinyVIVO",',
  '  "icons": [',
  '    {"src": "/web-app-manifest-192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},',
  '    {"src": "/web-app-manifest-512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}',
  "  ],",
  '  "theme_color": "#04242F",',
  '  "background_color": "#04242F",',
  '  "display": "standalone"',
  "}"
), "pkgdown/favicon/site.webmanifest")
