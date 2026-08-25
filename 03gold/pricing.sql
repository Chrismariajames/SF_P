USE database SFSESSION3;

USE SCHEMA SFSESSION3.SFSESSION3SCH;

SELECT * from Information_schema.table_storage_metrics where table_catalog = 'SFSESSION3';

USE schema snowflake.account_usage;

SElect * from query_history;

select query_type, SUM(credits_used_cloud_services) credits_consumed, COUNT(1) num_of_queries

from query_history

where start_time>=timestampadd(day,-2,current_timestamp())

group by 1

order by 2 desc;



select * from warehouse_metering_history;



select warehouse_name, SUM(credits_used_cloud_services) credits_used_cs,

SUM(credits_used_compute) credit_used_comp, sum(credits_used) credit_used

from warehouse_metering_history group by 1

order by 4 desc;

