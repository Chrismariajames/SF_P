--CREATE OR REPLACE SCHEMA ETL;
--USE SCHEMA ETL;
--customers
CREATE OR REPLACE STREAM BRONZE.customers_stream_bronze
ON TABLE BRONZE.CUSTOMERS_BRONZE;

--drop task task_bronze_to_silver_customers
CREATE OR REPLACE TASK ECOM_DW.SILVER.TASK_BRONZE_TO_SILVER_CUSTOMERS
WAREHOUSE = ECOM_WH
SCHEDULE = '5 MINUTES'
WHEN SYSTEM$STREAM_HAS_DATA('ECOM_DW.BRONZE.CUSTOMERS_STREAM_BRONZE')

AS

MERGE INTO ECOM_DW.SILVER.CUSTOMERS_SILVER TGT

USING
(
    SELECT
        CUSTOMER_ID,
        FIRST_NAME,
        LAST_NAME,
        EMAIL,
        PHONE,
        GENDER,
        DATE_OF_BIRTH,
        CUSTOMER_STATUS,
        CITY,
        STATE_CODE,
        STATE_NAME,
        COUNTRY_CODE,
        COUNTRY_NAME,
        POSTAL_CODE,
        SIGNUP_DATE,
        SOURCE_SYSTEM,
        CREATED_TIMESTAMP,
        UPDATED_TIMESTAMP

    FROM
    (
        SELECT

            TRIM(CUSTOMER_ID)                         AS CUSTOMER_ID,

            INITCAP(TRIM(FIRST_NAME))                AS FIRST_NAME,

            INITCAP(TRIM(LAST_NAME))                 AS LAST_NAME,

            LOWER(TRIM(EMAIL))                       AS EMAIL,

            TRIM(PHONE)                              AS PHONE,

            UPPER(TRIM(GENDER))                      AS GENDER,

            TRY_TO_DATE(DATE_OF_BIRTH)               AS DATE_OF_BIRTH,

            UPPER(TRIM(CUSTOMER_STATUS))             AS CUSTOMER_STATUS,

            INITCAP(TRIM(CITY))                      AS CITY,

            UPPER(TRIM(STATE_CODE))                  AS STATE_CODE,

            INITCAP(TRIM(STATE_NAME))                AS STATE_NAME,

            UPPER(TRIM(COUNTRY_CODE))                AS COUNTRY_CODE,

            INITCAP(TRIM(COUNTRY_NAME))              AS COUNTRY_NAME,

            TRIM(POSTAL_CODE)                        AS POSTAL_CODE,

            TRY_TO_DATE(SIGNUP_DATE)                 AS SIGNUP_DATE,

            UPPER(TRIM(SOURCE_SYSTEM))               AS SOURCE_SYSTEM,

            CURRENT_TIMESTAMP()                      AS CREATED_TIMESTAMP,

            CURRENT_TIMESTAMP()                      AS UPDATED_TIMESTAMP,

            ROW_NUMBER() OVER
            (
                PARTITION BY CUSTOMER_ID
                ORDER BY LOAD_TIME DESC
            ) AS RN

        FROM ECOM_DW.BRONZE.CUSTOMERS_STREAM_BRONZE
    ) S

    WHERE RN = 1

) SRC

ON TGT.CUSTOMER_ID = SRC.CUSTOMER_ID

WHEN MATCHED THEN

UPDATE SET

      FIRST_NAME        = SRC.FIRST_NAME
    , LAST_NAME         = SRC.LAST_NAME
    , EMAIL             = SRC.EMAIL
    , PHONE             = SRC.PHONE
    , GENDER            = SRC.GENDER
    , DATE_OF_BIRTH     = SRC.DATE_OF_BIRTH
    , CUSTOMER_STATUS   = SRC.CUSTOMER_STATUS
    , CITY              = SRC.CITY
    , STATE_CODE        = SRC.STATE_CODE
    , STATE_NAME        = SRC.STATE_NAME
    , COUNTRY_CODE      = SRC.COUNTRY_CODE
    , COUNTRY_NAME      = SRC.COUNTRY_NAME
    , POSTAL_CODE       = SRC.POSTAL_CODE
    , SIGNUP_DATE       = SRC.SIGNUP_DATE
    , SOURCE_SYSTEM     = SRC.SOURCE_SYSTEM
    , UPDATED_TIMESTAMP = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN

INSERT
(
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    PHONE,
    GENDER,
    DATE_OF_BIRTH,
    CUSTOMER_STATUS,
    CITY,
    STATE_CODE,
    STATE_NAME,
    COUNTRY_CODE,
    COUNTRY_NAME,
    POSTAL_CODE,
    SIGNUP_DATE,
    SOURCE_SYSTEM,
    CREATED_TIMESTAMP,
    UPDATED_TIMESTAMP
)

VALUES
(
    SRC.CUSTOMER_ID,
    SRC.FIRST_NAME,
    SRC.LAST_NAME,
    SRC.EMAIL,
    SRC.PHONE,
    SRC.GENDER,
    SRC.DATE_OF_BIRTH,
    SRC.CUSTOMER_STATUS,
    SRC.CITY,
    SRC.STATE_CODE,
    SRC.STATE_NAME,
    SRC.COUNTRY_CODE,
    SRC.COUNTRY_NAME,
    SRC.POSTAL_CODE,
    SRC.SIGNUP_DATE,
    SRC.SOURCE_SYSTEM,
    SRC.CREATED_TIMESTAMP,
    SRC.UPDATED_TIMESTAMP
);

SELECT * FROM TABLE (INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME=>'TASK_BRONZE_TO_SILVER_CUSTOMERS',scheduled_time_range_start=>dateadd('hour',-24,current_timestamp()))) order by scheduled_time desc;
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMERS RESUME;
EXECUTE TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMERS;
--drop task task_bronze_to_silver_channels
--select * from bronze.channels_bronze;
SHOW STREAMS IN SCHEMA ECOM_DW.BRONZE;
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();--CHANNELS_STREAM_BRONZE
select * from silver.channels_silver;
--ALTER TASK SILVER.TASK_BRONZE_TO_SILVER_CUSTOMERS SUSPEND
