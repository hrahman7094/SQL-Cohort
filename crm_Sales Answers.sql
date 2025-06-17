USE crm_sales;

-- Account Segmentation & Targeting
-- Objective: Analyze customer-level performance patterns to refine targeting and retention.

-- What is the total won revenue, % close value and win rate by sector?

with sector_wins as (
	select
		sector																Sector
		,sum(close_value)													Close_Value
        ,sum(case when deal_stage = 'Won' then 1 else 0 end) / count(*)		Sector_Win_Rate
	from
		sales_pipeline sp
	left join accounts ac on sp.account = ac.account
	group by
		sector
)

select
	Sector
    ,concat('$', format(Close_Value, 0)) 									Close_Value	
    ,concat(round(Close_Value * 100 / sum(Close_Value) OVER (), 2),'%')		Percentage_of_Total_Close_Value
    ,concat(round(Sector_Win_Rate * 100),'%')								Sector_Win_Rate
    ,rank() over (order by Close_Value desc)								Ranking
from
	sector_wins
order by 5;

-- Who are the top accounts by total won revenue?

with top_accounts as (
	select
		sp.account Account
		,sector Sector
		,sum(close_value) Close_Value
		,round(avg(close_value),2) Avg_Close_Value
        ,count(*) Number_Of_Deals
		-- ,rank() over (order by sum(close_value) desc) Ranking
	from
		sales_pipeline sp
	left join accounts ac on sp.account = ac.account
	where
		deal_stage = 'Won'
	group by sp.account
	order by 3 desc
)

select
	Account
    ,Sector
    ,concat('$', format(Close_Value,'N0'))											Close_Value
    ,Number_Of_Deals
    ,concat((ROUND(Close_Value * 100.0 / SUM(Close_Value) OVER (), 2)),'%')			Percentage_of_Total_Close_Value
    ,concat('$', format(Avg_Close_Value, 'N2'))										Avg_Close_Value
    ,rank() over (order by Close_Value desc)										Ranking	
from
	top_accounts
order by 7;

-- How does deal size change over time within each account?

with Accounts_MoM_Performance_cte as (
    select
        account
        ,date_format(close_date, '%Y-%m-01')		Beginning_of_Month
        ,sum(close_value)							Close_Value
    from sales_pipeline
    group by
		account
        ,date_format(close_date, '%Y-%m-01')
)

select
    account																								Account	
    ,Beginning_of_Month
    ,concat('$',format(lag(Close_Value) over (order by account, Beginning_of_Month),'N0'))				Prev_Month_Close_Value
    ,concat('$',format(round(Close_Value, 2),'N0'))														Close_Value
    ,case
		when Close_Value is null then 0
        else concat(round((Close_Value - lag(Close_Value) over (order by account, Beginning_of_Month)) 
			  / lag(Close_Value) over (order by account, Beginning_of_Month) * 100, 2),'%')
	end																									MoM_Change
from
	Accounts_MoM_Performance_cte
where
	account is not null or account <> ''
order by 
	account
    ,Beginning_of_Month;
    
-- Pipeline Performance Overview
-- Objective: Measure core metrics that define sales pipeline health, including volume, value, velocity, and win rates.

-- What are the total number of opportunities and total pipeline value currently open?

with prospective_sales_cte as (
	select
		 sp.*
		 ,pr.sales_price
	from
		sales_pipeline sp 
	left join products pr on sp.product = pr.product
	where
		deal_stage = 'Prospecting'
)

select
	 count(*) 										Number_of_Opportunities
    ,concat('$', format(sum(sales_price), '2')) 	Total_Pipeline_Value
from
	prospective_sales_cte ps;

-- What is the distribution of opportunity costs and values by stage?

with deal_stage_analysis_cte as (

	select
		deal_stage as Deal_Stage
		,count(*)																			Number_of_Opportunities
		,case 
			when deal_stage = "Won" then sum(close_value)
			when deal_stage = 'Lost' then sum(sales_price)
			when deal_stage = 'Prospecting' then sum(sales_price)
			when deal_stage = 'Engaging' then sum(sales_price)
		end																					costs_and_values
	from
		sales_pipeline sp 
	left join products pr on sp.product = pr.product
	group by deal_stage

)

select
	Deal_Stage
    ,format(Number_of_Opportunities, 'N0')			Number_of_Opportunities
    ,concat('$', format(costs_and_values, 'N0'))	Close_Value
from
	deal_stage_analysis_cte
order by
	costs_and_values desc;

-- What is the overall win rate across all closed opportunities?

with aggregation_cte as (
	select
		 sum(case when deal_stage = 'Won' then 1 else 0 end) 				Number_of_Wins
		,sum(case when deal_stage = 'Lost' then 1 else 0 end) 				Number_of_Losses
		,sum(case when deal_stage in ('Won', 'Lost') then 1 else 0 end) 	Total_Closed_Opportunities
	from
		sales_pipeline
)

select
	format(Number_of_Wins, 'N0')																	Number_of_Wins																
    ,format(Number_of_Losses, 'N0')																	Number_of_Losses
	,concat(cast((Number_of_Wins * 100.0 / Total_Closed_Opportunities) as decimal(10,2)), '%')		Win_Rate
    ,concat(cast((Number_of_Losses * 100.0 / Total_Closed_Opportunities) as decimal(10,2)), '%')	Loss_Rate
from aggregation_cte;

-- What is the win close value and % change by month?

select
	month(close_date)	Month
    ,concat('$',format(lag(sum(close_value)) over (order by month(close_date)),'N0'))						Prev_Month_Close_Value
    ,concat('$', format(sum(close_value), 'N0'))															Close_Value
    ,case
		when lag(sum(close_value)) over (order by month(close_date)) = 0 then 0
        else concat(round((sum(close_value) - lag(sum(close_value)) 
			over (order by month(close_date))) / lag(sum(close_value)) 
													over (order by month(close_date)) * 100,2),'%')
	end																										MoM_Change				
from
	sales_pipeline
group by
	month(close_date)
order by
	1;

-- What is the average number of days between opportunity creation and close for won deals?

with wins_cte as (
	select 
		round(datediff(close_date, engage_date))	deal_duration
		,close_value
	from sales_pipeline
	where deal_stage = 'Won'
),

wins_buckets_cte as (
	select
		case
			when deal_duration between 1 and 10 then '1 - 10 days'
			when deal_duration between 11 and 20 then '11 - 20 days'
			when deal_duration between 21 and 30 then '21 - 30 days'
			when deal_duration between 31 and 40 then '31 - 40 days'
			when deal_duration between 41 and 50 then '41 - 50 days'
			when deal_duration between 51 and 60 then '51 - 60 days'
			when deal_duration between 61 and 70 then '61 - 70 days'
			when deal_duration between 71 and 80 then '71 - 80 days'
			when deal_duration between 81 and 90 then '81 - 90 days'
			when deal_duration between 91 and 100 then '91 - 100 days'
			when deal_duration between 101 and 110 then '101 - 110 days'
			when deal_duration between 111 and 120 then '111 - 120 days'
			when deal_duration between 121 and 130 then '121 - 130 days'
			when deal_duration between 131 and 140 then '131 - 140 days'
			else 'other'
		end	duration_bucket
		,deal_duration
		,close_value
	from wins_cte
),

aggregations_cte as (
	select distinct
		duration_bucket
		,round(avg(deal_duration) over (partition by duration_bucket), 2)		average_deal_duration
		,sum(close_value) over (partition by duration_bucket)					total_close_value
		,round(
			sum(close_value) over (partition by duration_bucket) * 100.0 /
			sum(close_value) over ()
			,2
		)																		percentage_of_total_close_value
		,count(*) over (partition by duration_bucket)							opportunity_count
	from wins_buckets_cte
	order by 4 desc
)

select
	duration_bucket
	,concat(average_deal_duration, ' days')										Average_Deal_Duration
	,concat('$', format(total_close_value, 0))									Total_Close_Value
	,concat(percentage_of_total_close_value, '%')								Percentage_of_Total_Close_Value
	,format(opportunity_count, 'N0')											Number_of_Opportunities		
from aggregations_cte
order by opportunity_count desc;

-- What is the total pipeline value of lost deals in the last 6 months?

with max_date_cte as (
	select max(close_date) as max_close_date
	from sales_pipeline
)

select
	sum(pr.sales_price) as lost_sales
from sales_pipeline sp
	left join products pr on sp.product = pr.product
	join max_date_cte md on 1=1
where 
	sp.deal_stage = 'Lost'
	and sp.close_date between date_sub(md.max_close_date, interval 6 month) and md.max_close_date;

-- Sales Team Effectiveness
-- Objective: Compare performance across teams and managers to find top contributors and underperformers.

-- Which sales managers consistently close the highest-value deals, and how do their win rates compare to others?

with question_2_1_cte as (

select 						
    month(close_date)											Month
    ,st.manager													Manager
    ,sum(close_value)											Close_Value
    ,sum(sum(close_value)) over 
		(partition by month(close_date))						Total_Value
	,sum(close_value) / sum(sum(close_value)) over 				
    (partition by month(close_date))							Percent_Closed
    ,rank() over (partition by month(close_date) order by sum(close_value) desc) manager_rank_in_month
from 
	sales_pipeline sp 
left join sales_teams st on sp.sales_agent = st.sales_agent
where deal_stage = "Won"
group by
    month(close_date)
    ,st.manager
order by
	1, 6 desc
)

select
    Manager,
    round(avg(manager_rank_in_month), 2)	Avg_Monthly_Rank
from 
	question_2_1_cte
group by 
	Manager
order by 
	Avg_Monthly_Rank asc;

-- Which teams have the shortest average time-to-close, and does faster deal velocity correlate with higher win rates or revenue?

with opportunity_durations as (
    select
        sp.sales_agent
        ,st.manager
        ,datediff(close_date, engage_date) AS deal_duration_days
        ,close_value
        ,deal_stage
    from
		sales_pipeline sp
    left join sales_teams st on sp.sales_agent = st.sales_agent
    where 
		close_date is not null
),

manager_summary as (
	select
		manager
		,count(*)																			total_opportunities
		,sum(case when deal_stage = 'Won' then 1 else 0 end) 								won_opportunities
		,round(avg(case when deal_stage = 'Won' then deal_duration_days end), 2)			avg_days_to_close_won
		,round(avg(close_value), 2)															avg_deal_value
		,round(stddev_pop(close_value), 2)													deal_value_stddev
		,round(sum(case when deal_stage = 'Won' then close_value else 0 end), 2)			total_close_value
		,round(sum(case when deal_stage = 'Won' then 1 else 0 end) * 100.0 / count(*), 2)	win_rate_percent
	from 
		opportunity_durations
	group by 
		manager
	order by 7, 8
)

select
	manager											Manager
	,format(total_opportunities,'N0')				Total_Opportunities
	,format(won_opportunities,'N0')					Won_Opportunities
	,avg_days_to_close_won							Avg_Days_to_Close
	,concat('$',format(avg_deal_value,0))			Avg_Deal_Value
	,concat('$', format(deal_value_stddev,0))		Deal_Value_Stddev
	,concat('$', format(total_close_value, 0))		Total_Close_Value		
	,concat(win_rate_percent, '%')					Win_Rate
from
	manager_summary
order by 
	total_close_value desc;

-- How does individual agent performance vary within each sales team, and do top-performing managers consistently lift team-wide results?

with agent_performance as (
    select
        st.manager
        ,sp.sales_agent
        ,count(*)			won_deals
        ,sum(close_value)	total_close_value
    from
		sales_pipeline sp
    left join sales_teams st on sp.sales_agent = st.sales_agent
    where
		deal_stage = 'Won'
    group by 
		st.manager, sp.sales_agent
    order by 4 desc
)

select
    manager
    ,sales_agent
    ,won_deals
    ,concat('$', format(ROUND(total_close_value, 2),0))						Total_Close_Value
    ,rank() over (partition by manager order by total_close_value desc)		Agent_Rank_Within_Team
from agent_performance
order by manager, agent_rank_within_team;

-- Product Revenue Insights
-- Objective: Identify product-level drivers of revenue and win performance.

-- Which products have generated the highest total revenue from closed-won opportunities?

select
	month(close_date) Month
    ,product Product
    ,concat('$', format(sum(close_value),'N0')) Total_Won
    ,rank() over (partition by month(close_date) order by sum(close_value) desc) Product_Ranking
from sales_pipeline
where
	deal_stage = 'Won'
group by
	Month, product
order by 1, 4;

-- What is the win rate per product across all opportunities?

select
	product																							Product
	,format(sum(case when deal_stage = "Won" then 1 else 0 end),'N0')								Wins
    ,format(count(*),'N0')																			Instances
    ,concat(round((sum(case when deal_stage = "Won" then 1 else 0 end) / count(*)) * 100, 2),'%')	Win_Rate
	,concat('$',format(round(avg(close_value),2),'N0'))												Average_Close_Value
    ,concat('$',format(round(sum(close_value),2),'N0'))												Total_Close_Value
from
	sales_pipeline
group by
	product
order by 
	sum(close_value) desc;
    
-- What is the average deal size by product category or family?

select
	month(close_date) 																Month
    ,product Product
	,concat('$', format(round(avg(close_value), 2),'N0'))							Monthly_Closing
    ,rank() over (partition by month(close_date) order by avg(close_value) desc) 	Product_Ranking
from 
	sales_pipeline
where 
	deal_stage = 'Won'
group by 
	Month, product
order by 1, 4;
	
-- Which products have high opportunity volume but low win rates?

select
	sp.product
    ,format(count(*),'N0') 																						Number_Of_Opportunities
    ,concat(round((sum(case when deal_stage = "Won" then 1 else 0 end) / count(*)) * 100, 2),'%')				Win_Rate
    ,rank() over (order by round((sum(case when deal_stage = "Won" then 1 else 0 end) / count(*)) * 100, 2)) 	Ranking
from
	sales_pipeline sp left join products pr on sp.product = pr.product
group by 
	sp.product
order by 4;