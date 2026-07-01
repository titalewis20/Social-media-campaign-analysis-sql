# Social Media Campaign Performance Analysis (SQL)

**Author:** Lewis Brian | titalewis218@gmail.com | [LinkedIn](https://www.linkedin.com/in/tita-lewis-brian-zua-669ab42a0)

## What This Project Is About

Social media analytics is one of the areas I find most interesting to work in, so I built this project around a marketing agency scenario. The agency runs paid campaigns for four different clients across Instagram, TikTok, and YouTube, and they want to know which campaigns are actually working and which ones need to be rethought.

The main challenge here was calculating proper marketing KPIs like CTR, engagement rate, and CPM directly in SQL rather than in a spreadsheet. I also used window functions to rank campaigns within each platform independently, and LAG() to track how spend changed week over week within a campaign.

## Tools

- **PostgreSQL** (version 15)
- **pgAdmin 4**

## Dataset

Two CSV files are in the `/data` folder:

1. `campaigns.csv` - 8 campaigns across 3 platforms and 4 clients, with budgets and date ranges
2. `daily_metrics.csv` - 32 weekly performance records covering impressions, clicks, engagements, and spend per campaign per week

Import `campaigns.csv` first, then `daily_metrics.csv`, since the metrics table references campaign IDs.

## How To Set Up The Database

1. Open pgAdmin and create a new database called `social_media_db`
2. Open the Query Tool and run `social_media_analysis.sql` top to bottom, this creates both tables
3. Right-click each table, click Import/Export Data, select the matching CSV, Header ON, then click OK
4. Import `campaigns.csv` before `daily_metrics.csv`

## Queries Covered

| Step | What It Does |
|---|---|
| 1 | Create tables for campaigns and daily_metrics with a foreign key |
| 2 | Explore data, previews and record counts per campaign |
| 3 | Full performance summary per campaign showing impressions, clicks, spend vs budget |
| 4 | KPI calculations for CTR, Engagement Rate, and CPM |
| 5 | Platform comparison with impression share percentage using a CTE |
| 6 | Rank campaigns within each platform using RANK() and PARTITION BY |
| 7 | Performance labels (Strong, Average, Underperforming) with CASE WHEN |
| 8 | Week-over-week spend change per campaign using LAG() |

## Key Findings

- **TikTok had the highest total impressions** by a significant margin. The Nova Cosmetics Summer Heat campaign alone reached over 550,000 impressions, making it the top-performing campaign in the dataset.
- **Instagram had the best average CTR**, smaller reach but a more targeted audience clicking at a higher rate.
- **YouTube had the highest CPM**, meaning it costs more to reach 1,000 people there compared to the other two platforms. Worth flagging for clients on tighter budgets.
- The CASE WHEN labels flagged two YouTube campaigns as Underperforming based on CTR. The high CPM combined with a low click rate suggests the creative or targeting needs reviewing.
- The LAG() analysis showed TikTok spend generally increased week over week, which likely means the agency was scaling budgets mid-campaign based on early results.

## Skills Demonstrated

- Table design with a one-to-many foreign key relationship
- Multi-table JOINs
- Calculated KPI columns in SQL (CTR, Engagement Rate, CPM)
- CTEs (WITH clause) for multi-step logic
- Window functions using RANK() with PARTITION BY for per-platform rankings
- Window function LAG() for week-over-week comparisons
- CASE WHEN for performance classification
