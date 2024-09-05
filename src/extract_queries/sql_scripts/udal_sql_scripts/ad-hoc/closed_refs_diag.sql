IF OBJECT_ID('TempDB..#tmpClosed') IS NOT NULL DROP TABLE #tmpClosed
IF OBJECT_ID('TempDB..#tmpClosed_Diags') IS NOT NULL DROP TABLE #tmpClosed_Diags
IF OBJECT_ID('TempDB..#tmpClosed_Diags_Closest_Order') IS NOT NULL DROP TABLE #tmpClosed_Diags_Closest_Order

DECLARE @EndRP INT;
DECLARE @StartRP INT;
 
SET @EndRP = 1488
SET @StartRP = @EndRP - 35

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
    ETH.[Main_Description] AS [Ethnic_Category_Main_Desc],
    IMD.[IMD_Decile],
    REF_PROS.[Organisation_Name] AS [ODS_Prov_orgName],

    CASE WHEN (REF.[ServDischDate] IS NULL OR REF.[ServDischDate] > SF.[ReportingPeriodEndDate]) AND SERV.[ReferRejectionDate] IS NULL THEN 1 ELSE 0 END AS OpenReferrals,
    CASE WHEN REF.[ReferralRequestReceivedDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate] THEN 1 ELSE 0 END AS NewReferrals,
    CASE WHEN REF.[ServDischDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate] THEN 1 ELSE 0 END AS ClosedReferrals,
    
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
    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 1 ELSE 0 END AS [SL_PRO_FLAG],
	CASE WHEN SF.[ReportingPeriodStartDate] BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22'
		 WHEN SF.[ReportingPeriodStartDate] BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23'
		 WHEN SF.[ReportingPeriodStartDate] BETWEEN '2023-04-01' AND '2024-03-31' THEN '2023/24'
		 ELSE 'OTHER' END AS [FYear]

INTO #tmpClosed
FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published] AS REF

INNER JOIN [Reporting_MESH_MHSDS].[MHS001MPI_Published] AS MPI
ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS102ServiceTypeReferredTo_Published] AS  SERV
ON REF.[UniqServReqID] = SERV.[UniqServReqID] AND REF.[RecordNumber] = SERV.[RecordNumber] 

INNER JOIN [Reporting_MESH_MHSDS].[MHSDS_SubmissionFlags_Published] AS SF
ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [UKHD_Data_Dictionary].[Ethnic_Category_Code_SCD] as ETH
ON MPI.[EthnicCategory] = ETH.[Main_Code_Text]
AND ETH.[Is_Latest] = 1

LEFT JOIN [UKHD_Data_Dictionary].[Service_Or_Team_Type_For_Mental_Health_SCD] AS STYPE
ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
AND STYPE.[Is_Latest] = '1'

LEFT JOIN [Internal_Reference].[Provider_Geography] as REF_PROS
ON REF.[OrgIDProv] = REF_PROS.[Organisation_Code]

LEFT JOIN [UKHF_Demography].[Domains_Of_Deprivation_By_LSOA1] as IMD
ON MPI.[LSOA2011] = IMD.[LSOA_Code]
AND IMD.[Effective_Snapshot_Date] = '2019-12-31'

LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies_ICB] AS COMM
ON REF.[OrgIDComm] = COMM.[Organisation_Code]


WHERE REF.[UniqMonthID] BETWEEN @StartRP AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND REF.[ServDischDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate]
AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')

SELECT CLOSED.*,
	   PDIAG.[PrimDiag],
	   PDIAG.[Effective_From],
	   PDIAG.[CodedDiagTimestamp],
	   REPLACE(PDIAG.[PrimDiag], '.', '') AS [Cleaned_PrimDiag],
	   CASE WHEN PDIAG.[PrimDiag] IS NULL THEN 0 ELSE 1 END AS [DIAG_JOIN],
	   DATEDIFF(DAY,[ReferralRequestReceivedDate], [CodedDiagTimestamp]) AS [Days]
	   --ROW_NUMBER() OVER(PARTITION BY CLOSED.[Der_Person_ID], CLOSED.[UniqServReqID] ORDER BY (DATEDIFF(DAY, CLOSED.[ReferralRequestReceivedDate], PDIAG.[CodedDiagTimestamp])) DESC) AS [Closest]
INTO #tmpClosed_Diags
FROM #tmpClosed as [CLOSED]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS604PrimDiag_Published] as PDIAG
ON CLOSED.[Der_Person_ID] = PDIAG.[Der_Person_ID]
AND DATEDIFF(DAY,CLOSED.[ReferralRequestReceivedDate], PDIAG.[CodedDiagTimestamp]) >=0


SELECT *,
ROW_NUMBER() OVER(PARTITION BY [Der_Person_ID], [UniqServReqID] ORDER BY [Days] DESC) AS [Closest]
INTO #tmpClosed_Diags_Closest_Order
FROM #tmpClosed_Diags


SELECT CLOSED_DIAGS.*,
	   ICD.[Alt_Code],
	   ICD.[Description],
	   ICD.[Category_3_Code],
       ICD.[Category_3_Description]

FROM #tmpClosed_Diags_Closest_Order as CLOSED_DIAGS

LEFT JOIN [UKHD_ICD10].[Codes_And_Titles_And_MetaData] AS ICD
ON CLOSED_DIAGS.[Cleaned_PrimDiag] = ICD.[Alt_Code]
AND ICD.[Effective_To] IS NULL

WHERE CLOSED_DIAGS.[Closest] = 1

ORDER BY [Alt_Code]