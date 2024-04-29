
-- Script to return data for metrics 1, 2, 3 and 4 (Perinatal MH service patient access)

SELECT 
    REF.[UniqMonthID],
    REF_PROS.[ODS_Prov_orgName], 
    CASE WHEN CARE.[AttendOrDNACode] = '5' THEN 'Arrived on time'
         WHEN CARE.[AttendOrDNACode] = '6' THEN 'Arrived late, but was seen'
         ELSE 'Other attendance status' END AS [AttendDesc],
    CASE WHEN CARE.[ConsType] = '01' THEN 'F2F'
         WHEN CARE.[ConsType] = '11' THEN 'Video'
         ELSE 'Other consultation medium' END AS [ConsDesc],
    COUNT(DISTINCT REF.[Der_Person_ID]) AS PatientCount
    
FROM [NHSE_MHSDS].[dbo].[MHS101Referral] AS REF

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] AS SF
    ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
    AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] AS SERV
    ON REF.[RecordNumber] = SERV.[RecordNumber] 
    AND REF.[UniqServReqID] = SERV.[UniqServReqID]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS201CareContact] AS CARE
    ON REF.[RecordNumber] = CARE.[RecordNumber] 
    AND REF.[UniqServReqID] = CARE.[UniqServReqID]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] AS MPI
    ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth] AS STYPE
    ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
    AND STYPE.[Is_Latest] = '1'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_ProviderSite] AS REF_PROS
    ON REF.[OrgIDProv] = REF_PROS.[ODS_Prov_OrgCode]

WHERE REF.[UniqMonthID] BETWEEN 1470 AND 1487
    AND SERV.[ServTeamTypeRefToMH] = 'C02'
    AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')
    AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE 'E%')
    AND MPI.[Gender] = '2'
    AND CARE.[AttendOrDNACode] IN ('5', '6')
    AND CARE.[ConsType] IN ('01', '11')

GROUP BY 
    REF.[UniqMonthID],
    REF_PROS.[ODS_Prov_orgName],
    CASE 
        WHEN CARE.[AttendOrDNACode] = '5' THEN 'Arrived on time'
        WHEN CARE.[AttendOrDNACode] = '6' THEN 'Arrived late, but was seen'
        ELSE 'Other attendance status' 
    END,
    CASE 
        WHEN CARE.[ConsType] = '01' THEN 'F2F'
        WHEN CARE.[ConsType] = '11' THEN 'Video'
        ELSE 'Other consultation medium' 
    END;
