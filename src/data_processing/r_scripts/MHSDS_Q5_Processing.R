
# Script for processing the referral to first contact time for patients attending perinatal MH services across English providers from April 2019 until February 2024


## Loading Q5 data and data lookup files

MHSDS_q5_file_path <- paste0(here(),"/data/raw_extracts/MHSDS_Q5_Appointments.csv")
date_lookup <- paste0(here(),"/data/supporting_data/Date_Code_Lookup.csv")

q5_raw_df <- read.csv(MHSDS_q5_file_path)
date_code_df <- read.csv(date_lookup)


## Filtering out of area patients

q5_area_df <- q5_raw_df %>%
  filter(SL_PRO_FLAG == 1)


## Joining lookup file to raw Q4 data

q5_dates_df <- left_join(q5_area_df, date_code_df, by = c("UniqMonthID" = "Code"))


## Summarising the attendance status count per month for each provider

q5_app_total_df <- q5_dates_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Appointment_Status = "All") %>%
  select(1, 6, 7, 2, 3, 4, 5)

q5_app_spec_df <- q5_dates_df %>%
  mutate(Appointment_Status = case_when(
    AttendOrDNACode %in% c('5', '6') ~ "Attended and seen",
    AttendOrDNACode == '7' ~ "Arrived late, not seen",
    AttendOrDNACode == '2' ~ "Patient cancellation",
    AttendOrDNACode == '4' ~ "Provider cancellation",
    AttendOrDNACode == '3'  ~ "Did not attend",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Appointment_Status) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 7, 5, 2, 3, 4, 6)

q5_app_combined <- rbind(q5_app_total_df, q5_app_spec_df)

q5_app_combined <- q5_app_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_app_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_App_Combined.csv"), row.names = FALSE)


## Summarising the contact mechanism count per month for each provider

q5_con_df <- q5_dates_df %>%
  filter(AttendOrDNACode %in% c('5', '6'))

q5_con_total_df <- q5_con_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Contact_Mech = "All") %>%
  select(1, 6, 7, 2, 3, 4, 5)

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
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Contact_Mech) %>%
  summarise(Appointment_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 7, 5, 2, 3, 4, 6)

q5_con_combined <- rbind(q5_con_total_df, q5_con_spec_df)

q5_con_combined <- q5_con_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_con_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Con_Combined.csv"), row.names = FALSE)


## Adding attendance categories for demography summarising

q5_dem_spec_df <- q5_dates_df %>%
  mutate(Appointment_Status = case_when(
    AttendOrDNACode %in% c('5', '6') ~ "Attended and seen",
    AttendOrDNACode == '7' ~ "Arrived late, not seen",
    AttendOrDNACode == '2' ~ "Patient cancellation",
    AttendOrDNACode == '4' ~ "Provider cancellation",
    AttendOrDNACode == '3'  ~ "Did not attend",
    TRUE ~ "NotKnown"))


## Filtering the raw Q5 data to isolate those living within most deprived quintile

q5_dep_20 <- q5_dem_spec_df %>%
  filter(IMD_Decile %in% c('1','2'))

q5_dep_40 <- q5_dem_spec_df %>%
  filter(IMD_Decile %in% c('3','4'))

q5_dep_60 <- q5_dem_spec_df %>%
  filter(IMD_Decile %in% c('5','6'))

q5_dep_80 <- q5_dem_spec_df %>%
  filter(IMD_Decile %in% c('7','8'))

q5_dep_100 <- q5_dem_spec_df %>%
  filter(IMD_Decile %in% c('9','10'))


## mutating the 'age' field to numeric

q5_age_df <- q5_dem_spec_df %>%
  mutate(AgeRepPeriodEnd = as.numeric(AgeRepPeriodEnd))


## Creating a function to group by and summarise raW q2 data

app_groupby_fct <- function(input, metric, cat_desc) {
  result_df <- input %>%
    group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Appointment_Status) %>%
    summarise(Referral_Count = n(), .groups = "drop") %>%
    rename(Organisation_Name = ODS_Prov_orgName) %>%
    mutate(Metric = metric,
           IMD_Decile = cat_desc) %>%
    select(Month, Metric, Provider_Flag, ICB_Flag, Organisation_Name, Appointment_Status, IMD_Decile, Referral_Count)
  
  return(result_df)
  
}


## Summarising the caseload each month based on the ethnic group of referred patients

q5_eth_total_df <- q5_dem_spec_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Appointment_Status) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Ethnicity = "All") %>%
  select(1, 7, 2, 3, 4, 5, 8, 6)

q5_eth_spec_df <- q5_dem_spec_df %>%
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
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Appointment_Status, Ethnicity) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 8, 2, 3, 4, 5, 6, 7)

q5_eth_combined <- rbind(q5_eth_total_df, q5_eth_spec_df)

q5_eth_combined <- q5_eth_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_eth_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Eth_Combined.csv"), row.names = FALSE)


## Summarising the caseload each month based on the deprivation decile of referred patients

q5_dep_total_df <- app_groupby_fct(q5_dem_spec_df, "Provider_Total", "All Quintiles (Deprivation)")
q5_dep_20_df <- app_groupby_fct(q5_dep_20, "Provider_Specific", "First_Quintile (Deprivation)")
q5_dep_40_df <- app_groupby_fct(q5_dep_40, "Provider_Specific", "Second_Quintile (Deprivation)")
q5_dep_60_df <- app_groupby_fct(q5_dep_60, "Provider_Specific", "Third_Quintile (Deprivation)")
q5_dep_80_df <- app_groupby_fct(q5_dep_80, "Provider_Specific", "Fourth_Quintile (Deprivation)")
q5_dep_100_df <- app_groupby_fct(q5_dep_100, "Provider_Specific", "Fifth_Quintile (Deprivation)")

q5_dep_combined <- rbind(q5_dep_total_df, 
                         q5_dep_20_df,
                         q5_dep_40_df,
                         q5_dep_60_df,
                         q5_dep_80_df,
                         q5_dep_100_df)

q5_dep_combined <- q5_dep_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_dep_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Dep_Combined.csv"), row.names = FALSE)


## Summarising the caseload each month based on the age group of referred patients

q5_age_total_df <- q5_dem_spec_df %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Appointment_Status) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Total",
         Age_Band = "All") %>%
  select( 1, 7, 2, 3, 4, 5, 8, 6)

q5_age_spec_df <- q5_dem_spec_df %>%
  mutate(Age_Band = case_when(
    AgeRepPeriodEnd >= 16 & AgeRepPeriodEnd < 21 ~ "16-20",
    AgeRepPeriodEnd >= 21 & AgeRepPeriodEnd < 26 ~ "21-25",
    AgeRepPeriodEnd >= 26 & AgeRepPeriodEnd < 40 ~ "26-39",
    AgeRepPeriodEnd >= 40 ~ "40+",
    TRUE ~ "NotKnown")) %>%
  group_by(Month, Provider_Flag, ICB_Flag, ODS_Prov_orgName, Appointment_Status, Age_Band) %>%
  summarise(Referral_Count = n(), .groups = "drop") %>%
  rename(Organisation_Name = ODS_Prov_orgName) %>%
  mutate(Metric = "Provider_Specific") %>%
  select(1, 8, 2, 3, 4, 5, 6, 7)

q5_age_combined <- rbind(q5_age_total_df, q5_age_spec_df)

q5_age_combined <- q5_age_combined %>%
  arrange(Month, Organisation_Name)

write.csv(q5_age_combined, paste0(here(),"/data/processed_extracts/MHSDS_Q5_Age_Combined.csv"), row.names = FALSE)
