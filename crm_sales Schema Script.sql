DROP SCHEMA IF EXISTS crm_sales;
CREATE SCHEMA crm_sales;
USE crm_sales;

DROP TABLE IF EXISTS
 accounts
,products
,sales_teams
,sales_pipeline;

-- Create accounts table
CREATE TABLE crm_sales.accounts (
    account VARCHAR(255) PRIMARY KEY,
    sector VARCHAR(100),
    year_established INT,
    revenue DECIMAL(18,2),
    employees INT,
    office_location VARCHAR(100),
    subsidiary_of VARCHAR(255)
);

-- Create products table
CREATE TABLE crm_sales.products (
    product VARCHAR(255) PRIMARY KEY,
    series VARCHAR(100),
    sales_price DECIMAL(18,2)
);

-- Create sales_teams table
CREATE TABLE crm_sales.sales_teams (
    sales_agent VARCHAR(255) PRIMARY KEY,
    manager VARCHAR(255),
    regional_office VARCHAR(100)
);

-- Create sales_pipeline table
CREATE TABLE crm_sales.sales_pipeline (
    opportunity_id VARCHAR(50) PRIMARY KEY,
    sales_agent VARCHAR(255),
    product VARCHAR(255),
    account VARCHAR(255),
    deal_stage VARCHAR(100),
    engage_date DATE,
    close_date DATE NULL,
    close_value decimal(10,2)
);
