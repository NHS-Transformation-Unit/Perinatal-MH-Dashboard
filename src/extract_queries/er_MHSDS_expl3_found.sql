
-- Script for exploring joins between MHS101 and MHS102

--- Foundation script for identifying all columns/tables we need to pull into one MHSDS dashboard data source

SELECT
    r.UniqMonthID, 
    r.Der_Person_ID, 
    f.ReportingPeriodStartDate,
    f.ReportingPeriodEndDate,
    r.RecordNumber, 
    r.UniqServReqID, 
    h.UniqHospProvSpellID,
    h.StartDateHospProvSpell,
    h.DischDateHospProvSpell,
    s.ServTeamTypeRefToMH,
    r.OrgIDProv,
    d.EthnicCategory,
    r.ReferralRequestReceivedDate,
    r.SourceOfReferralMH,
    t.ReferToTreatPeriodStartDate,
    t.ReferToTreatPeriodEndDate,
    o.OnwardReferDate,
    o.OnwardReferReason,
    o.OrgIDReceiving

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] r

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] f ON r.NHSEUniqSubmissionID = f.NHSEUniqSubmissionID AND f.Der_IsLatest = 'Y'
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS501HospProvSpell] h ON r.NHSEUniqSubmissionID = h.NHSEUniqSubmissionID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] s ON r.RecordNumber = s.RecordNumber AND r.UniqServReqID = s.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] d ON r.NHSEUniqSubmissionID = d.NHSEUniqSubmissionID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS104RTT] t ON r.NHSEUniqSubmissionID = t.NHSEUniqSubmissionID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS105OnwardReferral] o ON r.NHSEUniqSubmissionID = o.NHSEUniqSubmissionID
WHERE r.UniqMonthID BETWEEN 1462 AND 1464; -- Jan to Mar 2022
