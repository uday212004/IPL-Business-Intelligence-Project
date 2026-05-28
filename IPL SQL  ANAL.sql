CREATE DATABASE ipl_analysis;

USE ipl_analysis;



-- Create matches Table
CREATE TABLE matches (
    id BIGINT PRIMARY KEY,
    season VARCHAR(20),
    city VARCHAR(100),
    date DATE,
    match_type VARCHAR(50),
    player_of_match VARCHAR(100),
    venue VARCHAR(255),
    team1 VARCHAR(100),
    team2 VARCHAR(100),
    toss_winner VARCHAR(100),
    toss_decision VARCHAR(20),
    winner VARCHAR(100),
    result VARCHAR(20),
    result_margin FLOAT,
    target_runs FLOAT,
    target_overs FLOAT,
    super_over VARCHAR(10),
    method VARCHAR(50),
    umpire1 VARCHAR(100),
    umpire2 VARCHAR(100)
);

-- Create deliveries Table
CREATE TABLE deliveries (
    match_id BIGINT,
    inning INT,
    batting_team VARCHAR(100),
    bowling_team VARCHAR(100),
    over_no INT,
    ball INT,
    batter VARCHAR(100),
    bowler VARCHAR(100),
    non_striker VARCHAR(100),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    extras_type VARCHAR(50),
    is_wicket INT,
    player_dismissed VARCHAR(100),
    dismissal_kind VARCHAR(100),
    fielder VARCHAR(100)
);



SHOW VARIABLES LIKE "secure_file_priv";


DESC matches;



-- Import matches csv file

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/matches_new_cleaned.csv'
INTO TABLE matches
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM matches;




-- Import deliveries csv file

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/deliveries_new_cleaned.csv'
INTO TABLE deliveries
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM deliveries;

-- Queries

SELECT * FROM matches LIMIT 5;

SELECT * FROM deliveries LIMIT 5;

-- ROADMAP

-- 1. Basic Aggregations
-- 2. GROUP BY Analysis
-- 3. JOINS
-- 4. Window Functions
-- 5. CTEs
-- 6. Advanced Cricket Insights

-- 1. MOST SUCCESSFUL TEAMS
SELECT winner,
COUNT(*) AS total_wins
FROM matches
GROUP BY winner
ORDER BY total_wins DESC;

-- 2. TOSS IMPACT
SELECT 
    toss_decision,
    COUNT(*) AS matches
FROM matches
GROUP BY toss_decision;

-- 3. TOSS WIN = MATCH WIN
SELECT 
COUNT(*) * 100.0 / (SELECT COUNT(*) FROM matches) AS toss_match_win_percentage
FROM matches
WHERE toss_winner = winner;

-- 4. TOP RUN SCORERS
SELECT 
    batter,
    SUM(batsman_runs) AS total_runs
FROM deliveries
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;

-- 5. MOST WICKETS
SELECT 
    bowler,
    COUNT(*) AS wickets
FROM deliveries
WHERE is_wicket = 1
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;

-- 6. BEST STRIKE RATE
SELECT 
    batter,
    SUM(batsman_runs) AS runs,
    COUNT(ball) AS balls,
    (SUM(batsman_runs)*100.0/COUNT(ball)) AS strike_rate
FROM deliveries
GROUP BY batter
HAVING runs > 2000
ORDER BY strike_rate DESC;

-- 7. BEST ECONOMY BOWLERS
SELECT 
    bowler,
    SUM(total_runs) AS runs_given,
    COUNT(ball) AS balls_bowled,
    (SUM(total_runs)*6.0/COUNT(ball)) AS economy
FROM deliveries
GROUP BY bowler
HAVING balls_bowled > 500
ORDER BY economy;

-- 8. VENUE-WISE-AVERAGE SCORE
SELECT 
    m.venue,
    AVG(t.total_score) AS avg_score
FROM (
    SELECT 
        match_id,
        inning,
        batting_team,
        SUM(total_runs) AS total_score
    FROM deliveries
    GROUP BY match_id, inning, batting_team
) t
JOIN matches m
ON t.match_id = m.id
GROUP BY m.venue
ORDER BY avg_score DESC;

-- 9. BEST CHASING TEAMS
SELECT 
    winner,
    COUNT(*) AS chase_wins
FROM matches
WHERE result = 'wickets'
GROUP BY winner
ORDER BY chase_wins DESC;

-- 10. POWERPLAY ANALYSIS
SELECT 
    batting_team,
    SUM(total_runs) AS powerplay_runs
FROM deliveries
WHERE over_no <= 5
GROUP BY batting_team
ORDER BY powerplay_runs DESC;

-- 11. DEATH-OVER ANALYSIS
SELECT 
    batting_team,
    SUM(total_runs) AS death_over_runs
FROM deliveries
WHERE over_no >= 15
GROUP BY batting_team
ORDER BY death_over_runs DESC;

-- ADVANCED SQL ANALYTICS

-- | Topic                 | SQL Concept       |
-- | --------------------- | ----------------- |
-- | Top player per season | Window Functions  |
-- | Team ranking          | DENSE_RANK        |
-- | Running totals        | OVER()            |
-- | CTE-based analysis    | WITH clause       |
-- | Venue dominance       | Multi-table joins |
-- | Batter vs bowler      | Complex joins     |


-- 1. TOP PLAYER PER SEASON / Find highest run scorer each season.
-- BY USING WINDOW FUNCTION
SELECT *
FROM (
    SELECT 
        m.season,
        d.batter,
        SUM(d.batsman_runs) AS total_runs,

        RANK() OVER(
            PARTITION BY m.season
            ORDER BY SUM(d.batsman_runs) DESC
        ) AS player_rank

    FROM deliveries d

    JOIN matches m
    ON d.match_id = m.id

    GROUP BY m.season, d.batter
) t

WHERE player_rank = 1;

-- RANK() OVER() .This is a:Window Function .It ranks players season-wise.

-- 2. TEAM RANKING USING DENSE_RANK() / Rank teams based on wins.
SELECT 
    winner,
    COUNT(*) AS wins,

    DENSE_RANK() OVER(
        ORDER BY COUNT(*) DESC
    ) AS team_rank

FROM matches

WHERE winner != 'No Result'

GROUP BY winner;

-- 3. RUNNING TOTALS USING OVER()
-- Track batter cumulative runs.
SELECT 
    batter,
    match_id,

    SUM(batsman_runs) AS match_runs,

    SUM(SUM(batsman_runs)) OVER(
        PARTITION BY batter
        ORDER BY match_id
    ) AS cumulative_runs

FROM deliveries

GROUP BY batter, match_id;

-- 4. CTE-BASED ANALYSIS (WITH CLAUSE) / Find teams with average score above 170.
WITH team_scores AS (

    SELECT 
        match_id,
        inning,
        batting_team,
        SUM(total_runs) AS total_score

    FROM deliveries

    GROUP BY match_id, inning, batting_team
)

SELECT 
    batting_team,
    AVG(total_score) AS avg_score

FROM team_scores

GROUP BY batting_team

HAVING avg_score > 170

ORDER BY avg_score DESC;

-- 5. VENUE DOMINANCE ANALYSIS / Find best teams at each venue.
SELECT 
    venue,
    winner,
    COUNT(*) AS wins

FROM matches

WHERE winner != 'No Result'

GROUP BY venue, winner

ORDER BY venue, wins DESC;

-- 6. Most dominant team per venue:
WITH venue_wins AS (

    SELECT 
        venue,
        winner,
        COUNT(*) AS wins,

        RANK() OVER(
            PARTITION BY venue
            ORDER BY COUNT(*) DESC
        ) AS rnk

    FROM matches

    WHERE winner != 'No Result'

    GROUP BY venue, winner
)

SELECT *
FROM venue_wins
WHERE rnk = 1;

-- 7. BATTER vs BOWLER ANALYSIS / Analyze batter performance against bowlers.
SELECT 
    batter,
    bowler,

    SUM(batsman_runs) AS runs_scored,
    COUNT(ball) AS balls_faced,

    (SUM(batsman_runs)*100.0/COUNT(ball)) AS strike_rate

FROM deliveries

GROUP BY batter, bowler

HAVING balls_faced > 20

ORDER BY strike_rate DESC;

-- Helps analyze:player matchups/dominance/weaknesses

-- 8. MOST CONSISTENT BATSMEN /Players with most 50+ scores.
WITH batter_scores AS (

    SELECT 
        match_id,
        batter,
        SUM(batsman_runs) AS runs

    FROM deliveries

    GROUP BY match_id, batter
)

SELECT 
    batter,
    COUNT(*) AS fifty_plus_scores

FROM batter_scores

WHERE runs >= 50

GROUP BY batter

ORDER BY fifty_plus_scores DESC;


-- 9. MOST DESTRUCTIVE DEATH OVER BATSMEN /Best finishers in overs 16–20.
SELECT 
    batter,

    SUM(batsman_runs) AS death_runs,

    COUNT(ball) AS balls,

    (SUM(batsman_runs)*100.0/COUNT(ball)) AS strike_rate

FROM deliveries

WHERE over_no >= 15

GROUP BY batter

HAVING balls > 50

ORDER BY strike_rate DESC;

-- 10. POWERPLAY SPECIALIST BOWLERS /Best economical bowlers in powerplay.
SELECT 
    bowler,

    SUM(total_runs) AS runs_given,
    COUNT(ball) AS balls,

    (SUM(total_runs)*6.0/COUNT(ball)) AS economy

FROM deliveries

WHERE over_no <= 5

GROUP BY bowler

HAVING balls > 100

ORDER BY economy;


-- 11. TEAM WIN PERCENTAGE
WITH matches_played AS (

    SELECT team1 AS team
    FROM matches

    UNION ALL

    SELECT team2 AS team
    FROM matches
),

wins AS (

    SELECT winner AS team,
    COUNT(*) AS wins

    FROM matches

    WHERE winner != 'No Result'

    GROUP BY winner
)

SELECT 
    mp.team,

    COUNT(*) AS matches_played,

    COALESCE(w.wins,0) AS wins,

    ROUND(
        COALESCE(w.wins,0)*100.0/COUNT(*),
        2
    ) AS win_percentage

FROM matches_played mp

LEFT JOIN wins w
ON mp.team = w.team

GROUP BY mp.team, w.wins

ORDER BY win_percentage DESC;




-- 12. Which batter performs best against a specific bowler?
SELECT 
    batter,
    bowler,
    SUM(batsman_runs) AS runs_scored,
    COUNT(ball) AS balls_faced,

    ROUND(
        SUM(batsman_runs)*100.0/COUNT(ball),
        2
    ) AS strike_rate

FROM deliveries

GROUP BY batter, bowler

HAVING balls_faced >= 30

ORDER BY strike_rate DESC;

-- insight --> Finds dominant batter vs bowler matchups. Useful in strategy and player analysis.


-- 13. Which batter performs best against each bowling team?
SELECT 
    batter,
    bowling_team,
    SUM(batsman_runs) AS runs
FROM deliveries
GROUP BY batter, bowling_team
HAVING runs > 300
ORDER BY runs DESC;

-- Insights --> Identifies batter dominance against specific teams. Useful for matchup analysis.


-- 14. Which players score most runs in winning matches?
SELECT 
    d.batter,
    SUM(d.batsman_runs) AS winning_runs

FROM deliveries d

JOIN matches m
ON d.match_id = m.id

WHERE d.batting_team = m.winner

GROUP BY d.batter

ORDER BY winning_runs DESC
LIMIT 10;

-- Insights-->Identifies clutch performers. Important for match-winning impact analysis.


-- 15 . Which bowlers dismiss specific batters most often?
SELECT 
    bowler,
    player_dismissed,
    COUNT(*) AS dismissals
FROM deliveries
WHERE player_dismissed IS NOT NULL
GROUP BY bowler, player_dismissed
HAVING dismissals >= 3
ORDER BY dismissals DESC;

-- Insights-->Shows batter weaknesses against bowlers. Useful in strategy and scouting.

-- 16. Which venues produce most sixes?
SELECT 
    m.venue,
    COUNT(*) AS total_sixes
FROM deliveries d
JOIN matches m
ON d.match_id = m.id
WHERE d.batsman_runs = 6
GROUP BY m.venue
ORDER BY total_sixes DESC;

-- Insight--> Identifies small boundary/high-scoring grounds.

-- 17. Which bowlers take wickets most frequently?
SELECT 
    bowler,

    COUNT(*) AS wickets,

    ROUND(
        COUNT(ball)*1.0/COUNT(*),
        2
    ) AS balls_per_wicket

FROM deliveries

WHERE is_wicket = 1

GROUP BY bowler

HAVING wickets > 30

ORDER BY balls_per_wicket;
-- Insight--> Lower balls-per-wicket means higher wicket-taking efficiency.

-- 18. Which teams score fastest in powerplay?
SELECT 
    batting_team,

    ROUND(
        SUM(total_runs) * 1.0 /
        COUNT(DISTINCT CONCAT(match_id, inning)),
        2
    ) AS avg_powerplay_runs

FROM deliveries

WHERE over_no <= 5

GROUP BY batting_team

ORDER BY avg_powerplay_runs DESC;

-- Insight--> show aggresive opening teams


-- 19. Which venues favor chasing teams most?
SELECT 
    venue,

    COUNT(
        CASE
            WHEN result = 'wickets'
            THEN 1
        END
    ) AS chasing_wins,

    COUNT(*) AS total_matches,

    ROUND(
        COUNT(
            CASE
                WHEN result = 'wickets'
                THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS chase_win_percentage

FROM matches

GROUP BY venue

HAVING total_matches > 20

ORDER BY chase_win_percentage DESC;

-- Insight -->Helps identify dew-heavy or batting-friendly grounds.

-- 20. Which bowlers are toughest to hit for sixes?
SELECT 
    bowler,
    COUNT(*) AS sixes_conceded
FROM deliveries
WHERE batsman_runs = 6
GROUP BY bowler
HAVING COUNT(ball) > 500
ORDER BY sixes_conceded;

-- Insight--> Shows bowlers with strong control and variation.

-- 21. Which teams rely most on boundaries?
SELECT 
    batting_team,

    SUM(
        CASE 
            WHEN batsman_runs IN (4,6)
            THEN batsman_runs
            ELSE 0
        END
    ) AS boundary_runs,

    SUM(total_runs) AS total_runs,

    ROUND(
        SUM(
            CASE 
                WHEN batsman_runs IN (4,6)
                THEN batsman_runs
                ELSE 0
            END
        ) * 100.0 /
        SUM(total_runs),
        2
    ) AS boundary_percentage

FROM deliveries

GROUP BY batting_team

ORDER BY boundary_percentage DESC;

-- Insight-->Reveals teams dependent on aggressive batting.

-- 22. Which batters rotate strike best?
SELECT 
    batter,

    COUNT(
        CASE
            WHEN batsman_runs IN (1,2,3)
            THEN 1
        END
    ) AS rotation_balls,

    COUNT(ball) AS total_balls,

    ROUND(
        COUNT(
            CASE
                WHEN batsman_runs IN (1,2,3)
                THEN 1
            END
        ) * 100.0 / COUNT(ball),
        2
    ) AS rotation_percentage

FROM deliveries

GROUP BY batter

HAVING total_balls > 500

ORDER BY rotation_percentage DESC;

-- Insights -->Measures strike rotation ability. Important in middle-over batting

-- 23. Which innings has higher scoring rate?
SELECT 
    inning,

    ROUND(
        SUM(total_runs) * 1.0 / COUNT(DISTINCT match_id),
        2
    ) AS avg_runs

FROM deliveries

GROUP BY inning;
-- insight -->Helps analyze batting conditions and chasing trends.

-- 24.Which teams depend most on boundaries?

SELECT 
    batting_team,

    SUM(
        CASE
            WHEN batsman_runs IN (4,6)
            THEN batsman_runs
            ELSE 0
        END
    ) AS boundary_runs,

    SUM(total_runs) AS total_runs,

    ROUND(
        SUM(
            CASE
                WHEN batsman_runs IN (4,6)
                THEN batsman_runs
                ELSE 0
            END
        ) * 100.0 / SUM(total_runs),
        2
    ) AS boundary_dependency

FROM deliveries

GROUP BY batting_team

ORDER BY boundary_dependency DESC;

-- Insight -->High dependency may indicate aggressive batting strategy.

-- 25.Which bowlers concede most sixes?
SELECT 
    bowler,
    COUNT(*) AS sixes_conceded

FROM deliveries

WHERE batsman_runs = 6

GROUP BY bowler

ORDER BY sixes_conceded DESC
LIMIT 10;
-- Insight -->Helps identify bowlers vulnerable in shorter formats.

-- 26 Which bowlers perform best in winning matches?
SELECT 
    d.bowler,
    COUNT(*) AS wickets

FROM deliveries d

JOIN matches m
ON d.match_id = m.id

WHERE d.bowling_team = m.winner
AND d.is_wicket = 1

GROUP BY d.bowler

ORDER BY wickets DESC;

-- Insight--> Shows impact bowlers in successful matches.

-- 27. Which matches had the highest combined score?
WITH innings_scores AS (

    SELECT 
        match_id,
        inning,
        SUM(total_runs) AS inning_score

    FROM deliveries

    GROUP BY match_id, inning
),

match_totals AS (

    SELECT 
        match_id,
        SUM(inning_score) AS combined_score

    FROM innings_scores

    GROUP BY match_id
)

SELECT 
    m.id,
    m.team1,
    m.team2,
    mt.combined_score

FROM match_totals mt

JOIN matches m
ON mt.match_id = m.id

ORDER BY mt.combined_score DESC
LIMIT 10;

-- insight -->Identifies most entertaining/high-scoring matches.

-- 28. Which teams have best home-ground advantage?
SELECT 
    city,
    winner,
    COUNT(*) AS wins

FROM matches

WHERE city IS NOT NULL

GROUP BY city, winner

ORDER BY city, wins DESC;

-- Insight-->Measures city/venue dominance.

-- 29. Which overs produce most wickets?
SELECT 
    over_no,
    COUNT(*) AS wickets
FROM deliveries
WHERE is_wicket = 1
GROUP BY over_no
ORDER BY wickets DESC;

-- Insight -->Death overs often produce more wickets due to aggressive batting.

-- 30. Which matches had the highest combined score?
WITH innings_scores AS (

    SELECT 
        match_id,
        inning,
        SUM(total_runs) AS inning_score

    FROM deliveries

    GROUP BY match_id, inning
),

match_totals AS (

    SELECT 
        match_id,
        SUM(inning_score) AS combined_score

    FROM innings_scores

    GROUP BY match_id
)

SELECT 
    m.id,
    m.team1,
    m.team2,
    mt.combined_score

FROM match_totals mt

JOIN matches m
ON mt.match_id = m.id

ORDER BY mt.combined_score DESC
LIMIT 10;

-- insight-->Identifies most entertaining/high-scoring matches.

-- 31. Which overs produce most wickets?
SELECT 
    over_no,
    COUNT(*) AS wickets
FROM deliveries
WHERE is_wicket = 1
GROUP BY over_no
ORDER BY wickets DESC;

-- insight-->Death overs often produce more wickets due to aggressive batting.

-- 32. Which teams improve most in death overs?
SELECT 
    batting_team,

    SUM(
        CASE
            WHEN over_no <= 5
            THEN total_runs
            ELSE 0
        END
    ) AS powerplay_runs,

    SUM(
        CASE
            WHEN over_no >= 15
            THEN total_runs
            ELSE 0
        END
    ) AS death_runs

FROM deliveries

GROUP BY batting_team

ORDER BY death_runs DESC;
-- Insight--> Compares starting vs finishing strength.

 -- 33. Which overs produce most runs?
 SELECT 
    over_no,
    SUM(total_runs) AS runs
FROM deliveries
GROUP BY over_no
ORDER BY runs DESC;

-- insight--> Helps identify scoring phases in T20 cricket.

-- 34.Which batters rotate strike best?
SELECT 
    batter,

    COUNT(*) AS singles

FROM deliveries

WHERE batsman_runs = 1

GROUP BY batter

ORDER BY singles DESC;

-- 35.Which players score fastest fifties on average?
WITH batter_match_stats AS (

    SELECT 
        match_id,
        batter,

        SUM(batsman_runs) AS runs,
        COUNT(ball) AS balls

    FROM deliveries

    GROUP BY match_id, batter
)

SELECT 
    batter,

    AVG(balls) AS avg_balls_for_50

FROM batter_match_stats

WHERE runs >= 50

GROUP BY batter

HAVING COUNT(*) >= 5

ORDER BY avg_balls_for_50;

-- Insight--> Identifies explosive batsmen.

-- 36.Which bowlers concede most extras?
SELECT 
    bowler,
    SUM(extra_runs) AS extras_given
FROM deliveries
GROUP BY bowler
ORDER BY extras_given DESC;
-- Insight--> Extras reflect bowling discipline issues.

-- 37. Which teams lose most tosses but still win?
SELECT 
    winner,
    COUNT(*) AS wins_after_losing_toss
FROM matches
WHERE toss_winner != winner
GROUP BY winner
ORDER BY wins_after_losing_toss DESC;
-- Insight--> Measures team resilience under disadvantage.

-- 38.Which bowlers perform best in specific venues?
SELECT 
    m.venue,
    d.bowler,

    COUNT(*) AS wickets

FROM deliveries d

JOIN matches m
ON d.match_id = m.id

WHERE d.is_wicket = 1

GROUP BY m.venue, d.bowler

ORDER BY wickets DESC;
-- Insight-->Some bowlers exploit venue conditions better.

-- 39.Which matches had the closest finishes?
SELECT 
    id,
    team1,
    team2,
    winner,
    result,
    result_margin
FROM matches
WHERE result_margin <= 5
ORDER BY result_margin;
-- Insight--> Identifies high-pressure thrillers.

-- 40. Which teams lose most after winning toss?
SELECT 
    toss_winner,
    COUNT(*) AS toss_losses

FROM matches

WHERE toss_winner != winner

GROUP BY toss_winner

ORDER BY toss_losses DESC;
-- Insight--> Shows poor decision-making after toss wins. 

-- 41. Which players perform best in finals?
SELECT 
    player_of_match,
    COUNT(*) AS final_awards
FROM matches
WHERE match_type = 'Final'
GROUP BY player_of_match
ORDER BY final_awards DESC;
-- Insight--> Shows players who handle pressure best.

-- 42. Which innings produces highest scores?
SELECT 
    inning,
    AVG(total_score) AS avg_score

FROM (

    SELECT 
        match_id,
        inning,
        SUM(total_runs) AS total_score

    FROM deliveries

    GROUP BY match_id, inning

) t

GROUP BY inning;
-- Insight--> Compares first innings vs chase scoring.

-- 43.Which venues host most finals?
SELECT 
    venue,
    COUNT(*) AS finals_hosted
FROM matches
WHERE match_type = 'Final'
GROUP BY venue
ORDER BY finals_hosted DESC;
-- Insight--> Shows historically important IPL venues.

-- 44.Which teams score fastest in powerplay?
SELECT 
    batting_team,

    ROUND(
        SUM(total_runs)*1.0/
        COUNT(DISTINCT CONCAT(match_id, inning)),
        2
    ) AS avg_powerplay_runs

FROM deliveries

WHERE over_no <= 5

GROUP BY batting_team

ORDER BY avg_powerplay_runs DESC;
-- Insight-->Identifies aggressive opening strategies.

-- 45.Which players score fastest centuries?
WITH batter_match_runs AS (

    SELECT 
        match_id,
        batter,
        SUM(batsman_runs) AS runs,
        COUNT(ball) AS balls

    FROM deliveries

    GROUP BY match_id, batter
)

SELECT 
    batter,
    match_id,
    runs,
    balls,

    ROUND(runs*100.0/balls,2) AS strike_rate

FROM batter_match_runs

WHERE runs >= 100

ORDER BY balls;
-- Insight-->Identifies explosive match-winning innings.

-- 46. Which bowlers dominate specific batters?
SELECT 
    bowler,
    batter,
    COUNT(*) AS dismissals

FROM deliveries

WHERE is_wicket = 1

GROUP BY bowler, batter

HAVING dismissals >= 3

ORDER BY dismissals DESC;

-- Insight--> Shows psychological/player matchup dominance. 