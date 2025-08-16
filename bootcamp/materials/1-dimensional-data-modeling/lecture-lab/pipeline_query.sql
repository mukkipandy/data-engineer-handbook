WITH params AS (
    SELECT 1996::int AS season
),
last_season AS (
    SELECT p.*
    FROM players p
    JOIN params ON true   -- makes params.season available
    WHERE p.current_season = params.season - 1
),
this_season AS (
    SELECT ps.*
    FROM player_seasons ps
    JOIN params ON true
    WHERE ps.season = params.season
)
INSERT INTO players
SELECT
    COALESCE(ls.player_name, ts.player_name) as player_name,
    COALESCE(ls.height, ts.height) as height,
    COALESCE(ls.college, ts.college) as college,
    COALESCE(ls.country, ts.country) as country,
    COALESCE(ls.draft_year, ts.draft_year) as draft_year,
    COALESCE(ls.draft_round, ts.draft_round) as draft_round,
    COALESCE(ls.draft_number, ts.draft_number) as draft_number,
    COALESCE(ls.seasons, ARRAY[]::season_stats[])
      || CASE WHEN ts.season IS NOT NULL THEN
            ARRAY[ROW(ts.season, ts.pts, ts.ast, ts.reb, ts.weight)::season_stats]
         ELSE ARRAY[]::season_stats[] END as seasons,
    CASE
        WHEN ts.season IS NOT NULL THEN
            (CASE WHEN ts.pts > 20 THEN 'star'
                  WHEN ts.pts > 15 THEN 'good'
                  WHEN ts.pts > 10 THEN 'average'
                  ELSE 'bad' END)::scoring_class
        ELSE ls.scoring_class
    END as scoring_class,
	CASE 
		WHEN ts.season IS NOT NULL THEN 0
		ELSE ls.years_since_last_active + 1
		END as years_since_last_active,
    ts.season IS NOT NULL as is_active,
    params.season AS current_season
FROM last_season ls
FULL OUTER JOIN this_season ts
    ON ls.player_name = ts.player_name
JOIN params ON true;   -- makes params.season available here