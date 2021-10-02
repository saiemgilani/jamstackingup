#' Build home section
#'
#' This function generates the home page, converts `.md` files found in the
#' package root (and in `.github/`), and builds an authors page from
#' `DESCRIPTION` and `inst/CITATION` (if present).
#' @param pkg Path to package.
#' @param override An optional named list used to temporarily override
#'   values in `_jamstack.yml`
#' @param quiet Set to `FALSE` to display output of knitr and
#'   pandoc. This is useful when debugging.
#' @param lazy If `TRUE`, will only re-build article if input file has been
#'   modified more recently than the output file.
#' @param preview If `TRUE`, or `is.na(preview) && interactive()`, will preview
#'   freshly generated section in browser.
#' @export
build_home <- function(pkg = ".",
                       override = list(),
                       preview = NA,
                       quiet = TRUE) {

  pkg <- section_init(pkg, depth = 0L, override = override)
  rule("Building home")
  dir_create(pkg$dst_path)

  if (has_citation(pkg$src_path)) {
    build_citation_authors(pkg)
  } else {
    build_authors(pkg)
  }
  build_home_md(pkg)
  build_home_index(pkg, quiet = quiet)

  preview_site(pkg, "/", preview = preview)
}
