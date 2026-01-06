-- =========================================================
-- Purpose:
-- --------
-- Create a reporting-friendly view that hides internal
-- metrics such as AverageLengthOfStay from end users.
-- =========================================================

CREATE OR ALTER VIEW vw_ClinicalData_Report
AS
SELECT
    HospitalID,
    AdmissionDate,
    TotalAdmissions,
    Readmissions,
    Infections,
    TotalDeaths
FROM NEW_TABLE;
GO
