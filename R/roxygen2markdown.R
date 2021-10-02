#' @export
#' @name roxygen2markdown
#' @title Rd file to markdown
#' @description This function converts an Rd file into markdown format.
#' @param rdfile Filepath to an .Rd file or an \code{Rd} object to parse.
#' @param outfile Filepath to output file (markdown file).
#' @param append If outfile exists, append to existing content.
#' @return Parsed Rd as named list
#' @examples
#' ## give a markdown source file
#' rdfile = "~/git/MyPackage/man/myfun.Rd"
#' ## specify, where markdown shall be stored
#' outfile = "/var/www/html/R_Web_app/md/myfun.md"
#' ## create markdown
#' ## roxygen2markdown(rdfile = rdfile, outfile = outfile)
roxygen2markdown <- function(
  rdfile="man/cfbd_betting.Rd",
  outfile="md/cfbd_betting.md",
  append=FALSE) {
	# VALIDATION
	append <- as.logical(append)
	if (length(append) != 1) stop("Please provide append as single logical value.")
	if (is.character(rdfile)) if ((length(rdfile) != 1)) stop("Please provide rdfile as single character value (file path with extension).")
	outfile <- as.character(outfile)
	if (length(outfile) != 1) stop("Please provide outfile as single character value (file path with extension).")
	if (append) {
		if (!file.exists(outfile)) stop("If append=TRUE, the outfile must exists already.")
	}
	type <- ifelse(inherits(rdfile, "Rd"), "bin", "src")

	# Global definitions for file parsing
	file.ext <- "md"
	section <- "#"
	yaml.sep <- "\n"
	subsection <- "##"
	section.sep <- "\n\n"
	run.examples <- FALSE


	# Parse rd file
	if (type == "src") {
		rd <- tools::parse_Rd(rdfile,verbose = TRUE,permissive = TRUE)
	} else {
		if (inherits(rdfile, "list"))  {
			rdfile = rdfile[[1]]
		}
		rd <- rdfile
		class(rd) <- "Rd"
	}
	# takes as input an "Rd" object
	results <- parseRd(rd)
  rdtags <- RdTags(rd)

	if (all(c("name","title") %in% names(results))) {
		filename <- paste0(results$name, ".", file.ext)
		results$filename <- filename
		results$directory <- dirname(outfile)

		# INIT file if required
		cat("", file=outfile, append=append)

		# YAML HEADING
		cat(paste0("---"), yaml.sep, file=outfile, append=TRUE, sep="")

		cat(glue::glue("title: {results$name}"), yaml.sep, file=outfile, append=TRUE, sep="")
		cat(glue::glue("description: {results$description}"), yaml.sep, file=outfile, append=TRUE, sep="")
		cat(glue::glue("featured: true"), yaml.sep, file=outfile, append=TRUE, sep="")
		cat(glue::glue("topics: {ifelse(!is.na(results$keyword),results$keyword,'null')}"), yaml.sep, file=outfile, append=TRUE, sep="")
		cat(glue::glue("recommended: null"), yaml.sep, file=outfile, append=TRUE, sep="")
		cat(paste0("---"), yaml.sep, file=outfile, append=TRUE, sep="")
		# HEADING
		cat(paste0(section, " `", results$name, "`"), section.sep, file=outfile, append=TRUE, sep="")
		# title as normal text
		cat(paste0(results$title, section.sep), file=outfile, append=TRUE, sep="\n")

		for (i in sections.print[!sections.print %in% c("name","title")]) {
			if (i %in% names(results)) {
			  cat(paste(subsection, simpleCap(i)), section.sep, file=outfile, append=TRUE, sep="")
				if (i %in% c("examples", "usage")) {
				  cat("```r", paste(results[[i]], collapse="\n"), "```", file=outfile, append=TRUE, sep="\n")
				} else if (i == "arguments") {
					cat("Argument |Description\n", file=outfile, append=TRUE)
					cat("-------- |------------\n", file=outfile, append=TRUE)
					cat(paste0("`", names(results[[i]]), "`", " | ", results[[i]], collapse="\n"), file=outfile, append=TRUE, sep="\n")
				} else if (i == "value") {
				  cat("Column |Description\n", file=outfile, append=TRUE)
				  cat("------- |------------\n", file=outfile, append=TRUE)
				  cat(paste0("`", names(results[[i]]), "`", " | ", results[[i]], collapse="\n"), file=outfile, append=TRUE, sep="\n")
				} else {
					cat(paste0(results[[i]], collapse="\n"), file=outfile, append=TRUE, sep="\n")
				}
			  cat(section.sep, file=outfile, append=TRUE)
			}
		}
	} else {
		warning("name and title are required. Not creating markdown file")
	}

	results
}
