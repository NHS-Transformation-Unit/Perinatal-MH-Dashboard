
-- Script for exploring joins between the MHS101 Referral table and all other tables containing data needed for dashboard requirements

--- Further development of the foundation script (`expl3`) but removing reference joins due to time taken to query

SELECT DISTINCT TOP (1000)
ref.UniqMonthID, 
ref.Der_Person_ID, 
ref.AgeServReferRecDate,
ref.RecordNumber, 
ref.UniqServReqID, 
ref.ReferralRequestReceivedDate,
ref.SourceOfReferralMH,
ref.OrgIDProv,
flag.ReportingPeriodStartDate,
flag.ReportingPeriodEndDate,
hs.UniqHospProvSpellID,
hs.StartDateHospProvSpell,
hs.DischDateHospProvSpell,
serv.ServTeamTypeRefToMH,
dem.EthnicCategory,
dem.DefaultPostcode,
dem.LSOA2011,
dem.IMDQuart,
onr.OnwardReferDate,
onr.OnwardReferReason,
onr.OrgIDReceiving

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] ref

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] flag ON ref.NHSEUniqSubmissionID = flag.NHSEUniqSubmissionID AND flag.Der_IsLatest = 'Y'
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS501HospProvSpell] hs ON ref.RecordNumber = hs.RecordNumber AND ref.UniqServReqID = hs.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] serv ON ref.RecordNumber = serv.RecordNumber AND ref.UniqServReqID = serv.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] dem ON ref.RecordNumber = dem.RecordNumber
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS105OnwardReferral] o ON ref.RecordNumber = onr.RecordNumber AND ref.UniqServReqID = onr.UniqServReqID

WHERE ref.UniqMonthID BETWEEN 1477 AND 1488 -- Apr to May 2023/24
AND ref.OrgIDProv IN ('RV5', 'RPG', 'RQY') -- SLaM, Oxleas and SWLaSG
AND serv.ServTeamTypeRefToMH = 'C02' -- Perinatal 
AND ref.AgeServReferRecDate BETWEEN 15 AND 44 -- possibly remove as we only need the denominators

ORDER BY ref.Der_Person_ID DESC;
