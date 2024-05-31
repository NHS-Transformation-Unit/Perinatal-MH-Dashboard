# The MHSDS Pipeline

## Introduction
There are several different extracts from the Mental Health Services Data Set which are required to recreate the Perinatal MH Dashboard. Within this repository are seven individual scripts which can be ran on the National Commissioning Data Repository (NCDR) to create the required seven data extracts for this dashboard - these scripts are detailed within the [MHSDS SQL Scripts](#-MHSDS-SQL-Scripts) section of this documentation. Similarly, the R scripts used to process the seven data extracts into our 13 resultant data sets for the Excel dashboard are detailed within the [Processing R Scripts](#-Processing-R-Scripts) section of this document.

In short, the process for refreshing the data for the Excel dashboard is as follows:

* Running each individual SQL script within NCDR to return the seven necessary MHSDS extracts for processing (and saving within an appropriate folder once the queries are complete - `data > raw_extracts`).
* Running the R scripts for processing the seven MHSDS extracts which in turn create the 13 resultant processed datasets.
* Loading the 13 processed data sets within the Excel dashboard as detailed within the `tableau_extracts_guidance.md` document located within the `documentation > project_documentation` folder.

<br/>

## Packages
As the model is built and ran within the R programming language it will require dependent packages to be installed by the user. These packages will only require installing once. Please ensure that these packages are installed prior to running the model. This can be undertaken by using the `install.packages()` command within the console. For example `install.packages(here)` will install the `here` package. This can then be called with the `library(here)` command. 

For a full list of packages used in this model, please see the `packages.R` script found in the `config/r_scripts` folder. Users may need to manually install the `here` package as exampled above.

<br/>

## MHSDS SQL Scripts
Each of the SQL scripts have been developed with a dynamic data range. This means that the analyst running the SQL scripts does not need to edit the scripts when they refresh the data. Each script should be ran within NCDR before exporting the resulting query to the `data > raw_extracts` folder.

The MHSDS SQL scripts included within this repository are as follows:

* `MHSDS_Q1_Access.sql` - script for returning a count of women who have had at least one contact with a community based, specialist perinatal mental health service in the rolling 12 month period - specific to South London providers over the previous 36-months.
* `MHSDS_Q2_Caseload_Main.sql` - script for returning the number of referrals to a community based, specialist perinatal mental health service that were open at the end of the reporting month and have had at least one attended Face to Face or Video consultation contact since the referral was opened - specific to South London providers over the previous 36-months.
* `MHSDS_Q2_Caseload_Snap.sql` - script for returning the number of referrals to a community based, specialist perinatal mental health service that were open at the end of the reporting month and have had at least one attended Face to Face or Video consultation contact since the referral was opened - national snapshot (all English providers) for the most recent complete reporting period.
* `MHSDS_Q3_Referral_Main.sql` - script for returning all new, open and closed referrals to a specialist perinatal mental health service - specific to South London providers over the previous 36-months.
* `MHSDS_Q3_Referral_Snap.sql` - script for returning all new, open and closed referrals to a specialist perinatal mental health service - national snapshot (all English providers) for the most recent complete reporting period.
* `MHSDS_Q4_RTFc.sql` - script for returning a detailed summary of the referral to first contact time (in days) for women who have been in contact with a community based, specialist perinatal mental health service - specific to South London providers over the previous 36-months.
* `MHSDS_Q5_App.sql` - script for returning a detailed summary of the attendance status and contact mechanisms of women who have been in contact with a community based, specialist perinatal mental health service - specific to South London providers over the previous 36-months.

<br/>

## Processing R Scripts
All processing scripts developed for this pipeline again require no input from the user. The entire processing pipeline can be ran automatically by running the `MHSDS_Processing_Pipeline.R` script located within the `src > data_processing > r_scripts` folder. This master script will run the five processing scripts in sequence and save the resultant 13 processed data files within the `data > processed_extracts` folder.

The processing R scripts included within this repository are as follows:

* `MHSDS_Processing_Pipeline.R` - master script for running all constituent processing scripts in sequence.
* `MHSDS_Q1_Processing.R` - script for processing access data - returns the `MHSDS_Q1_Access.csv` summary file.
* `MHSDS_Q2_Processing.R` - script for processing caseload data - returns the `MHSDS_Q2_Caseload.csv` summary file, as well as caseload demographic summaries for age, deprivation and ethnicity (`MHSDS_Q2_Age_Combined.csv`, `MHSDS_Q2_Dep_Combined.csv` and `MHSDS_Q2_Age_Combined.csv`, respectively).
* `MHSDS_Q3_Processing.R` - script for processing referrals (new, open and closed) data - returns the `MHSDS_Q3_NOC_Referrals.csv` summary file, as well as the referral source summary file `MHSDS_Q3_Ref_Source.csv`.
* `MHSDS_Q4_Processing.R` - script for processing referral to first contact data - returns the `MHSDS_Q4_RTFc.csv` summary file.
* `MHSDS_Q2_Processing.R` - script for processing attendance status and contact mechanism data - returns the `MHSDS_Q5_App_Combined.csv` and `MHSDS_Q5_Con_Combined.csv` summary files, as well as attendance demographic summaries for age, deprivation and ethnicity (`MHSDS_Q5_Age_Combined.csv`, `MHSDS_Q5_Dep_Combined.csv` and `MHSDS_Q5_Age_Combined.csv`, respectively).
