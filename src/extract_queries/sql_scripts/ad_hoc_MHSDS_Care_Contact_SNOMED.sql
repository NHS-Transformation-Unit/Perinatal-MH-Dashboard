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
	REF.[SpecialisedMHServiceCode],
	REF.[SourceOfReferralMH],
	REF.[OrgIDReferring],
	REF.[ReferringCareProfessionalStaffGroup],
	REF.[ClinRespPriorityType],
	REF.[PrimReasonReferralMH],
	REF.[ReasonOAT],
	REF.[ServDischDate],
	SERV.[MHS102UniqID],
	SERV.[UniqCareProfTeamID],
	SERV.[ServTeamTypeRefToMH],
	ETH.[Ethnic_Category_Main_Desc],
    IMD.[IMD_Decile],
	REF_PROS.[ODS_Prov_orgName],
	CARE.[CareContactId],
	CARE.[CareContDate],
	CARE.[ConsMechanismMH],
	CARE.[AttendOrDNACode],
	CARE_ACT.[CareActId],
	CARE_ACT.[ClinContactDurOfCareAct],
	CARE_ACT.[CodeProcAndProcStatus],
	CARE_ACT.[EFFECTIVE_FROM]

INTO #tempAW_CareActs
FROM [NHSE_MHSDS].[dbo].[MHS101Referral] AS REF

INNER JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] AS MPI
ON REF.[RecordNumber] = MPI.[RecordNumber]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] AS  SERV
ON REF.[UniqServReqID] = SERV.[UniqServReqID] AND REF.[RecordNumber] = SERV.[RecordNumber] 

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] AS SF
ON REF.[NHSEUniqSubmissionID] = SF.[NHSEUniqSubmissionID]
AND SF.[Der_IsLatest] = 'Y'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_EthnicCategory] AS ETH
ON MPI.[EthnicCategory] = ETH.[Ethnic_Category]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth] AS STYPE
ON SERV.[ServTeamTypeRefToMH] = STYPE.[Main_Code_Text]
AND STYPE.[Is_Latest] = '1'

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_ProviderSite] AS REF_PROS
ON REF.[OrgIDProv] = REF_PROS.[ODS_Prov_OrgCode]

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_Other_Deprivation_By_LSOA] as [IMD]
ON MPI.[LSOA2011] = IMD.[LSOA_Code]
AND IMD.[Effective_Snapshot_Date] = '2019-12-31'

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS201CareContact] AS CARE
ON REF.[Der_Person_ID] = CARE.[Der_Person_ID] 
AND REF.[UniqServReqID] = CARE.[UniqServReqID]

LEFT JOIN [NHSE_MHSDS].[dbo].[MHS202CareActivity] as CARE_ACT
ON CARE.[RecordNumber] = CARE_ACT.[RecordNumber]
AND CARE.[UniqServReqID] = CARE_ACT.[UniqServReqID]
AND CARE.[CareContactId] = CARE_ACT.[CareContactId]

WHERE REF.[UniqMonthID] = 1488
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND (REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY'))
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2'
AND CARE.[CareContDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate]
AND CARE.[CareContDate] IS NOT NULL
AND CARE.[ConsMechanismMH] IN ('01', '11')
AND CARE.[AttendOrDNACode] IN ('5', '6')

SELECT * FROM #tempAW_CareActs

SELECT [ReportingPeriodStartDate],
	   [ReportingPeriodEndDate],
	   [OrgIDProv],
	   [Der_Person_ID],
	   [UniqServReqID],
	   [ReferralRequestReceivedDate],
	   [ODS_Prov_orgName],
	   [CareContactId],
	   [CareContDate],
	   [ConsMechanismMH],
	   [CareActId],
	   [ClinContactDurOfCareAct],
	   [CodeProcAndProcStatus],
	   [EFFECTIVE_FROM]

	   FROM #tempAW_CareActs

