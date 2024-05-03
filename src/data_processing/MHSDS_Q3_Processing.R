
# Script for prcessing all new, open and closed referrals to perinatal MH services across English providers from April 2019 until February 2024

## Loading Q3 data and data lookup files

MHSDS_Q3_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q3_NOC_Referrals.csv")
date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")

Q3_raw_df <- read.csv(MHSDS_Q3_file_path)
date_code_df <- read.csv(date_lookup)


## Joining lookup file to raw Q3 data

Q3_dates_df <- left_join(Q3_raw_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Filtering the raw Q3 data into new, open and closed referral groups

Q3_new_ref_df <- Q3_dates_df %>%
  filter(NewReferrals == 1)

Q3_open_ref_df <- Q3_dates_df %>%
  filter(OpenReferrals == 1)

Q3_closed_ref_df <- Q3_dates_df %>%
  filter(ClosedReferrals == 1)


## Summarising the referral count per month for new referrals, based on the provider and ICB flags

Q3_new_proc_df <- Q3_new_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "New referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Summarising the referral count per month for open referrals, based on the provider and ICB flags

Q3_open_proc_df <- Q3_open_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Open referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Summarising the referral count per month for closed referrals, based on the provider and ICB flags

Q3_closed_proc_df <- Q3_closed_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Closed referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Combining all processed dataframes into one for exporting

q3_proc_combined <- rbind(Q3_new_proc_df, Q3_open_proc_df, Q3_closed_proc_df)

q3_proc_combined <- q3_proc_combined %>%
  arrange(Month)


## Exporting the final new, open and closed referrals df to csv

write.csv(q3_proc_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q3_NOC_Referrals.csv"), row.names = FALSE)


## Aggregating referral source for visualisation

Q3_ref_Source_df <- Q3_new_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, SourceOfReferralMH) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Referral_Source = case_when(
    x < 3 ~ "Low",
    x >= 3 & x < 5 ~ "Medium",
    x >= 5 ~ "High",
    TRUE ~ "Unknown"))
