# 🚀 Kickstarter Crowdfunding Campaign Analytics – End-to-End Business Intelligence & Data Analytics

[![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)](https://www.tableau.com/)
[![Excel](https://img.shields.io/badge/Microsoft_Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)](https://www.microsoft.com/en-us/microsoft-365/excel)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)

---

![Crowdfunding Analytics Banner](docs/images/crowdfunding_banner.jpg)

---

## 📌 Executive Summary

The **Kickstarter Crowdfunding Campaign Analytics Project** is an end-to-end data analytics and business intelligence solution designed to evaluate crowdfunding campaigns, backer participation, capital disbursement, funding success determinants, and creator performance across global crowdfunding initiatives.

Using **Power BI**, **Tableau**, **Microsoft Excel**, and **MySQL**, this project transforms complex raw transactional crowdfunding datasets (with UNIX Epoch timestamps and multi-currency metrics) into multidimensional executive dashboards and actionable business intelligence. The resulting insights empower campaign creators, platform operators, and investors to optimize funding targets, time campaign launches, and maximize backer engagement.

---

## 📊 Core Performance Indicators (KPIs) & Metrics

| Metric | Analytical Formula / Definition | Strategic Purpose |
| :--- | :--- | :--- |
| **Total Projects by Outcome** | $\text{COUNT}(\text{Project ID}) \text{ GROUP BY State}$ | Monitors campaign status distribution (Successful, Failed, Canceled, Suspended, Live) |
| **Overall Success Rate %** | $\frac{\text{Successful Projects}}{\text{Total Projects}} \times 100$ | Primary platform health benchmark and creator success baseline |
| **Total Amount Raised (USD)** | $\sum (\text{usd\_pledged})$ | Cumulative financial volume processed across successful campaigns |
| **Total Backer Community** | $\sum (\text{backers\_count})$ | Measures community reach, viral engagement, and investor participation |
| **Average Campaign Duration** | $\text{AVG}(\text{Deadline} - \text{Launched Date}) \text{ [Days]}$ | Evaluates optimal campaign duration for successful closure |
| **Average Pledge per Backer** | $\frac{\text{Total USD Pledged}}{\text{Total Backers}}$ | Identifies donor willingness-to-pay and ticket size per project |
| **Funding Realization %** | $\frac{\text{USD Pledged}}{\text{USD Goal}} \times 100$ | Evaluates overfunding capability and goal achievement ratios |
| **Goal Range Success Distribution** | $\text{Success Rate \% across } [<\$1\text{k}, \$1\text{k}-\$5\text{k}, \dots, >\$100\text{k}]$ | Pinpoints the "sweet spot" funding goal ranges for maximum success |

---

## 🛠️ Data Transformation & Engineering Pipeline

The raw dataset required extensive data cleaning and ETL transformations:

### 1️⃣ Epoch Timestamp Conversion
All raw time attributes (`created_at`, `launched_at`, `deadline`, `state_changed_at`) were stored in UNIX Epoch timestamps (seconds since Jan 1, 1970). Converted using:
$$\text{Natural DateTime} = \text{DATE\_ADD}('1970-01-01\text{ }00:00:00',\text{ INTERVAL Epoch\_Seconds SECOND})$$

### 2️⃣ Dynamic Calendar Table (Financial Year: April – March)
Generated a specialized calendar dimension table supporting standard calendar and corporate fiscal periods:
* **Calendar Periods**: Year, Month Number, Full Month Name, Quarter (`Q1-Q4`), Year-Month (`YYYY-MMM`), Weekday Number, Weekday Name.
* **Financial Months**: April = `FM1`, May = `FM2`, $\dots$, March = `FM12`.
* **Financial Quarters**: `FQ-1` (Apr–Jun), `FQ-2` (Jul–Sep), `FQ-3` (Oct–Dec), `FQ-4` (Jan–Mar).

### 3️⃣ Currency Normalization
Multi-currency project goals were normalized to US Dollars using static conversion multipliers:
$$\text{Goal (USD)} = \text{Goal} \times \text{static\_usd\_rate}$$

---

## 🖥️ Multi-Platform Business Intelligence Suite

### 1️⃣ Power BI Analytical Solution (`.pbix`)
* **Page 1: Executive Overview**: High-level KPI cards, outcome status donut chart, geographic heatmaps, and year-over-year creation velocity.
* **Page 2: Diagnostic Visuals**: Root cause analysis comparing failed vs successful initiatives across funding goal buckets.
* **Page 3: Exploratory Visuals**: Deep-dive slicers across categories, creators, and pledge tiers.
* **Page 4: Time-Series Diagnostics**: Trend analyses cross-referencing launch month and day-of-week against campaign success.

### 2️⃣ Tableau Packaged Visualizations (`.twbx`)
* **Executive Dashboard**: KPI summary, category distribution, outcome shares, and geographic density.
* **Detailed View**: Backer concentration, fastest funded projects, and repeat creator performance.
* **Trend Analysis**: Money vs time correlation, seasonal quarterly trends, and goal range success curves.

### 3️⃣ Excel Financial & Pivot Model (`.xlsx`)
* Complete interactive pivot tables with dynamic timeline slicers, category drill-downs, and summary KPI cards.

---

## 💻 SQL Analytical Queries Deep-Dive

The repository includes complete production SQL scripts ([`sql/crowdfunding_analytics.sql`](sql/crowdfunding_analytics.sql)):

```sql
-- 1. Project Outcomes & Percentage Distribution
SELECT 
    state AS Project_Outcome,
    COUNT(*) AS Total_Projects,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_projects)), 2) AS Percentage_Share
FROM fact_projects
GROUP BY state
ORDER BY Total_Projects DESC;

-- 2. Overall Success Metrics
SELECT 
    COUNT(*) AS Total_Successful_Projects,
    SUM(usd_pledged) AS Total_Amount_Raised_USD,
    SUM(backers_count) AS Total_Backers,
    ROUND(AVG(DATEDIFF(FROM_UNIXTIME(deadline), FROM_UNIXTIME(launched_at))), 1) AS Avg_Duration_Days,
    ROUND(AVG(usd_pledged / NULLIF(backers_count, 0)), 2) AS Avg_Pledge_Per_Backer_USD
FROM fact_projects
WHERE state = 'successful';

-- 3. Success Rate % by Goal Range (USD)
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
GROUP BY Goal_Range_USD
ORDER BY Goal_Range_USD;

-- 4. Top 10 Campaigns by Backer Engagement
SELECT 
    project_id,
    name AS Project_Name,
    country,
    backers_count,
    usd_pledged AS Amount_Raised_USD,
    ROUND((usd_pledged * 100.0 / NULLIF(goal * static_usd_rate, 0)), 2) AS Funding_Percentage
FROM fact_projects
WHERE state = 'successful'
ORDER BY backers_count DESC
LIMIT 10;
```

---

## 🎯 Key Business Takeaways & Insights

1. **Optimal Funding Goal Window**: Campaigns with modest, realistic funding goals under **$10,000** maintain a dramatically higher success rate (>55%) compared to mega-campaigns seeking over $100,000 (<18% success rate).
2. **Campaign Duration sweet-spot**: Successful projects maintain an average duration of **30 to 35 days**. Longer campaign durations (60+ days) do not correlate with higher funding and often experience backer fatigue.
3. **Category Dynamism**: Technology, Games, and Design command the highest gross USD volume, while Niche Arts, Comics, and Publishing demonstrate the highest percentage success rates.
4. **Early Momentum Effect**: Projects reaching 20% of their funding goal within the first 48 hours exhibit an 80%+ probability of successfully achieving or exceeding their target.

---

## 📁 Repository Directory Structure

```text
├── dashboards/
│   ├── power_bi/
│   │   └── Crowdfunding_PowerBI_Dashboard.pbix
│   ├── tableau/
│   │   └── Crowdfunding_Tableau_Dashboard.twbx
│   └── excel/
│       └── Crowdfunding_Excel_Dashboard.xlsx
├── data/
│   ├── CrowdFunding_Dataset.zip
│   ├── crowdfunding_Category.xlsx
│   └── Crowdfunding_Location.xlsx
├── sql/
│   └── crowdfunding_analytics.sql
├── docs/
│   ├── Kickstarter_Overview.pdf
│   ├── Crowdfunding_Questionnaires_KPI.txt
│   └── images/
│       ├── crowdfunding_banner.jpg
│       └── kickstarter_header.jpg
├── .gitattributes
├── .gitignore
└── README.md
```

---

## 👤 Author
* **Abhishek Laxman Sable** ([GitHub](https://github.com/abhisheksable789))
