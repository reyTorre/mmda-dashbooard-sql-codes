------------------ Functions ------------
create function fx_clean_time (@time varchar(100))
returns time as
begin
	declare @time_output time
	select @time_output = case 
		when @time is NULL then cast('00:00 AM' as time)
		when try_cast(@time as time) is NULL then CONCAT(
			case 
			when CHARINDEX(' ',@time) > 0 then LEFT(@time, CHARINDEX(' ',@time)-1)
			else SUBSTRING(@time, 1, 4) end, 
			' ', 
			case 
			when CHARINDEX(' ',@time) > 0 then 
					case 
						when SUBSTRING(@time, CHARINDEX(' ',@time)+1, 2) in ('PM', 'AM') then  SUBSTRING(@time, CHARINDEX(' ',@time)+1, 2)
						else 'AM' end
			else 'AM'  end)
		else @time end

			return cast(@time_output as time)
end
-------------- Fix Cities w/ view ---------------------------------
create view vw_city_cleaning_data as
select x.city,
	case 
	when x.city ='Parañaque' then 'Parañaque City'
	when x.city = 'ParaÃ±aque' then 'Parañaque City'
	when x.city = 'Mandaluyong' then 'Mandaluyong'
	when x.city = 'Manila' then 'Manila City'
	when x.city = 'Malabon' then 'Malabon City'
	when x.city = 'Navotas' then 'Navotas City'
	when x.city = 'Marikina' then 'Marikina City'
	when x.city = 'Kalookan City' then 'Caloocan City'
	when x.city = 'Valenzuela' then 'Valenzuela City'
	when x.city = 'San Juan' then 'San Juan City'
	when x.city = 'Taguig' then 'Taguig City'
	else x.city
	end as city_equivalent
	from (select distinct city from dbo.mmda_traffic_spatial where city is not null) x
------------- Load Cleansed Data ---------------------------
create view vw_mmda_traffic_spatial_clean as
select
	datename(MONTH,try_convert(date, [Date], 101)) as month_reported,
	datename(YEAR, try_convert(date, [Date], 101)) as year_reported,
	[Time],
	dbo.fx_clean_time([Time]) as time_reported,
	upper(coalesce(ccd.city_equivalent, 'UNKNOWN')) as City,
	upper([Location]) as [Location],
	round([Latitude],2) as [Latitude],
	round([Longitude], 2) as [Longitude],
	try_cast([High_Accuracy] as bit) as [High_Accuracy],
	coalesce([Direction], 'UNKNOWN') as [Direction],
	coalesce([Type], 'UNKNOWN') as [Type],
	coalesce(Lanes_Blocked, 0) as Lanes_Blocked,
	upper(coalesce(Involved, 'UNKNOWN')) as Involved,
	cast(Tweet as text) as Tweet,
	cast([Source] as text) as [Source]
from dbo.mmda_traffic_spatial mts
left join dbo.vw_city_cleaning_data ccd
on mts.City = ccd.city
