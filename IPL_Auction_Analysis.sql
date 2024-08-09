
-- IPL Auction Strategy Analysis
-- Developed by Sayed Arfat Geelanie

-- Query 1: High Strike Rate Batsmen (500+ balls faced)
SELECT batsman, SUM(total_runs) AS total_runs, COUNT(*) AS balls_faced,
       (SUM(total_runs) * 100.0 / COUNT(*)) AS strike_rate
FROM deliveries
GROUP BY batsman
HAVING COUNT(*) >= 500
ORDER BY strike_rate DESC
LIMIT 10;

-- Query 2: Batsmen with Good Average (played 2+ IPL seasons)
SELECT batsman, SUM(total_runs) AS total_runs,
       COUNT(CASE WHEN dismissal_kind IS NOT NULL THEN 1 END) AS total_outs,
       ROUND(SUM(total_runs) * 1.0 / COUNT(CASE WHEN dismissal_kind IS NOT NULL THEN 1 END), 2) AS batting_average
FROM deliveries d
INNER JOIN matches m ON d.match_id = m.match_id
GROUP BY batsman
HAVING COUNT(DISTINCT EXTRACT(YEAR FROM m.date)) > 2
ORDER BY batting_average DESC
LIMIT 10;

-- Query 3: All-rounders with Best Batting and Bowling Strike Rate
SELECT a.*, b.*
FROM (
    SELECT batsman, SUM(batsman_run) AS Total_run_hit,
           (SUM(batsman_run) * 100.0 / COUNT(ball)) AS strike_rate_batsman
    FROM deliveries
    WHERE extra_type != 'wides'
    GROUP BY batsman
    HAVING COUNT(ball) >= 500
) AS a
INNER JOIN (
    SELECT bowler, COUNT(ball) AS total_balls,
           SUM(total_run) AS total_runs_scored,
           SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END) AS total_wickets,
           (SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(ball)) AS strike_rate_ball
    FROM deliveries
    GROUP BY bowler
    HAVING COUNT(ball) >= 300
) AS b ON a.batsman = b.bowler
ORDER BY a.strike_rate_batsman DESC
LIMIT 10;

-- Query 4: Economical Bowlers (500+ balls bowled)
SELECT bowler,
       ROUND(SUM(total_runs) / (SUM(CASE WHEN extras_type NOT IN ('wides', 'noballs') THEN 1 ELSE 0 END) / 6.0), 2) AS economy_rate
FROM deliveries
GROUP BY bowler
HAVING SUM(CASE WHEN extras_type NOT IN ('wides', 'noballs') THEN 1 ELSE 0 END) >= 500
ORDER BY economy_rate ASC
LIMIT 10;

-- Query 5: Hard-hitting Batsmen (Most runs in boundaries, played 2+ seasons)
SELECT a.batsman, SUM(CASE WHEN a.batsman_run IN (4, 6) THEN 1 ELSE 0 END) AS Total_Boundaries,
       SUM(a.batsman_run) AS total_batsman_runs,
       (SUM(CASE WHEN a.batsman_run IN (4, 6) THEN a.batsman_run ELSE 0 END) * 100.0 / SUM(a.batsman_run)) AS boundary_percentage
FROM deliveries AS a
LEFT JOIN matches AS b ON a.id = b.id
GROUP BY a.batsman
HAVING COUNT(DISTINCT b.season) > 2
ORDER BY total_batsman_runs DESC
LIMIT 10;

-- Additional Queries:

-- Query 6: Count of cities that have hosted an IPL match
SELECT COUNT(DISTINCT city) AS unique_cities_hosted
FROM matches
WHERE city IS NOT NULL;

-- Query 7: Create table deliveries_v02 with an additional column ball_result
CREATE TABLE deliveries_v02 AS
SELECT id, inning, over, ball, batsman, non_striker, bowler, batsman_run, extra_run, total_run,
       is_wicket, dismissal_kind, player_dismissed, fielder, extra_type, batting_team, bowling_team,
       CASE 
           WHEN total_run >= 4 THEN 'boundary'
           WHEN total_run = 0 THEN 'dot'
           ELSE 'other'
       END AS ball_result
FROM deliveries;

-- Query 8: Total number of boundaries and dot balls from deliveries_v02
SELECT SUM(CASE WHEN ball_result = 'boundary' THEN 1 ELSE 0 END) AS total_boundaries,
       SUM(CASE WHEN ball_result = 'dot' THEN 1 ELSE 0 END) AS total_dot_balls
FROM deliveries_v02;

-- Query 9: Total number of boundaries scored by each team from deliveries_v02
SELECT batting_team, COUNT(*) AS total_boundaries
FROM deliveries_v02
WHERE ball_result = 'boundary'
GROUP BY batting_team
ORDER BY total_boundaries DESC;

-- Query 10: Total number of dot balls bowled by each team from deliveries_v02
SELECT bowling_team, COUNT(*) AS total_dot_balls
FROM deliveries_v02
WHERE ball_result = 'dot'
GROUP BY bowling_team
ORDER BY total_dot_balls DESC;

-- Query 11: Total number of dismissals by dismissal kinds where dismissal kind is not NA
SELECT dismissal_kind, COUNT(*) AS total_dismissals
FROM deliveries
WHERE dismissal_kind IS NOT NULL
  AND dismissal_kind != 'NA'
GROUP BY dismissal_kind
ORDER BY total_dismissals DESC;

-- Query 12: Top 5 bowlers who conceded maximum extra runs from the deliveries table
SELECT bowler, SUM(extra_run) AS total_extra_run
FROM deliveries
GROUP BY bowler
ORDER BY total_extra_run DESC
LIMIT 5;

-- Query 13: Create table deliveries_v03 with additional columns venue and match_date
CREATE TABLE deliveries_v03 AS
SELECT a.*, b.venue, b.date
FROM deliveries_v02 a
LEFT JOIN matches b ON a.id = b.id;

-- Query 14: Total runs scored for each venue in descending order
SELECT venue, SUM(total_run) AS total_runs_scored
FROM deliveries_v02
GROUP BY venue
ORDER BY total_runs_scored DESC;

-- Query 15: Year-wise total runs scored at Eden Gardens in descending order
SELECT EXTRACT(YEAR FROM date) AS year, SUM(total_run) AS total_runs_scored
FROM deliveries_v03
WHERE venue = 'Eden Gardens'
GROUP BY year
ORDER BY total_runs_scored DESC;
