
-- Script to read the MHSDS_Q2_Caseload_Main.sql temp tables into RStudio

SELECT *,
DATEDIFF(DAY, [ReferralRequestReceivedDate], [CareContDate]) as [Days_First_Contact]
FROM #temp_Q3_First_Contact_Order
WHERE [Order] = 1;
