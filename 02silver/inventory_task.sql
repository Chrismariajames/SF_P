--CREATE OR REPLACE SCHEMA ETL;
--USE SCHEMA ETL;
--customers
CREATE OR REPLACE STREAM BRONZE.inventory_stream_bronze
ON TABLE BRONZE.INVENTORY_BRONZE;
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_INVENTORY RESUME;
--drop task task_bronze_to_silver_customers
-- ============================================
-- MERGE SCRIPT FOR INVENTORY TABLE
-- Removes duplicates and applies transformations
-- Source  : bronze
-- Target  : silver
-- Platform: Snowflake
-- ============================================
CREATE OR REPLACE TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_INVENTORY
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTES'
WHEN SYSTEM$STREAM_HAS_DATA('ECOM_DW.BRONZE.INVENTORY_STREAM_BRONZE')
AS


MERGE INTO SILVER.INVENTORY_SILVER tgt
USING
(
    SELECT
        TO_DATE(snapshot_date)                                   AS snapshot_date,
        TRIM(product_id)                                         AS product_id,
        
        -- Handle nulls and negative quantities
        COALESCE(on_hand_qty,0)                                  AS on_hand_qty,
        COALESCE(reserved_qty,0)                                 AS reserved_qty,
        
        -- Derived available quantity
        COALESCE(on_hand_qty,0) - COALESCE(reserved_qty,0)       AS available_qty,
        
        ROUND(COALESCE(unit_cost,0),2)                           AS unit_cost,
        
        -- Derived inventory value
        ROUND(
            (COALESCE(on_hand_qty,0) - COALESCE(reserved_qty,0))
            * COALESCE(unit_cost,0),2
        )                                                        AS inventory_value,
        
        UPPER(TRIM(source_system))                               AS source_system,
        
        load_time                                     AS created_timestamp

    FROM
    (
        -- Deduplicate records
        SELECT *,
               ROW_NUMBER() OVER
               (
                   PARTITION BY snapshot_date, product_id
                   ORDER BY load_time DESC
               ) AS rn
        FROM ECOM_DW.BRONZE.INVENTORY_STREAM_BRONZE
    ) src
    WHERE rn = 1

) src

ON tgt.snapshot_date = src.snapshot_date
AND tgt.product_id   = src.product_id

WHEN MATCHED THEN
UPDATE SET
      tgt.on_hand_qty    = src.on_hand_qty
    , tgt.reserved_qty   = src.reserved_qty
    , tgt.available_qty  = src.available_qty
    , tgt.unit_cost      = src.unit_cost
    , tgt.inventory_value= src.inventory_value
    , tgt.source_system  = src.source_system
    , tgt.created_timestamp      = src.created_timestamp

WHEN NOT MATCHED THEN
INSERT
(
      snapshot_date
    , product_id
    , on_hand_qty
    , reserved_qty
    , available_qty
    , unit_cost
    , inventory_value
    , source_system
    , created_timestamp
)
VALUES
(
      src.snapshot_date
    , src.product_id
    , src.on_hand_qty
    , src.reserved_qty
    , src.available_qty
    , src.unit_cost
    , src.inventory_value
    , src.source_system
    , src.created_timestamp
);

-- ============================================
-- OPTIONAL VALIDATION QUERY
-- ============================================

SELECT
    snapshot_date,
    product_id,
    COUNT(*) AS duplicate_count
FROM SILVER.INVENTORY_SILVER
GROUP BY 1,2
HAVING COUNT(*) > 1;

SELECT * FROM TABLE (INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME=>'TASK_BRONZE_TO_SILVER_INVENTORY',scheduled_time_range_start=>dateadd('hour',-24,current_timestamp()))) order by scheduled_time desc;
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_INVENTORY RESUME;
EXECUTE TASK SILVER.TASK_BRONZE_TO_SILVER_INVENTORY;
--drop task TASK_BRONZE_TO_SILVER_INVENTORY
--select * from bronze.inventory_bronze;
SHOW STREAMS IN SCHEMA ECOM_DW.BRONZE;
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();--CHANNELS_STREAM_BRONZE
select * from silver.inventory_silver;
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMERS SUSPEND
SQL compilation error: error line 66 at position 6
invalid identifier 'LOAD_TIME'



select       src.snapshot_date
    , src.product_id
    , src.on_hand_qty
    , src.reserved_qty
    , src.available_qty
    , src.unit_cost
    , src.inventory_value
    , src.source_system
    , src.load_time   from bronze.inventory_bronze src;