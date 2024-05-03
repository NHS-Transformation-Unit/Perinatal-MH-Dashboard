
# Script for loading appropriate packages for the running of MHSDS processing scripts

packages <- c("here",
             "purrr",
             "tidyverse",
             "tidyr",
             "stringr",
             "openxlsx",
             "readxl",
             "dplyr")

lapply(packages, library, character.only=TRUE)