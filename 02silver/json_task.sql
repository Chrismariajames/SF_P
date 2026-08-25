

----------------------------------------------------------------------------------------------
--select * from bronze.raw_customer_reviews_bronze
--truncate table bronze.raw_customer_reviews_bronze  CUSTOMER_REVIEWS_STREAM_SILVER_RAW
CREATE OR REPLACE STREAM SILVER.CUSTOMER_REVIEWS_RAW_STREAM_BRONZE
ON TABLE BRONZE.raw_customer_reviews_bronze;
select * from SILVER.CUSTOMER_REVIEWS_RAW_STREAM_BRONZE;
select * from BRONZE.raw_customer_reviews_bronze;

show streams;
show tasks;
--drop task LOAD_CUSTOMER_REVIEWS_TASK
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS SUSPEND
--select * from SILVER.RAW_CUSTOMER_REVIEWS_SILVER;
CREATE OR REPLACE TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS_RAW
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('BRONZE.CUSTOMER_REVIEWS_RAW_STREAM_BRONZE')
AS
INSERT INTO SILVER.RAW_CUSTOMER_REVIEWS_SILVER
(
    REVIEW_ID,
    ORDER_ID,
    CUSTOMER_ID,
    REVIEW_DATE,
    RATING,
    REVIEW_TEXT,
    SOURCE_SYSTEM,
    created_timestamp,
    updated_timestamp
)
SELECT

    RAW_DATA:review_id::STRING,
    RAW_DATA:order_id::NUMBER,
    RAW_DATA:customer_id::STRING,
    TO_DATE(RAW_DATA:review_date::STRING),
    RAW_DATA:RATING::NUMBER,
    RAW_DATA:REVIEW_TEXT::STRING,
    SOURCE_SYSTEM, 
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM BRONZE.CUSTOMER_REVIEWS_RAW_STREAM_BRONZE;

EXECUTE TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS_RAW;
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS_RAW'
));


show tasks

-------------------------------------------
select * from raw_customer_reviews_silver
--select * from bronze.raw_customer_reviews_bronze
--truncate table bronze.raw_customer_reviews_bronze
CREATE OR REPLACE STREAM SILVER.CUSTOMER_REVIEWS_STREAM_SILVER_RAW
ON TABLE SILVER.raw_customer_reviews_silver;
select * from SILVER.raw_customer_reviews_silver;
select * from CUSTOMER_REVIEWS_STREAM_SILVER_RAW
show streams;
show tasks;
select * from 
--drop task LOAD_CUSTOMER_REVIEWS_TASK
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS SUSPEND
--select * from SILVER.RAW_CUSTOMER_REVIEWS_SILVER;


--drop task TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS

EXECUTE TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS;
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'TASK_BRONZE_TO_SILVER_CUSTOMER_REVIEWS'
));
CREATE OR REPLACE STREAM BRONZE.customer_reviews_stream_bronze
ON TABLE BRONZE.raw_customer_reviews_bronze;

-- =========================================================
-- MERGE Script: Load & Transform CUSTOMER_REVIEWS_SILVER
-- Source  : raw_customer_reviews_silver
-- Stream  : CUSTOMER_REVIEWS_STREAM_SILVER_RAW
-- Target  : CUSTOMER_REVIEWS_SILVER
--
-- Purpose:
-- 1. Read incremental data from stream
-- 2. Remove duplicates using latest UPDATED_TIMESTAMP
-- 3. Apply transformations
-- 4. MERGE into target table
-- =========================================================
CREATE OR REPLACE TASK SILVER.TASK_SILVER_TO_SILVER_CUSTOMER_REVIEWS
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTES'
WHEN SYSTEM$STREAM_HAS_DATA('SILVER.CUSTOMER_REVIEWS_STREAM_SILVER_RAW')
AS

MERGE INTO SILVER.CUSTOMER_REVIEWS_SILVER AS TGT
USING
(
    SELECT
        REVIEW_ID,
        ORDER_ID,
        CUSTOMER_ID,

        /* Transformations */
        TRY_TO_DATE(REVIEW_DATE)       AS REVIEW_DATE,
        TRY_TO_NUMBER(RATING)          AS RATING,
        TRIM(REVIEW_TEXT)              AS REVIEW_TEXT,
        UPPER(TRIM(SOURCE_SYSTEM))     AS SOURCE_SYSTEM,

        created_timestamp,
        CURRENT_TIMESTAMP()            AS updated_timestamp

    FROM
    (
        SELECT
            REVIEW_ID,
            ORDER_ID,
            CUSTOMER_ID,
            REVIEW_DATE,
            RATING,
            REVIEW_TEXT,
            SOURCE_SYSTEM,
            created_timestamp,
            updated_timestamp,

            ROW_NUMBER() OVER
            (
                PARTITION BY REVIEW_ID
                ORDER BY updated_timestamp DESC
            ) AS RN

        FROM SILVER.CUSTOMER_REVIEWS_STREAM_SILVER_RAW
    ) S
    WHERE RN = 1
) SRC

ON TGT.REVIEW_ID = SRC.REVIEW_ID

WHEN MATCHED THEN
UPDATE SET
      ORDER_ID          = SRC.ORDER_ID
    , CUSTOMER_ID       = SRC.CUSTOMER_ID
    , REVIEW_DATE       = SRC.REVIEW_DATE
    , RATING            = SRC.RATING
    , REVIEW_TEXT       = SRC.REVIEW_TEXT
    , SOURCE_SYSTEM     = SRC.SOURCE_SYSTEM
    , updated_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT
(
      REVIEW_ID,
      ORDER_ID,
      CUSTOMER_ID,
      REVIEW_DATE,
      RATING,
      REVIEW_TEXT,
      SOURCE_SYSTEM,
      created_timestamp,
      updated_timestamp
)
VALUES
(
      SRC.REVIEW_ID,
      SRC.ORDER_ID,
      SRC.CUSTOMER_ID,
      SRC.REVIEW_DATE,
      SRC.RATING,
      SRC.REVIEW_TEXT,
      SRC.SOURCE_SYSTEM,
      SRC.created_timestamp,
      SRC.updated_timestamp
);

show tasks;
Alter task TASK_SILVER_TO_SILVER_CUSTOMER_REVIEWS RESUME;


------------------------------------------------------------------------------------------
CREATE OR REPLACE STREAM BRONZE.RAW_WEB_EVENTS_NESTED_STREAM_BRONZE
ON TABLE BRONZE.RAW_WEB_EVENTS_NESTED_BRONZE;


CREATE OR REPLACE TASK SILVER.TASK_BRONZE_TO_SILVER_RAW_WEB_EVENTS_NESTED_TASK
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTES'
WHEN SYSTEM$STREAM_HAS_DATA('BRONZE.RAW_WEB_EVENTS_NESTED_STREAM_BRONZE')
AS
MERGE INTO SILVER.WEB_EVENTS_SILVER TGT
USING
(
    SELECT
        EVENT_ID,
        EVENT_TS,
        CUSTOMER_ID,
        CITY,
        EVENT_TYPE,
        PRODUCT_ID,
        ORDER_ID,
        SOURCE_SYSTEM,
        CREATED_TS,
        UPDATED_TS

    FROM
    (
        SELECT

            RAW_DATA:event_id::STRING               AS EVENT_ID,

            TO_TIMESTAMP(RAW_DATA:event_ts::STRING) AS EVENT_TS,

            RAW_DATA:customer.customer_id::STRING   AS CUSTOMER_ID,

            RAW_DATA:customer.city::STRING          AS CITY,

            RAW_DATA:event.type::STRING             AS EVENT_TYPE,

            RAW_DATA:event.product_id::STRING       AS PRODUCT_ID,

            RAW_DATA:event.order_id::NUMBER         AS ORDER_ID,

            SOURCE_SYSTEM,

            CURRENT_TIMESTAMP()                     AS CREATED_TS,

            CURRENT_TIMESTAMP()                     AS UPDATED_TS,

            ROW_NUMBER() OVER
            (
                PARTITION BY RAW_DATA:event_id::STRING
                ORDER BY TO_TIMESTAMP(RAW_DATA:event_ts::STRING) DESC
            ) RN

        FROM BRONZE.RAW_WEB_EVENTS_NESTED_STREAM_BRONZE
    ) S
    WHERE RN = 1
) SRC

ON TGT.EVENT_ID = SRC.EVENT_ID

WHEN MATCHED THEN
UPDATE SET
      EVENT_TS    = SRC.EVENT_TS
    , CUSTOMER_ID = SRC.CUSTOMER_ID
    , CITY        = SRC.CITY
    , EVENT_TYPE  = SRC.EVENT_TYPE
    , PRODUCT_ID  = SRC.PRODUCT_ID
    , ORDER_ID    = SRC.ORDER_ID
    , SOURCE_SYSTEM   = SRC.SOURCE_SYSTEM
    , UPDATED_TS  = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT
(
    EVENT_ID,
    EVENT_TS,
    CUSTOMER_ID,
    CITY,
    EVENT_TYPE,
    PRODUCT_ID,
    ORDER_ID,
    SOURCE_SYSTEM,
    CREATED_TS,
    UPDATED_TS
)
VALUES
(
    SRC.EVENT_ID,
    SRC.EVENT_TS,
    SRC.CUSTOMER_ID,
    SRC.CITY,
    SRC.EVENT_TYPE,
    SRC.PRODUCT_ID,
    SRC.ORDER_ID,
    SRC.SOURCE_SYSTEM,
    SRC.CREATED_TS,
    SRC.UPDATED_TS
);
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_RAW_WEB_EVENTS_NESTED_TASK RESUME;
execute task SILVER.TASK_BRONZE_TO_SILVER_RAW_WEB_EVENTS_NESTED_TASK;