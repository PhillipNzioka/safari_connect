# Safari Connect — Booking Data Analysis

End-to-end **SQL data cleaning and business analysis** of a Kenyan intercity
transport booking dataset, built entirely in **PostgreSQL** — from raw,
messy text columns to a set of analysis views that answer six core business
questions and drive operational recommendations.

## Why this project

Raw operational data is rarely analysis-ready. Safari Connect's booking
records arrived with inconsistent casing, mixed date formats, non-standard
phone numbers, currency-prefixed fares, duplicate rows, and invalid ratings.
This project demonstrates a full **extract → profile → clean → model →
analyze** workflow using only SQL.

## Business questions answered

| # | Question | Where |
|---|----------|-------|
| 1 | Which routes earn the most, are most popular, and are most efficient per seat sold? | `sql/06_business_questions.sql` |
| 2 | Who are the best drivers — and does driver rating affect passenger satisfaction? | `sql/06_business_questions.sql` |
| 3 | How is revenue trending month over month? | `sql/06_business_questions.sql` |
| 4 | Where do passengers come from, what seat class do they prefer, and are they satisfied? | `sql/06_business_questions.sql` |
| 5 | What is the cancellation rate per route, and how much revenue do cancellations cost? | `sql/06_business_questions.sql` |
| 6 | What are the busiest days and times — when should we add more vehicles? | `sql/06_business_questions.sql` |

## Project structure

```
safari-connect-analysis/
├── sql/
│   ├── 01_ddl_raw_table.sql        # Raw table schema (all TEXT columns)
│   ├── 02_data_cleaning.sql        # Staging table + full cleaning pipeline
│   ├── 03_column_profiling.sql     # Column-by-column distinct-value profiling
│   ├── 04_clean_table_and_view.sql # Typed clean table, v_clean_trips, indexes
│   ├── 05_analysis_views.sql       # 6 reusable analysis views (incl. KPIs)
│   └── 06_business_questions.sql   # The 6 business questions + answers
├── docs/
│   └── findings.md                 # Executive summary of insights & recommendations
└── LICENSE
```

## Data cleaning highlights

| Issue | Fix |
|-------|-----|
| Inconsistent name casing / whitespace | `INITCAP(TRIM())` |
| Phone numbers in mixed formats (`+254…`, `254…`, dashes) | Regex normalization to `0XXXXXXXXX` |
| Dates in `DD/MM/YYYY`, `MM-DD-YYYY`, `DD-MM-YY` formats | Pattern-matched `TO_DATE` conversion to `DATE` |
| Currency-prefixed fares (`KES 1,500`) | `REGEXP_REPLACE` + cast to `NUMERIC` |
| Gender codes (`F`, `M`, `female`) | Standardized to `Male` / `Female` |
| Seat class variants (`ECO`, `ECONOMY CLASS`, `BUS`) | Mapped to `Economy` / `Business` |
| Payment methods (`mpesa`, `Mpesa`) | Standardized to `M-Pesa` / `Cash` / `Card` |
| Invalid trip ratings (0, >5, empty) | Set to `NULL` |
| Negative `seats_booked` values | Removed |
| Duplicate `booking_id`s | Deduplicated on `MIN(ctid)` |

**Safety-first design:** cleaning runs on a *staging* copy of the raw table,
so the original data is always recoverable. Sanity checks (`COUNT(*)`,
column-count checks) run after every major step.

## Data model

- `bookings_raw` — untouched raw extract (all TEXT)
- `bookings_staging` — working copy where all cleaning happens
- `bookings` — final typed, clean table
- `v_clean_trips` — analysis-ready view: completed trips only, plus derived
  columns (`travel_month`, `day_name`, `satisfaction` tier, `calculated_fare`)
- 6 analysis views: route performance, driver performance, monthly revenue,
  cancellation analysis, passenger insights, and KPIs
- 7 indexes on frequent filter/group-by columns

## Key findings

- **RT001 (Nairobi–Mombasa)** leads on revenue (KES 51,600) and seat efficiency (KES 1,259/seat); **RT009 (Nairobi–Machakos)** trails at KES 7,300.
- **Matatus** are the most profitable fleet (KES 87,925); all vehicle types average only ~2 seats booked per trip — a major utilization gap.
- Driver rating **does not** correlate with passenger satisfaction — top-rated driver (4.8) had among the lowest trip ratings (3.2).
- **KES 32,150** in revenue lost to cancellations and no-shows; satisfaction sits at **46.2%**, just under the 50% benchmark.
- Peak demand: **06:00–09:00** departures and **19:00** (highest-revenue slot).

Full details: [docs/findings.md](docs/findings.md)

## How to run

```bash
# 1. Create the schema and raw table
psql -d your_db -f sql/01_ddl_raw_table.sql

# 2. Load your raw CSV/data into safari_connect.bookings_raw, then:
psql -d your_db -f sql/02_data_cleaning.sql      # clean into staging
psql -d your_db -f sql/04_clean_table_and_view.sql  # build clean table + views
psql -d your_db -f sql/05_analysis_views.sql      # analysis views
psql -d your_db -f sql/06_business_questions.sql  # run the business questions
```

> Run order matters: `04` before `05`, and `v_clean_trips` must exist before
> the analysis views and business questions.

## Tech stack

- **PostgreSQL** — DDL, data cleaning, window functions (`RANK`, `LAG`,
  running totals, `NTILE`), conditional aggregation, views, indexes

