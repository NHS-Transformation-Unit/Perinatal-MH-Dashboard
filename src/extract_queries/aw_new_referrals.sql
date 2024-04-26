
-- Script to return new perinatal referrals from select providers across 18-month period

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
	  IMD.[IMD_Decile]

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

WHERE REF.[UniqMonthID] BETWEEN 1470 AND 1487
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND REF.[ReferralRequestReceivedDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate];
