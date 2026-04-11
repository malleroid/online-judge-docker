# Install R packages in dependency order with pinned versions
packages <- c(
  "cli"="3.6.4", "generics"="0.1.3", "glue"="1.8.0", "magrittr"="2.0.3",
  "fansi"="1.0.6", "utf8"="1.2.4", "R6"="2.6.1", "rlang"="1.1.6",
  "pkgconfig"="2.0.3", "withr"="3.0.2", "lifecycle"="1.0.4", "vctrs"="0.6.5",
  "pillar"="1.10.2", "tibble"="3.2.1", "tidyselect"="1.2.1", "dplyr"="1.1.4",
  "proxy"="0.4-27", "e1071"="1.7-16", "gtools"="3.9.5", "cpp11"="0.5.2",
  "timechange"="0.3.0", "lubridate"="1.9.4", "purrr"="1.0.4", "Rcpp"="1.0.14",
  "clipr"="0.8.0", "crayon"="1.5.3", "hms"="1.1.3", "bit"="4.6.0",
  "bit64"="4.6.0-1", "prettyunits"="1.2.0", "progress"="1.2.3", "tzdb"="0.5.0",
  "vroom"="1.6.5", "readr"="2.1.5", "sets"="1.0-25", "stringi"="1.8.7",
  "stringr"="1.5.1", "zeallot"="0.1.0", "collections"="0.3.7"
)

for (i in seq_along(packages)) {
  pkg <- names(packages)[i]
  ver <- packages[i]
  latest_info <- available.packages()
  if (pkg %in% rownames(latest_info) && latest_info[pkg, "Version"] == ver) {
    url <- paste0("https://cran.r-project.org/src/contrib/", pkg, "_", ver, ".tar.gz")
  } else {
    url <- paste0("https://cran.r-project.org/src/contrib/Archive/", pkg, "/", pkg, "_", ver, ".tar.gz")
  }
  cat("Installing", pkg, ver, "from", url, "\n")
  install.packages(url, repos=NULL, type="source", ask=FALSE)
}
