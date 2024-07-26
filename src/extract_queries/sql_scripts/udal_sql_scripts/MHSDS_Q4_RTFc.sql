
-- Script to return first contact (isolates new referrals each month and then calculates the days to their first appointment) during the previous 36-months

IF OBJECT_ID('TempDB..#temp_Q3_First_Contact') IS NOT NULL DROP TABLE #temp_Q3_First_Contact
IF OBJECT_ID('TempDB..#temp_Q3_First_Contact_Order') IS NOT NULL DROP TABLE #temp_Q3_First_Contact_Order


DECLARE @EndRP INT;
DECLARE @StartRP INT;
 
SET @EndRP = (SELECT MAX(UniqMonthID)
              FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published])
 
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
    MPI.[GenderSameAtBirth],
    MPI.[MaritalStatus],
    MPI.[PersDeathDate],
    MPI.[AgeDeath],
    MPI.[LanguageCodePreferred],
    MPI.[ElectoralWard],
    MPI.[LADistrictAuth],
    MPI.[LSOA2011],
    MPI.[County],
    MPI.[NHSNumberStatus],
    MPI.[OrgIDLocalPatientId],
    MPI.[PostcodeDistrict],
    MPI.[DefaultPostcode],
    MPI.[AgeRepPeriodStart],
    MPI.[AgeRepPeriodEnd],
    REF.[MHS101UniqID],
    REF.[UniqServReqID],
    REF.[OrgIDComm],
    REF.[ReferralRequestReceivedDate],
    REF.[ReferralRequestReceivedTime],
    LEFT([NHSServAgreeLineID],10) AS [NHSServAgreeLineNum],
    REF.[SpecialisedMHServiceCode],
    REF.[SourceOfReferralMH],
    REF.[OrgIDReferringOrg] AS [OrgIDReferring],
    REF.[ReferringCareProfessionalStaffGroup],
    REF.[ClinRespPriorityType],
    REF.[PrimReasonReferralMH],
    REF.[ReasonOAT],
    REF.[DecisionToTreatDate],
    REF.[DecisionToTreatTime],
    REF.[DischPlanCreationDate],
    REF.[DischPlanCreationTime],
    REF.[DischPlanLastUpdatedDate],
    REF.[DischPlanLastUpdatedTime],
    REF.[ServDischDate],
    REF.[ServDischTime],
    REF.[AgeServReferRecDate],
    REF.[AgeServReferDischDate],
    SERV.[MHS102UniqID],
    SERV.[UniqCareProfTeamID],
    SERV.[ServTeamTypeRefToMH],
    SERV.[ReferClosureDate],
    SERV.[ReferClosureTime],
    SERV.[ReferRejectionDate],
    SERV.[ReferRejectionTime],
    SERV.[ReferClosReason],
    SERV.[ReferRejectReason],
    SERV.[AgeServReferClosure],
    SERV.[AgeServReferRejection],
    ETH.[Main_Description_60_Chars] AS [Ethnic_Category_Main_Desc],
    IMD.[IMD_Decile],
    REF_PROS.[Organisation_Name] AS [ODS_Prov_orgName],
    CARE.[CareContDate],
    
    CASE WHEN REF.[ReferralRequestReceivedDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate] THEN 1 ELSE 0 END AS NewReferrals,
		
	COMM.[Organisation_Code],
    COMM.[Organisation_Name],
    COMM.[STP_Name],
    COMM.[STP_Code],

    CASE WHEN COMM.[STP_Code] IN ('QWE', 'QKK') THEN 1 ELSE 0 END AS [SL_ICB_FLAG],
    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 1 ELSE 0 END AS [SL_PRO_FLAG]

INTO #temp_Q3_First_Contact
FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published] AS REF

INNER JOIN [Reporting_MESH_MHSDS].[MHS001MPI_Published] AS MPI
ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS102ServiceTypeReferredTo_Published] AS  SERV
ON REF.[UniqServReqID] = SERV.[UniqServReqID] AND REF.[RecordNumber] = SERV.[RecordNumber] 

INNER JOIN [Reporting_MESH_MHSDS].[MHSDS_SubmissionFlags_Published] AS SF
ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [UKHD_Data_Dictionary].[Ethnic_Category_Code_SCD] AS ETH
ON MPI.[EthnicCategory] = ETH.[Main_Code_Text]
AND ETH.[Is_Latest] = 1

LEFT JOIN [UKHD_Data_Dictionary].[Service_Or_Team_Type_For_Mental_Health_SCD] AS STYPE
ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
AND STYPE.[Is_Latest] = '1'

LEFT JOIN [Internal_Reference].[Provider_Geography] AS REF_PROS
ON REF.[OrgIDProv] = REF_PROS.[Organisation_Code]

LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] as IMD
ON MPI.[LSOA2011] = IMD.[LSOA_Code]
AND IMD.[Effective_Snapshot_Date] = '2019-12-31'

LEFT JOIN [Reporting_MESH_MHSDS].[MHS201CareContact_Published] AS CARE
ON REF.[Der_Person_ID] = CARE.[Der_Person_ID] 
AND REF.[UniqServReqID] = CARE.[UniqServReqID]

LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies_ICB] AS COMM
ON REF.[OrgIDComm] = COMM.[Organisation_Code]

WHERE REF.[UniqMonthID] BETWEEN @StartRP AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND (REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') OR COMM.[STP_Code] IN ('QWE', 'QKK'))
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND REF.[ReferralRequestReceivedDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate]
AND CARE.[ConsMechanismMH] IN ('01', '11')
AND CARE.[AttendStatus] IN ('5', '6')
AND CARE.[CareContDate] IS NOT NULL

SELECT *,
ROW_NUMBER() OVER(PARTITION BY [UniqServReqID], [UniqMonthID] ORDER BY [CareContDate]) AS [Order]
INTO #temp_Q3_First_Contact_Order
FROM #temp_Q3_First_Contact;
