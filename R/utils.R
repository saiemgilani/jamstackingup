dir_copy_to <- function(pkg, from, to, overwrite = TRUE) {
  stopifnot(length(to) == 1)
  new_path <- function(path) {
    path_abs(path_rel(path, start = from), start = to)
  }

  contents <- dir_ls(from, recurse = TRUE)
  is_dir <- fs::is_dir(contents)

  # First create directories
  dir_create(to)
  dirs <- contents[is_dir]
  dir_create(new_path(dirs))

  # Then copy files
  file_copy_to(pkg, contents[!is_dir],
               to_dir = to,
               from_dir = from,
               overwrite = overwrite
  )
}

# Would be better to base on top of data structure that provides both
# files and root directory to use for printing
file_copy_to <- function(pkg,
                         from_paths,
                         to_dir = pkg$dst_path,
                         from_dir = path_common(from_paths),
                         overwrite = TRUE) {

  if (length(from_paths) == 0) {
    return()
  }

  from_rel <- path_rel(from_paths, from_dir)
  to_paths <- path_abs(from_rel, to_dir)

  # Ensure all the "to" directories exist
  dirs_to_paths <- unique(fs::path_dir(to_paths))
  dir_create(dirs_to_paths)

  eq <- purrr::map2_lgl(from_paths, to_paths, file_equal)
  if (any(!eq)) {
    cat_line(
      "Copying ", src_path(path_rel(from_paths[!eq], pkg$src_path)),
      " to ", dst_path(path_rel(to_paths[!eq], pkg$dst_path))
    )
  }

  file_copy(from_paths[!eq], to_paths[!eq], overwrite = overwrite)
}

#' @title Strip white space
#' @description Strip white space (spaces only) from the beginning and end of a character.
#' @param x character to strip white space from
#' @return a character with white space stripped
stripWhite <- function(x) {
	sub("([ ]+$)", "", sub("(^[ ]+)", "", x, perl=TRUE), perl=TRUE)
}

#' @title Extract Rd tags
#' @description Extract Rd tags from Rd object
#' @param Rd Object of class `Rd`
#' @return character vector with Rd tags
RdTags = function(Rd) {
  res <- sapply(Rd, attr, "Rd_tag")
  if (!length(res))
    res <- character()
  res
}

#' @title Make first letter capital
#' @description Capitalize the first letter of every new word. Very simplistic approach.
#' @param x Character string
#' @return character vector with capitalized first letters
simpleCap <- function(x) {
	s <- strsplit(x, " ")[[1]]
	paste(toupper(substring(s, 1,1)), substring(s, 2), sep="", collapse=" ")
}

#' @title Make first letter capital
#' @description Capitalize the first letter of every new word. Very simplistic approach.
#' @param filebase The file path to the database (`.rdb` file), with no extension
#' @param key Keys to fetch
#' @return character vector with capitalized first letters
fetchRdDB <- function (filebase, key = NULL) {
  fun <- function(db) {
    vals <- db$vals
    vars <- db$vars
    datafile <- db$datafile
    compressed <- db$compressed
    envhook <- db$envhook
    fetch <- function(key) lazyLoadDBfetch(vals[key][[1L]],
        datafile, compressed, envhook)
    if (length(key)) {
      if (!key %in% vars)
        stop(gettextf("No help on %s found in RdDB %s",
            sQuote(key), sQuote(filebase)), domain = NA)
      fetch(key)
    }
    else {
      res <- lapply(vars, fetch)
      names(res) <- vars
      res
    }
  }
  res <- lazyLoadDBexec(filebase, fun)
  if (length(key))
    res
  else invisible(res)
}

#' @title Trim
#' @description Trim whitespaces and newlines before and after
#' @param x String to trim
#' @return character vector with stripped whitespaces
trim <- function(x) {
  gsub("^\\s+|\\s+$", "", x)
}

node_available <- function(){
  test <- suppressWarnings(
    system(
      "npm -v",
      ignore.stdout = TRUE,
      ignore.stderr = TRUE
    )
  )
  if(test!=0){
    message("Error launching npm")
  }
  test <- suppressWarnings(
    system(
      "node -v",
      ignore.stdout = TRUE,
      ignore.stderr = TRUE
    )
  )

  if(test!=0){
    message("Error launching Node")
  }

}


# These functions are from the rmarkdown R package (https://github.com/rstudio/rmarkdown)
# they are included here as dependencies for writeMDX()

# read and write UTF-8
read_utf8 <- function(file, encoding = 'UTF-8') {
  if (inherits(file, 'connection')) con <- file else {
    con <- base::file(file, encoding = encoding); on.exit(close(con), add = TRUE)
  }
  enc2utf8(readLines(con, warn = FALSE))
}

write_utf8 <- function (text, con, ...) {
  opts <- options(encoding = "native.enc"); on.exit(options(opts), add = TRUE)
  writeLines(enc2utf8(text), con, ..., useBytes = TRUE)
}

#-------------------------------------------------------
# blank check
is_blank <- function (x){
  if (length(x))
    all(grepl("^\\s*$", x))
  else TRUE
}

#------------------------------------------------------
# preserve YAML
partition_yaml_front_matter <- function(input_lines){
  validate_front_matter <- function(delimiters) {
    if (length(delimiters) >= 2 && (delimiters[2] - delimiters[1] >
                                    1) && grepl("^---\\s*$", input_lines[delimiters[1]])) {
      if (delimiters[1] == 1)
        TRUE
      else is_blank(input_lines[1:delimiters[1] - 1])
    }
    else {
      FALSE
    }
  }
  delimiters <- grep("^(---|\\.\\.\\.)\\s*$", input_lines)
  if (validate_front_matter(delimiters)) {
    front_matter <- input_lines[(delimiters[1]):(delimiters[2])]
    input_body <- c()
    if (delimiters[1] > 1)
      input_body <- c(input_body, input_lines[1:delimiters[1] -
                                                1])
    if (delimiters[2] < length(input_lines))
      input_body <- c(input_body, input_lines[-(1:delimiters[2])])
    list(front_matter = front_matter, body = input_body)
  }
  else {
    list(front_matter = NULL, body = input_lines)
  }
}
