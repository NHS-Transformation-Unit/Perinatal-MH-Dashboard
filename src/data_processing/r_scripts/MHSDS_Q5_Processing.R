
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
