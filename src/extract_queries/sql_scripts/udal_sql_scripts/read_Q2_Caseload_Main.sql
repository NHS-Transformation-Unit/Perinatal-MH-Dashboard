
-- Script to read the MHSDS_Q2_Caseload_Main.sql temp tables into RStudio

SELECT *
FROM #temp_Q2_Caseload_Main_Order
WHERE [Order] = 1
  AND [Count] = 1;
