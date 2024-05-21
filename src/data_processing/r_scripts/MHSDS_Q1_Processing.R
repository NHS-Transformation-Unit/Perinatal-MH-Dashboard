
# Script for prcessing the access to perinatal MH services across English providers from April 2019 until February 2024


## Loading Q4 data and data lookup files

MHSDS_q4_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q4_RTFc.csv")
date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")

q4_raw_df <- read.csv(MHSDS_q4_file_path)
date_code_df <- read.csv(date_lookup)


## Joining lookup file to raw Q4 data

q4_dates_df <- left_join(q4_raw_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the referral count per month for new referrals, based on the provider and ICB flags

q4_RTFc_Partnership <- q4_dates_df %>%
  group_by(Month, Provider_Flag) %>%
  summarise(Average_RTFc = mean(Days_First_Contact, na.rm = TRUE), .groups = "drop") %>%
  mutate(Metric = "Referral to First Contact", 
         Organisation_Name = "Partnership Summary",
         ICB_Flag = "Both") %>%
  select(Month, Metric, Provider_Flag, ICB_Flag, Organisation_Name, Average_RTFc)

q4_RTFc_Individual <- q4_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Average_RTFc = mean(Days_First_Contact, na.rm = TRUE), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Referral to First Contact") %>%
  select(Month, Metric, Provider_Flag, ICB_Flag, Organisation_Name, Average_RTFc)

q4_RTFc_Summary <- rbind(q4_RTFc_Partnership, q4_RTFc_Individual)

q4_RTFc_Summary <- q4_RTFc_Summary %>%
  arrange(Month, Organisation_Name)

write.csv(q4_RTFc_Summary, paste0(here(),"/data/processed_extracts/MHSDS_Q4_RTFc.csv"), row.names = FALSE)
