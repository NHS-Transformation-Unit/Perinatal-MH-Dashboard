
-- Script to read the MHSDS_Q2_Caseload_Snap.sql temp tables into RStudio

SELECT *
FROM #temp_Q2_Caseload_Snap_Order
WHERE [Order] = 1
  AND [Count] = 1;
