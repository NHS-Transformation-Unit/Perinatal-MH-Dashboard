
# Script for loading appropriate packages for the running of MHSDS processing scripts

packages <- c("here",
              "tidyverse",
              "odbc",
              "DBI",
              "purrr",
              "tidyr",
              "stringr",
              "dplyr")

lapply(packages, library, character.only=TRUE)
