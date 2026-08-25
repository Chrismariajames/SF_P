CREATE OR REPLACE STREAM BRONZE.shipments_stream_bronze
ON TABLE BRONZE.SHIPMENTS_BRONZE;
select * from ECOM_DW.BRONZE.shipments_stream_bronze;
--TRUNCATE TABLE SHIPMENTS_bronze
--truncate table bronze.promotions_bronze;
CREATE OR REPLACE TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_SHIPMENTS
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('ECOM_DW.BRONZE.SHIPMENTS_STREAM_BRONZE')
AS
MERGE INTO ECOM_DW.SILVER.SHIPMENTS_SILVER AS TGT
USING
(
    SELECT
        shipment_id,
        order_id,
        TRY_TO_DATE(shipment_date) AS shipment_date,
        customer_id,
        product_id,
        shipping_method_code,
        TRY_TO_NUMBER(shipped_qty, 10, 0) AS shipped_qty,
        TRY_TO_NUMBER(shipping_cost, 10, 2) AS shipping_cost,
        TRY_TO_NUMBER(delivery_days, 10, 0) AS delivery_days,
        source_system,
        load_time AS bronze_load_time
    FROM
    (
        SELECT
            *,
            ROW_NUMBER() OVER
            (
                PARTITION BY shipment_id
                ORDER BY load_time DESC
            ) AS RN
        FROM ECOM_DW.BRONZE.SHIPMENTS_STREAM_BRONZE
        WHERE METADATA$ACTION = 'INSERT'
    )
    WHERE RN = 1
) AS SRC

ON TGT.shipment_id = SRC.shipment_id

WHEN MATCHED THEN
UPDATE SET
    TGT.order_id             = SRC.order_id,
    TGT.shipment_date        = SRC.shipment_date,
    TGT.customer_id          = SRC.customer_id,
    TGT.product_id           = SRC.product_id,
    TGT.shipping_method_code = SRC.shipping_method_code,
    TGT.shipped_qty          = SRC.shipped_qty,
    TGT.shipping_cost        = SRC.shipping_cost,
    TGT.delivery_days        = SRC.delivery_days,
    TGT.source_system        = SRC.source_system,
    TGT.bronze_load_time     = SRC.bronze_load_time,
    TGT.silver_load_time     = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT
(
    shipment_id,
    order_id,
    shipment_date,
    customer_id,
    product_id,
    shipping_method_code,
    shipped_qty,
    shipping_cost,
    delivery_days,
    source_system,
    bronze_load_time,
    silver_load_time
)
VALUES
(
    SRC.shipment_id,
    SRC.order_id,
    SRC.shipment_date,
    SRC.customer_id,
    SRC.product_id,
    SRC.shipping_method_code,
    SRC.shipped_qty,
    SRC.shipping_cost,
    SRC.delivery_days,
    SRC.source_system,
    SRC.bronze_load_time,
    CURRENT_TIMESTAMP()
);

-- Step 3: Resume Task
ALTER TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_SHIPMENTS RESUME;

EXECUTE TASK silver.TASK_BRONZE_TO_SILVER_SHIPMENTS
--drop task  silver.TSK_MERGE_SHIPMENTS_BRONZE_TO_SILVER