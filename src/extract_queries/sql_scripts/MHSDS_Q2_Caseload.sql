
-- Script to return perinatal caseload for all English providers between April 2019 and Feb 2024

DECLARE @EndRP INT;

SELECT @EndRP = MAX(UniqMonthID)
FROM [NHSE_MHSDS].[dbo].[MHS101Referral];

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
REF_PROS.[ODS_Prov_orgName], 
SERV.[ServTeamTypeRefToMH],
STYPE.[Main_Description],
MPI.[EthnicCategory],
ETH.[Ethnic_Category_Main_Desc],
MPI.[LSOA2011],
IMD.[IMD_Decile],
CARE.[CareContDate],
CARE.[AttendOrDNACode],
CARE.[ConsMechanismMH],

CASE WHEN CARE.[CareContDate] > SF.[ReportingPeriodEndDate] THEN 0 
     ELSE 1 END AS [Count],

CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 'Providers'
		 ELSE 'Other' END AS [Provider_Flag],
		      
CASE WHEN REF.[OrgIDProv] IN ('RRU', 'RPG', 'RJZ', 'RJ1', 'RV5', 'RJ2') THEN 'NHS South East London ICB'
		 WHEN REF.[OrgIDProv] IN ('RJ7', 'RAX', 'RQY', 'RY9', 'RJ6', 'RVR') THEN 'NHS South West London ICB'
		 ELSE 'Other' END AS [ICB_Flag]

INTO #tmp_AW_Caseload
FROM [NHSE_MHSDS].[dbo].[MHS101Referral] AS REF

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] AS SF
ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] AS SERV
ON REF.[RecordNumber] = SERV.[RecordNumber] AND REF.[UniqServReqID] = SERV.[UniqServReqID]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] AS MPI
ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_EthnicCategory] AS ETH
ON MPI.[EthnicCategory] = ETH.[Ethnic_Category]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth] AS STYPE
ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
AND STYPE.[Is_Latest] = '1'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_ProviderSite] AS REF_PROS
ON REF.[OrgIDProv] = REF_PROS.[ODS_Prov_OrgCode]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Deprivation_By_LSOA] AS [IMD]
ON MPI.[LSOA2011] = IMD.[LSOA_Code]
AND IMD.[Effective_Snapshot_Date] = '2019-12-31'

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS201CareContact] AS CARE
ON REF.[Der_Person_ID] = CARE.[Der_Person_ID] 
AND REF.[UniqServReqID] = CARE.[UniqServReqID]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] AS DISC
ON REF.[RecordNumber] = DISC.[RecordNumber] 
AND REF.[UniqServReqID] = DISC.[UniqServReqID]

WHERE REF.[UniqMonthID] BETWEEN 1429 AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND (REF.[ServDischDate] IS NULL OR REF.[ServDischDate] > SF.[ReportingPeriodEndDate])
AND DISC.[ReferRejectionDate] IS NULL
AND CARE.[ConsMechanismMH] IN ('01', '11')
AND CARE.[AttendOrDNACode] IN ('5', '6')
AND CARE.[CareContDate] IS NOT NULL


SELECT *,
ROW_NUMBER() OVER(PARTITION BY [UniqServReqID], [UniqMonthID] ORDER BY [CareContDate]) AS [Order]
INTO #tmp_AW_Caseload_Order
FROM #tmp_AW_Caseload

SELECT *
FROM #tmp_AW_Caseload_Order
WHERE [Order] = 1
AND [Count] = 1

DROP TABLE #tmp_AW_Caseload
DROP TABLE #tmp_AW_Caseload_Order;
