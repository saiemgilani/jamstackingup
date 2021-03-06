
#' @title Create jamstack site folder
#' @description Shell script to build the website directory
#' @param pkg_dir Directory of package
#' @param site_dir Directory to clone the website template in
#' @param template site template (default: "nextjs-ts")
#' @param rebuild Logical. Remove and rebuild website
#'
#' @export
use_jamstackup_site <- function(pkg_dir = ".",
                                site_dir = 'website',
                                template = "nextjs-ts",
                                rebuild = FALSE) {
  if(rebuild == TRUE){
    rm(glue::glue("{site_dir}"))
    system(glue::glue("npx create-next-app --example https://github.com/saiemgilani/nextjs-ts-starter website"))

  }
  if(template == "nextjs-ts"){
    if(!dir.exists(glue::glue("{site_dir}"))){
      system(glue::glue("npx create-next-app --example https://github.com/saiemgilani/nextjs-ts-starter website"))
    }

    build_reference(site_dir)
    build_articles(site_dir)

    fs::file_copy(path = glue::glue('logo.png'),
                  new_path = glue::glue('{site_dir}/public/logo/logo.png'),overwrite=TRUE)
    preview_site(site_dir)
  }
}


build_reference <- function(site_dir = 'website'){

  rd_list <- list.files(path = glue::glue('man'))
  ifelse(!dir.exists(file.path(glue::glue("{site_dir}/references"))), dir.create(file.path(glue::glue("{site_dir}/references"))), FALSE)
  rds <- purrr::map(rd_list[stringr::str_detect(rd_list,'.Rd')] , function(x){
    jamstackingup::roxygen2markdown(rdfile = glue::glue('man/{x}'), outfile = glue::glue('{site_dir}/references/{gsub(".Rd",".md", x)}'))
  })

}

build_articles <- function(site_dir = 'website'){

  ifelse(!dir.exists(file.path(glue::glue("{site_dir}/articles"))), dir.create(file.path(glue::glue("{site_dir}/articles"))), FALSE)

  vig_lst <- list.files(path = glue::glue('vignettes'))
  vigs <- purrr::map(vig_lst[stringr::str_detect(vig_lst,'.Rmd')] , function(x){
    rmarkdown::render(input = glue::glue('vignettes/{x}'), output_format = rmarkdown::html_document(keep_md = TRUE))
  })
  vig_lst <- list.files(path = glue::glue('vignettes'))
  vigs_md <- purrr::map(vig_lst , function(x){
    if(tools::file_ext(glue::glue("{x}"))== "md"){
      fs::file_copy(path = glue::glue('vignettes/{x}'),
                    new_path = glue::glue('{site_dir}/articles/{x}'),overwrite=TRUE)
    }
  })
  vig_lst <- list.files(path = glue::glue('vignettes'))

  vigs_rm <- purrr::map(vig_lst , function(x){
    if(tools::file_ext(glue::glue("{x}"))!= "Rmd"){
      unlink(glue::glue("vignettes/{x}"))
    }
  })
}


preview_site <- function(site_dir = 'website'){
  shell(glue::glue('cd {site_dir} && pwd && npm run dev'))
}
