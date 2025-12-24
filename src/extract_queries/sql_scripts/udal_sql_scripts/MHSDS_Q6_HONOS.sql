-- =================================================================================
-- Stage 0: Set-up
-- =================================================================================

IF OBJECT_ID('TempDB..#TempDischargesAll') IS NOT NULL DROP TABLE #TempDischargesAll
IF OBJECT_ID('TempDB..#TempDischarges') IS NOT NULL DROP TABLE #TempDischarges
IF OBJECT_ID('TempDB..#TempAss') IS NOT NULL DROP TABLE #TempAss
IF OBJECT_ID('TempDB..#TempAssReference') IS NOT NULL DROP TABLE #TempAssReference
IF OBJECT_ID('TempDB..#TempAssCombScores') IS NOT NULL DROP TABLE #TempAssCombScores
IF OBJECT_ID('TempDB..#TempDisAssLink') IS NOT NULL DROP TABLE #TempDisAssLink
IF OBJECT_ID('TempDB..#TempDisFirstLastAss') IS NOT NULL DROP TABLE #TempDisFirstLastAss
IF OBJECT_ID('TempDB..#PairedHoNOS') IS NOT NULL DROP TABLE #PairedHoNOS

DECLARE @EndRP INT;
DECLARE @StartRP INT;
 
SET @EndRP = (SELECT MAX(UniqMonthID)
              FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published])
 
SET @StartRP = (@EndRP - 48)

-- =================================================================================
-- Stage 1: Creating Discharges Table
-- =================================================================================

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
    COALESCE(SERV.[ServTeamTypeRefToMH],SERVTD.[ServTeamTypeMH]) AS ServTeamTypeRefToMH,
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
    ROW_NUMBER () OVER(PARTITION BY REF.[Der_Person_ID], REF.[UniqServReqID], SERV.[MHS102UniqID] ORDER BY REF.[ServDischDate], REF.[UniqMonthID] DESC) AS [Ref_Order_Start],
    ROW_NUMBER () OVER(PARTITION BY REF.[Der_Person_ID], REF.[UniqServReqID], SERV.[MHS102UniqID] ORDER BY REF.[ServDischDate] DESC, REF.[UniqMonthID] DESC) AS [Ref_Order_End],
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
    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 1 ELSE 0 END AS [SL_PRO_FLAG]
      
INTO #TempDischargesAll
FROM [Reporting_MESH_MHSDS].[MHS101Referral_Published] AS REF

INNER JOIN [Reporting_MESH_MHSDS].[MHS001MPI_Published] AS MPI
  ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS102ServiceTypeReferredTo_Published] AS  SERV
  ON REF.[UniqServReqID] = SERV.[UniqServReqID] 
  AND REF.[RecordNumber] = SERV.[RecordNumber] 

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

LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies_ICB] AS COMM
  ON REF.[OrgIDComm] = COMM.[Organisation_Code]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS902ServiceTeamDetails_Published] as SERVTD
  ON REF.[UniqCareProfTeamLocalID] = SERVTD.[UniqCareProfTeamLocalID]


WHERE REF.[UniqMonthID] BETWEEN @StartRP AND @EndRP
  AND (SERV.[ServTeamTypeRefToMH] = 'C02' OR SERVTD.[ServTeamTypeMH] = 'C02')
  AND (REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') OR COMM.[STP_Code] IN ('QWE', 'QKK'))
  AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
  AND MPI.[Gender] = '2'


SELECT * 
INTO #TempDischarges
FROM #TempDischargesAll as [Dis]
WHERE Dis.[Ref_Order_Start] = 1

DROP TABLE #TempDischargesAll

-- =================================================================================
-- Stage 2: Create Assessments Table
-- =================================================================================

SELECT 
	'CON' AS [Der_AssTable]
	,ACON.[UniqSubmissionID]
	,ACON.[NHSEUniqSubmissionID]
	,ACON.[UniqMonthID]
	,ACON.[CodedAssToolType]
	,ACON.[PersScore]
	,CON.[CareContDate] AS [Der_AssToolCompDate]
	,ACON.[RecordNumber]
	,ACON.[MHS607UniqID] AS [Der_AssUniqID]
	,ACON.[OrgIDProv]
	,ACON.[Der_Person_ID]
	,ACON.[UniqServReqID]
	,ACON.[AgeAssessToolCont] AS [Der_AgeAssessTool]
	,ACON.[UniqCareContID]
	,ACON.[UniqCareActID]

INTO #TempAss
FROM  [Reporting_MESH_MHSDS].[MHS607CodedScoreAssessmentAct_Published] AS [ACON]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS201CareContact_Published] AS [CON] 
  ON ACON.[RecordNumber] = CON.[RecordNumber]
  AND ACON.[UniqServReqID] = CON.[UniqServReqID]
  AND ACON.[UniqCareContID] = CON.[UniqCareContID]

WHERE ACON.[Der_Person_ID] IN (SELECT [Der_Person_ID] FROM #TempDischarges)
AND ACON.[UniqServReqID] IN (SELECT [UniqServReqID] FROM #TempDischarges)

INSERT INTO #TempAss
SELECT 
	'REF' AS [Der_AssTable]
	,REF.[UniqSubmissionID]
	,REF.[NHSEUniqSubmissionID]
	,REF.[UniqMonthID]
	,REF.[CodedAssToolType]
	,REF.[PersScore]
	,REF.[AssToolCompTimestamp] AS [Der_AssToolCompDate]
	,REF.[RecordNumber]
	,REF.[MHS606UniqID] AS [Der_AssUniqID]
	,REF.[OrgIDProv]
	,REF.[Der_Person_ID]
	,REF.[UniqServReqID]
	,REF.AgeAssessToolReferCompDate AS [Der_AgeAssessTool]
	,NULL AS [UniqCareContID]
	,NULL AS [UniqCareActID]


FROM [Reporting_MESH_MHSDS].[MHS606CodedScoreAssessmentRefer_Published] AS [REF]

WHERE REF.[Der_Person_ID] IN (SELECT [Der_Person_ID] FROM #TempDischarges)
AND REF.[UniqServReqID] IN (SELECT [UniqServReqID] FROM #TempDischarges)

INSERT INTO #TempAss
SELECT
	'CLU' AS [Der_AssTable]
	,ACLU.[UniqSubmissionID]
	,ACLU.[NHSEUniqSubmissionID]
	,CLU.[UniqMonthID]
	,ACLU.[CodedAssToolType]
	,ACLU.[PersScore]
	,CLU.[AssToolCompDate] AS [Der_AssToolCompDate]
	,CLU.[RecordNumber]
	,ACLU.[MHS802UniqID] AS [Der_AssUniqID]
	,ACLU.[OrgIDProv]
	,ACLU.[Der_Person_ID] AS [Person_ID]
	,RF.[UniqServReqID]
	,NULL AS [Der_AgeAssessTool]
	,NULL AS [UniqCareContID]
	,NULL AS [UniqCareActID]

FROM [Reporting_MESH_MHSDS].[MHS802ClusterAssess_Published] AS [ACLU]

LEFT JOIN [Reporting_MESH_MHSDS].[MHS801ClusterTool_Published] AS [CLU]
ON ACLU.[UniqClustID] = CLU.[UniqClustID]
AND ACLU.[RecordNumber] = CLU.[RecordNumber]

INNER JOIN [Reporting_MESH_MHSDS].[MHS101Referral_Published] AS [RF]
ON CLU.[RecordNumber] = RF.[RecordNumber]

WHERE CLU.[Der_Person_ID] IN (SELECT [Der_Person_ID] FROM #TempDischarges)
AND RF.[UniqServReqID] IN (SELECT [UniqServReqID] FROM #TempDischarges)


-- =================================================================================
-- Stage 3: Join Assessments to SNOMED Reference, limit to HONOS
-- =================================================================================

SELECT *
INTO #TempAssReference
FROM #TempAss AS ASS

LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD] AS SNO
ON ASS.[CodedAssToolType] = SNO.[Concept_ID]
AND SNO.[Term] LIKE '%Health of the Nation Outcome Scales%'
AND SNO.[Term] LIKE '%score%'
--AND SNO.[Type_ID] = '900000000000003001'

-- =================================================================================
-- Stage 4: Combined HoNOS Score for Each Assessment
-- =================================================================================

SELECT [Der_Person_ID]
	   ,[UniqServReqID]
	   ,[RecordNumber]
	   ,[Der_AssTable]
	   ,[Type_ID]
	   ,[Der_AssToolCompDate]
	   ,SUM(CAST([PersScore] AS INT)) AS [CombinedScore]
INTO #TempAssCombScores
FROM #TempAssReference

WHERE [PersScore] IN ('0','1','2','3','4')
GROUP BY [Der_Person_ID]
	   ,[UniqServReqID]
	   ,[RecordNumber]
	   ,[Der_AssTable]
	   ,[Type_ID]
	   ,[Der_AssToolCompDate]

-- =================================================================================
-- Stage 5: Join HoNOS combined scores to Discharges and identify first/last
-- =================================================================================

SELECT Dis.*
	   ,AssScore.[Der_AssToolCompDate]
	   ,AssScore.[CombinedScore]
	   ,ROW_NUMBER() OVER (PARTITION BY Dis.[Der_Person_ID], Dis.[UniqServReqID], Dis.[MHS102UniqID] ORDER BY Der_AssToolCompDate) AS [Der_First_Ass_WS]
	   ,ROW_NUMBER() OVER (PARTITION BY Dis.[Der_Person_ID], Dis.[UniqServReqID], Dis.[MHS102UniqID] ORDER BY Der_AssToolCompDate DESC) AS [Der_Last_Ass_WS]
INTO #TempDisAssLink
FROM #TempDischarges as [Dis]

INNER JOIN #TempAssCombScores as [AssScore]
ON Dis.[Der_Person_ID] = AssScore.[Der_Person_ID]
AND Dis.[UniqServReqID] = AssScore.[UniqServReqID]
AND AssScore.[Der_AssToolCompDate] BETWEEN DIS.[ReferralRequestReceivedDate] AND CASE WHEN DIS.[ServDischDate] is Null THEN CAST(GETDATE() AS date)
                                                                                        ELSE DIS.[ServDischDate]
                                                                                 END

-- =================================================================================
-- Stage 6: Join Discharges to First Assessment and Last Assessments
-- =================================================================================

SELECT Dis.*
	   ,AssScoreFirst.[Der_AssToolCompDate] AS [Der_FirstAssToolCompDate]
	   ,AssScoreFirst.[CombinedScore] AS [Der_FirstCombinedScore]
	   ,AssScoreLast.[Der_AssToolCompDate] AS [Der_LastAssToolCompDate]
	   ,AssScoreLast.[CombinedScore] AS [Der_LastCombinedScore]
	   ,DATEDIFF(DAY, Dis.[ReferralRequestReceivedDate], CASE WHEN DIS.[ServDischDate] is Null THEN CAST(GETDATE() AS date) ELSE DIS.[ServDischDate] END) AS [ReferralDays]
INTO #TempDisFirstLastAss
FROM #TempDischarges as [Dis]

LEFT JOIN #TempDisAssLink as [AssScoreFirst]
ON Dis.[Der_Person_ID] = AssScoreFirst.[Der_Person_ID]
AND Dis.[UniqServReqID] = AssScoreFirst.[UniqServReqID]
AND AssScoreFirst.[Der_First_Ass_WS] = 1

LEFT JOIN #TempDisAssLink as [AssScoreLast]
ON Dis.[Der_Person_ID] = AssScoreLast.[Der_Person_ID]
AND Dis.[UniqServReqID] = AssScoreLast.[UniqServReqID]
AND AssScoreLast.[Der_Last_Ass_WS] = 1
AND AssScoreLast.[Der_First_Ass_WS] != 1

SELECT [Der_Person_ID]
	   ,[UniqServReqID]
	   ,[RecordNumber]
	   ,[ReferralRequestReceivedDate]
	   ,[ServDischDate]
	   ,[ReferralDays]
	   ,[Der_FirstAssToolCompDate]
	   ,[Der_FirstCombinedScore]
	   ,[Der_LastAssToolCompDate]
	   ,[Der_LastCombinedScore]
	   ,CASE WHEN [Der_FirstAssToolCompDate] IS NOT NULL AND [Der_LastAssToolCompDate] IS NOT NULL THEN 'Match' ELSE 'No Match' END AS [Paired_HoNOS]
	   ,CASE WHEN [Der_FirstAssToolCompDate] IS NOT NULL AND [Der_LastAssToolCompDate] IS NOT NULL AND [Der_LastCombinedScore] < [Der_FirstCombinedScore] THEN 'Improved'
			WHEN [Der_FirstAssToolCompDate] IS NOT NULL AND [Der_LastAssToolCompDate] IS NOT NULL AND [Der_LastCombinedScore] = [Der_FirstCombinedScore] THEN 'Same'
			WHEN [Der_FirstAssToolCompDate] IS NOT NULL AND [Der_LastAssToolCompDate] IS NOT NULL AND [Der_LastCombinedScore] > [Der_FirstCombinedScore] THEN 'Declined'
			ELSE 'No Match'
			END AS [Paired_HoNOS_Score]
INTO #PairedHoNOS
FROM #TempDisFirstLastAss


-- =================================================================================
-- Stage 7: Extract Paired HONOS table
-- =================================================================================

SELECT *
FROM #PairedHoNOS
