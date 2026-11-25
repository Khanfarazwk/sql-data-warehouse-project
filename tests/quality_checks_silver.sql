/*
=================================================================================
Quality Checks
=================================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy,
  and standardization across the 'silver' schemas. It includes checks for:
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.

Usage Notes:
  - Run these checks after data loading silver layer.
  - Investigate and resolve any discrepancies found during the checks.
=================================================================================
*/

-- ========================================================
-- Check for nulls or duplicates in primary key.
-- Expectation: No result
-- ========================================================

SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- ========================================================
-- Check for unwanted spaces
-- Expectation: No results
-- ========================================================

SELECT 
	prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- ========================================================
-- Data Standardization & Consistency
-- ========================================================

SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

-- ========================================================
-- Check for NULLS or Negative Numbers
-- Expectation: No results
-- ========================================================

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- ========================================================
-- Check for Invalid Date Orders
-- ========================================================

SELECT 
NULLIF(sls_order_dt, 0) sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8

-- ========================================================
-- Fixing the dating where the product end date is invalid.
-- ========================================================

SELECT
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS prd_end_dt_test
FROM silver.crm_prd_info
WHERE  prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

-- ========================================================
-- Check for invalid date orders in crm_sales_details.
-- ========================================================

SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- ========================================================
-- Check data consistency: Between Sales, quantity, and price.
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
-- ========================================================
  
SELECT
sls_sales AS old_sls_sales,
sls_quantity,
sls_price AS old_sls_price,
CASE
	WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE 
	WHEN sls_price IS NULL OR sls_price <= 0 
		THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-- ========================================================
-- Identify Out-of-Range Dates
-- ========================================================

SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()
  
-- ========================================================
-- Check for unwanted spaces
-- ========================================================

SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)


