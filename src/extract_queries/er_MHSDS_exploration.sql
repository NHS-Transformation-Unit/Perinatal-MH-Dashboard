-- Script for exploring aggregated count data from MHSDS

SELECT
	r.UniqMonthID,
	m.OrgIDCCGRes AS CCG,
	r.AgeServReferRecDate,
	m.EthnicCategory,
	s.ServTeamTypeRefToMH,
	COUNT(r.UniqServReqID) AS Referrals,
	COUNT(DISTINCT r.Der_Person_ID) AS People

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] r

INNER JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] m ON r.RecordNumber = m.RecordNumber
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] s ON r.RecordNumber = s.RecordNumber AND r.UniqServReqID = s.UniqServReqID
INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] f ON r.NHSEUniqSubmissionID = f.NHSEUniqSubmissionID AND f.Der_IsLatest = 'Y'

WHERE r.ServDischDate IS NULL OR r.ServDischDate > f.ReportingPeriodEndDate

GROUP BY r.UniqMonthID, m.OrgIDCCGRes, r.AgeServReferRecDate, m.EthnicCategory, s.ServTeamTypeRefToMH

ORDER BY r.UniqMonthID DESC