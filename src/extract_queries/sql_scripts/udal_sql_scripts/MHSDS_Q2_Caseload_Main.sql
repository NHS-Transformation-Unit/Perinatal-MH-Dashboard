-- Script to return perinatal caseload for specific South London providers during the previous 36-months

IF OBJECT_ID('TempDB..#temp_Q2_Caseload_Main') IS NOT NULL DROP TABLE #temp_Q2_Caseload_Main
IF OBJECT_ID('TempDB..#temp_Q2_Caseload_Main_Order') IS NOT NULL DROP TABLE #temp_Q2_Caseload_Main_Order


DECLARE @EndRP INT;
DECLARE @StartRP INT;
 
SET @EndRP = (SELECT MAX(UniqMonthID)
              FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published])
 
SET @StartRP = (@EndRP - 36)

SELECT DISTINCT

    REF.[UniqMonthID],
    SF.[ReportingPeriodStartDate],
    SF.[ReportingPeriodEndDate],
    REF.[Der_Person_ID], 
    REF.[AgeServReferRecDate],
    REF.[RecordNumber], 
    REF.[UniqServReqID], 
    REF.[ReferralRequestReceivedDate],
    REF.[SourceOfReferralMH],
    REF.[OrgIDProv],
    REF_PROS.[Organisation_Name] AS [ODS_Prov_orgName], 
    SERV.[ServTeamTypeRefToMH],
    STYPE.[Main_Description],
    MPI.[EthnicCategory],
    ETH.[Main_Description_60_Chars] AS [Ethnic_Category_Main_Desc],
    MPI.[LSOA2011],
    IMD.[IMD_Decile],
    CARE.[CareContDate],
    CARE.[AttendStatus] as [AttendOrDNACode],
    CARE.[ConsMechanismMH],

    CASE WHEN CARE.[CareContDate] > SF.[ReportingPeriodEndDate] THEN 0 
         ELSE 1 END AS [Count],

    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 'Providers'
         ELSE 'Other' END AS [Provider_Flag],
		      
    CASE WHEN REF.[OrgIDProv] IN ('RRU', 'RPG', 'RJZ', 'RJ1', 'RV5', 'RJ2') THEN 'NHS South East London ICB'
         WHEN REF.[OrgIDProv] IN ('RJ7', 'RAX', 'RQY', 'RY9', 'RJ6', 'RVR') THEN 'NHS South West London ICB'
         ELSE 'Other' END AS [ICB_Flag],
		 
    COMM.[Organisation_Code],
    COMM.[Organisation_Name],
    COMM.[STP_Name],
    COMM.[STP_Code],
    
    CASE WHEN COMM.[STP_Code] IN ('QWE', 'QKK') THEN 1 ELSE 0 END AS [SL_ICB_FLAG],
    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 1 ELSE 0 END AS [SL_PRO_FLAG]

INTO #temp_Q2_Caseload_Main
FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published] AS REF

INNER JOIN [Reporting_MESH_MHSDS].[SubmissionFlags_Published] AS SF
ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [Reporting_MESH_MHSDS].[MHS102ServiceTypeReferredTo_Published] AS SERV
ON REF.[RecordNumber] = SERV.[RecordNumber] AND REF.[UniqServReqID] = SERV.[UniqServReqID]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS001MPI_Published] AS MPI
ON REF.[RecordNumber] = MPI.[RecordNumber]

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

LEFT JOIN [Reporting_MESH_MHSDS].[MHS102ServiceTypeReferredTo_Published] AS DISC
ON REF.[RecordNumber] = DISC.[RecordNumber] 
AND REF.[UniqServReqID] = DISC.[UniqServReqID]

LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies_ICB] AS COMM
ON REF.[OrgIDComm] = COMM.[Organisation_Code]

WHERE REF.[UniqMonthID] BETWEEN @StartRP AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND (REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') OR COMM.[STP_Code] IN ('QWE', 'QKK'))
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND (REF.[ServDischDate] IS NULL OR REF.[ServDischDate] > SF.[ReportingPeriodEndDate])
AND DISC.[ReferRejectionDate] IS NULL
AND CARE.[ConsMechanismMH] IN ('01', '11')
AND CARE.[AttendStatus] IN ('5', '6')
AND CARE.[CareContDate] IS NOT NULL

SELECT *,
ROW_NUMBER() OVER(PARTITION BY [UniqServReqID], [UniqMonthID] ORDER BY [CareContDate]) AS [Order]
INTO #temp_Q2_Caseload_Main_Order
FROM #temp_Q2_Caseload_Main

SELECT *
FROM #temp_Q2_Caseload_Order
WHERE [Order] = 1
AND [Count] = 1

DROP TABLE #temp_Q2_Caseload_Main
DROP TABLE #temp_Q2_Caseload_Main_Order;
