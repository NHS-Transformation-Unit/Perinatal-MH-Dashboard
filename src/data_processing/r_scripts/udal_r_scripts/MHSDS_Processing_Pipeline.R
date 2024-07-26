
# Script for running all processing scripts for the Perinatal Mental Health Dashboard pipeline

library(here)

## Loading necessary packages for processing scripts

source(paste0(here(),"/src/config/r_scripts/packages.R"))

## Remote access into the UDAL environment

source(paste0(here(),"/src/config/r_scripts/UDAL_connect.R"))

## Running of all processing scripts

source(paste0(here(),"/src/data_processing/r_scripts/udal_r_scripts/MHSDS_Q2_Processing.R"))    
source(paste0(here(),"/src/data_processing/r_scripts/udal_r_scripts/MHSDS_Q3_Processing.R"))
source(paste0(here(),"/src/data_processing/r_scripts/udal_r_scripts/MHSDS_Q4_Processing.R"))    
source(paste0(here(),"/src/data_processing/r_scripts/udal_r_scripts/MHSDS_Q5_Processing.R"))    

## Drop all temporary tables in UDAL

source(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/drop_temp_tables.sql"))
