
# Script for prcessing referral to first contact time for perinatal MH services across English providers from April 2019 until February 2024

## Loading Q4 data and data lookup files

MHSDS_q4_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q4_RTFc.csv")
date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")

q4_raw_df <- read.csv(MHSDS_q4_file_path)
date_code_df <- read.csv(date_lookup)


## Joining lookup file to raw Q4 data

q4_dates_df <- left_join(q4_raw_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the referral count per month for new referrals, based on the provider and ICB flags

q3_new_proc_df <- q3_new_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "New referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Summarising the referral count per month for open referrals, based on the provider and ICB flags

q3_open_proc_df <- q3_open_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Open referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Summarising the referral count per month for closed referrals, based on the provider and ICB flags

q3_closed_proc_df <- q3_closed_ref_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Closed referrals") %>%
  select(1, 6, 2, 3, 4, 5)


## Combining all processed dataframes into one for exporting

q3_proc_combined <- rbind(q3_new_proc_df, q3_open_proc_df, q3_closed_proc_df)

q3_proc_combined <- q3_proc_combined %>%
  arrange(Month, Organisation_Name)


## Exporting the final new, open and closed referrals df to csv

write.csv(q3_proc_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q3_NOC_Referrals.csv"), row.names = FALSE)


## Aggregating new referral sources

q3_ref_Source_df <- q3_new_ref_df %>%
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
    TRUE ~ "MissingInvalid")) %>%
  select(1, 7, 2, 3, 4, 5, 6) %>%
  arrange(Month, Organisation_Name)

write.csv(q3_ref_Source_df, paste0(here(),"/data/processed_extracts/MHSDS_Q3_Ref_Source.csv"), row.names = FALSE)
