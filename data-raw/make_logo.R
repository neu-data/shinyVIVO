# ---------------------------------------------------------------------------
# Builds the shinyVIVO hex logo and the pkgdown favicons.
#
# A participant's words chalked on a blackboard between quote marks, with
# coloured chalk highlights and code brackets in the margin: in vivo coding,
# where codes come from people's own words. Everything is drawn with jittered
# strokes so it reads as hand-made chalk rather than vector art.
#
# Fonts are Windows system fonts (Gill Sans MT, Segoe Print, Century
# Schoolbook); other systems fall back to sans/serif.
#
# Run from the package root:  source("data-raw/make_logo.R")
# ---------------------------------------------------------------------------

library(grid)

W <- 518; H <- 600; CX <- W / 2; CY <- H / 2
u <- function(v) unit(v, "native")

fams <- systemfonts::system_fonts()$family
font <- function(want, fallback) if (want %in% fams) want else fallback
f_name <- font("Gill Sans MT", "sans")
f_hand <- font("Segoe Print", "sans")
f_quote <- font("Century Schoolbook", "serif")

chalk_white <- "#F4F1E8"
yellow <- "#F7D23E"
pink <- "#F28BA8"
mint <- "#8FD9B6"

hex <- function(r) {
  a <- seq(90, 390, by = 60)[1:6] * pi / 180
  list(x = CX + r * cos(a), y = CY + r * sin(a))
}
hex_grob <- function(r, ...) polygonGrob(u(hex(r)$x), u(hex(r)$y), ...)

# --- hand-drawn strokes ------------------------------------------------------
densify <- function(x, y, step = 3) {
  ox <- x[1]; oy <- y[1]
  for (i in seq_along(x)[-1]) {
    n <- max(2, ceiling(sqrt((x[i] - x[i - 1])^2 + (y[i] - y[i - 1])^2) / step))
    ox <- c(ox, seq(x[i - 1], x[i], length.out = n)[-1])
    oy <- c(oy, seq(y[i - 1], y[i], length.out = n)[-1])
  }
  list(x = ox, y = oy)
}
wobble <- function(p, amt) {
  n <- length(p$x)
  smooth <- function() stats::filter(rnorm(n + 10, 0, amt), rep(1 / 6, 6), circular = TRUE)[1:n]
  list(x = p$x + smooth(), y = p$y + smooth())
}
stroke <- function(x, y, col, lwd = 3, passes = 2, amt = 1.2, close = FALSE, alpha = 0.9) {
  if (close) { x <- c(x, x[1]); y <- c(y, y[1]) }
  p <- densify(x, y)
  for (i in seq_len(passes)) {
    q <- wobble(p, amt)
    grid.lines(u(q$x), u(q$y), gp = gpar(col = col, lwd = lwd * runif(1, 0.7, 1.1), alpha = alpha,
                                         lineend = "round", linejoin = "round"))
  }
}
fill_wobbly <- function(x, y, col, alpha = 0.95, layers = 2, amt = 0.6) {
  p <- densify(x, y, 4)
  for (i in seq_len(layers)) {
    q <- wobble(p, amt)
    grid.polygon(u(q$x), u(q$y), gp = gpar(fill = col, col = NA, alpha = alpha / layers * 1.6))
  }
}
# Cursive: a prolate cycloid makes the loops; each loop gets a letter height
# (x-height, or a taller ascender), and words are separated by gaps.
scribble <- function(x0, x1, y0, size = 8, col = chalk_white, lwd = 2.4) {
  x <- x0
  w <- 0.62
  while (x < x1 - 12) {
    wl <- min(runif(1, 40, 95), (x1 - x) / 0.55)
    t <- seq(0, wl, by = 0.35)
    cyc <- floor(w * t / (2 * pi))
    h <- sample(c(1, 1, 1, 1, 2.2, 1.3), max(cyc) + 1, TRUE)[cyc + 1]
    xx <- x + 0.55 * t - 3.1 * sin(w * t)
    yy <- y0 + size * 0.38 * (1 - cos(w * t)) * h + 0.6 * sin(t / 7)
    grid.lines(u(xx), u(yy), gp = gpar(col = col, lwd = lwd, alpha = 0.88,
                                       lineend = "round", linejoin = "round"))
    x <- x + 0.55 * wl + runif(1, 8, 13)
  }
}

draw_logo <- function() {
  set.seed(31)
  grid.newpage()
  pushViewport(viewport(xscale = c(0, W), yscale = c(0, H)))

  # wooden frame, then the board clipped to the inner hex
  grid.draw(hex_grob(299, gp = gpar(fill = "#7A5230", col = NA)))
  pushViewport(viewport(xscale = c(0, W), yscale = c(0, H), clip = hex_grob(278)))
  grid.rect(gp = gpar(fill = radialGradient(c("#2F4A3E", "#1E322A"), cx1 = 0.5, cy1 = 0.55, r2 = 0.8),
                      col = NA))
  n <- 1800  # chalk dust
  grid.points(u(runif(n, 0, W)), u(runif(n, 0, H)), pch = 16, size = unit(runif(n, 0.3, 1.6), "pt"),
              gp = gpar(col = "#FFFFFF", alpha = runif(n, 0.02, 0.09)))
  for (i in 1:5) {  # eraser smudges
    sx <- runif(1, 60, 380); sy <- runif(1, 170, 500)
    for (k in 1:25) {
      grid.lines(u(sx + c(0, runif(1, 60, 140))), u(rep(sy + rnorm(1, 0, 12), 2) + c(0, rnorm(1, 0, 8))),
                 gp = gpar(col = "#FFFFFF", lwd = runif(1, 4, 10), alpha = 0.012, lineend = "round"))
    }
  }

  # the quote, with chalk highlights on the coded passages
  grid.text("“", x = u(118), y = u(452),
            gp = gpar(col = chalk_white, fontsize = 90, fontfamily = f_quote, alpha = 0.8))
  set.seed(7)
  ys <- c(420, 388, 356, 324, 292)
  ends <- c(396, 368, 404, 340, 262)
  hl <- c(NA, yellow, NA, pink, mint)
  for (i in seq_along(ys)) {
    if (!is.na(hl[i])) {
      for (k in 1:5) {
        grid.lines(u(c(132, ends[i] + 4) + rnorm(2, 0, 2)), u(rep(ys[i] + 3, 2) + rnorm(2, 0, 2.5)),
                   gp = gpar(col = hl[i], lwd = 14, alpha = 0.22, lineend = "round"))
      }
    }
    scribble(140, ends[i], ys[i] - 3)
  }
  grid.text("”", x = u(296), y = u(276),
            gp = gpar(col = chalk_white, fontsize = 90, fontfamily = f_quote, alpha = 0.8))

  # code brackets in the margin
  for (b in list(list(398, 378, yellow), list(334, 282, pink))) {
    stroke(c(424, 432, 432, 424), c(b[[1]], b[[1]], b[[2]], b[[2]]), col = b[[3]],
           lwd = 3, passes = 3, amt = 0.9, alpha = 0.55)
  }

  # stick of chalk on the ledge
  fill_wobbly(c(318, 396, 402, 324), c(232, 254, 238, 216), "#F7F4EC")

  # name, tagline and address
  grid.text("shinyVIVO", x = u(CX), y = u(156),
            gp = gpar(col = chalk_white, fontsize = 60, fontfamily = f_name))
  grid.text("in vivo coding", x = u(CX), y = u(112),
            gp = gpar(col = yellow, fontsize = 18, fontfamily = f_hand))
  f <- 0.64; off <- 16  # along the lower-right edge
  grid.text("neu-data.com", x = u(CX + f * 239 - 0.5 * off), y = u(CY - 276 + f * 138 + 0.866 * off),
            rot = 30, gp = gpar(col = "#CFC7B0", fontsize = 13, fontfamily = f_name))
  popViewport()

  # a thin dark line where the frame meets the board
  edge <- hex(279)
  stroke(edge$x, edge$y, col = "#1A120B", lwd = 1.6, passes = 1, amt = 0.4, close = TRUE, alpha = 0.6)
  popViewport()
}

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
ragg::agg_png("man/figures/logo.png", width = W, height = H, background = "transparent", res = 72)
draw_logo()
invisible(grDevices::dev.off())

# No SVG: it would carry the Windows font names and thousands of chalk-dust
# points, and pkgdown prefers an SVG logo when one exists.

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
  '  "theme_color": "#1E322A",',
  '  "background_color": "#1E322A",',
  '  "display": "standalone"',
  "}"
), "pkgdown/favicon/site.webmanifest")
