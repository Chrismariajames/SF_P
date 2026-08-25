
select $1, $2 from @amz_sf_ecomdw_stg;
show pipes;             
desc pipe ECOMDW_CHANNELS_PIPE;  --arn:aws:sqs:eu-north-1:378743674015:sf-snowpipe-AIDAVQLXB2SP66EGGS6F6-rhS3iJj4sJ-VoyVoaHgy1A
select system$pipe_status('ECOMDW_CHANNELS_PIPE');
SELECT * from TABLE(INFORMATION_SCHEMA.COPY_HISTORY(TABLE_NAME=>'CHANNELS',START_TIME=>DATEADD('hour',-1, CURRENT_TIMESTAMP())));
select * from channels;
LIST @amz_sf_ecomdw_stg;
SELECT SYSTEM$PIPE_STATUS('ECOMDW_CHANNELS_PIPE');
--truncate table channels
--create or replace table task_details_brnztosil (task_number number default auto  )
--
--CREATE OR REPLACE SEQUENCE seq_01 START = 1 INCREMENT = 1;
--
CREATE or replace PIPE ECOMDW_CHANNELS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.CHANNELS_BRONZE
FROM
(
    SELECT
        TRIM(t.$1) AS channel_code,
        TRIM(t.$2) AS channel_name,
        TRIM(t.$3) AS channel_type,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        CURRENT_TIMESTAMP()
    FROM @amz_sf_ecomdw_stg t
)
PATTERN = '.*channels.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

select * from CHANNELS_BRONZE;
--2

CREATE or replace PIPE ECOMDW_CUSTOMERS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.CUSTOMERS_BRONZE
(   CUSTOMER_ID,
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
    LOAD_TIME)
    FROM
(
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        $13,
        $14,
        $15,

        METADATA$FILENAME,

        CURRENT_TIMESTAMP()

    FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)

PATTERN = '.*customers.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';
Number of columns in file (15) does not match that of the corresponding table (17), use file format option error_on_column_count_mismatch=false to ignore this error
select * from CUSTOMERS_BRONZE;
--3
CREATE or replace PIPE ECOMDW_INVENTORY_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.INVENTORY_BRONZE
(   snapshot_date , 
product_id , 
on_hand_qty , 
reserved_qty , 
available_qty , 
unit_cost , 
inventory_value ,
source_system , 
load_time )
    FROM
(
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)

PATTERN = '.*inventory.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

select * from inventory_bronze;
--4
CREATE or replace PIPE ECOMDW_ORDERS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.ORDERS_BRONZE
(order_id , 
order_line_id , 
order_date , 
customer_id , 
product_id , 
channel_code , 
promo_code , 
quantity , 
unit_price , 
gross_amount , 
discount_amount , 
tax_amount , 
net_amount , 
payment_status ,
source_system , 
load_time 
)
FROM
(
 SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        $13,
        $14,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)
PATTERN = '.*orders.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

select * from ORDERS_BRONZE;
--5
CREATE or replace PIPE ECOMDW_PRODUCTS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.PRODUCTS_BRONZE
(   product_id , 
sku , 
product_name , 
brand , 
department_id , 
department_name , 
category_id , 
category_name , 
supplier_id , 
supplier_name , 
unit_cost , 
unit_price , 
is_active ,
source_system , 
load_time )
    FROM
(
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        $13,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)

PATTERN = '.*products.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

--6
CREATE or replace PIPE ECOMDW_PROMOTIONS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.PROMOTIONS_BRONZE
(   PROMO_CODE ,
	PROMO_NAME ,
	DISCOUNT_TYPE ,
	DISCOUNT_VALUE ,
	START_DATE ,
	END_DATE ,
	IS_ACTIVE ,
	SOURCE_SYSTEM ,
	LOAD_TIME )
    FROM
(
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)

PATTERN = '.*promotions.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

select * from PROMOTIONS_BRONZE;
--7
CREATE or replace PIPE ECOMDW_SHIPMENTS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.SHIPMENTS_BRONZE
(   shipment_id ,
order_id ,
shipment_date ,
customer_id ,
product_id ,
shipping_method_code ,
shipped_qty ,
shipping_cost ,
delivery_days ,
source_system , 
load_time )
    FROM
(
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)

PATTERN = '.*shipments.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

select * from SHIPMENTS_BRONZE;
--8
CREATE or replace PIPE ECOMDW_SHIPPING_METHODS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.SHIPPING_METHODS_BRONZE
(  shipping_method_code ,
shipping_method_name ,
shipping_type ,
source_system , 
load_time )
    FROM
(
    SELECT
        $1,
        $2,
        $3,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
FROM @ECOM_DW.BRONZE.amz_sf_ecomdw_stg
)

PATTERN = '.*shipping_methods.*\.csv$'
FILE_FORMAT = (FORMAT_NAME=sf_csv_ecomdw_ff)
ON_ERROR = 'CONTINUE';

select * from SHIPPING_METHODS;
--9 json
CREATE or replace PIPE ECOMDW_CUSTOMER_REVIEWS_PIPE
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.RAW_CUSTOMER_REVIEWS_BRONZE
FROM (
    SELECT
        $1,
        METADATA$FILENAME,
        CURRENT_TIMESTAMP()
    FROM @amz_sf_ecomdw_stg
)
PATTERN = '.*customer_reviews.*\.json$'
FILE_FORMAT = (
    FORMAT_NAME = SF_JSON_ECOMDW_FF
)
ON_ERROR = 'CONTINUE';

select * from RAW_CUSTOMER_REVIEWS_BRONZE;
--10
CREATE OR REPLACE TABLE ECOM_DW.BRONZE.RAW_WEB_EVENTS_NESTED
(RAW_DATA VARIANT,FILENAME STRING,LOAD_TIME TIMESTAMP);
COPY INTO ECOM_DW.BRONZE.RAW_WEB_EVENTS_NESTED
FROM (
    SELECT
        $1,
        METADATA$FILENAME,
        CURRENT_TIMESTAMP()
    FROM @amz_sf_ecomdw_stg
)
PATTERN = '.*web_events_nested.*\.json$'
FILE_FORMAT = (
    FORMAT_NAME = SF_JSON_ECOMDW_FF
)
ON_ERROR = 'CONTINUE';

select * from RAW_WEB_EVENTS_NESTED;


CREATE OR REPLACE PIPE ecomdw_shipping_methods_pipe
AUTO_INGEST=TRUE
AS
COPY INTO ECOM_DW.BRONZE.SHIPPING_METHODS
FROM
(
    SELECT
        $1::STRING AS shipping_method_id,
        $2::STRING AS shipping_method_name,
        $3::STRING AS shipping_cost,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        CURRENT_TIMESTAMP() AS load_timestamp
    FROM @ECOM_DW.BRONZE.ex_amz_sf_ecomdw_stg/shipping_methods.csv
)
FILE_FORMAT = (FORMAT_NAME = sf_csv_ecomdw_ff);

show pipes;
--drop pipe CUSTOMER_REVIEWS_PIPE;
--drop pipe ECOMDW_CHANNELS_PIPE;
--drop pipe ECOMDW_SHIPPING_METHODS_PIPE;