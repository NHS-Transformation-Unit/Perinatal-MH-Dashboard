
-- Script to return the contact mechanism that patients referred to perinatal MH services access across specific South London providers during the previous 36-months

DECLARE @EndRP INT;
DECLARE @StartRP INT;
 
SET @EndRP = (SELECT MAX(UniqMonthID)
              FROM [NHSE_MHSDS].[dbo].[MHS101Referral])
 
SET @StartRP = (@EndRP - 36)

SELECT DISTINCT

    SF.[ReportingPeriodStartDate],
    SF.[ReportingPeriodEndDate],
    MPI.[UniqSubmissionID],
    MPI.[NHSEUniqSubmissionID],
    MPI.[UniqMonthID],
    MPI.[OrgIDProv],
    MPI.[Der_Person_ID],
    MPI.[RecordNumber],
    MPI.[MHS001UniqID],
    MPI.[OrgIDCCGRes],
    MPI.[OrgIDEduEstab],
    MPI.[EthnicCategory],
    MPI.[EthnicCategory2021],
    CASE WHEN MPI.GenderIDCode IN ('1','2','3','4','X','Z') THEN MPI.GenderIDCode ELSE MPI.[Gender] END AS Gender,
    MPI.[ElectoralWard],
    MPI.[LADistrictAuth],
    MPI.[LSOA2011],
    MPI.[AgeRepPeriodStart],
    MPI.[AgeRepPeriodEnd],
    REF.[MHS101UniqID],
    REF.[UniqServReqID],
    REF.[OrgIDComm],
    REF.[ReferralRequestReceivedDate],
    REF.[SpecialisedMHServiceCode],
    REF.[SourceOfReferralMH],
    REF.[OrgIDReferring],
    REF.[ReferringCareProfessionalStaffGroup],
    REF.[ClinRespPriorityType],
    REF.[PrimReasonReferralMH],
    REF.[ReasonOAT],
    REF.[ServDischDate],
    SERV.[MHS102UniqID],
    SERV.[UniqCareProfTeamID],
    SERV.[ServTeamTypeRefToMH],
    ETH.[Ethnic_Category_Main_Desc],
    IMD.[IMD_Decile],
    REF_PROS.[ODS_Prov_orgName],
    CARE.[CareContDate],
    CARE.[ConsMechanismMH],
    CARE.[AttendOrDNACode],
    ATT_STAT.[Main_Description] as [Attendance_Status],
    
    COMM.[Organisation_Code],
    COMM.[Organisation_Name],
    COMM.[STP_Name],
    COMM.[STP_Code],
    
    CASE WHEN COMM.[STP_Code] IN ('QWE', 'QKK') THEN 1 ELSE 0 END AS [SL_ICB_FLAG],
    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 1 ELSE 0 END AS [SL_PRO_FLAG]

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] AS REF

INNER JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] AS MPI
ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] AS  SERV
ON REF.[UniqServReqID] = SERV.[UniqServReqID] AND REF.[RecordNumber] = SERV.[RecordNumber] 

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] AS SF
ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_EthnicCategory] AS ETH
ON MPI.[EthnicCategory] = ETH.[Ethnic_Category]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth] AS STYPE
ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
AND STYPE.[Is_Latest] = '1'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_ProviderSite] AS REF_PROS
ON REF.[OrgIDProv] = REF_PROS.[ODS_Prov_OrgCode]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Deprivation_By_LSOA] as [IMD]
ON MPI.[LSOA2011] = IMD.[LSOA_Code]
AND IMD.[Effective_Snapshot_Date] = '2019-12-31'

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS201CareContact] AS CARE
ON REF.[Der_Person_ID] = CARE.[Der_Person_ID] 
AND REF.[UniqServReqID] = CARE.[UniqServReqID]

LEFT JOIN [NHSE_UKHF].[Data_Dictionary].[vw_Attended_Or_Did_Not_Attend_SCD] AS [ATT_STAT]
ON CARE.[AttendOrDNACode] = ATT_STAT.[Main_Code_Text]
AND ATT_STAT.[Is_Latest] = '1'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_Commissioner_Hierarchies] AS COMM
ON REF.[OrgIDComm] = COMM.[Organisation_Code]

WHERE REF.[UniqMonthID] BETWEEN @StartRP AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND (REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') OR COMM.[STP_Code] IN ('QWE', 'QKK'))
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND CARE.[CareContDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate]
AND CARE.[CareContDate] IS NOT NULL;
