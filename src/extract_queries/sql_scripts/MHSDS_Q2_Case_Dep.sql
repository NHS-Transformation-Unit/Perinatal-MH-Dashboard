
-- Script to return new perinatal referrals from select providers across 18-month period

SELECT 
    REF.[ReferralRequestReceivedDate],
    REF_PROS.[ODS_Prov_orgName], 
    IMD.[IMD_Decile],
    COUNT(DISTINCT REF.[Der_Person_ID]) AS PatientCount

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] AS REF

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] AS SF
    ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
    AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] AS SERV
    ON REF.[RecordNumber] = SERV.[RecordNumber] AND REF.[UniqServReqID] = SERV.[UniqServReqID]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] AS MPI
    ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth] AS STYPE
    ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
    AND STYPE.[Is_Latest] = '1'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_ProviderSite] AS REF_PROS
    ON REF.[OrgIDProv] = REF_PROS.[ODS_Prov_OrgCode]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Deprivation_By_LSOA] AS [IMD]
    ON MPI.[LSOA2011] = IMD.[LSOA_Code]
    AND IMD.[Effective_Snapshot_Date] = '2019-12-31'
    
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS201CareContact] AS CARE
    ON REF.[RecordNumber] = CARE.[RecordNumber] 
    AND REF.[UniqServReqID] = CARE.[UniqServReqID]

WHERE REF.[UniqMonthID] BETWEEN 1470 AND 1487
    AND SERV.[ServTeamTypeRefToMH] = 'C02'
    AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')
    AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
    AND MPI.[Gender] = '2'
    AND CARE.[AttendOrDNACode] IN ('5', '6')
    AND CARE.[ConsType] IN ('01', '11')
    AND IMD.[IMD_Decile] IN ('1', '2')
    AND REF.[ServDischDate] IS NULL
    
GROUP BY 
    REF.[ReferralRequestReceivedDate],
    REF_PROS.[ODS_Prov_orgName],
    IMD.[IMD_Decile]
    


