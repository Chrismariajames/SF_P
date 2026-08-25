--CREATE OR REPLACE SCHEMA ETL;
--USE SCHEMA ETL;
--create or replace table task_detailsbrnztosil(task_number NUMBER,TASK_NAME STRING, LOADTIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP());
--CHANNELS
CREATE OR REPLACE STREAM BRONZE.channels_stream_bronze
ON TABLE BRONZE.CHANNELS_BRONZE;

--drop task task_bronze_to_silver_channels
CREATE OR REPLACE TASK silver.task_bronze_to_silver_channels
WAREHOUSE = ecom_wh
SCHEDULE = '5 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('CHANNELS_STREAM_BRONZE')
AS
MERGE INTO silver.channels_silver tgt
USING (
    WITH cleaned_data AS (
        SELECT
            UPPER(TRIM(channel_code)) AS channel_code,
            INITCAP(NULLIF(TRIM(channel_name), '')) AS channel_name,
            UPPER(NULLIF(TRIM(channel_type), '')) AS channel_type,
            --INITCAP(NULLIF(TRIM(channel_name), '')) AS channel_name_std,
           -- UPPER(NULLIF(TRIM(channel_type), '')) AS channel_type_std,
            source_system,
            load_time,
            ROW_NUMBER() OVER (
                PARTITION BY UPPER(TRIM(channel_code))
                ORDER BY load_time DESC
            ) AS rn
        FROM ecom_dw.bronze.CHANNELS_STREAM_BRONZE
        WHERE channel_code IS NOT NULL
          AND TRIM(channel_code) <> ''
    )
    SELECT *
    FROM cleaned_data
    WHERE rn = 1
) src
ON tgt.channel_code = src.channel_code
WHEN MATCHED THEN UPDATE SET
    tgt.channel_name      = src.channel_name,
    tgt.channel_type      = src.channel_type,
    --tgt.channel_name_std  = src.channel_name_std,
    --tgt.channel_type_std  = src.channel_type_std,
    tgt.updated_timestamp = CURRENT_TIMESTAMP(),
    tgt.source_system     = src.source_system

WHEN NOT MATCHED THEN INSERT (
    channel_code,
    channel_name,
    channel_type,
    --channel_name_std,
    --channel_type_std,
    is_active,
    created_timestamp,
    updated_timestamp,
    source_system
)

VALUES (

    src.channel_code,
    src.channel_name,
    src.channel_type,
    --src.channel_name_std,
    --src.channel_type_std,
    TRUE,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP(),
    src.source_system
);

SELECT * FROM TABLE (INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME=>'TASK_BRONZE_TO_SILVER_CHANNELS',scheduled_time_range_start=>dateadd('hour',-24,current_timestamp()))) order by scheduled_time desc;
--ALTER TASK TASK_BRONZE_TO_SILVER_CHANNELS RESUME;
EXECUTE TASK bronze.TASK_BRONZE_TO_SILVER_CHANNELS;
--drop task task_bronze_to_silver_channels
--select * from bronze.channels_bronze;
SHOW STREAMS IN SCHEMA ECOM_DW.BRONZE;
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();--CHANNELS_STREAM_BRONZE
select * from silver.channels_silver;
--ALTER TASK task_bronze_to_silver_channels SUSPEND
