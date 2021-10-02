#' @importFrom rmarkdown render
#' @importFrom strex str_after_first str_after_last str_before_first
#' @title writeMDX
#' @description write and Rmarkdown (.Rmd) file to MDX (.mdx) format.
#' @param input Input file (.Rmd format).
#' @param config `list`. Configurable YAML fields to check for. Default is
#' config = list("date", "title", "featuredImage")
#' @examples
#' \dontrun{
#' # supposing you have a 'test.Rmd' file:
#' writeMDX("test.Rmd")
#' }
#' @export
writeMDX <- function(input,
                     config = list(
                       include = list("description", "title"),
                       exclude = list("author", "output")
                     )) {
  if (tools::file_ext(input) != "Rmd") stop("This only works with Rmarkdown files (.Rmd).")
  # if (tools::file_ext(output_file) != "mdx") stop("This only works with Mdx files (.mdx).")

  rmarkdown::render(input, mdx_format(cfig = config))
}
