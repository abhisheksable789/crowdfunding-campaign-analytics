-- ==============================================================================
-- 🚀 CROWDFUNDING & KICKSTARTER CAMPAIGN ANALYTICS
-- Database Management, Data Transformation, and KPI Business Intelligence Queries
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1️⃣ TABLE DDL SCHEMAS
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS dim_category (
    category_id INT PRIMARY KEY,
    name VARCHAR(255),
    parent_id INT,
    position INT
);

CREATE TABLE IF NOT EXISTS dim_creator (
    creator_id INT PRIMARY KEY,
    name VARCHAR(255),
    chosen_currency VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS dim_location (
    location_id INT PRIMARY KEY,
    name VARCHAR(255),
    country VARCHAR(10),
    state VARCHAR(255),
    type VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS fact_projects (
    project_id INT PRIMARY KEY,
    state VARCHAR(50), -- successful, failed, canceled, suspended, live
    name VARCHAR(500),
    country VARCHAR(10),
    creator_id INT,
    location_id INT,
    category_id INT,
    created_at INT,       -- Epoch timestamp
    deadline INT,         -- Epoch timestamp
    updated_at INT,       -- Epoch timestamp
    state_changed_at INT, -- Epoch timestamp
    successful_at VARCHAR(100),
    launched_at INT,      -- Epoch timestamp
    goal DECIMAL(18, 2),
    pledged DECIMAL(18, 2),
    currency VARCHAR(10),
    currency_symbol VARCHAR(10),
    usd_pledged DECIMAL(18, 2),
    static_usd_rate DECIMAL(10, 6),
    backers_count INT,
    spotlight VARCHAR(10),
    staff_pick VARCHAR(10),
    blurb TEXT
);

-- ------------------------------------------------------------------------------
-- 2️⃣ DATA TRANSFORMATION: EPOCH TIMESTAMP TO NATURAL DATETIME
-- ------------------------------------------------------------------------------
-- Converting Epoch seconds (UNIX time) to Human-Readable DateTime & Date formats

SELECT 
    project_id,
    name,
    state,
    -- Converted Dates
    FROM_UNIXTIME(created_at) AS created_datetime,
    DATE(FROM_UNIXTIME(created_at)) AS created_date,
    FROM_UNIXTIME(launched_at) AS launched_datetime,
    DATE(FROM_UNIXTIME(launched_at)) AS launched_date,
    FROM_UNIXTIME(deadline) AS deadline_datetime,
    DATE(FROM_UNIXTIME(deadline)) AS deadline_date,
    -- Campaign Duration in Days
    DATEDIFF(FROM_UNIXTIME(deadline), FROM_UNIXTIME(launched_at)) AS campaign_duration_days,
    -- Goal Converted to USD using Static Rate
    (goal * static_usd_rate) AS goal_usd,
    pledged,
    usd_pledged,
    backers_count
FROM fact_projects;

-- ------------------------------------------------------------------------------
-- 3️⃣ CALENDAR TABLE GENERATION (Financial Year: April - March)
-- ------------------------------------------------------------------------------

CREATE OR REPLACE VIEW view_calendar_table AS
SELECT 
    cal_date,
    YEAR(cal_date) AS Year,
    MONTH(cal_date) AS Monthno,
    MONTHNAME(cal_date) AS Monthfullname,
    CONCAT('Q', QUARTER(cal_date)) AS Quarter,
    DATE_FORMAT(cal_date, '%Y-%b') AS YearMonth,
    DAYOFWEEK(cal_date) AS Weekdayno,
    DAYNAME(cal_date) AS Weekdayname,
    -- Financial Month: April = FM1, May = FM2 ... March = FM12
    CASE 
        WHEN MONTH(cal_date) >= 4 THEN MONTH(cal_date) - 3 
        ELSE MONTH(cal_date) + 9 
    END AS FinancialMonth,
    -- Financial Quarter: FQ-1 (Apr-Jun), FQ-2 (Jul-Sep), FQ-3 (Oct-Dec), FQ-4 (Jan-Mar)
    CASE 
        WHEN MONTH(cal_date) BETWEEN 4 AND 6 THEN 'FQ-1'
        WHEN MONTH(cal_date) BETWEEN 7 AND 9 THEN 'FQ-2'
        WHEN MONTH(cal_date) BETWEEN 10 AND 12 THEN 'FQ-3'
        ELSE 'FQ-4'
    END AS FinancialQuarter
FROM (
    SELECT DISTINCT DATE(FROM_UNIXTIME(created_at)) AS cal_date 
    FROM fact_projects 
    WHERE created_at IS NOT NULL
) dates_query;

-- ------------------------------------------------------------------------------
-- 4️⃣ PROJECTS OVERVIEW KPIS
-- ------------------------------------------------------------------------------

-- KPI 4.1: Total Number of Projects by Outcome State
SELECT 
    state AS Project_Outcome,
    COUNT(*) AS Total_Projects,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_projects)), 2) AS Percentage_Share
FROM fact_projects
GROUP BY state
ORDER BY Total_Projects DESC;

-- KPI 4.2: Total Number of Projects by Country / Location
SELECT 
    country,
    COUNT(*) AS Total_Projects,
    SUM(usd_pledged) AS Total_Pledged_USD,
    SUM(backers_count) AS Total_Backers
FROM fact_projects
GROUP BY country
ORDER BY Total_Projects DESC;

-- KPI 4.3: Total Number of Projects by Category
SELECT 
    c.name AS Category_Name,
    COUNT(p.project_id) AS Total_Projects,
    SUM(p.usd_pledged) AS Total_Pledged_USD,
    SUM(p.backers_count) AS Total_Backers
FROM fact_projects p
LEFT JOIN dim_category c ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY Total_Projects DESC;

-- KPI 4.4: Total Number of Projects Created by Year, Quarter, Month
SELECT 
    YEAR(FROM_UNIXTIME(created_at)) AS Created_Year,
    CONCAT('Q', QUARTER(FROM_UNIXTIME(created_at))) AS Created_Quarter,
    MONTHNAME(FROM_UNIXTIME(created_at)) AS Created_Month,
    COUNT(*) AS Projects_Created
FROM fact_projects
GROUP BY 
    YEAR(FROM_UNIXTIME(created_at)),
    QUARTER(FROM_UNIXTIME(created_at)),
    MONTH(FROM_UNIXTIME(created_at)),
    MONTHNAME(FROM_UNIXTIME(created_at))
ORDER BY Created_Year, MONTH(FROM_UNIXTIME(created_at));

-- ------------------------------------------------------------------------------
-- 5️⃣ SUCCESSFUL PROJECTS DEEP-DIVE
-- ------------------------------------------------------------------------------

-- KPI 5.1: Overall Summary of Successful Projects
SELECT 
    COUNT(*) AS Total_Successful_Projects,
    SUM(usd_pledged) AS Total_Amount_Raised_USD,
    SUM(backers_count) AS Total_Backers,
    ROUND(AVG(DATEDIFF(FROM_UNIXTIME(deadline), FROM_UNIXTIME(launched_at))), 1) AS Avg_Duration_Days,
    ROUND(AVG(usd_pledged / NULLIF(backers_count, 0)), 2) AS Avg_Pledge_Per_Backer_USD
FROM fact_projects
WHERE state = 'successful';

-- ------------------------------------------------------------------------------
-- 6️⃣ TOP SUCCESSFUL PROJECTS
-- ------------------------------------------------------------------------------

-- KPI 6.1: Top 10 Projects by Number of Backers
SELECT 
    project_id,
    name AS Project_Name,
    country,
    backers_count,
    usd_pledged AS Amount_Raised_USD,
    (goal * static_usd_rate) AS Goal_USD,
    ROUND((usd_pledged * 100.0 / NULLIF(goal * static_usd_rate, 0)), 2) AS Funding_Percentage
FROM fact_projects
WHERE state = 'successful'
ORDER BY backers_count DESC
LIMIT 10;

-- KPI 6.2: Top 10 Projects by Amount Raised (USD Pledged)
SELECT 
    project_id,
    name AS Project_Name,
    country,
    usd_pledged AS Amount_Raised_USD,
    backers_count,
    (goal * static_usd_rate) AS Goal_USD,
    ROUND((usd_pledged * 100.0 / NULLIF(goal * static_usd_rate, 0)), 2) AS Funding_Percentage
FROM fact_projects
WHERE state = 'successful'
ORDER BY usd_pledged DESC
LIMIT 10;

-- ------------------------------------------------------------------------------
-- 7️⃣ SUCCESS RATE (%) MULTIDIMENSIONAL ANALYSIS
-- ------------------------------------------------------------------------------

-- KPI 7.1: Overall Project Success Rate
SELECT 
    COUNT(*) AS Total_Projects,
    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) AS Successful_Projects,
    SUM(CASE WHEN state = 'failed' THEN 1 ELSE 0 END) AS Failed_Projects,
    ROUND(SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Overall_Success_Rate_Percentage
FROM fact_projects;

-- KPI 7.2: Success Rate % by Category
SELECT 
    c.name AS Category_Name,
    COUNT(p.project_id) AS Total_Projects,
    SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) AS Successful_Projects,
    ROUND(SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(p.project_id), 2) AS Success_Rate_Percentage,
    SUM(p.usd_pledged) AS Total_Pledged_USD
FROM fact_projects p
LEFT JOIN dim_category c ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY Success_Rate_Percentage DESC;

-- KPI 7.3: Success Rate % by Year and Month
SELECT 
    YEAR(FROM_UNIXTIME(p.created_at)) AS Year,
    MONTHNAME(FROM_UNIXTIME(p.created_at)) AS Month,
    COUNT(*) AS Total_Projects,
    SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) AS Successful_Projects,
    ROUND(SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Success_Rate_Percentage
FROM fact_projects p
GROUP BY YEAR(FROM_UNIXTIME(p.created_at)), MONTH(FROM_UNIXTIME(p.created_at)), MONTHNAME(FROM_UNIXTIME(p.created_at))
ORDER BY Year, MONTH(FROM_UNIXTIME(p.created_at));

-- KPI 7.4: Success Rate % by Goal Range (USD)
SELECT 
    CASE 
        WHEN (goal * static_usd_rate) < 1000 THEN '1. Under $1,000'
        WHEN (goal * static_usd_rate) BETWEEN 1000 AND 4999 THEN '2. $1,000 - $4,999'
        WHEN (goal * static_usd_rate) BETWEEN 5000 AND 9999 THEN '3. $5,000 - $9,999'
        WHEN (goal * static_usd_rate) BETWEEN 10000 AND 49999 THEN '4. $10,000 - $49,999'
        WHEN (goal * static_usd_rate) BETWEEN 50000 AND 99999 THEN '5. $50,000 - $99,999'
        ELSE '6. $100,000 and Above'
    END AS Goal_Range_USD,
    COUNT(*) AS Total_Projects,
    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) AS Successful_Projects,
    ROUND(SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Success_Rate_Percentage,
    SUM(usd_pledged) AS Total_Raised_USD
FROM fact_projects
GROUP BY 
    CASE 
        WHEN (goal * static_usd_rate) < 1000 THEN '1. Under $1,000'
        WHEN (goal * static_usd_rate) BETWEEN 1000 AND 4999 THEN '2. $1,000 - $4,999'
        WHEN (goal * static_usd_rate) BETWEEN 5000 AND 9999 THEN '3. $5,000 - $9,999'
        WHEN (goal * static_usd_rate) BETWEEN 10000 AND 49999 THEN '4. $10,000 - $49,999'
        WHEN (goal * static_usd_rate) BETWEEN 5000 AND 99999 THEN '5. $50,000 - $99,999'
        ELSE '6. $100,000 and Above'
    END
ORDER BY Goal_Range_USD;
