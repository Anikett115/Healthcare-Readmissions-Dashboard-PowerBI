/* =========================================================
   Script Name  : 02_data_cleanup_date_correction.sql
   Purpose      : Correct unrealistic admission dates
   Description  :
   - Creates a working copy of the ClinicalData table
   - Identifies admission dates beyond the year 2030
   - Replaces invalid dates with realistic dates between
     2024-01-01 and 2030-12-31
   ========================================================= */

-- Create a working copy of the original dataset
SELECT *
INTO NEW_TABLE
FROM ClinicalData;

-- Quick validation: preview sample records
SELECT TOP 10 *
FROM NEW_TABLE;

------------------------------------------------------------
-- Data Quality Fix: Handle unrealistic future admission dates
-- Problem:
-- Some records contain AdmissionDate values beyond year 2030,
-- which is not realistic for healthcare analysis.
--
-- Solution:
-- Reassign such dates to a random valid date within
-- the range 2024-01-01 to 2030-12-31
------------------------------------------------------------

UPDATE NEW_TABLE
SET AdmissionDate =
    CASE
        WHEN YEAR(AdmissionDate) > 2030 THEN
            DATEADD(
                DAY,
                ABS(CHECKSUM(NEWID())) %
                DATEDIFF(DAY, '2024-01-01', '2030-12-31') + 1,
                '2024-01-01'
            )
        ELSE AdmissionDate
    END;

------------------------------------------------------------
-- Post-update validation checks
------------------------------------------------------------

-- Verify the maximum admission date
SELECT MAX(AdmissionDate) AS MaxAdmissionDate
FROM NEW_TABLE;

-- Verify the minimum admission date
SELECT MIN(AdmissionDate) AS MinAdmissionDate
FROM NEW_TABLE;
