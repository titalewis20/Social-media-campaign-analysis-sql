-- PROJECT: Social Media Campaign Performance Analysis
-- Tool: PostgreSQL
-- Author: Tita Lewis
-- Description: Campaign KPI analysis across Instagram, TikTok,
--              and YouTube for a marketing agency with 4 clients.


-- 1: CREATE TABLES

CREATE TABLE campaigns (
    campaign_id   SERIAL PRIMARY KEY,
    campaign_name VARCHAR(100),
    client        VARCHAR(100),
    platform      VARCHAR(50),
    start_date    DATE,
    end_date      DATE,
    budget        NUMERIC(10, 2)
);

CREATE TABLE daily_metrics (
    metric_id     SERIAL PRIMARY KEY,
    campaign_id   INT REFERENCES campaigns(campaign_id),
    metric_date   DATE,
    impressions   INT,
    clicks        INT,
    engagements   INT,
    spend         NUMERIC(10, 2)
);
-- ============================================================
-- 2: IMPORT DATA

-- Import order:
--   1. campaigns.csv
--   2. daily_metrics.csv

-- ============================================================
-- 3: EXPLORE THE DATA

SELECT * FROM campaigns;
SELECT * FROM daily_metrics LIMIT 10;

-- How many weekly records does each campaign have?
SELECT campaign_id, COUNT(*) AS weekly_records
FROM daily_metrics
GROUP BY campaign_id
ORDER BY campaign_id;

-- ============================================================
-- 4: FULL CAMPAIGN PERFORMANCE SUMMARY
-- Roll up all weekly records into one row per campaign.
-- Shows total reach, engagement, clicks, and actual spend
-- versus the planned budget.

SELECT
    c.campaign_name,
    c.client,
    c.platform,
    c.budget                       AS planned_budget,
    SUM(dm.spend)                  AS actual_spend,
    c.budget - SUM(dm.spend)       AS budget_remaining,
    SUM(dm.impressions)            AS total_impressions,
    SUM(dm.clicks)                 AS total_clicks,
    SUM(dm.engagements)            AS total_engagements
FROM campaigns c
JOIN daily_metrics dm ON c.campaign_id = dm.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.client, c.platform, c.budget
ORDER BY total_impressions DESC;


-- ============================================================
-- 5: KEY MARKETING KPIs
--   CTR (Click-Through Rate): clicks / impressions × 100
--   → What percentage of people who saw the ad clicked it?
--
--   Engagement Rate: engagements / impressions × 100
--   → What percentage interacted (liked, commented, shared)?
--
--   CPM (Cost Per 1,000 Impressions): spend / impressions × 1000
--   → How much does it cost to reach 1,000 people?
--
-- ::NUMERIC casts the integer to a decimal before dividing
-- so PostgreSQL doesn't do integer division and lose precision.

SELECT
    c.campaign_name,
    c.platform,
    SUM(dm.impressions)                                            AS total_impressions,
    SUM(dm.clicks)                                                 AS total_clicks,
    SUM(dm.engagements)                                            AS total_engagements,
    SUM(dm.spend)                                                  AS total_spend,
    ROUND(SUM(dm.clicks)::NUMERIC / SUM(dm.impressions) * 100, 2) AS ctr_percent,
    ROUND(SUM(dm.engagements)::NUMERIC / SUM(dm.impressions) * 100, 2)
                                                                   AS engagement_rate_percent,
    ROUND(SUM(dm.spend) / SUM(dm.impressions) * 1000, 2)          AS cpm
FROM campaigns c
JOIN daily_metrics dm ON c.campaign_id = dm.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.platform
ORDER BY ctr_percent DESC;


-- ============================================================
-- 6: PLATFORM COMPARISON WITH IMPRESSION SHARE (CTE)
-- First calculate totals per platform in the CTE,
-- then use those totals to compute each platform's share
-- of overall impressions. Doing this in two steps with a CTE
-- is much cleaner than nesting a subquery.

WITH platform_totals AS (
    SELECT
        c.platform,
        SUM(dm.impressions) AS total_impressions,
        SUM(dm.clicks)      AS total_clicks,
        SUM(dm.spend)       AS total_spend
    FROM campaigns c
    JOIN daily_metrics dm ON c.campaign_id = dm.campaign_id
    GROUP BY c.platform
)
SELECT
    platform,
    total_impressions,
    total_clicks,
    total_spend,
    ROUND(
        total_impressions::NUMERIC / SUM(total_impressions) OVER () * 100, 1
    ) AS impression_share_percent
FROM platform_totals
ORDER BY total_impressions DESC;


-- ============================================================
-- 7: RANK CAMPAIGNS WITHIN EACH PLATFORM
-- PARTITION BY platform means the ranking resets for each
-- platform group independently. So TikTok has its own rank 1,
-- Instagram has its own rank 1, and so on.

SELECT
    c.campaign_name,
    c.client,
    c.platform,
    SUM(dm.impressions) AS total_impressions,
    RANK() OVER (
        PARTITION BY c.platform
        ORDER BY SUM(dm.impressions) DESC
    )                   AS platform_rank
FROM campaigns c
JOIN daily_metrics dm ON c.campaign_id = dm.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.client, c.platform
ORDER BY c.platform, platform_rank;


-- ============================================================
-- 8: PERFORMANCE LABELS (CASE WHEN)
-- Automatically classify each campaign based on CTR.
-- Benchmarks used: strong > 4%, average 2.5–4%, under 2.5% = review.
-- This kind of segmentation is useful for executive dashboards.

SELECT
    c.campaign_name,
    c.platform,
    ROUND(SUM(dm.clicks)::NUMERIC / SUM(dm.impressions) * 100, 2) AS ctr_percent,
    CASE
        WHEN SUM(dm.clicks)::NUMERIC / SUM(dm.impressions) * 100 >= 4.0 THEN 'Strong'
        WHEN SUM(dm.clicks)::NUMERIC / SUM(dm.impressions) * 100 >= 2.5 THEN 'Average'
        ELSE 'Underperforming'
    END                                                            AS performance_label
FROM campaigns c
JOIN daily_metrics dm ON c.campaign_id = dm.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.platform
ORDER BY ctr_percent DESC;


-- ============================================================
-- 9: WEEK-OVER-WEEK SPEND CHANGE (LAG)
-- LAG() looks back at the previous row within a window.
-- PARTITION BY campaign_id keeps each campaign's rows separate.
-- ORDER BY metric_date ensures "previous" means the earlier date.
-- The result shows whether weekly spend is going up or down.

SELECT
    c.campaign_name,
    dm.metric_date,
    dm.spend                                   AS weekly_spend,
    LAG(dm.spend) OVER (
        PARTITION BY dm.campaign_id
        ORDER BY dm.metric_date
    )                                          AS prev_week_spend,
    dm.spend - LAG(dm.spend) OVER (
        PARTITION BY dm.campaign_id
        ORDER BY dm.metric_date
    )                                          AS spend_change
FROM campaigns c
JOIN daily_metrics dm ON c.campaign_id = dm.campaign_id
ORDER BY c.campaign_name, dm.metric_date;
