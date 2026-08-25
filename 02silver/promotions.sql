CREATE OR REPLACE STREAM BRONZE.promotions_stream_bronze
ON TABLE BRONZE.PROMOTIONS_BRONZE;
select * from ECOM_DW.BRONZE.promotions_stream_bronze;
--truncate table bronze.promotions_bronze;
CREATE OR REPLACE TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_PROMOTIONS
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('ECOM_DW.BRONZE.PROMOTIONS_STREAM_BRONZE')
AS
MERGE INTO ECOM_DW.SILVER.PROMOTIONS_SILVER AS TGT
USING
(
    SELECT
        promo_code,
        promo_name,
        discount_type,
        TRY_TO_NUMBER(discount_value, 10, 2) AS discount_value,
        TRY_TO_DATE(start_date) AS start_date,
        TRY_TO_DATE(end_date)   AS end_date,
        CASE
            WHEN UPPER(is_active) IN ('TRUE','Y','YES','1')
            THEN TRUE
            ELSE FALSE
        END AS is_active,
        source_system,
        load_time AS bronze_load_time
    FROM ECOM_DW.BRONZE.PROMOTIONS_STREAM_BRONZE
    WHERE METADATA$ACTION = 'INSERT'
) AS SRC

ON TGT.promo_code = SRC.promo_code

WHEN MATCHED THEN
UPDATE SET
    TGT.promo_name        = SRC.promo_name,
    TGT.discount_type     = SRC.discount_type,
    TGT.discount_value    = SRC.discount_value,
    TGT.start_date        = SRC.start_date,
    TGT.end_date          = SRC.end_date,
    TGT.is_active         = SRC.is_active,
    TGT.source_system     = SRC.source_system,
    TGT.bronze_load_time  = SRC.bronze_load_time,
    TGT.silver_load_time  = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT
(
    promo_code,
    promo_name,
    discount_type,
    discount_value,
    start_date,
    end_date,
    is_active,
    source_system,
    bronze_load_time,
    silver_load_time
)
VALUES
(
    SRC.promo_code,
    SRC.promo_name,
    SRC.discount_type,
    SRC.discount_value,
    SRC.start_date,
    SRC.end_date,
    SRC.is_active,
    SRC.source_system,
    SRC.bronze_load_time,
    CURRENT_TIMESTAMP()
);
select * from silver.promotions_silver;
-- Step 3: Resume the task
ALTER TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_PROMOTIONS SUSPEND;
EXECUTE TASK TASK_BRONZE_TO_SILVER_PROMOTIONS;