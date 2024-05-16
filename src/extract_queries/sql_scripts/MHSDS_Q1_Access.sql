
-- Script to return perinatal access for all English providers during the previous 12-months

DECLARE @EndRP INT;

SET @EndRP = (SELECT MAX(UniqMonthID)
              FROM [NHSE_MHSDS].[dbo].[MHS101Referral]);

DECLARE @StartRP INT;

SET @StartRP = (SELECT MAX(UniqMonthID)
                FROM [NHSE_MHSDS].[dbo].[MHS101Referral]
                WHERE UniqMonthID <= DATEADD(MONTH, -24, @EndRP));

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

INTO #tmp_ER_Access
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

WHERE REF.[UniqMonthID] BETWEEN @StartRP AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND DISC.[ReferRejectionDate] IS NULL
AND CARE.[ConsMechanismMH] IN ('01', '11')
AND CARE.[AttendOrDNACode] IN ('5', '6')
AND CARE.[CareContDate] IS NOT NULL


SELECT *,
ROW_NUMBER() OVER(PARTITION BY [UniqServReqID], [UniqMonthID] ORDER BY [CareContDate]) AS [Order]
INTO #tmp_ER_Access_Order
FROM #tmp_ER_Access

SELECT *
FROM #tmp_ER_Access_Order
WHERE [Order] = 1
AND [Count] = 1

DROP TABLE #tmp_ER_Access
DROP TABLE #tmp_ER_Access_Order;