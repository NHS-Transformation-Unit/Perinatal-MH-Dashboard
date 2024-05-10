
# Script for processing all demographic data related to the current caseload in perinatal MH services across English providers from April 2019 until February 2024

## Loading Q2 data and data lookup files

MHSDS_q2_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q2_Caseload.csv") ## will need changing to actual caseload data
date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")

q2_raw_df <- read.csv(MHSDS_q2_file_path)
date_code_df <- read.csv(date_lookup)


## Joining lookup file to raw Q3 data

q2_dates_df <- left_join(q2_raw_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Filtering the raw Q2 data to isolate those living within most deprived quintile

q2_dep_20 <- q2_dates_df %>%
  filter(IMD_Decile %in% c('1','2'))

q2_age_df <- q2_dates_df %>%
  mutate(AgeServReferRecDate = as.numeric(AgeServReferRecDate))


## Summarising the caseload each month based on the ethnic group of referred patients

q2_eth_total_df <- q2_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Ethnicity = "All") %>%
  select(1, 6, 7, 2, 3, 4, 5)

q2_eth_spec_df <- q2_dates_df %>%
  mutate(Ethnicity = case_when(
    Ethnic_Category_Main_Desc %in% c('British','Irish') ~ "WhiteBritishIrish",
    Ethnic_Category_Main_Desc == 'Any other white background' ~ "OtherWhite",
    Ethnic_Category_Main_Desc %in% c('White and Black Caribbean','White and Black African', 'White and Asian', 'Any other mixed background') ~ "EthnicityMixed",
    Ethnic_Category_Main_Desc %in% c('Indian','Pakistani', 'Bangladeshi', 'Any other Asian background') ~ "AsianAsianBritish",
    Ethnic_Category_Main_Desc %in% c('Caribbean','African', 'Any other Black background') ~ "BlackBlackBritish",
    Ethnic_Category_Main_Desc %in% c('Chinese','Any other ethnic group') ~ "OtherEthnicGroups",
    Ethnic_Category_Main_Desc == 'Not stated' ~ "NotStated",
    Ethnic_Category_Main_Desc == 'Missing / invalid' ~ "MissingInvalid",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Ethnicity) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 7, 5, 2, 3, 4, 6)

q2_eth_combined <- rbind(q2_eth_total_df, q2_eth_spec_df)

q2_eth_combined <- q2_eth_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q2_eth_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q2_Eth_Combined.csv"), row.names = FALSE)


## Summarising the caseload each month based on the deprivation decile of referred patients

q2_dep_total_df <- q2_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         IMD_Decile = "All") %>%
  select(1, 6, 7, 2, 3, 4, 5)

q2_dep_spec_df <- q2_dep_20 %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific",
         IMD_Decile = "20% Most Deprived") %>%
  select(1, 6, 7, 2, 3, 4, 5)

q2_dep_combined <- rbind(q2_dep_total_df, q2_dep_spec_df)

q2_dep_combined <- q2_dep_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q2_dep_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q2_Dep_Combined.csv"), row.names = FALSE)


## Summarising the caseload each month based on the age group of referred patients

q2_age_total_df <- q2_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Age_Band = "All") %>%
  select(1, 6, 7, 2, 3, 4, 5)

q2_age_spec_df <- q2_age_df %>%
  mutate(Age_Band = case_when(
    AgeServReferRecDate >= 16 & AgeServReferRecDate < 21 ~ "16-20",
    AgeServReferRecDate >= 21 & AgeServReferRecDate < 26 ~ "21-25",
    AgeServReferRecDate >= 26 & AgeServReferRecDate < 40 ~ "26-39",
    AgeServReferRecDate >= 40 ~ "40+",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Age_Band) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 7, 5, 2, 3, 4, 6)

q2_age_combined <- rbind(q2_age_total_df, q2_age_spec_df)

q2_age_combined <- q2_age_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q2_age_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q2_Age_Combined.csv"), row.names = FALSE)
