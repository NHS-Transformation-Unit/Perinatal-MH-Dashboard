
# Script for processing the access to perinatal MH services across English providers for previous 36-months


## Loading Q1 data and data lookup files
DBI::dbExecute(con, statement = read_file(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/MHSDS_Q1_Access.sql")), immediate=TRUE)
q1_main_raw_df <- DBI::dbGetQuery(con, statement = "SELECT [OrgIDProv],[ODS_Prov_orgName], COUNT(DISTINCT Der_Person_ID) 
                                                  FROM #temp_Q1_Access
                                                  GROUP BY [OrgIDProv],[ODS_Prov_orgName]")

date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")
date_code_df <- read.csv(date_lookup)


## Filtering out of area patients

q1_main_area_df <- q1_main_raw_df %>%
  filter(SL_PRO_FLAG == 1)


## Joining lookup file to raw Q1 data

q1_main_dates_df <- left_join(q1_main_area_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the access count per month based on the provider and ICB flags

q1_main_proc_df <- q1_main_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Access",
         Geography = "Provider Specific") %>%
  select(1, 6, 2, 3, 4, 5)

q1_access_summary <- q1_main_proc_df %>%
  arrange(Month, Organisation_Name)

write.csv(q1_access_summary, paste0(here(),"/data/processed_extracts/MHSDS_Q1_Access.csv"), row.names = FALSE)
