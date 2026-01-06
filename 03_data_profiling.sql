/* =========================================================
   Script Name : 03_data_profiling.sql
   Purpose     : Column-level data profiling and quality analysis
   Description :
   - Generates frequency distributions for each column
   - Computes descriptive statistics (min, max, mean, median, mode, SD)
   - Identifies null values, zero values, and distinct counts
   - Handles numeric, date, string, and boolean columns dynamically
   ========================================================= */

------------------------------------------------------------
-- PART 1: Column Distribution Analysis
-- Generates frequency counts for each column dynamically
------------------------------------------------------------

DECLARE @i INT = 1;
DECLARE @j INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @columnname NVARCHAR(MAX);

-- Get total number of columns in ClinicalData table
SET @j = (
    SELECT MAX(ORDINAL_POSITION)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'ClinicalData'
);

WHILE @i <= @j
BEGIN
    -- Fetch column name based on ordinal position
    SELECT @columnname = COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'ClinicalData'
      AND ORDINAL_POSITION = @i;

    -- Dynamic frequency distribution query
    SET @SQL = '
        SELECT ' + @columnname + ',
               COUNT(*) AS Frequency
        FROM ClinicalData
        GROUP BY ' + @columnname + '
        ORDER BY Frequency DESC';

    EXEC sp_executesql @SQL;

    SET @i = @i + 1;
END;

------------------------------------------------------------
-- PART 2: Metadata Extraction for Profiling
------------------------------------------------------------

DROP TABLE IF EXISTS #Profile;

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    ORDINAL_POSITION,
    CHARACTER_MAXIMUM_LENGTH
INTO #Profile
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'ClinicalData';

------------------------------------------------------------
-- PART 3: Add Profiling Metrics Columns
------------------------------------------------------------

ALTER TABLE #Profile ADD
    maximum NVARCHAR(MAX),
    minimum NVARCHAR(MAX),
    nulls INT,
    distinct_counts INT,
    mean FLOAT,
    median FLOAT,
    mode NVARCHAR(MAX),
    SD FLOAT,
    zero_values INT;

------------------------------------------------------------
-- PART 4: Dynamic Profiling by Data Type
------------------------------------------------------------

DECLARE @datatype NVARCHAR(MAX);
SET @i = 1;
SET @j = (SELECT MAX(ORDINAL_POSITION) FROM #Profile);

WHILE @i <= @j
BEGIN
    SELECT
        @columnname = COLUMN_NAME,
        @datatype = DATA_TYPE
    FROM #Profile
    WHERE ORDINAL_POSITION = @i;

    --------------------------------------------------------
    -- NUMERIC COLUMNS PROFILING
    --------------------------------------------------------
    IF @datatype IN ('int','decimal','float','real','numeric','money','smallint','tinyint')
    BEGIN
        -- Min, Max, Mean, Standard Deviation
        EXEC('UPDATE #Profile SET maximum = (SELECT MAX(' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET minimum = (SELECT MIN(' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET mean = (SELECT AVG(CAST(' + @columnname + ' AS BIGINT)) FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET SD = (SELECT STDEV(' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);

        -- Zero, Null, Distinct Counts
        EXEC('UPDATE #Profile SET zero_values = (SELECT COUNT(*) FROM ClinicalData WHERE ' + @columnname + ' = 0) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET nulls = (SELECT COUNT(*) FROM ClinicalData WHERE ' + @columnname + ' IS NULL) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET distinct_counts = (SELECT COUNT(DISTINCT ' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);

        -- Mode Calculation
        EXEC('
            UPDATE #Profile SET mode =
            (SELECT STRING_AGG(' + @columnname + ', '','')
             FROM (
                 SELECT ' + @columnname + ',
                        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rn
                 FROM ClinicalData
                 GROUP BY ' + @columnname + '
             ) t WHERE rn = 1)
            WHERE ORDINAL_POSITION = ' + @i);

        -- Median Calculation
        EXEC('
            SELECT ' + @columnname + ',
                   ROW_NUMBER() OVER (ORDER BY ' + @columnname + ') AS rn
            INTO #Temp
            FROM ClinicalData;

            DECLARE @cnt INT = (SELECT COUNT(*) FROM #Temp);
            DECLARE @mid FLOAT;

            IF @cnt % 2 = 0
                SET @mid = (SELECT AVG(' + @columnname + ') FROM #Temp WHERE rn IN (@cnt/2, @cnt/2 + 1));
            ELSE
                SET @mid = (SELECT ' + @columnname + ' FROM #Temp WHERE rn = (@cnt/2 + 1));

            DROP TABLE #Temp;
            UPDATE #Profile SET median = @mid WHERE ORDINAL_POSITION = ' + @i);
    END;

    --------------------------------------------------------
    -- DATE COLUMNS PROFILING
    --------------------------------------------------------
    IF @datatype IN ('date','datetime','datetime2','smalldatetime','time')
    BEGIN
        EXEC('UPDATE #Profile SET maximum = (SELECT MAX(' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET minimum = (SELECT MIN(' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET nulls = (SELECT COUNT(*) FROM ClinicalData WHERE ' + @columnname + ' IS NULL) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET distinct_counts = (SELECT COUNT(DISTINCT ' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
    END;

    --------------------------------------------------------
    -- STRING & BOOLEAN COLUMNS PROFILING
    --------------------------------------------------------
    IF @datatype IN ('varchar','nvarchar','char','nchar','text','bit')
    BEGIN
        EXEC('UPDATE #Profile SET nulls = (SELECT COUNT(*) FROM ClinicalData WHERE ' + @columnname + ' IS NULL) WHERE ORDINAL_POSITION = ' + @i);
        EXEC('UPDATE #Profile SET distinct_counts = (SELECT COUNT(DISTINCT ' + @columnname + ') FROM ClinicalData) WHERE ORDINAL_POSITION = ' + @i);
    END;

    SET @i = @i + 1;
END;

------------------------------------------------------------
-- Final Profiling Output
------------------------------------------------------------

SELECT *
FROM #Profile;
