-- Code Basics Project Challenge
-- Primary analysis

use ipl_data;

-- Top 10 batsmen based on past 3 years total runs scored.

select fb.batsmanName as Batsman, sum(fb.runs) as total_runs
from fact_bating_summary fb
join dim_match_summary dm 
on fb.match_id = dm.match_id
group by fb.batsmanName
order by total_runs desc
limit 10;

-- Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in each season)

with cte as (select fb.batsmanName as batsman, sum(fb.balls) as total_balls, sum(fb.runs) as total_runs,
			 count(case when fb.`out/not_out` = 'out' then 1 end) as total_out,
             (sum(fb.runs) / count(case when fb.`out/not_out` = 'out' then 1 end)) as average
			 from fact_bating_summary fb
             join dim_match_summary dm
             on fb.match_id = dm.match_id
             where (dm.`year`) in (2021,2022,2023)
             group by  fb.batsmanName
             having (total_balls/count(distinct dm.`year`)) >= 60 and count(distinct (dm.`year`)) = 3), 
	 cte2 as (select batsman, average as total_avg 
			 from cte 
             order by total_avg desc
             limit 10)
	 
select * from cte2;

-- Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each season)

with cte as (select fb.batsmanName as batsman, sum(fb.balls) as total_balls, sum(fb.runs) as total_runs,
			 count(case when fb.`out/not_out` = 'out' then 1 end) as total_out,
             (sum(fb.runs) / count(case when fb.`out/not_out` = 'out' then 1 end)) as average
			 from fact_bating_summary fb
             join dim_match_summary dm
             on fb.match_id = dm.match_id
             where (dm.`year`) in (2021,2022,2023)
             group by  fb.batsmanName
             having (total_balls/count(distinct dm.`year`)) >= 60 and count(distinct (dm.`year`)) = 3), 
	 cte2 as (select batsman, (total_runs / total_balls) * 100 as total_sr
			 from cte 
             order by total_sr desc
             limit 10)
	 
select * from cte2;

-- Top 10 bowlers based on past 3 years total wickets taken.

select fb.bowlerName as bowlers, sum(fb.wickets) as total_wickets
from fact_bowling_summary fb
join dim_match_summary dm
on fb.match_id = dm.match_id
group by bowlerName
order by total_wickets desc
limit 10;

-- Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in each season)

with cte as (select  fb.bowlerName as bowlers, round((sum(fb.overs) * 6),0) as total_balls,
			 sum(fb.runs) as total_runs, (sum(fb.runs) / sum(fb.wickets)) as average
			 from fact_bowling_summary fb
             join dim_match_summary dm
             on fb.match_id = dm.match_id 
             where (dm.`year`) in (2021,2022,2023)
             group by  fb.bowlerName
             having (total_balls / count(distinct dm.`year`)) >= 60 and count(distinct (dm.`year`)) = 3),
	 cte2 as (select bowlers, average as total_avg
			  from cte
              order by total_avg
              limit 10)
select * from cte2;

-- Top 10 bowlers based on past 3 years economy rate. (min 60 balls bowled in each season)

with cte as (select  fb.bowlerName as bowlers, round((sum(fb.overs) * 6),0) as total_balls,
			 sum(fb.runs) as total_runs, (sum(fb.runs) / sum(fb.overs)) as economy_rate
			 from fact_bowling_summary fb
             join dim_match_summary dm
             on fb.match_id = dm.match_id 
             where (dm.`year`) in (2021,2022,2023)
             group by  fb.bowlerName
             having (total_balls / count(distinct dm.`year`)) >= 60 and count(distinct (dm.`year`)) = 3),
	 cte2 as (select bowlers, round(economy_rate,1) as total_eco
			  from cte
              order by total_eco
              limit 10)
select * from cte2;

-- Top 5 batsmen based on past 3 years boundary % (fours and sixes).

with cte as (select fb.batsmanName as batsman, (sum(fb.`4s`) + sum(fb.`6s`)) as total_boundary
			 from fact_bating_summary fb
             join dim_match_summary dm
             on fb.match_id = dm.match_id
             where (dm.`year`) in (2021,2022,2023)
             group by  fb.batsmanName
             having  count(distinct (dm.`year`)) = 3), 
	 cte2 as (select sum(total_boundary) as overall
			 from cte) 
             
select batsman, concat(round((total_boundary / overall) * 100,2),'%') as boundary_percent
from cte,cte2
order by boundary_percent desc
limit 5;

-- Top 5 bowlers based on past 3 years dot ball %.

with cte as (select  fb.bowlerName as bowlers, sum(fb.`0s`) as total_dots
			 from fact_bowling_summary fb
             join dim_match_summary dm
             on fb.match_id = dm.match_id 
             where (dm.`year`) in (2021,2022,2023)
             group by  fb.bowlerName
             having count(distinct (dm.`year`)) = 3),
	 cte2 as (select sum(total_dots) as overall
			  from cte)
              
select bowlers, concat((total_dots/overall)* 100,'%') as dot_percent
from cte, cte2
order by dot_percent desc
limit 5;

-- Top 4 teams based on past 3 years winning %.

with cte as (select team, count(*) as total_matches
from (select team1 as team from dim_match_summary where `year` in (2021,2022,2023)
union all
      select team2 as team from dim_match_summary where `year` in (2021,2022,2023)) as combined
group by team
order by total_matches desc),

cte2 as (select winner as team, count(*) as total_win
from dim_match_summary
group by winner)

select cte.team as teams,cte.total_matches as overall_matches,cte2.total_win as overall_wins,
		(cte2.total_win/cte.total_matches) * 100 as win_percent
from cte
left join cte2 
on cte.team = cte2.team
order by win_percent desc
limit 4;

-- Top 2 teams with the highest number of wins achieved by chasing targets over the past 3 years.

select winner as teams, count(case when right(margin, 4) = 'kets' then 1 end) as total_win
from dim_match_summary
group by winner
order by total_win desc
limit 2;

select winner as teams, count(*) as wins
from dim_match_summary
where margin like '%wickets%'
group by winner
order by wins desc
limit 2;
