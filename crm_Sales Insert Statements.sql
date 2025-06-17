USE crm_sales;

TRUNCATE TABLE accounts;
TRUNCATE TABLE products;
TRUNCATE TABLE sales_pipeline;
TRUNCATE TABLE sales_teams;

-- Load Accounts Data
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/accounts.csv'
INTO TABLE accounts
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Load Products Data
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Load Sales Team Data
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales_teams.csv'
INTO TABLE sales_teams
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Load Sales Pipeline Data
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales_pipeline.csv'
INTO TABLE sales_pipeline
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
  opportunity_id,
  sales_agent,
  product,
  account,
  deal_stage,
  @engage_date,
  @close_date,
  @close_value
)
SET
  engage_date = NULLIF(TRIM(@engage_date), ''),
  close_date = NULLIF(TRIM(@close_date), ''),
  close_value = NULLIF(TRIM(@close_value), '');
  
-- Data Transformations

UPDATE sales_pipeline
SET product = 'GTX Pro'
WHERE product = 'GTXPro' AND opportunity_id IS NOT NULL;


