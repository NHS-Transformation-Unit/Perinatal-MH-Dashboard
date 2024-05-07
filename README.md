<img src="images/TU_logo_large.png" alt="TU logo" width="200" align="right"/>

<br/>

<br/>

<br/>

# Perinatal Mental Health Dashboard

The repository contains all code used by the NHS Transformation Unit analytics team during the development of the Perinatal Mental Health Dashboard for South London Perinatal Provider Collaborative.

The purpose of this dashboard is to collect and visualise a number of key metrics related to Perinatal Mental Health services. Specifically, the dashboard visualises data specific to three Mental Health Trusts working within the NHS South West London Integrated Care Board. 

The data to inform the agreed metrics is exported from the Mental Health Services Data Set (MHSDS) and processed using R before being visualised within Microsoft Excel. The ambition of this project is to automate as much of this reporting process as possible, to reduce the analytical capacity needed to maintain the dashboard. You can find out more about the MHSDS [here](https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-sets/mental-health-services-data-set).

<br/>

## Using the Repository

The data for this dashboard is processed following the pipeline outlined below:

<img src="images/data_pipeline.png" alt="data pipeline" width="500" align="centre"/>

<br/>

## Using the Repository

This codebase contains:

1. The SQL queries for extracting all relevant data from MHSDS.
2. The R scripts needed for processing the MHSDS data extracted using the SQL queries.

To recreate the data pipeline created for this dashboard, users will need to ensure their working directory is structured as outlined in the [Repo Structure](#repo-structure) section of this ReadMe. This can be completed using Git or by simply downloading a zipped version of the tool from this repository.

Following the cloning of this repository to the user's preferred IDE, and assuming all the constituent files are located in the appropriate folders, all extracted MHSDS data can be processed by **running the `MHSDS_Processing.R` script** found within the `src > data_processing > r_scripts` folder. The processed data files can then be read into the MHSDS dashboard file. Please see the guidance located under `documentation > project_documentation` for a more in depth process outline.

It is worth noting that whilst the SQL scripts for querying MHSDS can be run within IDE's such as RStudio, in this project the MHSDS SQL scripts were ran within NCDR and are as such outside of the R data pipeline.

<br/>

## Repository Structure

The current structure of the repository is detailed below:

``` plaintext

├─── documentation
     └─── project_documentation
├─── images
└─── src
     ├─── extract_queries
          └─── sql_scripts
               ├─── archived_scripts
               └─── MHSDS_examples
     ├─── data_processing
          └─── r_scripts
     └─── config
          └─── r_scripts

```

<br/>

### `documentation`
This folder contain the project documentation, including brief summaries of each scripts purpose and the dashboard metrics they relate to.

### `images`
This folder contains all images used in the outputs or repository such as the TU logo.

### `src`
All code is stored within the `src` folder. This is then divided into `extract_queries` for the SQL scripts that query NCDR and `data_processing` for R scripts employed in processing raw data. A single R script is stored in the `config` subfolder which provides a list of packages needed to process any MHSDS data within R.


<br/>

## Contributors

This repository has been created and developed by:
-   [Andy Wilson](https://github.com/ASW-Analyst)
-   [Elliot Royle](https://github.com/elliotroyle)
-   [Simon Wickham](https://github.com/SiWickham)
