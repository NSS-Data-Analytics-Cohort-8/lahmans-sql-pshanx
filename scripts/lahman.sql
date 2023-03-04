-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.



-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 
  
SELECT 
	MIN(yearid),
	MAX(yearid)
FROM appearances
  
-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?


SELECT 
	g_all as games_played,
	CONCAT(namegiven, ' ', namelast) as full_name,
	height,
	t.name as team_name
FROM appearances as a
	INNER JOIN people as p
		USING (playerid)
	INNER JOIN teams as t
		ON a.teamid = t.teamid
		AND a.yearid = t.yearid
WHERE playerid IN
		(SELECT
			playerid
		FROM people
		WHERE height IN
			(SELECT MIN(height)
			FROM people));



-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
	CONCAT(namefirst, ' ', namelast),
	SUM(salary) as total_salary
FROM people as p
INNER JOIN salaries as s
USING (playerid)
WHERE playerid IN
	(SELECT distinct playerid
	FROM collegeplaying
	WHERE schoolid IN
		(SELECT schoolid
		FROM schools
		WHERE schoolname LIKE '%Vanderbilt%'))
GROUP BY CONCAT(namefirst, ' ', namelast)
ORDER by SUM(salary) DESC

-- This gives me a list of 15 players, where the where-subqueries give me 24. Assuming that 9 players didn't make the transition to the major leagues. 
-- No, they all appear under 'people'
-- 'people' lists all players; 'salaries' tracks players gone pro 
	
--VALIDATION--VALIDATION--VALIDATION--VALIDATION--VALIDATION

-- SELECT playerid
-- FROM people
-- WHERE playerid NOT IN
-- 	(SELECT DISTINCT
-- 		playerid
-- 	-- 	SUM(salary)
-- 	FROM salaries as s
-- 	WHERE playerid IN
-- 		(SELECT distinct playerid
-- 		FROM collegeplaying
-- 		WHERE schoolid IN
-- 			(SELECT schoolid
-- 			FROM schools
-- 			WHERE schoolname LIKE '%Vanderbilt%'))
-- 	GROUP BY playerid)
-- AND playerid IN
-- 	(SELECT distinct playerid
-- 		FROM collegeplaying
-- 		WHERE schoolid IN
-- 			(SELECT schoolid
-- 			FROM schools
-- 			WHERE schoolname LIKE '%Vanderbilt%'))

--VALIDATION--VALIDATION--VALIDATION--VALIDATION--VALIDATION

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT DISTINCT
	positions,
	SUM(total_putouts)
FROM
	(SELECT 
		CASE WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
			WHEN pos = 'OF' THEN 'Outfield'
			ELSE 'Infield' END as positions,
		SUM(po) as total_putouts
	FROM fielding
	WHERE yearid = 2016
	GROUP BY pos) as sub
GROUP BY positions




-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

WITH strike AS
(
	SELECT
		concat(left(cast(year as varchar(4)), 3), '0s') as decade,
		ROUND(SUM(strikeo)/SUM(games),2) as avg_so
	FROM
		(SELECT
			SUM(so) as strikeo,
			SUM(g) as games,
			yearid as year
		FROM pitching
		WHERE yearid >=1920
		GROUP BY yearid
		ORDER BY yearid) AS sub
	GROUP BY decade
)
,
homer AS
(
	SELECT
		concat(left(cast(year as varchar(4)), 3), '0s') as decade,
		ROUND(SUM(homer)/SUM(games),2) as avg_homer
	FROM
		(SELECT
			SUM(hr) as homer,
			SUM(g) as games,
			yearid as year
		FROM batting
		WHERE yearid >=1920
		GROUP BY yearid
		ORDER BY yearid) as sub2
	GROUP BY decade
)
SELECT 
	strike.decade,
	avg_so,
	avg_homer
FROM strike 
INNER JOIN homer
USING (decade);


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT
	CONCAT(namefirst, ' ', namelast) as player_name,
	ROUND(scot_free/(scot_free+caught_dirty),2) as pct_sf
FROM
	(SELECT 
		DISTINCT playerid,
		CAST(SUM(sb) as numeric) as scot_free,
		CAST(SUM(cs) as numeric) as caught_dirty
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
	HAVING SUM(sb)+SUM(cs)>=20
	ORDER BY playerid) as sub
LEFT JOIN people
USING (playerid)
ORDER BY pct_sf DESC


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- SELECT 
-- 	yearid,
-- 	name,
-- 	w
-- FROM teams
-- WHERE yearid >= 1970 AND wswin = 'N'
-- ORDER by w DESC;

-- SELECT
-- 	yearid,
-- 	name,
-- 	w
-- FROM teams
-- WHERE yearid >= 1970 AND wswin = 'Y'
-- ORDER by w ASC;


WITH strike AS
(SELECT *
FROM teams
WHERE yearid >= 1970 
EXCEPT
SELECT *
FROM teams
WHERE yearid = 1981) 
,
ws_pct AS
(SELECT 
CAST(COUNT(DISTINCT yearid) as numeric) as year_count
FROM strike)

SELECT
	name,
	yearid
-- 	COUNT(yearid),
-- 	ROUND(CAST(COUNT(yearid) as numeric)/(SELECT year_count FROM ws_pct), 2) as pct
FROM 
	(SELECT 
		name,
		w as wins,
		MAX(w) OVER (PARTITION BY yearid) as max_wins,
		yearid,
		wswin
	FROM strike) AS maxes
WHERE max_wins = wins AND wswin = 'Y'




-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT distinct 
		t.name as team_name,
		park_name,
		h.attendance/h.games as avg_attendance
FROM homegames as h
INNER JOIN teams as t
	ON h.team = t.teamid
	AND h.attendance = t.attendance
INNER JOIN parks as p
	ON h.park = p.park
WHERE h.year = 2016
	AND h.games>10
-- ORDER BY avg_attendance DESC
ORDER BY avg_attendance ASC
LIMIT 5
	



-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH losdos as
(
SELECT playerid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%'
	AND lgid = 'AL'
INTERSECT
SELECT playerid
FROM awardsmanagers
WHERE awardid LIKE 'TSN%'
	AND lgid = 'NL'
)
-- ,
-- tsn_year as
-- (
-- SELECT
-- 	playerid,
-- 	yearid
--  FROM awardsmanagers
--  WHERE playerid IN
--  			(SELECT playerid
-- 			FROM losdos
-- 			WHERE
-- )
	
-- SELECT DISTINCT
-- 	CONCAT(namegiven, ' ', namelast) as manager_name,
-- 	t.name
-- FROM losdos as ld
-- LEFT JOIN tsn_year as ty
-- 	ON ld.playerid = ty.playerid
-- LEFT JOIN people as p
-- 	ON ld.playerid = p.playerid
-- LEFT JOIN managers as m
-- 	ON ty.yearid = m.yearid
-- LEFT JOIN teams as t
-- 	ON m.teamid = t.teamid

-- SELECT *
-- FROM  
-- WHERE playerid = 'leylaji99'
-- 	OR playerid = 'johnsda02'
	


SELECT 	
	CONCAT(namegiven, ' ', namelast) as manager_name,
	t.name
FROM people as p
	INNER JOIN awardsmanagers as a
	USING (playerid)
	INNER JOIN salaries as s
	USING (playerid)
	INNER JOIN teams as t
	USING (teamid)
WHERE playerid IN 
				(SELECT playerid
				FROM awardsmanagers
				WHERE awardid LIKE 'TSN%'
					AND lgid = 'AL'
				INTERSECT
				SELECT playerid
				FROM awardsmanagers
				WHERE awardid LIKE 'TSN%'
					AND lgid = 'NL')
	AND a.awardid LIKE 'TSN%'
	

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  