
-- Script to return new, open and closed referrals for all English providers between April 2019 and Feb 2024

DECLARE @EndRP INT;

SELECT @EndRP = MAX(UniqMonthID)
FROM [NHSE_MHSDS].[dbo].[MHS101Referral];

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
    LEFT([NHSServAgreeLineNum],10) AS [NHSServAgreeLineNum],
    REF.[SpecialisedMHServiceCode],
    REF.[SourceOfReferralMH],
    REF.[OrgIDReferring],
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
    ETH.[Ethnic_Category_Main_Desc],
    MPI.[LSOA2011],
    IMD.[IMD_Decile],
    MPI.[AgeRepPeriodEnd],
    REF_PROS.[ODS_Prov_orgName],

    CASE WHEN (REF.[ServDischDate] IS NULL OR REF.[ServDischDate] > SF.[ReportingPeriodEndDate]) AND SERV.[ReferRejectionDate] IS NULL THEN 1 ELSE 0 END AS OpenReferrals,
    CASE WHEN REF.[ReferralRequestReceivedDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate] THEN 1 ELSE 0 END AS NewReferrals,
    CASE WHEN REF.[ServDischDate] BETWEEN SF.[ReportingPeriodStartDate] AND SF.[ReportingPeriodEndDate] THEN 1 ELSE 0 END AS ClosedReferrals,
    
    CASE WHEN REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY') THEN 'Providers'
		ELSE 'Other' END AS [Provider_Flag],
	  CASE WHEN REF.[OrgIDProv] IN ('RRU', 'RPG', 'RJZ', 'RJ1', 'RV5', 'RJ2') THEN 'NHS South East London ICB'
		WHEN REF.[OrgIDProv] IN ('RJ7', 'RAX', 'RQY', 'RY9', 'RJ6', 'RVR') THEN 'NHS South West London ICB'
		ELSE 'Other' END AS [ICB_Flag]

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

WHERE REF.[UniqMonthID] BETWEEN 1429 AND @EndRP
AND SERV.[ServTeamTypeRefToMH] = 'C02'
AND REF.[OrgIDProv] IN ('RV5', 'RPG', 'RQY')
AND (MPI.[LADistrictAuth] IS NULL OR MPI.[LADistrictAuth] LIKE ('E%'))
AND MPI.[Gender] = '2';
