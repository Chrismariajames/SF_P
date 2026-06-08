create or replace database ECOM_DW;

use database ECOM_DW;

CREATE or replace SCHEMA GOLD;

use schema GOLD;

use warehouse ecom_wh;


use database ECOM_DW;

use schema GOLD;



-- =====================================================================

-- TABLE: DIM_DATE

-- PURPOSE:

-- Stores one row per calendar date.

-- This is a standard time dimension used by fact tables for reporting by

-- day, week, month, quarter, and year.

--

-- BUSINESS VALUE:

-- Helps business users analyze sales, shipments, and inventory trends

-- across time without recalculating calendar attributes in every query.

-- Makes reporting faster and more consistent.

--

-- DATATYPE CHOICES:

-- DATE_KEY NUMBER:

--  Stored as YYYYMMDD numeric surrogate-style reporting key.

--  Useful for joins from fact tables and easy date filtering in BI tools.

-- FULL_DATE DATE:

--  Native date type for date arithmetic and calendar functions.

-- DAY, MONTH, YEAR fields NUMBER:

--  Numeric values are efficient for filtering and grouping.

-- DAY_NAME, MONTH_NAME STRING:

--  Human-readable labels for reporting.

-- IS_WEEKEND BOOLEAN:

--  Efficient true/false flag for business analysis.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_DATE (

  DATE_KEY         number not null,

  FULL_DATE        date not null,

  DAY_OF_WEEK       number,

  DAY_NAME         string,

  DAY_OF_MONTH       number,

  DAY_OF_YEAR       number,

  WEEK_OF_YEAR       number,

  MONTH_NUMBER       number,

  MONTH_NAME        string,

  QUARTER_NUMBER      number,

  YEAR_NUMBER       number,

  IS_WEEKEND        boolean,

  primary key (DATE_KEY)

);



-- =====================================================================

-- TABLE: DIM_COUNTRY

-- PURPOSE:

-- Stores country master data for customer geography hierarchy.

--

-- BUSINESS VALUE:

-- Supports country-level reporting such as sales by country,

-- shipment volume by country, and market expansion analysis.

--

-- DATATYPE CHOICES:

-- COUNTRY_KEY NUMBER AUTOINCREMENT:

--  Surrogate key used internally for modeling and joins.

-- COUNTRY_CODE STRING:

--  Country codes like IN, US, UK are alphanumeric.

-- COUNTRY_NAME STRING:

--  Country names are text and can vary in length.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_COUNTRY (

  COUNTRY_KEY       number autoincrement start 1 increment 1,

  COUNTRY_CODE       string,

  COUNTRY_NAME       string,

  primary key (COUNTRY_KEY)

);



-- =====================================================================

-- TABLE: DIM_STATE

-- PURPOSE:

-- Stores state or province details.

-- This table belongs to the geography hierarchy.

--

-- BUSINESS VALUE:

-- Enables state-level analysis for customer concentration,

-- shipment performance, and regional demand planning.

--

-- DATATYPE CHOICES:

-- STATE_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for dimensional joins.

-- STATE_CODE STRING:

--  Some states use short codes like KA, TX, MH.

-- STATE_NAME STRING:

--  State or province name stored as text.

-- COUNTRY_KEY NUMBER:

--  Logical parent reference to country.

--  Kept as NUMBER because it points to surrogate key in DIM_COUNTRY.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_STATE (

  STATE_KEY        number autoincrement start 1 increment 1,

  STATE_CODE        string,

  STATE_NAME        string,

  COUNTRY_KEY       number,

  primary key (STATE_KEY)

);



-- =====================================================================

-- TABLE: DIM_GEOGRAPHY

-- PURPOSE:

-- Stores lower geography granularity such as city and postal code.

-- This table sits below state in the location hierarchy.

--

-- BUSINESS VALUE:

-- Useful for hyperlocal demand analysis, delivery optimization,

-- and studying customer density by city or postal code.

--

-- DATATYPE CHOICES:

-- GEOGRAPHY_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for joins from customer dimension.

-- CITY STRING:

--  City names are text.

-- POSTAL_CODE STRING:

--  Postal codes should be STRING because many countries use

--  leading zeros or alphanumeric codes.

-- STATE_KEY NUMBER:

--  Parent key to DIM_STATE.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_GEOGRAPHY (

  GEOGRAPHY_KEY      number autoincrement start 1 increment 1,

  CITY           string,

  POSTAL_CODE       string,

  STATE_KEY        number,

  primary key (GEOGRAPHY_KEY)

);



-- =====================================================================

-- TABLE: DIM_CUSTOMER

-- PURPOSE:

-- Stores customer profile attributes.

-- This dimension may be used as SCD Type 2 in future for history tracking.

--

-- BUSINESS VALUE:

-- Helps answer questions like:

--  Which customer segment buys most

--  Which geography has high-value customers

--  How customer status affects sales

--

-- DATATYPE CHOICES:

-- CUSTOMER_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for fact table joins.

-- CUSTOMER_ID, CUSTOMER_NK STRING:

--  Business identifiers may come from source systems and can be alphanumeric.

-- FIRST_NAME, LAST_NAME, FULL_NAME, EMAIL, PHONE, GENDER, STATUS STRING:

--  These are descriptive text fields.

-- DATE_OF_BIRTH DATE:

--  Native date type is best for age analysis.

-- GEOGRAPHY_KEY NUMBER:

--  Links customer to geography dimension.

-- EFFECTIVE_FROM, EFFECTIVE_TO TIMESTAMP_NTZ:

--  Useful for historical tracking without timezone complexity.

-- IS_CURRENT BOOLEAN:

--  Indicates active current record in SCD design.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_CUSTOMER (

  CUSTOMER_KEY       number autoincrement start 1 increment 1,

  CUSTOMER_ID       string,

  CUSTOMER_NK       string,

  FIRST_NAME        string,

  LAST_NAME        string,

  FULL_NAME        string,

  EMAIL          string,

  PHONE          string,

  GENDER          string,

  DATE_OF_BIRTH      date,

  CUSTOMER_STATUS     string,

  GEOGRAPHY_KEY      number,

  EFFECTIVE_FROM      timestamp_ntz,

  EFFECTIVE_TO       timestamp_ntz,

  IS_CURRENT        boolean,

  primary key (CUSTOMER_KEY)

);



-- =====================================================================

-- TABLE: DIM_DEPARTMENT

-- PURPOSE:

-- Stores top-level product grouping such as Electronics, Fashion, Grocery.

--

-- BUSINESS VALUE:

-- Helps business leaders analyze revenue and margin at department level.

-- Very useful for merchandising, assortment planning, and executive dashboards.

--

-- DATATYPE CHOICES:

-- DEPARTMENT_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for dimension hierarchy.

-- DEPARTMENT_ID STRING:

--  Business key from source systems.

-- DEPARTMENT_NAME STRING:

--  Descriptive label for reporting.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_DEPARTMENT (

  DEPARTMENT_KEY      number autoincrement start 1 increment 1,

  DEPARTMENT_ID      string,

  DEPARTMENT_NAME     string,

  primary key (DEPARTMENT_KEY)

);



-- =====================================================================

-- TABLE: DIM_CATEGORY

-- PURPOSE:

-- Stores product categories under a department.

-- Example: Mobiles under Electronics.

--

-- BUSINESS VALUE:

-- Enables product mix analysis below department level.

-- Useful for category management, pricing, and promotions.

--

-- DATATYPE CHOICES:

-- CATEGORY_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for joins.

-- CATEGORY_ID STRING:

--  Business category identifier.

-- CATEGORY_NAME STRING:

--  Human-readable category name.

-- DEPARTMENT_KEY NUMBER:

--  Parent reference to department.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_CATEGORY (

  CATEGORY_KEY       number autoincrement start 1 increment 1,

  CATEGORY_ID       string,

  CATEGORY_NAME      string,

  DEPARTMENT_KEY      number,

  primary key (CATEGORY_KEY)

);



-- =====================================================================

-- TABLE: DIM_SUPPLIER

-- PURPOSE:

-- Stores supplier or vendor information for products.

--

-- BUSINESS VALUE:

-- Supports supplier performance analysis, inventory dependency tracking,

-- and procurement reporting.

--

-- DATATYPE CHOICES:

-- SUPPLIER_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for dimensional joins.

-- SUPPLIER_ID STRING:

--  Supplier IDs may be alphanumeric.

-- SUPPLIER_NAME STRING:

--  Descriptive supplier name.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_SUPPLIER (

  SUPPLIER_KEY       number autoincrement start 1 increment 1,

  SUPPLIER_ID       string,

  SUPPLIER_NAME      string,

  primary key (SUPPLIER_KEY)

);



-- =====================================================================

-- TABLE: DIM_PRODUCT

-- PURPOSE:

-- Stores product master details.

-- Product links to category and supplier in the snowflake dimension design.

--

-- BUSINESS VALUE:

-- Central table for product-level sales, shipment, and inventory analysis.

-- Supports product profitability, brand analysis, and assortment performance.

--

-- DATATYPE CHOICES:

-- PRODUCT_KEY NUMBER AUTOINCREMENT:

--  Surrogate key used in fact tables.

-- PRODUCT_ID, PRODUCT_NK, SKU STRING:

--  Product identifiers and SKUs are often alphanumeric.

-- PRODUCT_NAME, BRAND STRING:

--  Descriptive business attributes.

-- CATEGORY_KEY, SUPPLIER_KEY NUMBER:

--  Parent references to related dimensions.

-- UNIT_COST, UNIT_PRICE NUMBER(18,2):

--  Fixed precision numeric type is appropriate for money-related values.

--  Avoid FLOAT for financial values because of rounding risk.

-- IS_ACTIVE BOOLEAN:

--  Efficient indicator for active or inactive product.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_PRODUCT (

  PRODUCT_KEY       number autoincrement start 1 increment 1,

  PRODUCT_ID        string,

  PRODUCT_NK        string,

  SKU           string,

  PRODUCT_NAME       string,

  BRAND          string,

  CATEGORY_KEY       number,

  SUPPLIER_KEY       number,

  UNIT_COST        number(18,2),

  UNIT_PRICE        number(18,2),

  IS_ACTIVE        boolean,

  primary key (PRODUCT_KEY)

);



-- =====================================================================

-- TABLE: DIM_CHANNEL

-- PURPOSE:

-- Stores selling channel details such as Web, Mobile App, Marketplace, Store.

--

-- BUSINESS VALUE:

-- Helps compare sales performance across sales channels and optimize

-- digital versus offline strategy.

--

-- DATATYPE CHOICES:

-- CHANNEL_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for fact joins.

-- CHANNEL_CODE STRING:

--  Short source/business code.

-- CHANNEL_NAME STRING:

--  Human-readable channel name.

-- CHANNEL_TYPE STRING:

--  Can be used to group channels into broader types.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_CHANNEL (

  CHANNEL_KEY       number autoincrement start 1 increment 1,

  CHANNEL_CODE       string,

  CHANNEL_NAME       string,

  CHANNEL_TYPE       string,

  primary key (CHANNEL_KEY)

);



-- =====================================================================

-- TABLE: DIM_PROMOTION

-- PURPOSE:

-- Stores promotion or discount campaign details.

--

-- BUSINESS VALUE:

-- Enables analysis of promotional effectiveness, discount impact,

-- and campaign-driven sales uplift.

--

-- DATATYPE CHOICES:

-- PROMOTION_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for reporting joins.

-- PROMO_CODE, PROMO_NAME, DISCOUNT_TYPE STRING:

--  Business descriptors and identifiers.

-- DISCOUNT_VALUE NUMBER(18,2):

--  Supports percentage-like or amount-like values.

-- START_DATE, END_DATE DATE:

--  Best type for campaign period boundaries.

-- IS_ACTIVE BOOLEAN:

--  Quick flag for active promotion logic.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_PROMOTION (

  PROMOTION_KEY      number autoincrement start 1 increment 1,

  PROMO_CODE        string,

  PROMO_NAME        string,

  DISCOUNT_TYPE      string,

  DISCOUNT_VALUE      number(18,2),

  START_DATE        date,

  END_DATE         date,

  IS_ACTIVE        boolean,

  primary key (PROMOTION_KEY)

);



-- =====================================================================

-- TABLE: DIM_SHIPPING_METHOD

-- PURPOSE:

-- Stores shipping mode details such as Standard, Express, Same Day.

--

-- BUSINESS VALUE:

-- Helps analyze logistics cost, delivery speed performance,

-- and customer preference by shipping option.

--

-- DATATYPE CHOICES:

-- SHIPPING_METHOD_KEY NUMBER AUTOINCREMENT:

--  Surrogate key for joins from shipment facts.

-- SHIPPING_METHOD_CODE STRING:

--  Business code from source systems.

-- SHIPPING_METHOD_NAME STRING:

--  Readable label for reporting.

-- SHIPPING_TYPE STRING:

--  Optional grouping like economy or express.

-- =====================================================================

create or replace table ECOM_DW.GOLD.DIM_SHIPPING_METHOD (

  SHIPPING_METHOD_KEY   number autoincrement start 1 increment 1,

  SHIPPING_METHOD_CODE   string,

  SHIPPING_METHOD_NAME   string,

  SHIPPING_TYPE      string,

  primary key (SHIPPING_METHOD_KEY)

);



-- =====================================================================

-- TABLE: FACT_SALES

-- PURPOSE:

-- Stores one row per sales transaction line or order line.

-- This is the main business fact table for revenue analysis.

--

-- BUSINESS VALUE:

-- Supports KPIs such as:

--  Gross sales

--  Net sales

--  Quantity sold

--  Discount impact

--  Tax analysis

--  Sales by product, customer, date, channel, promotion

--

-- DATATYPE CHOICES:

-- SALES_KEY NUMBER AUTOINCREMENT:

--  Surrogate primary key for the fact row.

-- ORDER_ID, ORDER_LINE_NK STRING:

--  Transaction identifiers may be alphanumeric.

-- *_KEY NUMBER:

--  Foreign keys to dimensions use NUMBER because dimension surrogate keys are numeric.

-- QUANTITY NUMBER(18,2):

--  Allows decimal quantities if business sells weighted or fractional units.

-- UNIT_PRICE, UNIT_COST, GROSS_AMOUNT, DISCOUNT_AMOUNT, TAX_AMOUNT, NET_AMOUNT NUMBER(18,2):

--  Exact numeric storage for financial measures.

-- =====================================================================

create or replace table ECOM_DW.GOLD.FACT_SALES (

  SALES_KEY        number autoincrement start 1 increment 1,

  ORDER_ID         string,

  ORDER_LINE_NK      string,

  ORDER_DATE_KEY      number,

  CUSTOMER_KEY       number,

  PRODUCT_KEY       number,

  CHANNEL_KEY       number,

  PROMOTION_KEY      number,

  QUANTITY         number(18,2),

  UNIT_PRICE        number(18,2),

  UNIT_COST        number(18,2),

  GROSS_AMOUNT       number(18,2),

  DISCOUNT_AMOUNT     number(18,2),

  TAX_AMOUNT        number(18,2),

  NET_AMOUNT        number(18,2),

  primary key (SALES_KEY),

  foreign key (ORDER_DATE_KEY) references ECOM_DW.GOLD.DIM_DATE (DATE_KEY),

  foreign key (CUSTOMER_KEY) references ECOM_DW.GOLD.DIM_CUSTOMER (CUSTOMER_KEY),

  foreign key (PRODUCT_KEY) references ECOM_DW.GOLD.DIM_PRODUCT (PRODUCT_KEY),

  foreign key (CHANNEL_KEY) references ECOM_DW.GOLD.DIM_CHANNEL (CHANNEL_KEY),

  foreign key (PROMOTION_KEY) references ECOM_DW.GOLD.DIM_PROMOTION (PROMOTION_KEY)

);



-- =====================================================================

-- TABLE: FACT_SHIPMENT

-- PURPOSE:

-- Stores shipment activity at shipment line or shipped product level.

--

-- BUSINESS VALUE:

-- Helps track:

--  shipped quantity

--  shipping cost

--  delivery time

--  customer fulfillment performance

--  logistics efficiency by product and shipping method

--

-- DATATYPE CHOICES:

-- SHIPMENT_KEY NUMBER AUTOINCREMENT:

--  Surrogate primary key.

-- SHIPMENT_ID, ORDER_ID STRING:

--  Shipment and order references may contain letters and symbols.

-- SHIPMENT_DATE_KEY, CUSTOMER_KEY, PRODUCT_KEY, SHIPPING_METHOD_KEY NUMBER:

--  Foreign keys to related dimensions.

-- SHIPPED_QTY NUMBER(18,2):

--  Supports fractional quantities if needed.

-- SHIPPING_COST NUMBER(18,2):

--  Exact financial storage.

-- DELIVERY_DAYS NUMBER:

--  Integer-like metric for time between order and delivery.

-- =====================================================================

create or replace table ECOM_DW.GOLD.FACT_SHIPMENT (

  SHIPMENT_KEY       number autoincrement start 1 increment 1,

  SHIPMENT_ID       string,

  ORDER_ID         string,

  SHIPMENT_DATE_KEY    number,

  CUSTOMER_KEY       number,

  PRODUCT_KEY       number,

  SHIPPING_METHOD_KEY   number,

  SHIPPED_QTY       number(18,2),

  SHIPPING_COST      number(18,2),

  DELIVERY_DAYS      number,

  primary key (SHIPMENT_KEY),

  foreign key (SHIPMENT_DATE_KEY) references ECOM_DW.GOLD.DIM_DATE (DATE_KEY),

  foreign key (CUSTOMER_KEY) references ECOM_DW.GOLD.DIM_CUSTOMER (CUSTOMER_KEY),

  foreign key (PRODUCT_KEY) references ECOM_DW.GOLD.DIM_PRODUCT (PRODUCT_KEY),

  foreign key (SHIPPING_METHOD_KEY) references ECOM_DW.GOLD.DIM_SHIPPING_METHOD (SHIPPING_METHOD_KEY)

);



-- =====================================================================

-- TABLE: FACT_INVENTORY

-- PURPOSE:

-- Stores inventory snapshot measures for a product on a given date.

--

-- BUSINESS VALUE:

-- Supports stock health and supply chain analytics such as:

--  on-hand inventory

--  reserved stock

--  available stock

--  inventory valuation

-- Helps reduce stockouts and overstock situations.

--

-- DATATYPE CHOICES:

-- INVENTORY_KEY NUMBER AUTOINCREMENT:

--  Surrogate primary key for each snapshot row.

-- SNAPSHOT_DATE_KEY, PRODUCT_KEY NUMBER:

--  Dimension references for date and product.

-- ON_HAND_QTY, RESERVED_QTY, AVAILABLE_QTY NUMBER(18,2):

--  Supports fractional inventory when needed.

-- UNIT_COST, INVENTORY_VALUE NUMBER(18,2):

--  Financial values need exact decimal precision.

-- =====================================================================

create or replace table ECOM_DW.GOLD.FACT_INVENTORY (

  INVENTORY_KEY      number autoincrement start 1 increment 1,

  SNAPSHOT_DATE_KEY    number,

  PRODUCT_KEY       number,

  ON_HAND_QTY       number(18,2),

  RESERVED_QTY       number(18,2),

  AVAILABLE_QTY      number(18,2),

  UNIT_COST        number(18,2),

  INVENTORY_VALUE     number(18,2),

  primary key (INVENTORY_KEY),

  foreign key (SNAPSHOT_DATE_KEY) references ECOM_DW.GOLD.DIM_DATE (DATE_KEY),

  foreign key (PRODUCT_KEY) references ECOM_DW.GOLD.DIM_PRODUCT (PRODUCT_KEY)

);

------------------------

CREATE OR REPLACE TABLE ECOM_DW.GOLD.DIM_SENTIMENT
(
    SENTIMENT_KEY       NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    SENTIMENT_LABEL     STRING,
    SENTIMENT_RANGE     STRING,
    PRIMARY KEY (SENTIMENT_KEY)
);


INSERT INTO ECOM_DW.GOLD.DIM_SENTIMENT
(SENTIMENT_LABEL, SENTIMENT_RANGE)
VALUES
('POSITIVE', '0.5 TO 1'),
('NEUTRAL', '-0.49 TO 0.49'),
('NEGATIVE', '-1 TO -0.5');



CREATE OR REPLACE TABLE ECOM_DW.GOLD.FACT_CUSTOMER_REVIEW
(
    REVIEW_KEY              NUMBER AUTOINCREMENT START 1 INCREMENT 1,

    REVIEW_ID               STRING,
    ORDER_ID                NUMBER,

    REVIEW_DATE_KEY         NUMBER,
    CUSTOMER_KEY            NUMBER,

    SENTIMENT_KEY           NUMBER,

    RATING                  NUMBER,

    SENTIMENT_SCORE         FLOAT,
    SENTIMENT_LABEL         STRING,

    REVIEW_CATEGORY         STRING,
    REVIEW_SUMMARY          STRING,
    REVIEW_EMOTION          STRING,
    REVIEW_KEYWORDS         STRING,

    ESCALATION_REQUIRED     BOOLEAN,

    SOURCE_SYSTEM           STRING,

    CREATED_TIMESTAMP       TIMESTAMP_NTZ,
    UPDATED_TIMESTAMP       TIMESTAMP_NTZ,
    AI_PROCESSED_TIMESTAMP  TIMESTAMP_NTZ,

    PRIMARY KEY (REVIEW_KEY),

    FOREIGN KEY (REVIEW_DATE_KEY)
        REFERENCES ECOM_DW.GOLD.DIM_DATE(DATE_KEY),

    FOREIGN KEY (CUSTOMER_KEY)
        REFERENCES ECOM_DW.GOLD.DIM_CUSTOMER(CUSTOMER_KEY),

    FOREIGN KEY (SENTIMENT_KEY)
        REFERENCES ECOM_DW.GOLD.DIM_SENTIMENT(SENTIMENT_KEY)
);



INSERT INTO ECOM_DW.GOLD.FACT_CUSTOMER_REVIEW
(
    REVIEW_ID,
    ORDER_ID,
    REVIEW_DATE_KEY,
    CUSTOMER_KEY,
    SENTIMENT_KEY,
    RATING,
    SENTIMENT_SCORE,
    SENTIMENT_LABEL,
    REVIEW_CATEGORY,
    REVIEW_SUMMARY,
    REVIEW_EMOTION,
    REVIEW_KEYWORDS,
    ESCALATION_REQUIRED,
    SOURCE_SYSTEM,
    CREATED_TIMESTAMP,
    UPDATED_TIMESTAMP,
    AI_PROCESSED_TIMESTAMP
)

SELECT

    R.REVIEW_ID,
    R.ORDER_ID,

    TO_NUMBER(TO_CHAR(R.REVIEW_DATE,'YYYYMMDD')) AS REVIEW_DATE_KEY,

    DC.CUSTOMER_KEY,

    DS.SENTIMENT_KEY,

    R.RATING,

    /* AI SENTIMENT SCORE */
    SNOWFLAKE.CORTEX.SENTIMENT(R.REVIEW_TEXT)
        AS SENTIMENT_SCORE,

    /* AI SENTIMENT LABEL */
    CASE
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(R.REVIEW_TEXT) >= 0.5
            THEN 'POSITIVE'

        WHEN SNOWFLAKE.CORTEX.SENTIMENT(R.REVIEW_TEXT) <= -0.5
            THEN 'NEGATIVE'

        ELSE 'NEUTRAL'
    END AS SENTIMENT_LABEL,

    /* REVIEW CATEGORY */
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        CONCAT(
            'Classify this review into one category only: ',
            'Delivery, Product Quality, Customer Service, Pricing, Website Experience. ',
            'Review: ',
            R.REVIEW_TEXT
        )
    ) AS REVIEW_CATEGORY,

    /* REVIEW SUMMARY */
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        CONCAT(
            'Summarize this customer review in one sentence: ',
            R.REVIEW_TEXT
        )
    ) AS REVIEW_SUMMARY,

    /* REVIEW EMOTION */
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        CONCAT(
            'Return one word emotion only from ',
            'Happy, Angry, Frustrated, Disappointed, Satisfied. ',
            R.REVIEW_TEXT
        )
    ) AS REVIEW_EMOTION,

    /* REVIEW KEYWORDS */
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        CONCAT(
            'Extract top 5 keywords comma separated: ',
            R.REVIEW_TEXT
        )
    ) AS REVIEW_KEYWORDS,

    /* ESCALATION */
    CASE
        WHEN
            R.RATING <= 2
            OR SNOWFLAKE.CORTEX.SENTIMENT(R.REVIEW_TEXT) < -0.7
        THEN TRUE
        ELSE FALSE
    END AS ESCALATION_REQUIRED,

    R.SOURCE_SYSTEM,
    R.CREATED_TIMESTAMP,
    R.UPDATED_TIMESTAMP,

    CURRENT_TIMESTAMP()

FROM ECOM_DW.SILVER.CUSTOMER_REVIEWS_SILVER R

LEFT JOIN ECOM_DW.GOLD.DIM_CUSTOMER DC
    ON R.CUSTOMER_ID = DC.CUSTOMER_ID
    AND DC.IS_CURRENT = TRUE

LEFT JOIN ECOM_DW.GOLD.DIM_SENTIMENT DS
    ON DS.SENTIMENT_LABEL =
        CASE
            WHEN SNOWFLAKE.CORTEX.SENTIMENT(R.REVIEW_TEXT) >= 0.5
                THEN 'POSITIVE'

            WHEN SNOWFLAKE.CORTEX.SENTIMENT(R.REVIEW_TEXT) <= -0.5
                THEN 'NEGATIVE'

            ELSE 'NEUTRAL'
        END;

        CREATE OR REPLACE TABLE ECOM_DW.GOLD.FACT_WEB_EVENTS
(
    WEB_EVENT_KEY      NUMBER AUTOINCREMENT START 1 INCREMENT 1,

    EVENT_ID           STRING,

    EVENT_DATE_KEY     NUMBER,

    CUSTOMER_KEY       NUMBER,
    PRODUCT_KEY        NUMBER,

    EVENT_TYPE         STRING,

    CITY               STRING,

    ORDER_ID           NUMBER,

    SOURCE_SYSTEM      STRING,

    CREATED_TS         TIMESTAMP,
    UPDATED_TS         TIMESTAMP,

    PRIMARY KEY (WEB_EVENT_KEY)
);



CREATE OR REPLACE TABLE ECOM_DW.GOLD.FACT_WEB_EVENTS
(
    WEB_EVENT_KEY      NUMBER AUTOINCREMENT START 1 INCREMENT 1,

    EVENT_ID           STRING,

    EVENT_DATE_KEY     NUMBER,

    CUSTOMER_KEY       NUMBER,
    PRODUCT_KEY        NUMBER,

    EVENT_TYPE         STRING,

    CITY               STRING,

    ORDER_ID           NUMBER,

    SOURCE_SYSTEM      STRING,

    CREATED_TS         TIMESTAMP,
    UPDATED_TS         TIMESTAMP,

    PRIMARY KEY (WEB_EVENT_KEY)
);

--Load FACT_WEB_EVENTS
INSERT INTO ECOM_DW.GOLD.FACT_WEB_EVENTS
SELECT

    W.EVENT_ID,

    TO_NUMBER(TO_CHAR(W.EVENT_TS,'YYYYMMDD')),

    DC.CUSTOMER_KEY,

    DP.PRODUCT_KEY,

    W.EVENT_TYPE,

    W.CITY,

    W.ORDER_ID,

    W.SOURCE_SYSTEM,

    W.CREATED_TS,

    W.UPDATED_TS

FROM ECOM_DW.SILVER.WEB_EVENTS_SILVER W

LEFT JOIN ECOM_DW.GOLD.DIM_CUSTOMER DC
    ON W.CUSTOMER_ID = DC.CUSTOMER_ID
    AND DC.IS_CURRENT = TRUE

LEFT JOIN ECOM_DW.GOLD.DIM_PRODUCT DP
    ON W.PRODUCT_ID = DP.PRODUCT_ID;--not working

    ALTER TABLE GOLD.DIM_PRODUCT ADD COLUMN PRODUCT_DESCRIPTION STRING,
PRODUCT_WEIGHT NUMBER(10,2),
PRODUCT_COLOR STRING,
PRODUCT_SIZE STRING;

ALTER TABLE FACT_SALES ADD COLUMN ORDER_STATUS STRING,
PAYMENT_STATUS STRING,
RETURN_FLAG BOOLEAN;

