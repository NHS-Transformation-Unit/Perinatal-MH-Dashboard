
# Script for running all processing scripts for the Perinatal Mental Health Dashboard pipeline

library(here)

## Loading necessary packages for processing scripts

source(paste0(here(),"/src/config/r_scripts/packages.R"))

## Running of all processing scripts

source(paste0(here(),"/src/data_processing/r_scripts/MHSDS_Q1_Processing.R"))
source(paste0(here(),"/src/data_processing/r_scripts/MHSDS_Q2_Processing.R"))
source(paste0(here(),"/src/data_processing/r_scripts/MHSDS_Q3_Processing.R"))
source(paste0(here(),"/src/data_processing/r_scripts/MHSDS_Q4_Processing.R"))
source(paste0(here(),"/src/data_processing/r_scripts/MHSDS_Q5_Processing.R"))
