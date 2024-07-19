
# Script for prcessing all new, open and closed referrals to perinatal MH services across English providers for previous 36-months

## Loading Q3 data and data lookup files

q3_main_raw_df <- DBI::dbGetQuery(con, statement = read_file(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/MHSDS_Q3_Referral_Main.sql")))
q3_snap_raw_df <- DBI::dbGetQuery(con, statement = read_file(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/MHSDS_Q3_Referral_Snap.sql")))

date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")


## Filtering out of area patients

q3_main_area_df <- q3_main_raw_df %>%
  filter(SL_PRO_FLAG == 1)


## Joining lookup file to raw Q3 data

q3_main_dates_df <- left_join(q3_main_area_df, date_code_df, by = c("UniqMonthID" = "Code"))
q3_snap_dates_df <- left_join(q3_snap_raw_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Filtering the raw Q3 data into new, open and closed referral groups

q3_new_main_df <- q3_main_dates_df %>%
  filter(NewReferrals == 1)

q3_open_main_df <- q3_main_dates_df %>%
  filter(OpenReferrals == 1)

q3_closed_main_df <- q3_main_dates_df %>%
  filter(ClosedReferrals == 1)

q3_new_snap_df <- q3_snap_dates_df %>%
  filter(NewReferrals == 1)

q3_open_snap_df <- q3_snap_dates_df %>%
  filter(OpenReferrals == 1)

q3_closed_snap_df <- q3_snap_dates_df %>%
  filter(ClosedReferrals == 1)


## Summarising the referral count per month for new referrals, based on the provider and ICB flags

q3_new_proc_main <- q3_new_main_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "New referrals") %>%
  select(1, 6, 2, 3, 4, 5)

q3_new_proc_snap <- q3_new_snap_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "New referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Summarising the referral count per month for open referrals, based on the provider and ICB flags

q3_open_proc_main <- q3_open_main_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Open referrals") %>%
  select(1, 6, 2, 3, 4, 5)

q3_open_proc_snap <- q3_open_snap_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Open referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Summarising the referral count per month for closed referrals, based on the provider and ICB flags

q3_closed_proc_main <- q3_closed_main_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Closed referrals") %>%
  select(1, 6, 2, 3, 4, 5)

q3_closed_proc_snap <- q3_closed_snap_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Closed referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Combining all processed dataframes into one for exporting

q3_proc_combined <- rbind(q3_new_proc_main, q3_open_proc_main, q3_closed_proc_main, q3_new_proc_snap, q3_open_proc_snap, q3_closed_proc_snap)

q3_proc_combined <- q3_proc_combined %>%
  arrange(Month, Organisation_Name) %>%
  distinct()


## Exporting the final new, open and closed referrals df to csv

write.csv(q3_proc_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q3_NOC_Referrals.csv"), row.names = FALSE)


## Aggregating new referral sources

q3_ref_Source_df <- q3_new_main_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, SourceOfReferralMH) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Referral_Source = case_when(
    SourceOfReferralMH == 'A1' ~ "Referral_GP",
    SourceOfReferralMH == 'A3' ~ "OtherPrimaryCare",
    SourceOfReferralMH == 'A2' ~ "PrimaryCareHealthVisitor",
    SourceOfReferralMH == 'A4' ~ "PrimaryCareMaternityService",
    SourceOfReferralMH %in% c('P1','H2','M9','Q1') ~ "SecondaryCare",
    SourceOfReferralMH %in% c('B1','B2') ~ "SelfReferral",
    SourceOfReferralMH %in% c('D1','M6','I2','M7','H1','M3','N3','C1','G3','C2','E2','F3','I1','F1','E1','F2','G4','M2','M4','E3','E4','E5','G1','M1','C3','D2','E6','G2','M5') ~ "OtherReferralSource",
    TRUE ~ "MissingInvalid"),
    Metric = "New referrals - source") %>%
  select(1, 8, 2, 3, 4, 7, 6) %>%
  arrange(Month, Organisation_Name)

write.csv(q3_ref_Source_df, paste0(here(),"/data/processed_extracts/MHSDS_Q3_Ref_Source.csv"), row.names = FALSE)
