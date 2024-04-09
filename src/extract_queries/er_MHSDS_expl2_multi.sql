
-- Script for exploring aggregated count data from MHSDS across multiple months

SELECT
m.EthnicCategory,
m.OrgIDProv,
m.OrgIDCCGRes,
SUM(CASE WHEN h.StartDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN 1 ELSE 0 END) AS Admissions,
COUNT(DISTINCT CASE WHEN h.StartDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN h.Der_Person_ID END) AS PeopleAdmitted,
SUM(CASE WHEN h.DischDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN 1 ELSE 0 END) AS Discharges,
COUNT(DISTINCT CASE WHEN h.DischDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN h.Der_Person_ID END) AS PeopleDischarged

FROM #HospOrder h

INNER JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] m ON m.RecordNumber = h.RecordNumber 

WHERE h.Der_HospSpellRecordOrder = 1
