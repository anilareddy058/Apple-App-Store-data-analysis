-- Create Database, Schema, Warehouse, fileformat
-- create or replace database appstore_db;
-- create or replace schema appstore_schema;
-- create or replace warehouse appstore_wh WITH 
-- WAREHOUSE_SIZE = 'small' 
-- WAREHOUSE_TYPE = 'STANDARD' 
-- AUTO_SUSPEND = 60 
-- AUTO_RESUME = TRUE 
-- MIN_CLUSTER_COUNT = 1 
-- MAX_CLUSTER_COUNT = 1 
-- SCALING_POLICY = 'STANDARD';

-- create or replace FILE FORMAT CSV
-- TYPE = 'CSV' 
-- COMPRESSION = 'AUTO'
-- FIELD_DELIMITER = ','
-- RECORD_DELIMITER = '\n'
-- SKIP_HEADER = 0
-- FIELD_OPTIONALLY_ENCLOSED_BY = '\042'
-- TRIM_SPACE = FALSE
-- ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
-- ESCAPE = 'NONE'
-- ESCAPE_UNENCLOSED_FIELD = '\134'
-- DATE_FORMAT = 'AUTO'
-- TIMESTAMP_FORMAT = 'AUTO'
-- NULL_IF = ('');  

-- use warehouse APPSTORE_WH;
-- use DATABASE APPSTORE_DB;
-- use schema APPSTORE_SCHEMA;

-- create or replace STAGE appstore_stage;
-- show grants on stage appstore_stage;

-- PUT file:///Users/anilareddy/Downloads/appleAppData.csv @appstore_stage;

-- CREATE OR REPLACE TABLE Apps (
-- App_Id VARCHAR(255),
-- App_Name VARCHAR(255),
-- AppStore_Url VARCHAR(255),
-- Primary_Genre VARCHAR(50),
-- Content_Rating VARCHAR(10),
-- Size_Bytes INT,
-- Required_IOS_Version INT,
-- Released TIMESTAMP,
-- Updated TIMESTAMP,
-- Version VARCHAR(20),
-- Price DECIMAL(10, 2),
-- Currency VARCHAR(5),
-- Free BOOLEAN,
-- DeveloperId VARCHAR(255),
-- Developer VARCHAR(255),
-- Developer_Url VARCHAR(255),
-- Developer_Website VARCHAR(255),
-- Average_User_Rating DECIMAL(10, 2),
-- Reviews INT,
-- Current_Version_Score DECIMAL(10, 2),
-- Current_Version_Reviews INT
-- );

-- select $1, $2, $3 from @appstore_stage/appleAppData.csv limit 5;

-- copy into Apps(App_Name, Primary_Genre, Content_Rating, Size_Bytes, Required_IOS_Version, Released, Updated, Version, Price, Currency, Free, DeveloperId, Developer, Average_User_Rating, Reviews, Current_Version_Score, Current_Version_Reviews) from (select $2,$4, CASE
--             WHEN TRY_TO_NUMBER($5) IS NOT NULL THEN TRY_TO_NUMBER($5) -- If content rating is already a number
--             WHEN $5 = 'Not Yet Rated' THEN NULL -- Handle 'Not Yet Rated' case
--             WHEN $5 = 'Free' THEN NULL -- Handle 'Free' case (if applicable)
--             ELSE TRY_TO_NUMBER(REPLACE($5, '+', '')) -- Remove '+' and convert to number
--         END AS Content_Rating,
-- try_to_number($6), try_to_number($7) , try_to_timestamp_ntz($8),try_to_timestamp_ntz($9),try_to_decimal($10,3,2), try_to_decimal($11,4,2), $12,$13,try_to_number($14),$15,try_to_decimal($18,4,2),try_to_number($19),try_to_decimal($20,4,2),try_to_number($21) from @appstore_stage/appleAppData.csv) FILE_FORMAT=(FORMAT_NAME=CSV) ON_ERROR='CONTINUE';

--ALL THE ABOVE CODE IN CLI

SELECT * FROM APPS;
ALTER TABLE APPS DROP APP_ID, APPSTORE_URL, CONTENT_RATING, DEVELOPER_URL, DEVELOPER_WEBSITE;
ALTER TABLE APPS DROP VERSION;
ALTER TABLE APPS DROP REQUIRED_IOS_VERSION; ---THIS COLUMN HAD ALMOST 19000 NULL VALUES AND NOT THAT REQUIRED
show columns in apps;
DELETE from apps where SIZE_BYTES is null or
RELEASED is null or
UPDATED is null OR PRICE IS NULL;
--NOW THE TABLE IS CLEANED
select count(*) from apps;

SELECT PRIMARY_GENRE, COUNT(*) AS NUM_OF_APPS FROM APPS GROUP BY PRIMARY_GENRE ORDER BY NUM_OF_APPS DESC; --NUMBER OF APPS PER GENRE

--DELETED CONTENT_RATING COLUMN WHICH MIGHT BE USEFUL. SO TO GET IT BACK, GO SEE THE PREV QUERY ID WHERE THE COLUMN WAS LAST PRESENT AND THEN CLONE THE TABLE AT THAT TIME AND QUERY ON THAT CLONED TABLE

create or replace table APPS_CLONE
clone APPS
at (statement => '01b3eeba-0002-057e-0002-aab60018f326');
ALTER TABLE APPS_CLONE DROP APP_ID, APPSTORE_URL, DEVELOPER_URL, DEVELOPER_WEBSITE, VERSION, REQUIRED_IOS_VERSION; 
SELECT COUNT(*) FROM APPS_CLONE WHERE SIZE_BYTES IS NULL OR RELEASED IS NULL OR UPDATED IS NULL OR PRICE IS NULL OR CONTENT_RATING IS NULL;
DELETE FROM APPS_CLONE WHERE SIZE_BYTES IS NULL OR RELEASED IS NULL OR UPDATED IS NULL OR PRICE IS NULL OR CONTENT_RATING IS NULL;
select * FROM APPS_CLONE WHERE average_user_rating is null or current_version_score is null;
SELECT MIN(AVERAGE_USER_RATING) AS MINRATING, MAX(AVERAGE_USER_RATING) AS MAXRATING, AVG(AVERAGE_USER_RATING) AS AVGRATING FROM APPS_CLONE;


-----Analysis
SELECT PRIMARY_GENRE,CONTENT_RATING, COUNT(*) AS NUM_OF_APPS FROM APPS_CLONE GROUP BY PRIMARY_GENRE, CONTENT_RATING ORDER BY NUM_OF_APPS DESC;  --NUMBER OF APPS PER GENRE ACROSS CONTENT_RATINGS

SELECT PRIMARY_GENRE, COUNT(*) AS NUM_OF_APPS FROM APPS GROUP BY PRIMARY_GENRE ORDER BY NUM_OF_APPS DESC; --NUMBER OF APPS PER GENRE
--COULD DECIDE WHETHER TO INVEST IN OTHER APP GENRES WHICH ARE LOW IN NUMBER, THIS MIGHT BE BASED ON THE AVERAGE RATINGS PER GENRE

--DETERMINE AVERAGE RATINGS PER GENRE
SELECT PRIMARY_GENRE, AVG(AVERAGE_USER_RATING) AS AVG_RATING FROM APPS_CLONE GROUP BY PRIMARY_GENRE ORDER BY AVG_RATING ASC;

--CHECK TO SEE IF THERE IS ANY CORRELATION BETWEEN CONTENT_RATING AND AVERAGE_USER_RATING
--DETERMINE THE AVERAGE RATINGS OF APPS ACROSS CONTENT_RATING
SELECT CONTENT_RATING, COUNT(*) AS NUM_OF_APPS, AVG(AVERAGE_USER_RATING) FROM APPS_CLONE GROUP BY CONTENT_RATING;

--DETERMINE IF PAID APPS HAVE HIGHER RATING THAN FREE APPS 
SELECT AVG(AVERAGE_USER_RATING), FREE FROM APPS_CLONE GROUP BY FREE;
--FREE APPS HAVE SLIGHTLY BETTER REVIEWS THAN PAID ONES-- BUT IT MIGHT NOT BE 100% TRUE DUE TO SKEWNESS

--DETERMINE IF PAID APPS HAVE MORE REVIEWS THAN FREE APPS 
SELECT SUM(REVIEWS), FREE FROM APPS_CLONE GROUP BY FREE;

--DETERMINE NUMBER OF APPS DEVELOPED PER DEVELOPER
SELECT COUNT(*) AS NUM_OF_APPS_BY_DEV, DEVELOPER FROM APPS_CLONE GROUP BY DEVELOPER ORDER BY NUM_OF_APPS_BY_DEV DESC;

SELECT COUNT(*) AS NUM_OF_APPS_BY_DEV, DEVELOPER FROM APPS_CLONE GROUP BY DEVELOPER ORDER BY NUM_OF_APPS_BY_DEV DESC;

--TOP RATED APPS PER EACH GENRE
SELECT PRIMARY_GENRE, APP_NAME, AVERAGE_USER_RATING, REVIEWS, DEVELOPER FROM ( SELECT PRIMARY_GENRE, APP_NAME, AVERAGE_USER_RATING, REVIEWS, DEVELOPER, RANK() OVER(PARTITION BY PRIMARY_GENRE ORDER BY AVERAGE_USER_RATING DESC, REVIEWS DESC) AS RK FROM APPS_CLONE) AS X WHERE X.RK=1;
--USING REVIEWS CAN BREAK TIES IF MOST OF THE APS HAVE THE SAME NUMBER OF AVERAGE-USER_RATING

--TOP RATED DEVELOPERS AND THEIR RANK
WITH DeveloperStats AS (
    SELECT 
        DEVELOPER,
        COUNT(*) AS TOTAL_APPS,
        AVG(AVERAGE_USER_RATING) AS AVG_USER_RATING,
        SUM(REVIEWS) AS TOTAL_REVIEWS
    FROM 
        APPS_CLONE
    GROUP BY 
        DEVELOPER
),
RankedDevelopers AS (
    SELECT 
        DEVELOPER,
        TOTAL_APPS,
        AVG_USER_RATING,
        TOTAL_REVIEWS,
        RANK() OVER (ORDER BY AVG_USER_RATING DESC, TOTAL_REVIEWS DESC) AS DEV_RANK
    FROM 
        DeveloperStats
)
SELECT 
    DEVELOPER,
    TOTAL_APPS,
    AVG_USER_RATING,
    TOTAL_REVIEWS,
    DEV_RANK
FROM 
    RankedDevelopers;


--RANK OF EACH DEVELOPER , RESULT ORDERED BY THE NUMBER OF APPS THEY MADE
WITH DeveloperStats AS (
    SELECT 
        DEVELOPER,
        COUNT(*) AS TOTAL_APPS,
        AVG(AVERAGE_USER_RATING) AS AVG_USER_RATING,
        SUM(REVIEWS) AS TOTAL_REVIEWS
    FROM 
        APPS_CLONE
    GROUP BY 
        DEVELOPER
),
RankedDevelopers AS (
    SELECT 
        DEVELOPER,
        TOTAL_APPS,
        AVG_USER_RATING,
        TOTAL_REVIEWS,
        RANK() OVER (ORDER BY TOTAL_APPS DESC) AS DEVELOPER_RANK_BYNUMEROFAPPS
    FROM 
        DeveloperStats
)
SELECT 
    DEVELOPER,
    TOTAL_APPS,
    AVG_USER_RATING,
    TOTAL_REVIEWS,
    RANK() OVER (ORDER BY AVG_USER_RATING DESC, TOTAL_REVIEWS DESC) AS DEV_RANK
FROM 
    RankedDevelopers
ORDER BY 
    TOTAL_APPS DESC;

