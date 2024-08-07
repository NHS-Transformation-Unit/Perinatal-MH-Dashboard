
# Script for processing the referral to first contact time for patients attending perinatal MH services across English providers for previous 36-months


## Loading Q4 data and data lookup files

DBI::dbExecute(con, statement = read_file(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/MHSDS_Q4_RTFc.sql")), immediate=TRUE)
q4_raw_df <- DBI::dbGetQuery(con, statement = read_file(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/read_Q4_RTFc.sql")))

date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")
date_code_df <- read.csv(date_lookup)


## Filtering out of area patients

q4_area_df <- q4_raw_df %>%
  filter(SL_PRO_FLAG == 1)


## Joining lookup file to raw Q4 data

q4_dates_df <- left_join(q4_area_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Joining lookup file to raw Q4 data

q4_dates_df <- left_join(q4_area_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the referral count per month for new referrals, based on the provider and ICB flags

q4_RTFc_Partnership <- q4_dates_df %>%
  mutate(RTFc_Weeks = case_when(
    Days_First_Contact >= 84 ~ 'More than 12 Weeks',
    Days_First_Contact >= 28 ~ '4 - 12 Weeks',
    Days_First_Contact < 28 ~ 'Less than 4 Weeks',
    TRUE ~ "NotKnown")) %>%
  group_by(Month, RTFc_Weeks) %>%
  summarise(Average_RTFc = mean(Days_First_Contact, na.rm = TRUE), Patient_Count = n(), .groups = "drop") %>%
  mutate(Metric = "Referral to First Contact", 
         Organisation_Name = "Partnership Summary",
         ICB_Flag = "Both") %>%
  select(Month, Metric, Organisation_Name, RTFc_Weeks, Average_RTFc, Patient_Count)

q4_RTFc_Individual <- q4_dates_df %>%
  mutate(RTFc_Weeks = case_when(
    Days_First_Contact >= 84 ~ 'More than 12 Weeks',
    Days_First_Contact >= 28 ~ '4 - 12 Weeks',
    Days_First_Contact < 28 ~ 'Less than 4 Weeks',
    TRUE ~ "NotKnown")) %>%
  group_by(Month, ODS_Prov_orgName, RTFc_Weeks) %>%
  summarise(Average_RTFc = mean(Days_First_Contact, na.rm = TRUE), Patient_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Referral to First Contact") %>%
  select(Month, Metric, Organisation_Name, RTFc_Weeks, Average_RTFc, Patient_Count)

q4_RTFc_Summary <- rbind(q4_RTFc_Partnership, q4_RTFc_Individual)

q4_RTFc_Summary <- q4_RTFc_Summary %>%
  arrange(Month, Organisation_Name)

write.csv(q4_RTFc_Summary, paste0(here(),"/data/processed_extracts/MHSDS_Q4_RTFc.csv"), row.names = FALSE)
