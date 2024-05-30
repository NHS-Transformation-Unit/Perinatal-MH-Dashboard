
# Script for processing the access to perinatal MH services across English providers for previous 36-months


## Loading Q1 data and data lookup files

MHSDS_q1_main_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q1_Access_Main.csv")
MHSDS_q1_snap_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q1_Access_Snap.csv")
date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")

q1_main_raw_df <- read.csv(MHSDS_q1_main_file_path)
q1_snap_raw_df <- read.csv(MHSDS_q1_snap_file_path)
date_code_df <- read.csv(date_lookup)


## Filtering out of area patients

q1_main_area_df <- q1_main_raw_df %>%
  filter(SL_PRO_FLAG == 1)


## Joining lookup file to raw Q4 data

q1_main_dates_df <- left_join(q1_main_area_df, date_code_df, by = c("UniqMonthID" = "Code"))
q1_snap_dates_df <- left_join(q1_snap_raw_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the access count per month based on the provider and ICB flags

q1_main_proc_df <- q1_main_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Access",
         Geography = "Provider Specific") %>%
  select(1, 6, 2, 3, 4, 5)

q1_snap_proc_df <- q1_snap_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Access",
         Geography = "National Snapshot") %>%
  select(1, 6, 2, 3, 4, 5)

q1_access_summary <- rbind(q1_main_proc_df, q1_snap_proc_df)

q1_access_summary <- q1_access_summary %>%
  arrange(Month, Organisation_Name)

write.csv(q1_access_summary, paste0(here(),"/data/processed_extracts/MHSDS_Q1_Access.csv"), row.names = FALSE)
