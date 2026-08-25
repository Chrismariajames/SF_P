CREATE OR REPLACE STREAM BRONZE.ORDERS_STREAM_BRONZE --channels_stream_bronze
ON TABLE ORDERS_BRONZE;

--TASK_BRONZE_TO_SILVER_CUSTOMERS
CREATE OR REPLACE TASK SILVER.TASK_BRONZE_TO_SILVER_ORDERS
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('ORDERS_STREAM_BRONZE')
AS

MERGE INTO SILVER.ORDERS_SILVER tgt
USING
(
    SELECT
          TRIM(order_id)                                   AS order_id
        , TRIM(order_line_id)                              AS order_line_id
        
        -- Convert string to date
        , TO_DATE(order_date,'YYYY-MM-DD')                 AS order_date
        
        , TRIM(customer_id)                                AS customer_id
        , TRIM(product_id)                                 AS product_id
        , UPPER(TRIM(channel_code))                        AS channel_code
        , UPPER(TRIM(promo_code))                          AS promo_code

        -- Numeric conversions
        , TRY_TO_NUMBER(quantity,18,2)                     AS quantity
        , TRY_TO_NUMBER(unit_price,18,2)                   AS unit_price
        , TRY_TO_NUMBER(gross_amount,18,2)                 AS gross_amount
        , TRY_TO_NUMBER(discount_amount,18,2)              AS discount_amount
        , TRY_TO_NUMBER(tax_amount,18,2)                   AS tax_amount

        -- Recalculate net amount for consistency
        , ROUND(
              TRY_TO_NUMBER(gross_amount,18,2)
            - TRY_TO_NUMBER(discount_amount,18,2)
            + TRY_TO_NUMBER(tax_amount,18,2)
          ,2)                                              AS net_amount

        , UPPER(TRIM(payment_status))                      AS payment_status
        , UPPER(TRIM(source_system))                       AS source_system

        , CURRENT_TIMESTAMP()                              AS created_timestamp
        , CURRENT_TIMESTAMP()                              AS updated_timestamp

    FROM
    (
        -- Remove duplicates
        SELECT *,
               ROW_NUMBER() OVER
               (
                   PARTITION BY order_id, order_line_id
                   ORDER BY load_time DESC
               ) AS rn
        FROM ORDERS_STREAM_BRONZE
    ) src
    WHERE rn = 1

) src

ON tgt.order_id = src.order_id
AND tgt.order_line_id = src.order_line_id

WHEN MATCHED THEN
UPDATE SET

      tgt.order_date        = src.order_date
    , tgt.customer_id       = src.customer_id
    , tgt.product_id        = src.product_id
    , tgt.channel_code      = src.channel_code
    , tgt.promo_code        = src.promo_code
    , tgt.quantity          = src.quantity
    , tgt.unit_price        = src.unit_price
    , tgt.gross_amount      = src.gross_amount
    , tgt.discount_amount   = src.discount_amount
    , tgt.tax_amount        = src.tax_amount
    , tgt.net_amount        = src.net_amount
    , tgt.payment_status    = src.payment_status
    , tgt.source_system     = src.source_system
    , tgt.updated_timestamp = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN

INSERT
(
      order_id
    , order_line_id
    , order_date
    , customer_id
    , product_id
    , channel_code
    , promo_code
    , quantity
    , unit_price
    , gross_amount
    , discount_amount
    , tax_amount
    , net_amount
    , payment_status
    , source_system
    , created_timestamp
    , updated_timestamp
)

VALUES
(
      src.order_id
    , src.order_line_id
    , src.order_date
    , src.customer_id
    , src.product_id
    , src.channel_code
    , src.promo_code
    , src.quantity
    , src.unit_price
    , src.gross_amount
    , src.discount_amount
    , src.tax_amount
    , src.net_amount
    , src.payment_status
    , src.source_system
    , CURRENT_TIMESTAMP()
    , CURRENT_TIMESTAMP()
);

-- =========================================================
-- ENABLE TASK
-- =========================================================

ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_ORDERS RESUME;

-- =========================================================

ALTER TASk ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_ORDERS SUSPEND;
select * from bronze.ORDERS_STREAM_BRONZE

select * from silver.orders_silver
-- VALIDATION QUERY
-- =========================================================

SELECT
    order_id,
    order_line_id,
    COUNT(*) AS duplicate_count
FROM SILVER_ORDERS
GROUP BY 1,2
HAVING COUNT(*) > 1;

ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_ORDERS RESUME;

select * from bronze.orders_bronze;