---- Data Analysis -----
--- Get TOP 3 Months and Years ------

select
	top 3
	month_reported,
	year_reported,
	count(1) as number_of_incidents
from  dbo.vw_mmda_traffic_spatial_clean
group by year_reported,month_reported
order by number_of_incidents desc


-- Get Number of Incidence per year
select
	pivot_table.City,
	coalesce([2018], 0) as [2018], 
    coalesce([2019], 0) as [2019], 
    coalesce([2020], 0) as [2020],
	x.total_number_of_incidents
	from (
select
	City,
	year_reported,
	count(1) as number_of_incidents
from  dbo.vw_mmda_traffic_spatial_clean
group by year_reported, City ) t PIVOT(
    SUM(number_of_incidents) 
    FOR year_reported IN (
        [2018], 
        [2019], 
        [2020])
) pivot_table
left join (select
	City,
	count(1) as total_number_of_incidents
from  dbo.vw_mmda_traffic_spatial_clean
group by City ) x on pivot_table.City = x.City
order by total_number_of_incidents desc

-- Window Time Analysis of Incidents Happening Month and Year ------

with reported_incident_per_time_window (month_year_reported, time_window, no_of_incident) as (
select
	month_reported + ' ' + year_reported,
	time_window,
	count(1)
	from (
		select year_reported,
				month_reported,
				time_reported,
				City,
				[Time],
				case 
				when time_reported <= '06:00:00' then '12 AM to 6 AM'
				when time_reported between '06:00:00' and '12:00:00' then '6 AM to 12 PM'
				when time_reported between '12:00:00' and '18:00:00' then '12 PM to 6 PM'
				when time_reported >= '18:00:00' then '6 PM to 12 AM'
				end as time_window
		from dbo.vw_mmda_traffic_spatial_clean
	) x group by year_reported, month_reported, time_window
)

select * from (
select
	month_year_reported,
	coalesce(SUM(case when time_window = '12 AM to 6 AM' then no_of_incident else NULL end),0) [12 AM to 6 AM],
	coalesce(SUM(case when time_window = '6 AM to 12 PM' then no_of_incident else NULL end),0) [6 AM to 12 PM],
	coalesce(SUM(case when time_window = '12 PM to 6 PM' then no_of_incident else NULL end),0) [12 PM to 6 PM],
	coalesce(SUM(case when time_window = '6 PM to 12 AM' then no_of_incident else NULL end),0) [6 PM to 12 AM],
	coalesce(SUM(no_of_incident),0) as total_no_of_incident
from reported_incident_per_time_window
group by month_year_reported

union

select 'Total', 
coalesce(SUM(case when time_window = '12 AM to 6 AM' then no_of_incident else NULL end),0) [12 AM to 6 AM],
coalesce(SUM(case when time_window = '6 AM to 12 PM' then no_of_incident else NULL end),0) [6 AM to 12 PM],
coalesce(SUM(case when time_window = '12 PM to 6 PM' then no_of_incident else NULL end),0) [12 PM to 6 PM],
coalesce(SUM(case when time_window = '6 PM to 12 AM' then no_of_incident else NULL end),0) [6 PM to 12 AM],
coalesce(SUM(no_of_incident),0) as total_no_of_incident
from reported_incident_per_time_window) x 


-- Window Time Analysis of Incidents Happening Month Reported ------

with reported_incident_per_time_window (month_reported, time_window, no_of_incident) as (
select
	month_reported,
	time_window,
	count(1)
	from (
		select month_reported,
				time_reported,
				City,
				[Time],
				case 
				when time_reported <= '06:00:00' then '12 AM to 6 AM'
				when time_reported between '06:00:00' and '12:00:00' then '6 AM to 12 PM'
				when time_reported between '12:00:00' and '18:00:00' then '12 PM to 6 PM'
				when time_reported >= '18:00:00' then '6 PM to 12 AM'
				end as time_window
		from dbo.vw_mmda_traffic_spatial_clean
	) x group by month_reported, time_window
)

select * from (
select
	month_reported,
	coalesce(SUM(case when time_window = '12 AM to 6 AM' then no_of_incident else NULL end),0) [12 AM to 6 AM],
	coalesce(SUM(case when time_window = '6 AM to 12 PM' then no_of_incident else NULL end),0) [6 AM to 12 PM],
	coalesce(SUM(case when time_window = '12 PM to 6 PM' then no_of_incident else NULL end),0) [12 PM to 6 PM],
	coalesce(SUM(case when time_window = '6 PM to 12 AM' then no_of_incident else NULL end),0) [6 PM to 12 AM],
	coalesce(SUM(no_of_incident),0) as total_no_of_incident
from reported_incident_per_time_window
where month_reported like '%ber'
group by month_reported

union

select 'Total', 
coalesce(SUM(case when time_window = '12 AM to 6 AM' then no_of_incident else NULL end),0) [12 AM to 6 AM],
coalesce(SUM(case when time_window = '6 AM to 12 PM' then no_of_incident else NULL end),0) [6 AM to 12 PM],
coalesce(SUM(case when time_window = '12 PM to 6 PM' then no_of_incident else NULL end),0) [12 PM to 6 PM],
coalesce(SUM(case when time_window = '6 PM to 12 AM' then no_of_incident else NULL end),0) [6 PM to 12 AM],
coalesce(SUM(no_of_incident),0) as total_no_of_incident
from reported_incident_per_time_window
where month_reported like '%ber'
) x 
