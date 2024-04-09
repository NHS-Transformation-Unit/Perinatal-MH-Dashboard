
-- Script for exploring aggregated count data from MHSDS across multiple months

--- Dropping the temporary table if ruh multiple times in one session

    DROP TABLE #HospOrder;
    
--- Creating a temporary table

SELECT
    h.UniqMonthID,
    h.Der_Person_ID,
    f.ReportingPeriodStartDate,
    f.ReportingPeriodEndDate,
    h.RecordNumber,
    h.UniqServReqID,
    h.UniqHospProvSpellID,
    h.StartDateHospProvSpell,
    h.DischDateHospProvSpell,
    ROW_NUMBER() OVER (PARTITION BY h.Der_Person_ID, h.UniqServReqID, h.UniqHospProvSpellID ORDER BY h.UniqMonthID DESC) AS Der_HospSpellRecordOrder
INTO #HospOrder
FROM [NHSE_MHSDS].[dbo].[MHS501HospProvSpell] h
INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] f ON h.NHSEUniqSubmissionID = f.NHSEUniqSubmissionID AND f.Der_IsLatest = 'Y'
WHERE h.UniqMonthID BETWEEN 1462 AND 1464; -- Jan to Mar 2022


--- Querying our temporary table

SELECT
SUM(CASE WHEN h.StartDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN 1 ELSE 0 END) AS Admissions,
COUNT(DISTINCT CASE WHEN h.StartDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN h.Der_Person_ID END) AS PeopleAdmitted,
SUM(CASE WHEN h.DischDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN 1 ELSE 0 END) AS Discharges,
COUNT(DISTINCT CASE WHEN h.DischDateHospProvSpell BETWEEN h.ReportingPeriodStartDate AND h.ReportingPeriodEndDate THEN h.Der_Person_ID END) AS PeopleDischarged

FROM #HospOrder h

WHERE h.Der_HospSpellRecordOrder = 1;
