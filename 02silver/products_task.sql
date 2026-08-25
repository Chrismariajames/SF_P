CREATE OR REPLACE STREAM BRONZE.products_stream_bronze
ON TABLE BRONZE.PRODUCTS_BRONZE;

CREATE OR REPLACE TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_PRODUCTS
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('ECOM_DW.BRONZE.PRODUCTS_STREAM_BRONZE')
AS

MERGE INTO ECOM_DW.SILVER.PRODUCTS_SILVER AS TGT
USING
(
    SELECT
        product_id,
        sku,
        product_name,
        brand,
        department_id,
        department_name,
        category_id,
        category_name,
        supplier_id,
        supplier_name,
        TRY_TO_NUMBER(unit_cost, 10, 2)  AS unit_cost,
        TRY_TO_NUMBER(unit_price, 10, 2) AS unit_price,
        CASE 
            WHEN UPPER(is_active) IN ('TRUE','Y','YES','1') THEN TRUE
            ELSE FALSE
        END AS is_active,
        source_system,
        load_time AS bronze_load_time
    FROM ECOM_DW.BRONZE.PRODUCTS_STREAM_BRONZE
    WHERE METADATA$ACTION = 'INSERT'
) AS SRC

ON TGT.product_id = SRC.product_id

WHEN MATCHED THEN
UPDATE SET
    TGT.sku               = SRC.sku,
    TGT.product_name      = SRC.product_name,
    TGT.brand             = SRC.brand,
    TGT.department_id     = SRC.department_id,
    TGT.department_name   = SRC.department_name,
    TGT.category_id       = SRC.category_id,
    TGT.category_name     = SRC.category_name,
    TGT.supplier_id       = SRC.supplier_id,
    TGT.supplier_name     = SRC.supplier_name,
    TGT.unit_cost         = SRC.unit_cost,
    TGT.unit_price        = SRC.unit_price,
    TGT.is_active         = SRC.is_active,
    TGT.source_system     = SRC.source_system,
    TGT.bronze_load_time  = SRC.bronze_load_time,
    TGT.silver_load_time  = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT
(
    product_id,
    sku,
    product_name,
    brand,
    department_id,
    department_name,
    category_id,
    category_name,
    supplier_id,
    supplier_name,
    unit_cost,
    unit_price,
    is_active,
    source_system,
    bronze_load_time,
    silver_load_time
)
VALUES
(
    SRC.product_id,
    SRC.sku,
    SRC.product_name,
    SRC.brand,
    SRC.department_id,
    SRC.department_name,
    SRC.category_id,
    SRC.category_name,
    SRC.supplier_id,
    SRC.supplier_name,
    SRC.unit_cost,
    SRC.unit_price,
    SRC.is_active,
    SRC.source_system,
    SRC.bronze_load_time,
    CURRENT_TIMESTAMP()
);

-- Step 3: Resume the task
ALTER TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_PRODUCTS SUSPEND;