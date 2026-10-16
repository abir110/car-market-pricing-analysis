-- =====================================================================
-- Car Market Pricing Analysis — SQL queries
-- Database: SQLite (data/processed/cars.db, table: cars)
-- Each query starts with a "-- name:" line so the notebook can run
-- them one by one. You can also paste any query into DB Browser for
-- SQLite and run it directly.
-- =====================================================================


-- name: market_overview
-- Headline numbers for the whole market.
SELECT
    COUNT(*)                                  AS models,
    ROUND(AVG(retail_price), 0)               AS avg_price,
    MIN(retail_price)                         AS min_price,
    MAX(retail_price)                         AS max_price,
    ROUND(AVG(retail_price - dealer_cost), 0) AS avg_margin_usd,
    ROUND(AVG(100.0 * (retail_price - dealer_cost) / retail_price), 2) AS avg_margin_pct
FROM cars;


-- name: data_quality_checks
-- Rows that look unusual and need a decision (keep, fix or exclude).
SELECT
    car_id,
    retail_price,
    hp,
    city_mpg,
    hwy_mpg,
    CASE
        WHEN city_mpg > hwy_mpg      THEN 'City MPG above highway (typical of hybrids)'
        WHEN hwy_mpg >= 50           THEN 'Very high MPG (likely hybrid)'
        WHEN hwy_mpg <= 14           THEN 'Very low MPG (heavy truck/SUV)'
        WHEN retail_price > 150000   THEN 'Extreme price (supercar)'
    END AS flag
FROM cars
WHERE city_mpg > hwy_mpg
   OR hwy_mpg >= 50
   OR hwy_mpg <= 14
   OR retail_price > 150000
ORDER BY flag, retail_price DESC;


-- name: margin_by_price_band
-- Do dealers make more on expensive cars, in % and in dollars?
SELECT
    CASE
        WHEN retail_price < 20000 THEN '1. Under $20k'
        WHEN retail_price < 30000 THEN '2. $20k–30k'
        WHEN retail_price < 45000 THEN '3. $30k–45k'
        ELSE                           '4. $45k+'
    END                                                        AS price_band,
    COUNT(*)                                                   AS models,
    ROUND(AVG(retail_price), 0)                                AS avg_price,
    ROUND(AVG(retail_price - dealer_cost), 0)                  AS avg_margin_usd,
    ROUND(AVG(100.0 * (retail_price - dealer_cost) / retail_price), 2) AS avg_margin_pct
FROM cars
GROUP BY price_band
ORDER BY price_band;


-- name: margin_by_cylinders
-- Engine configuration vs price and dealer margin.
SELECT
    cylinders,
    COUNT(*)                                                   AS models,
    ROUND(AVG(retail_price), 0)                                AS avg_price,
    ROUND(AVG(hp), 0)                                          AS avg_hp,
    ROUND(AVG(100.0 * (retail_price - dealer_cost) / retail_price), 2) AS avg_margin_pct
FROM cars
GROUP BY cylinders
ORDER BY cylinders;


-- name: best_value_performance
-- Most horsepower per $1,000 spent, among cars that also manage 25+ MPG on the highway.
SELECT
    car_id,
    retail_price,
    hp,
    hwy_mpg,
    ROUND(1000.0 * hp / retail_price, 2) AS hp_per_1000_usd
FROM cars
WHERE hwy_mpg >= 25
ORDER BY hp_per_1000_usd DESC
LIMIT 10;


-- name: fuel_economy_by_engine_size
-- How much highway fuel economy you give up as engines get bigger.
SELECT
    CASE
        WHEN engine_l < 2.0 THEN '1. Under 2.0L'
        WHEN engine_l < 3.0 THEN '2. 2.0–2.9L'
        WHEN engine_l < 4.0 THEN '3. 3.0–3.9L'
        WHEN engine_l < 5.0 THEN '4. 4.0–4.9L'
        ELSE                     '5. 5.0L+'
    END                       AS engine_band,
    COUNT(*)                  AS models,
    ROUND(AVG(hwy_mpg), 1)    AS avg_hwy_mpg,
    ROUND(AVG(city_mpg), 1)   AS avg_city_mpg,
    ROUND(AVG(retail_price), 0) AS avg_price
FROM cars
GROUP BY engine_band
ORDER BY engine_band;


-- name: price_rank_within_cylinders
-- Window function example: rank each car by price within its cylinder group
-- and show how far it sits above or below the group average.
SELECT *
FROM (
    SELECT
        car_id,
        cylinders,
        retail_price,
        RANK() OVER (PARTITION BY cylinders ORDER BY retail_price DESC)  AS price_rank,
        ROUND(retail_price - AVG(retail_price) OVER (PARTITION BY cylinders), 0) AS diff_from_group_avg
    FROM cars
)
WHERE price_rank <= 3
ORDER BY cylinders, price_rank;
