#' Generate jamstack data structure
#'
#' You will generally not need to use this unless you need a custom site
#' design and you're writing your own equivalent of [build_site()].
#'
#' @param pkg Path to package.
#' @param override An optional named list used to temporarily override
#'   values in `_jamstack.yml`
#' @export
as_jamstack <- function(pkg = ".", override = list()) {
  if (is_jamstack(pkg)) {
    return(pkg)
  }

  if (!dir_exists(pkg)) {
    stop("`pkg` is not an existing directory", call. = FALSE)
  }

  desc <- read_desc(pkg)
  meta <- read_meta(pkg)
  meta <- utils::modifyList(meta, override)

  template_config <- find_template_config(meta[["template"]]$package)
  meta <- modify_list(template_config, meta)

  # Ensure the URL has no trailing slash
  if (!is.null(meta$url)) {
    meta$url <- sub("/$", "", meta$url)
  }

  package <- desc$get("Package")[[1]]
  version <- desc$get_field("Version")

  development <- meta_development(meta, version)

  if (is.null(meta$destination)) {
    dst_path <- path(pkg, "docs")
  } else {
    dst_path <- path_abs(meta$destination, start = pkg)
  }

  if (development$in_dev) {
    dst_path <- path(dst_path, development$destination)
  }



  install_metadata <- meta$deploy$install_metadata %||% FALSE

  pkg_list <- list(
    package = package,
    version = version,

    src_path = path_abs(pkg),
    dst_path = path_abs(dst_path),
    install_metadata = install_metadata,

    desc = desc,
    meta = meta,
    figures = meta_figures(meta),
    repo = package_repo(desc, meta),

    development = development,
    topics = package_topics(pkg, package),
    tutorials = package_tutorials(pkg, meta),
    vignettes = package_vignettes(pkg)
  )

  pkg_list$bs_version <- get_bs_version(pkg_list)
  pkg_list$has_logo <- has_logo(pkg_list)
  pkg_list$prefix <- ""
  if (pkg_list$development$in_dev) {
    pkg_list$prefix <- paste0(
      meta_development(pkg_list$meta, pkg_list$version)$destination,
      "/"
    )
  }

  structure(
    pkg_list,
    class = "jamstack"
  )
}

is_jamstack <- function(x) inherits(x, "jamstack")

read_desc <- function(path = ".") {
  path <- path(path, "DESCRIPTION")
  if (!file_exists(path)) {
    stop("Can't find DESCRIPTION", call. = FALSE)
  }
  desc::description$new(path)
}

# Metadata ----------------------------------------------------------------

jamstack_config_path <- function(path) {
  path_first_existing(
    path,
    c("_jamstack.yml",
      "_jamstack.yaml",
      "jamstack/_jamstack.yml",
      "inst/_jamstack.yml"
    )
  )
}

read_meta <- function(path) {
  path <- jamstack_config_path(path)

  if (is.null(path)) {
    yaml <- list()
  } else {
    yaml <- yaml::yaml.load_file(path) %||% list()
  }

  yaml
}
