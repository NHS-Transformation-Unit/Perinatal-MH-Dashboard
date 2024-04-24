
-- Script for exploring joins between MHS101 and MHS102

--- Foundation script for identifying all columns/tables we need to pull into one MHSDS dashboard data source

SELECT TOP (100)
    r.UniqMonthID, 
    r.Der_Person_ID, 
    r.AgeServReferRecDate,
    r.RecordNumber, 
    r.UniqServReqID, 
    r.ReferralRequestReceivedDate,
    r.SourceOfReferralMH,
    r.OrgIDProv,
    ro.ODS_Prov_orgName, 
    f.ReportingPeriodStartDate,
    f.ReportingPeriodEndDate,
    h.UniqHospProvSpellID,
    h.StartDateHospProvSpell,
    h.DischDateHospProvSpell,
    s.ServTeamTypeRefToMH,
    rs.Main_Description,
    d.EthnicCategory,
    re.Ethnic_Category_Main_Desc,
    d.DefaultPostcode,
    d.LSOA2011,
    d.IMDQuart,
    o.OnwardReferDate,
    o.OnwardReferReason,
    o.OrgIDReceiving

FROM [NHSE_MHSDS].[dbo].[MHS101Referral] r

INNER JOIN [NHSE_MHSDS].[dbo].[MHSDS_SubmissionFlags] f ON r.NHSEUniqSubmissionID = f.NHSEUniqSubmissionID AND f.Der_IsLatest = 'Y'
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS501HospProvSpell] h ON r.RecordNumber = h.RecordNumber AND r.UniqServReqID = h.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS102ServiceTypeReferredTo] s ON r.RecordNumber = s.RecordNumber AND r.UniqServReqID = s.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS001MPI] d ON r.RecordNumber = d.RecordNumber
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS104RTT] t ON r.RecordNumber = t.RecordNumber AND r.UniqServReqID = t.UniqServReqID
LEFT JOIN [NHSE_MHSDS].[dbo].[MHS105OnwardReferral] o ON r.RecordNumber = o.RecordNumber AND r.UniqServReqID = o.UniqServReqID

LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_EthnicCategory] re ON d.EthnicCategory = re.Ethnic_Category
LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_DataDic_ZZZ_ServiceOrTeamTypeForMentalHealth] rs ON s.ServTeamTypeRefToMH = rs.Main_Code_Text
LEFT JOIN [NHSE_Reference].[dbo].[tbl_Ref_ODS_ProviderSite] ro ON r.OrgIDProv = ro.ODS_Prov_OrgCode

WHERE r.UniqMonthID BETWEEN 1477 AND 1488 -- Apr to May 2023/24
AND r.OrgIDProv IN ('RV5', 'RPG', 'RQY') -- SLaM, Oxleas and SWLaSG
AND s.ServTeamTypeRefToMH = 'C02' -- Perinatal 
AND r.AgeServReferRecDate BETWEEN 15 AND 44;
