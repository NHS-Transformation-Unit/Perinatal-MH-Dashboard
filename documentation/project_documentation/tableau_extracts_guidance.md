# Running the Tool Guidance

## Introduction
There are several ways in which the AIDF BI Support Geospatial Mapping Tool can be ran. This guidance provides an overview of the different approaches and the stages in which these need to be undertaken. There are two ways in which the tool can be ran:

* Knitting the `AIDF_Mapping_Tool.Rmd` file within the `src/r_scripts/geospatial` folder will run the tool and create the viewable instance of the tool itself, which can in turn be loaded into an external browser.
* Running the individual geospatial mapping scripts to load the processed AIDF data and create distinct visualisations from it. This is more labour intensive but is useful for understanding the mechanics of the tool.

<br/>

## Amending Imaging Network/NHS Trust information
All data related to the different Imaging Networks and NHS Trusts participating in the AIDF programme are located in the `AIDF_Geo_Final.csv` text file. Data can be changed directly within this file, but the file should always be saved within the `data/processed SFBC` folder with the same name.

<br/>

## Packages
As the model is built and ran within the R programming language it will require dependent packages to be installed by the user. These packages will only require installing once. Please ensure that these packages are installed prior to running the model. This can be undertaken by using the `install.packages()` command within the console. For example `install.packages(tidyr)` will install the `tidyr` package. For a full list of packages used in this model, please see the `packages.R` script found in the `config/r_scripts` folder.

<br/>

## Knitting the Model Outputs Document
The file `AIDF_Mapping_Tool.Rmd` will run the tool and create the necessary visualisations for each part of the tool. The output of this is an .`html` file that can be viewed and shared with others. To create this file ensure that the all files are saved to their respective folders as per the online repository. Changing the location of these files will result in the tool not initialising. The outputs can be created by **knitting** the document. This can be achieved by either clicking the `Knit` button or by using `Ctrl+Shift+K` command. The output will then render and load the knitted document into a viewing window. The output will also be available within the `src/geospatial` folder as an `.html` file.

<br/>

## Running the Model in Stages
The tool can be created in stages. This will take longer and requires the model objects to be created in order. However, this will be helpful for the user to understand how the tool functions. The order for running is:

1. Run the `src/config/r_scripts/packages.R` script. This will load all required packages into the library.
2. Run the `src/geospatial/r_scripts/geojson.R` script. This will load the MSOA ShapeFile and ensure it is in the right format to be utilised by the `leaflet()` package.
3. Run the `src/geospatial/r_scripts/implementation/implementation_mapping.R` script. This will not only load the `AIDF_Geo_Final.csv` file into the environment, but will also begin to create and filter the appropriate geospatial dataframes for use within the `shiny()` applications built by this script for loading into the `AIDF_Mapping_Tool.Rmd` file. These geospatial dataframes relate specifically to the implementation mapping section of the output.
4. Run the `src/geospatial/r_scripts/modality/modality_mapping.R` script. This script creates further geospatial dataframes visualising specific imaging modalities for use by the `leaflet()` visualisations built by this script for loading into the `AIDF_Mapping_Tool.Rmd` file.
5. Run the `src/geospatial/r_scripts/network/network_mapping.R` script. This script creates further geospatial dataframes visualising specific imaging modalities for use within the `shiny()` applications built by this script for loading into the `AIDF_Mapping_Tool.Rmd` file. These geospatial dataframes relate specifically to the network mapping section of the output.

Running these scripts in sequence will allow users to create three distinct visualisations outside of the `.Rmd` output.

<br/>

## Archived Data
Included within this repository are a number of data files and scripts related to previous iterations of the AIDF BI Support Geospatial Mapping Tool pipeline. The scripts located in `src/processing (archived` folder were created for taking the raw SFBC Excel files from the AIDF NHS Futures site and processing them into a usable format for the creation of the geospatial tool. These files have been modified to access data files within their new archived locations.

The archived scripts can be ran in the following order to reprocess raw SFBC data files:

1. `SFBC_Load.R` - this script uses a function to extract key information fields from the raw SFBC files.
2. `SFBC_ETL.R` - this script processes the raw data pulled from SFBC files to ready it for cleaning.
3. `SFBC_Clean.R` - this script cleans the output of the previous script to ensure no fields are missing, names are consistent with AIDF documentation and organisational codes are accurate.
4. `SFBC_Join.R` - thie script joins the cleaned SFBC data to supplementary AIDF information and NCDR accessed NHS Trust latitude and longitude data. The output of this fourth script is the processed `AIDF_Geo_Final.csv` file used in the latest iteration of the model.

To ensure the above scripts work, a number of data files need to be present in archived data folders. These are as follows:

1. Raw SFBC files - these raw SFBC Excel files are taken from the AIDF NHS Futures site and saved within the `data/archived/raw SFBC` folder. They have the naming convention `X_SFBC.xlsx` where 'X' is the imaging network ID. These IDs are available on request, as well as present in the `SFBC_Clean.R` script.
2. `AIDF_Network_Summary.xlsx` - this data file contains supplementary data provided by the AIDF programme team and saved within the `data/archived/TU summaries` folder. Available upon request.
3. `NCDR_reference_locations.xlsx` - this data file functions as a lookup between NHS Trust organisation code, latitude and longitude and saved within the `data/archived/geospatial` folder. Accessed from NCDR and available upon request.
