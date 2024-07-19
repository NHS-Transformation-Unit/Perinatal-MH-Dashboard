
-- Script to read the MHSDS_Q1_Access.sql temp tables into RStudio

SELECT [OrgIDProv],
      [ODS_Prov_orgName],
      COUNT(DISTINCT Der_Person_ID) 
FROM #temp_Q1_Access
GROUP BY [OrgIDProv],[ODS_Prov_orgName];
