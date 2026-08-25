


CREATE OR REPLACE TABLE SILVER.CUSTOMER_REVIEW_AI_SILVER AS
SELECT
    REVIEW_ID,
    ORDER_ID,
    CUSTOMER_ID,
    REVIEW_DATE,
    RATING,
    REVIEW_TEXT,

    SNOWFLAKE.CORTEX.SENTIMENT(REVIEW_TEXT) AS SENTIMENT_SCORE,

    CASE
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(REVIEW_TEXT) > 0.5 THEN 'POSITIVE'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(REVIEW_TEXT) < -0.5 THEN 'NEGATIVE'
        ELSE 'NEUTRAL'
    END AS SENTIMENT_LABEL,

    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        CONCAT('Summarize this review: ', REVIEW_TEXT)
    ) AS REVIEW_SUMMARY,

    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large',
        CONCAT(
            'Classify this review into: Delivery, Product, Service, Pricing, Website. ',
            REVIEW_TEXT
        )
    ) AS CATEGORY,

    CURRENT_TIMESTAMP() AS AI_PROCESSED_TS

FROM customer_reviews_silver;


-- ============================================================
-- Cortex AI Functions: Text & Image/Document Analysis
-- ============================================================
-- Prerequisites:
--   - Stage must use SNOWFLAKE_SSE encryption (not SNOWFLAKE_FULL)
--   - GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE <your_role>;
--   - Replace @ECOM_DW.SILVER.MY_FILES with your actual stage

-- Pricing (per 1,000 pages):
--   AI_PARSE_DOCUMENT OCR:    0.5 credits
--   AI_PARSE_DOCUMENT LAYOUT: 3.33 credits
--   AI_EXTRACT:               ~5 credits per 1M tokens

-- 1. Create a stage for files (if needed)
CREATE OR REPLACE STAGE ECOM_DW.SILVER.MY_FILES
  DIRECTORY = (ENABLE = TRUE)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- ============================================================
-- TEXT ANALYSIS
-- ============================================================

-- 2. Sentiment analysis on text
SELECT
    review_text,
    AI_SENTIMENT(review_text) AS sentiment_score,
    CASE
        WHEN AI_SENTIMENT(review_text):score > 0.5 THEN 'POSITIVE'
        WHEN AI_SENTIMENT(review_text):score < -0.5 THEN 'NEGATIVE'
        ELSE 'NEUTRAL'
    END AS sentiment_label
FROM (VALUES
    ('This product is amazing, I love it!'),
    ('Terrible quality, broke after one day.'),
    ('It was okay, nothing special.')
) AS t(review_text);

-- 3. Extract structured fields from text
SELECT AI_EXTRACT(
    text => 'John Smith ordered 3 laptops on May 10, 2026 from New York for $4,500.',
    responseFormat => ['person_name', 'product', 'quantity', 'date', 'location', 'amount']
):response AS extracted_entities;

-- 4. Classify text into categories
SELECT
    ticket_text,
    AI_CLASSIFY(
        ticket_text,
        ['billing', 'technical_support', 'account_access', 'feature_request', 'bug_report']
    ):labels[0]::VARCHAR AS assigned_team
FROM (VALUES
    ('I cannot log into my account after changing my password'),
    ('I was charged twice for my last order'),
    ('Would be great if you added dark mode')
) AS t(ticket_text);

-- ============================================================
-- DOCUMENT ANALYSIS (PDFs, DOCX, etc.)
-- ============================================================

-- 5. Parse a PDF — OCR mode (fast text extraction)
SELECT AI_PARSE_DOCUMENT(
    TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'sample_document.pdf'),
    {'mode': 'OCR'}
):content::STRING AS extracted_text;

-- 6. Parse a PDF — LAYOUT mode (preserves tables/structure as Markdown)
SELECT AI_PARSE_DOCUMENT(
    TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'invoice.pdf'),
    {'mode': 'LAYOUT'}
):content::STRING AS markdown_text;

-- 7. Parse specific pages only (pages 1-5, 0-indexed)
SELECT AI_PARSE_DOCUMENT(
    TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'large_report.pdf'),
    {'mode': 'LAYOUT', 'page_filter': [{'start': 0, 'end': 5}]}
):content::STRING AS first_5_pages;

-- 8. Extract structured fields from a document
SELECT AI_EXTRACT(
    file => TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'invoice.pdf'),
    responseFormat => {
        'vendor_name': 'Who is the vendor? NOT the buyer.',
        'invoice_date': 'Invoice date in YYYY-MM-DD format. NOT the due date.',
        'total_amount': 'Total amount due as a number without currency symbol.'
    }
):response AS invoice_data;

-- ============================================================
-- IMAGE ANALYSIS
-- ============================================================

-- 9. Classify an image into categories
SELECT AI_CLASSIFY(
    TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'product_photo.jpg'),
    ['electronics', 'clothing', 'furniture', 'food', 'sports']
):labels[0]::VARCHAR AS image_category;

-- 10. Analyze/describe an image with AI_COMPLETE (vision)
SELECT AI_COMPLETE(
    'claude-sonnet-4-6',
    'Describe what you see in this image in detail.',
    TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'product_photo.jpg')
) AS image_description;

-- 11. Multi-label image classification
SELECT AI_CLASSIFY(
    TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'product_photo.jpg'),
    ['indoor', 'outdoor', 'person', 'product', 'text'],
    {'output_mode': 'multi'}
):labels AS image_tags;

-- ============================================================
-- BATCH PROCESSING: All files on a stage
-- ============================================================

-- 12. Batch parse all PDFs on a stage
ALTER STAGE ECOM_DW.SILVER.MY_FILES REFRESH;

SELECT
    RELATIVE_PATH,
    AI_PARSE_DOCUMENT(
        TO_FILE('@ECOM_DW.SILVER.MY_FILES', RELATIVE_PATH),
        {'mode': 'LAYOUT'}
    ):content::STRING AS parsed_text
FROM DIRECTORY(@ECOM_DW.SILVER.MY_FILES)
WHERE RELATIVE_PATH ILIKE '%.pdf';

-- 13. Batch classify all images on a stage
SELECT
    RELATIVE_PATH,
    AI_CLASSIFY(
        TO_FILE('@ECOM_DW.SILVER.MY_FILES', RELATIVE_PATH),
        ['product', 'lifestyle', 'logo', 'diagram']
    ):labels[0]::VARCHAR AS category
FROM DIRECTORY(@ECOM_DW.SILVER.MY_FILES)
WHERE RELATIVE_PATH ILIKE '%.jpg' OR RELATIVE_PATH ILIKE '%.png';

-- 14. Batch extract fields from all invoices
SELECT
    RELATIVE_PATH,
    AI_EXTRACT(
        file => TO_FILE('@ECOM_DW.SILVER.MY_FILES', SPLIT_PART(RELATIVE_PATH, '/', -1)),
        responseFormat => {
            'invoice_number': 'What is the invoice number?',
            'date': 'Invoice date in YYYY-MM-DD format',
            'total': 'Total amount due as a number'
        }
    ):response AS extracted
FROM DIRECTORY(@ECOM_DW.SILVER.MY_FILES)
WHERE RELATIVE_PATH ILIKE '%.pdf';

-- 15. Combined pipeline: Parse document, then summarize with LLM
WITH parsed AS (
    SELECT AI_PARSE_DOCUMENT(
        TO_FILE('@ECOM_DW.SILVER.MY_FILES', 'report.pdf'),
        {'mode': 'LAYOUT'}
    ):content::STRING AS doc_text
)
SELECT AI_COMPLETE(
    'claude-sonnet-4-6',
    'Summarize this document in 3 bullet points:\n\n' || doc_text
) AS summary
FROM parsed;