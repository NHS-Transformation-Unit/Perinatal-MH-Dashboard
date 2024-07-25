
# Script for loading appropriate packages for the running of MHSDS processing scripts

packages <- c("here",
              "tidyverse",
              "odbc",
              "DBI",
              "purrr",
              "tidyr",
              "stringr",
              "openxlsx",
              "readxl")

lapply(packages, library, character.only=TRUE)
