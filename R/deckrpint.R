# Export Quarto/revealjs slides to PDF using Decktape instead of
# pagedown::chrome_print(). chrome_print() renders a single static
# snapshot of the page, and reveal.js only eagerly loads images
# (<img data-src="...">) for slides near the current one; slides far
# from the start (or images inside them) were rendering blank in the
# PDF. Decktape drives a real reveal.js "print" pass, navigating
# through every slide and waiting for each one (including lazy images)
# to finish loading before capturing it, which produces a faithful PDF.
#
# One-time setup (already done on this machine):
#   brew install node
#   npm install decktape --no-save
#   npx puppeteer browsers install chrome   # or point to a system Chrome
#     (if the bundled Chromium download is unavailable/corrupted, decktape
#     can also be pointed at an existing Google Chrome install with
#     --chrome-path "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

decktape_chrome_path <- "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

file_url <- function(html_path) {
  paste0("file://", normalizePath(html_path))
}

#' Replace non-breaking spaces (U+00A0) in an HTML file with regular spaces.
#'
#' Quarto/pandoc's `smart` extension inserts U+00A0 after certain
#' abbreviations (e.g. "f.", "m.", "adj.") to avoid awkward line breaks.
#' Chrome renders this fine, but the font subset decktape embeds when
#' printing to PDF sometimes lacks a usable glyph for it, so Acrobat (unlike
#' Chrome's own PDF viewer) shows a placeholder box instead of a space.
remove_nbsp <- function(html_path) {
  html <- readLines(html_path, warn = FALSE, encoding = "UTF-8")
  html <- gsub("\u00a0", " ", html, fixed = TRUE)
  writeLines(html, html_path, useBytes = TRUE)
  invisible(html_path)
}

decktape_print <- function(html_path, pdf_path, chrome_path = decktape_chrome_path) {
  remove_nbsp(html_path)

  args <- c(
    "decktape",
    "reveal",
    if (!is.null(chrome_path)) c("--chrome-path", shQuote(chrome_path)),
    shQuote(file_url(html_path)),
    shQuote(pdf_path)
  )
  status <- system2("npx", args = args)
  if (status != 0) {
    stop("decktape failed with status ", status, " for ", html_path)
  }
  invisible(pdf_path)
}


quarto::quarto_render("index.qmd")
decktape_print(
  "index.html",
  "index.pdf"
)
