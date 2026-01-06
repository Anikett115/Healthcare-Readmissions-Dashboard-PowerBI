/*
====================================================
File: 01_data_generation.sql
Project: Healthcare Readmissions Dashboard – Power BI
Author: Aniket Aman

Purpose:
- Create a simulated healthcare clinical dataset
- Generate large-scale hospital-level admission records
- Mimic real-world variability in admissions, readmissions,
  infections, mortality, and length of stay
====================================================
*/

-- Create database for healthcare analytics
CREATE DATABASE HEALTHCARE1;
GO

-- Switch context to the healthcare database
USE HEALTHCARE1;
GO

----------------------------------------------------
-- Table: ClinicalData
-- Stores daily hospital-level clinical metrics
----------------------------------------------------
CREATE TABLE ClinicalData (
    HospitalID INT,
    AdmissionDate DATE,
    TotalAdmissions INT,
    Readmissions INT,
    Infections INT,
    TotalDeaths INT,
    AverageLengthOfStay DECIMAL(4,2)
);

----------------------------------------------------
-- Variable declarations for data generation
----------------------------------------------------
DECLARE 
    @hospitalID INT,
    @date DATE,
    @totalAdmissions INT,
    @readmissions INT,
    @infections INT,
    @totalDeaths INT,
    @averageLengthOfStay DECIMAL(4,2),
    @i INT;

----------------------------------------------------
-- Outer loop: iterate through hospitals
-- Simulates data for 10 different hospitals
----------------------------------------------------
SET @i = 1;

WHILE @i <= 10
BEGIN
    SET @hospitalID = @i;

    ------------------------------------------------
    -- Inner loop: generate daily records per hospital
    -- Generates ~2 million records per hospital
    -- Total dataset size ≈ 20 million rows
    ------------------------------------------------
    DECLARE @j INT = 1;

    WHILE @j <= 2000000
    BEGIN
        -- Generate sequential admission dates
        SET @date = DATEADD(DAY, @j, '2024-01-01');

        -- Generate realistic admission volumes (50–200 per day)
        SET @totalAdmissions = ABS(CHECKSUM(NEWID())) % 150 + 50;

        -- Readmissions derived as a fraction of total admissions
        SET @readmissions = ABS(CHECKSUM(NEWID())) % @totalAdmissions / 10;

        -- Random infection counts (0–4 per day)
        SET @infections = ABS(CHECKSUM(NEWID())) % 5;

        -- Random mortality counts (0–2 per day)
        SET @totalDeaths = ABS(CHECKSUM(NEWID())) % 3;

        -- Average length of stay between 1–7 days
        SET @averageLengthOfStay =
            ROUND((ABS(CHECKSUM(NEWID())) % 7 + 1) * 1.0, 2);

        -- Insert generated record into ClinicalData table
        INSERT INTO ClinicalData (
            HospitalID,
            AdmissionDate,
            TotalAdmissions,
            Readmissions,
            Infections,
            TotalDeaths,
            AverageLengthOfStay
        )
        VALUES (
            @hospitalID,
            @date,
            @totalAdmissions,
            @readmissions,
            @infections,
            @totalDeaths,
            @averageLengthOfStay
        );

        SET @j = @j + 1;
    END

    SET @i = @i + 1;
END

----------------------------------------------------
-- Validation queries
----------------------------------------------------

-- Preview sample records
SELECT TOP 10 *
FROM ClinicalData;

-- Verify total record count
SELECT COUNT(*) AS TotalRecords
FROM ClinicalData;





