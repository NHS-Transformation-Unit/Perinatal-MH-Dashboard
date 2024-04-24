
-- Script for exploring joins between MHS101 and MHS102

--- Foundation script for identifying all columns/tables we need to pull into one MHSDS dashboard data source

SELECT TOP (100) -- Do I want to use DISTINCT to limit the number of Der_Persdon_ID I return?
    r.UniqMonthID, 
    r.Der_Person_ID, 
    f.ReportingPeriodStartDate,
    f.ReportingPeriodEndDate,
    r.RecordNumber, 
    r.UniqServReqID, 
    r.ReferralRequestReceivedDate,
    r.SourceOfReferralMH,
    r.OrgIDProv,
    h.UniqHospProvSpellID,
    h.StartDateHospProvSpell,
    h.DischDateHospProvSpell,
    s.ServTeamTypeRefToMH,
    d.EthnicCategory,
    --t.ReferToTreatPeriodStartDate, nearly all entries are NULL
    --t.ReferToTreatPeriodEndDate, nearly all entries are NULL
    o.OnwardReferDate,
    --o.OnwardReferReason, nearly all entries are NULL
    o.OrgIDReceiving

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] r

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] f ON r.NHSEUniqSubmissionID = f.NHSEUniqSubmissionID AND f.Der_IsLatest = 'Y'
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS501HospProvSpell] h ON r.NHSEUniqSubmissionID = h.NHSEUniqSubmissionID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] s ON r.RecordNumber = s.RecordNumber AND r.UniqServReqID = s.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] d ON r.NHSEUniqSubmissionID = d.NHSEUniqSubmissionID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS104RTT] t ON r.NHSEUniqSubmissionID = t.NHSEUniqSubmissionID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS105OnwardReferral] o ON r.NHSEUniqSubmissionID = o.NHSEUniqSubmissionID
WHERE r.UniqMonthID BETWEEN 1477 AND 1488 -- Apr to May 2023/24
AND r.OrgIDProv IN ('RV5', 'RPG', 'RQY')
AND s.ServTeamTypeRefToMH = 'C02'; -- SLaM, Oxleas and SWLaSG
