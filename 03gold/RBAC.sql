For your Snowflake enterprise data warehouse:

* Role-based access control (RBAC)
* Separate admin, ETL, analyst, and BI roles
* Least privilege access
* Secure Gold layer access
* Read-only BI access
* Write access only for ETL roles

Below is a production-grade setup.

---

# Recommended Role Hierarchy


ACCOUNTADMIN
    |
SYSADMIN
    |
------------------------------------------------
|              |              |                |
ECOM_ETL_ROLE  ECOM_BI_ROLE  ECOM_ANALYST_ROLE ECOM_DATA_SCIENCE_ROLE
```

---

# 1. Create Roles

## ETL Role

CREATE OR REPLACE ROLE ECOM_ETL_ROLE;
```

---

## BI Role

CREATE OR REPLACE ROLE ECOM_BI_ROLE;
```

---

## Analyst Role

CREATE OR REPLACE ROLE ECOM_ANALYST_ROLE;
```

---

## Data Science Role

CREATE OR REPLACE ROLE ECOM_DATA_SCIENCE_ROLE;
```

---

# 2. Create Warehouses

## ETL Warehouse

CREATE OR REPLACE WAREHOUSE ECOM_ETL_WH
WITH
WAREHOUSE_SIZE = LARGE
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;
```

---

## BI Warehouse

Scale-out warehouse.

CREATE OR REPLACE WAREHOUSE ECOM_BI_WH
WITH
WAREHOUSE_SIZE = MEDIUM
MIN_CLUSTER_COUNT = 1
MAX_CLUSTER_COUNT = 5
SCALING_POLICY = STANDARD
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE;
```

---

## Data Science Warehouse

CREATE OR REPLACE WAREHOUSE ECOM_DS_WH
WITH
WAREHOUSE_SIZE = LARGE
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE;
```

---

# 3. Warehouse Permissions

## ETL Role

GRANT USAGE
ON WAREHOUSE ECOM_ETL_WH
TO ROLE ECOM_ETL_ROLE;
```

---

## BI Role

GRANT USAGE
ON WAREHOUSE ECOM_BI_WH
TO ROLE ECOM_BI_ROLE;
```

---

## Analyst Role
GRANT USAGE
ON WAREHOUSE ECOM_BI_WH
TO ROLE ECOM_ANALYST_ROLE;
```

---

## Data Science Role

GRANT USAGE
ON WAREHOUSE ECOM_DS_WH
TO ROLE ECOM_DATA_SCIENCE_ROLE;
```

---

# 4. Database Permissions

## Gold Layer Access

---

## ETL Full Access

```sql id="wgj8gj"
GRANT USAGE
ON DATABASE ECOM_DW
TO ROLE ECOM_ETL_ROLE;

GRANT USAGE
ON SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ETL_ROLE;

GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ETL_ROLE;

GRANT ALL PRIVILEGES
ON FUTURE TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ETL_ROLE;
```

---

## BI Read-Only Access

GRANT USAGE
ON DATABASE ECOM_DW
TO ROLE ECOM_BI_ROLE;

GRANT USAGE
ON SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_BI_ROLE;

GRANT SELECT
ON ALL TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_BI_ROLE;

GRANT SELECT
ON FUTURE TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_BI_ROLE;
```

---

## Analyst Access

GRANT USAGE
ON DATABASE ECOM_DW
TO ROLE ECOM_ANALYST_ROLE;

GRANT USAGE
ON SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ANALYST_ROLE;

GRANT SELECT
ON ALL TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ANALYST_ROLE;

GRANT SELECT
ON FUTURE TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ANALYST_ROLE;
```

---

## Data Science Access

GRANT USAGE
ON DATABASE ECOM_DW
TO ROLE ECOM_DATA_SCIENCE_ROLE;

GRANT USAGE
ON SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_DATA_SCIENCE_ROLE;

GRANT SELECT
ON ALL TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_DATA_SCIENCE_ROLE;

GRANT SELECT
ON FUTURE TABLES IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_DATA_SCIENCE_ROLE;
```

---

# 5. Grant Stream & Task Permissions

Required for ETL automation.

GRANT CREATE TASK
ON SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ETL_ROLE;

GRANT EXECUTE TASK
ON ACCOUNT
TO ROLE ECOM_ETL_ROLE;

GRANT MONITOR
ON ALL TASKS IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ETL_ROLE;

GRANT USAGE
ON ALL STREAMS IN SCHEMA ECOM_DW.SILVER
TO ROLE ECOM_ETL_ROLE;
```

---

# 6. Grant Cortex AI Permissions

For AI sentiment analysis.

GRANT USAGE
ON DATABASE SNOWFLAKE
TO ROLE ECOM_DATA_SCIENCE_ROLE;

GRANT IMPORTED PRIVILEGES
ON DATABASE SNOWFLAKE
TO ROLE ECOM_DATA_SCIENCE_ROLE;
```

---

# 7. Create Users

## ETL User

CREATE OR REPLACE USER ECOM_ETL_USER
PASSWORD = 'StrongPassword123!'
DEFAULT_ROLE = ECOM_ETL_ROLE
DEFAULT_WAREHOUSE = ECOM_ETL_WH
MUST_CHANGE_PASSWORD = TRUE;
```

---

## BI User

CREATE OR REPLACE USER ECOM_BI_USER
PASSWORD = 'StrongPassword123!'
DEFAULT_ROLE = ECOM_BI_ROLE
DEFAULT_WAREHOUSE = ECOM_BI_WH
MUST_CHANGE_PASSWORD = TRUE;
```

---

## Analyst User


CREATE OR REPLACE USER ECOM_ANALYST_USER
PASSWORD = 'StrongPassword123!'
DEFAULT_ROLE = ECOM_ANALYST_ROLE
DEFAULT_WAREHOUSE = ECOM_BI_WH
MUST_CHANGE_PASSWORD = TRUE;
```

---

## Data Science User


CREATE OR REPLACE USER ECOM_DS_USER
PASSWORD = 'StrongPassword123!'
DEFAULT_ROLE = ECOM_DATA_SCIENCE_ROLE
DEFAULT_WAREHOUSE = ECOM_DS_WH
MUST_CHANGE_PASSWORD = TRUE;
```

---

# 8. Assign Roles to Users


GRANT ROLE ECOM_ETL_ROLE
TO USER ECOM_ETL_USER;

GRANT ROLE ECOM_BI_ROLE
TO USER ECOM_BI_USER;

GRANT ROLE ECOM_ANALYST_ROLE
TO USER ECOM_ANALYST_USER;

GRANT ROLE ECOM_DATA_SCIENCE_ROLE
TO USER ECOM_DS_USER;
```

---

# 9. Grant Future Object Access

Critical enterprise best practice.

## Future Views

```sql id="ukxujz"
GRANT SELECT
ON FUTURE VIEWS IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_BI_ROLE;

GRANT SELECT
ON FUTURE VIEWS IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_ANALYST_ROLE;
```

---

## Future Materialized Views

```sql id="ubgspr"
GRANT SELECT
ON FUTURE MATERIALIZED VIEWS IN SCHEMA ECOM_DW.GOLD
TO ROLE ECOM_BI_ROLE;
```

---

# 10. Recommended Row Access Policy

Protect customer data.

## Example

```sql id="zb8wll"
CREATE OR REPLACE ROW ACCESS POLICY CUSTOMER_REGION_POLICY
AS (COUNTRY_NAME STRING)
RETURNS BOOLEAN ->

CASE
    WHEN CURRENT_ROLE() = 'ECOM_ANALYST_ROLE'
         AND COUNTRY_NAME = 'Germany'
    THEN TRUE

    WHEN CURRENT_ROLE() = 'ACCOUNTADMIN'
    THEN TRUE

    ELSE FALSE
END;
```

---

# Apply Policy

```sql id="91fj1e"
ALTER TABLE ECOM_DW.GOLD.DIM_CUSTOMER
ADD ROW ACCESS POLICY CUSTOMER_REGION_POLICY
ON (COUNTRY_NAME);
```

---

# 11. Recommended Secure Views

For BI consumption.

```sql id="2yrm5h"
CREATE OR REPLACE SECURE VIEW ECOM_DW.GOLD.VW_SALES_SUMMARY
AS

SELECT
    ORDER_DATE_KEY,
    SUM(NET_AMOUNT) AS TOTAL_SALES
FROM ECOM_DW.GOLD.FACT_SALES
GROUP BY ORDER_DATE_KEY;
```

---

# 12. Recommended Admin Grants

Allow SYSADMIN to manage.

```sql id="a3c1wy"
GRANT ROLE ECOM_ETL_ROLE TO ROLE SYSADMIN;

GRANT ROLE ECOM_BI_ROLE TO ROLE SYSADMIN;

GRANT ROLE ECOM_ANALYST_ROLE TO ROLE SYSADMIN;

GRANT ROLE ECOM_DATA_SCIENCE_ROLE TO ROLE SYSADMIN;
```

---

# Final Enterprise Security Model

| Role                   | Access                     |
| ---------------------- | -------------------------- |
| ECOM_ETL_ROLE          | Full ETL + Tasks + Streams |
| ECOM_BI_ROLE           | Read-only dashboards       |
| ECOM_ANALYST_ROLE      | Ad hoc analysis            |
| ECOM_DATA_SCIENCE_ROLE | AI/ML/Cortex access        |
| SYSADMIN               | Full administration        |

---

# Recommended Additional Security

## Enable

* MFA
* Network Policies
* PrivateLink
* Tri-Secret Secure
* Object Tagging
* Access History
* Query History Auditing
* Data Classification
* Object Dependencies

---

# Recommended Governance Features

Use:

* masking policies
* row access policies
* tags
* secure views
* data retention
* fail-safe
* zero-copy cloning

These are heavily used in enterprise Snowflake architectures.
