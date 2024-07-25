
# Script for processing the referral to first contact time for patients attending perinatal MH services across English providers for previous 36-months


## Loading Q5 data and data lookup files

q5_raw_df <- DBI::dbGetQuery(con, statement = read_file(paste0(here(),"/src/extract_queries/sql_scripts/udal_sql_scripts/MHSDS_Q5_App.sql")))

date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")
date_code_df <- read.csv(date_lookup)


## Filtering out of area patients

q5_area_df <- q5_raw_df %>%
  filter(SL_PRO_FLAG == 1)


## Joining lookup file to raw Q4 data

q5_dates_df <- left_join(q5_area_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the attendance status count per month for each provider

q5_app_total_df <- q5_dates_df %>%
  group_by(Month, ODS_Prov_orgName) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Appointment_Status = "All") %>%
  select(1, 4, 5, 2, 3)

q5_app_spec_df <- q5_dates_df %>%
  mutate(Appointment_Status = case_when(
    AttendOrDNACode %in% c('5', '6') ~ "Attended and seen",
    AttendOrDNACode == '7' ~ "Arrived late, not seen",
    AttendOrDNACode == '2' ~ "Patient cancellation",
    AttendOrDNACode == '4' ~ "Provider cancellation",
    AttendOrDNACode == '3'  ~ "Did not attend",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, ODS_Prov_orgName, Appointment_Status) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 5, 3, 2, 4)

q5_app_combined <- rbind(q5_app_total_df, q5_app_spec_df)

q5_app_combined <- q5_app_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_app_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_App_Combined.csv"), row.names = FALSE)


## Summarising the contact mechanism count per month for each provider

q5_con_df <- q5_dates_df %>%
  filter(AttendOrDNACode %in% c('5', '6'))

q5_con_total_df <- q5_con_df %>%
  group_by(Month, ODS_Prov_orgName) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Contact_Mech = "All") %>%
  select(1, 4, 2, 5, 3)

q5_con_spec_df <- q5_con_df %>%
  mutate(Contact_Mech = case_when(
    ConsMechanismMH == '01'  ~ 'Face to Face',
    ConsMechanismMH == '02'  ~ 'Telephone',
    ConsMechanismMH == '03'  ~ 'Telemedicine',
    ConsMechanismMH == '04'  ~ 'Talk type for a person unable to speak',
    ConsMechanismMH == '05'  ~ 'Email',
    ConsMechanismMH == '06'  ~ 'Short message service (SMS) - text messaging',
    ConsMechanismMH == '07'  ~ 'On-line Triage',
    ConsMechanismMH == '08'  ~ 'Online Instant Messaging',
    ConsMechanismMH == '09'  ~ 'Text message (Asynchronous)',
    ConsMechanismMH == '10'  ~ 'Instant messaging (Synchronous)',
    ConsMechanismMH == '11'  ~ 'Video Consultation',
    ConsMechanismMH == '12'  ~ 'Message Board (Asynchronous)',
    ConsMechanismMH == '13'  ~ 'Chat Room (Synchronous)',
    ConsMechanismMH == '98'  ~ 'Other',
    TRUE ~ "NotKnown")) %>%
  group_by(Month, ODS_Prov_orgName, Contact_Mech) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 5, 2, 3, 4)

q5_con_combined <- rbind(q5_con_total_df, q5_con_spec_df)

q5_con_combined <- q5_con_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_con_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Con_Combined.csv"), row.names = FALSE)


## Adding attendance categories for demography summarising the attendance status outputs

q5_dem_att_df <- q5_dates_df %>%
  mutate(Appointment_Status = case_when(
    AttendOrDNACode %in% c('5', '6') ~ "Attended and seen",
    AttendOrDNACode == '7' ~ "Arrived late, not seen",
    AttendOrDNACode == '2' ~ "Patient cancellation",
    AttendOrDNACode == '4' ~ "Provider cancellation",
    AttendOrDNACode == '3'  ~ "Did not attend",
    TRUE ~ "NotKnown"))


## Filtering the raw Q5 data to isolate those living within most deprived quintile

q5_dep_20 <- q5_dem_att_df %>%
  filter(IMD_Decile %in% c('1','2'))

q5_dep_40 <- q5_dem_att_df %>%
  filter(IMD_Decile %in% c('3','4'))

q5_dep_60 <- q5_dem_att_df %>%
  filter(IMD_Decile %in% c('5','6'))

q5_dep_80 <- q5_dem_att_df %>%
  filter(IMD_Decile %in% c('7','8'))

q5_dep_100 <- q5_dem_att_df %>%
  filter(IMD_Decile %in% c('9','10'))


## mutating the 'age' field to numeric

q5_age_att_df <- q5_dem_att_df %>%
  mutate(AgeRepPeriodEnd = as.numeric(AgeRepPeriodEnd))


## Creating a function to group by and summarise raW q5 data

app_groupby_fct <- function(input, metric, cat_desc) {
  result_df <- input %>%
    group_by(Month, SL_ICB_FLAG, ODS_Prov_orgName, Appointment_Status) %>%
    summarise(Referral_Count = n(), .groups = "drop") %>%
    rename(Organisation_Name = ODS_Prov_orgName) %>%
    mutate(Metric = metric,
           IMD_Decile = cat_desc) %>%
    select(Month, Metric, Organisation_Name, Appointment_Status, IMD_Decile, Referral_Count)
  
  return(result_df)
  
}


## Summarising the caseload each month based on the ethnic group of referred patients

q5_eth_att_total_df <- q5_dem_att_df %>%
  group_by(Month, ODS_Prov_orgName, Appointment_Status) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Ethnicity - Provider Total",
         Ethnicity = "All") %>%
  select(1, 5, 2, 3, 6, 4)

q5_eth_att_spec_df <- q5_dem_att_df %>%
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
  group_by(Month, ODS_Prov_orgName, Appointment_Status, Ethnicity) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Ethnicity - Provider Specific") %>%
  select(1, 6, 2, 3, 4, 5)

q5_eth_att_combined <- rbind(q5_eth_att_total_df, q5_eth_att_spec_df)

q5_eth_att_combined <- q5_eth_att_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_eth_att_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Att_Eth.csv"), row.names = FALSE)


## Summarising the caseload each month based on the deprivation decile of referred patients

q5_dep_att_total_df <- app_groupby_fct(q5_dem_att_df, "Deprivation - Provider Total", "All Quintiles (Deprivation)")
q5_dep_att_20_df <- app_groupby_fct(q5_dep_20, "Deprivation - Provider Specific", "First_Quintile (Deprivation)")
q5_dep_att_40_df <- app_groupby_fct(q5_dep_40, "Deprivation - Provider Specific", "Second_Quintile (Deprivation)")
q5_dep_att_60_df <- app_groupby_fct(q5_dep_60, "Deprivation - Provider Specific", "Third_Quintile (Deprivation)")
q5_dep_att_80_df <- app_groupby_fct(q5_dep_80, "Deprivation - Provider Specific", "Fourth_Quintile (Deprivation)")
q5_dep_att_100_df <- app_groupby_fct(q5_dep_100, "Deprivation - Provider Specific", "Fifth_Quintile (Deprivation)")

q5_dep_att_combined <- rbind(q5_dep_att_total_df, 
                             q5_dep_att_20_df,
                             q5_dep_att_40_df,
                             q5_dep_att_60_df,
                             q5_dep_att_80_df,
                             q5_dep_att_100_df)

q5_dep_att_combined <- q5_dep_att_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_dep_att_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Att_Dep.csv"), row.names = FALSE)


## Summarising the caseload each month based on the age group of referred patients

q5_age_att_total_df <- q5_dem_att_df %>%
  group_by(Month, ODS_Prov_orgName, Appointment_Status) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Age - Provider Total",
         Age_Band = "All") %>%
  select( 1, 5, 2, 3, 6, 4)

q5_age_att_spec_df <- q5_age_att_df %>%
  mutate(Age_Band = case_when(
    AgeRepPeriodEnd >= 16 & AgeRepPeriodEnd < 21 ~ "16-20",
    AgeRepPeriodEnd >= 21 & AgeRepPeriodEnd < 26 ~ "21-25",
    AgeRepPeriodEnd >= 26 & AgeRepPeriodEnd < 31 ~ "26-30",
    AgeRepPeriodEnd >= 31 & AgeRepPeriodEnd < 36 ~ "31-35",
    AgeRepPeriodEnd >= 36 & AgeRepPeriodEnd < 40 ~ "36-39",
    AgeRepPeriodEnd >= 40 ~ "40+",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, ODS_Prov_orgName, Appointment_Status, Age_Band) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Age - Provider Specific") %>%
  select(1, 6, 2, 3, 4, 5)

q5_age_att_combined <- rbind(q5_age_att_total_df, q5_age_att_spec_df)

q5_age_att_combined <- q5_age_att_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_age_att_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Att_Age.csv"), row.names = FALSE)


## Adding attendance categories for demography summarising the contact mechanism outputs

q5_dem_con_df <- q5_con_df %>%
  mutate(Contact_Mech = case_when(
    ConsMechanismMH == '01'  ~ 'Face to Face',
    ConsMechanismMH == '02'  ~ 'Telephone',
    ConsMechanismMH == '03'  ~ 'Telemedicine',
    ConsMechanismMH == '04'  ~ 'Talk type for a person unable to speak',
    ConsMechanismMH == '05'  ~ 'Email',
    ConsMechanismMH == '06'  ~ 'Short message service (SMS) - text messaging',
    ConsMechanismMH == '07'  ~ 'On-line Triage',
    ConsMechanismMH == '08'  ~ 'Online Instant Messaging',
    ConsMechanismMH == '09'  ~ 'Text message (Asynchronous)',
    ConsMechanismMH == '10'  ~ 'Instant messaging (Synchronous)',
    ConsMechanismMH == '11'  ~ 'Video Consultation',
    ConsMechanismMH == '12'  ~ 'Message Board (Asynchronous)',
    ConsMechanismMH == '13'  ~ 'Chat Room (Synchronous)',
    ConsMechanismMH == '98'  ~ 'Other',
    TRUE ~ "NotKnown"))


## Filtering the raw Q5 data to isolate those living within most deprived quintile

q5_dep_con_20 <- q5_dem_con_df %>%
  filter(IMD_Decile %in% c('1','2'))

q5_dep_con_40 <- q5_dem_con_df %>%
  filter(IMD_Decile %in% c('3','4'))

q5_dep_con_60 <- q5_dem_con_df %>%
  filter(IMD_Decile %in% c('5','6'))

q5_dep_con_80 <- q5_dem_con_df %>%
  filter(IMD_Decile %in% c('7','8'))

q5_dep_con_100 <- q5_dem_con_df %>%
  filter(IMD_Decile %in% c('9','10'))


## mutating the 'age' field to numeric

q5_age_con_df <- q5_dem_con_df %>%
  mutate(AgeRepPeriodEnd = as.numeric(AgeRepPeriodEnd))


## Creating a function to group by and summarise raW q5 data

con_groupby_fct <- function(input, metric, cat_desc) {
  result_df <- input %>%
    group_by(Month, SL_ICB_FLAG, ODS_Prov_orgName, Contact_Mech) %>%
    summarise(Referral_Count = n(), .groups = "drop") %>%
    rename(Organisation_Name = ODS_Prov_orgName) %>%
    mutate(Metric = metric,
           IMD_Decile = cat_desc) %>%
    select(Month, Metric, Organisation_Name, Contact_Mech, IMD_Decile, Referral_Count)
  
  return(result_df)
  
}


## Summarising the caseload each month based on the ethnic group of referred patients

q5_eth_con_total_df <- q5_dem_con_df %>%
  group_by(Month, ODS_Prov_orgName, Contact_Mech) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Ethnicity - Provider Total",
         Ethnicity = "All") %>%
  select(1, 5, 2, 3, 6, 4)

q5_eth_con_spec_df <- q5_dem_con_df %>%
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
  group_by(Month, ODS_Prov_orgName, Contact_Mech, Ethnicity) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Ethnicity - Provider Specific") %>%
  select(1, 6, 2, 3, 4, 5)

q5_eth_con_combined <- rbind(q5_eth_con_total_df, q5_eth_con_spec_df)

q5_eth_con_combined <- q5_eth_con_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_eth_con_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Con_Eth.csv"), row.names = FALSE)


## Summarising the caseload each month based on the deprivation decile of referred patients

q5_dep_con_total_df <- con_groupby_fct(q5_dem_con_df, "Deprivation - Provider Total", "All Quintiles (Deprivation)")
q5_dep_con_20_df <- con_groupby_fct(q5_dep_con_20, "Deprivation - Provider Specific", "First_Quintile (Deprivation)")
q5_dep_con_40_df <- con_groupby_fct(q5_dep_con_40, "Deprivation - Provider Specific", "Second_Quintile (Deprivation)")
q5_dep_con_60_df <- con_groupby_fct(q5_dep_con_60, "Deprivation - Provider Specific", "Third_Quintile (Deprivation)")
q5_dep_con_80_df <- con_groupby_fct(q5_dep_con_80, "Deprivation - Provider Specific", "Fourth_Quintile (Deprivation)")
q5_dep_con_100_df <- con_groupby_fct(q5_dep_con_100, "Deprivation - Provider Specific", "Fifth_Quintile (Deprivation)")

q5_dep_con_combined <- rbind(q5_dep_con_total_df, 
                             q5_dep_con_20_df,
                             q5_dep_con_40_df,
                             q5_dep_con_60_df,
                             q5_dep_con_80_df,
                             q5_dep_con_100_df)

q5_dep_con_combined <- q5_dep_con_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_dep_con_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Con_Dep.csv"), row.names = FALSE)


## Summarising the caseload each month based on the age group of referred patients

q5_age_con_total_df <- q5_dem_con_df %>%
  group_by(Month, ODS_Prov_orgName, Contact_Mech) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Age - Provider Total",
         Age_Band = "All") %>%
  select( 1, 5, 2, 3, 6, 4)

q5_age_con_spec_df <- q5_age_con_df %>%
  mutate(Age_Band = case_when(
    AgeRepPeriodEnd >= 16 & AgeRepPeriodEnd < 21 ~ "16-20",
    AgeRepPeriodEnd >= 21 & AgeRepPeriodEnd < 26 ~ "21-25",
    AgeRepPeriodEnd >= 26 & AgeRepPeriodEnd < 31 ~ "26-30",
    AgeRepPeriodEnd >= 31 & AgeRepPeriodEnd < 36 ~ "31-35",
    AgeRepPeriodEnd >= 36 & AgeRepPeriodEnd < 40 ~ "36-39",
    AgeRepPeriodEnd >= 40 ~ "40+",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, ODS_Prov_orgName, Contact_Mech, Age_Band) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Age - Provider Specific") %>%
  select(1, 6, 2, 3, 4, 5)

q5_age_con_combined <- rbind(q5_age_con_total_df, q5_age_con_spec_df)

q5_age_con_combined <- q5_age_con_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_age_con_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Con_Age.csv"), row.names = FALSE)
