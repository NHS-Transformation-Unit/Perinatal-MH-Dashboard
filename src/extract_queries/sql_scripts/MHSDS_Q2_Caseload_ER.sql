
-- Derivative of Q2_Caseload script which uses partitions to flag a woman's first contact within the FY at the national and provider levels

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
CARE.[CareContactID],
     
ROW_NUMBER () OVER(PARTITION BY REF.[Der_Person_ID], REF.[OrgIDComm], 
                    CASE WHEN REF.[UniqMonthID] BETWEEN 1417 AND 1428 THEN '2018/19'
                         WHEN REF.[UniqMonthID] BETWEEN 1429 AND 1440 THEN '2019/20'
                         WHEN REF.[UniqMonthID] BETWEEN 1441 AND 1452 THEN '2020/21'
                         WHEN REF.[UniqMonthID] BETWEEN 1453 AND 1464 THEN '2021/22'
                         WHEN REF.[UniqMonthID] BETWEEN 1465 AND 1476 THEN '2022/23'
                         WHEN REF.[UniqMonthID] BETWEEN 1477 AND 1488 THEN '2023/24'
                         WHEN REF.[UniqMonthID] BETWEEN 1489 AND 1500 THEN '2024/25'
                         WHEN REF.[UniqMonthID] BETWEEN 1501 AND 1512 THEN '2025/26'
                         WHEN REF.[UniqMonthID] BETWEEN 1513 AND 1524 THEN '2026/27'
                         ELSE 'Unknown FY'
                    END
                    ORDER BY REF.[UniqMonthID] ASC, CARE.[CareContactID] ASC) AS FY_FA_National,
                    
ROW_NUMBER () OVER(PARTITION BY REF.[Der_Person_ID], REF.[OrgIDProv], 
                    CASE WHEN REF.[UniqMonthID] BETWEEN 1417 AND 1428 THEN '2018/19'
                         WHEN REF.[UniqMonthID] BETWEEN 1429 AND 1440 THEN '2019/20'
                         WHEN REF.[UniqMonthID] BETWEEN 1441 AND 1452 THEN '2020/21'
                         WHEN REF.[UniqMonthID] BETWEEN 1453 AND 1464 THEN '2021/22'
                         WHEN REF.[UniqMonthID] BETWEEN 1465 AND 1476 THEN '2022/23'
                         WHEN REF.[UniqMonthID] BETWEEN 1477 AND 1488 THEN '2023/24'
                         WHEN REF.[UniqMonthID] BETWEEN 1489 AND 1500 THEN '2024/25'
                         WHEN REF.[UniqMonthID] BETWEEN 1501 AND 1512 THEN '2025/26'
                         WHEN REF.[UniqMonthID] BETWEEN 1513 AND 1524 THEN '2026/27'
                         ELSE 'Unknown FY'
                    END
                    ORDER BY REF.[UniqMonthID] ASC, CARE.[CareContactID] ASC) AS FY_FA_Provider

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

WHERE REF.[UniqMonthID] BETWEEN 1485 AND 1487 
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND (REF.[ServDischDate] IS NULL OR REF.[ServDischDate] > SF.[ReportingPeriodEndDate])
AND DISC.[ReferRejectionDate] IS NULL
AND CARE.[AttendOrDNACode] IN ('5', '6')
AND CARE.[ConsMechanismMH] IN ('01', '11');
