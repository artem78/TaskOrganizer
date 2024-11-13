/* Update dates from pascal internal format to julian day in periods table */

UPDATE `_periods`
SET `begin` = `begin` + 2415018.5
WHERE `begin` < 2415018.5
	AND `begin` NOT NULL;
	
UPDATE `_periods`
SET `end` = `end` + 2415018.5
WHERE `end` < 2415018.5
	AND `end` NOT NULL;


/* Update views */

DROP VIEW IF EXISTS `periods`;

CREATE VIEW periods AS
    SELECT *,
           [end] - [begin] AS duration
      FROM (
               SELECT id,
                      [begin],
                      IFNULL([end], JULIANDAY('now', 'localtime') ) AS [end],
                      task_id,
                      IIF([end] IS NULL, TRUE, FALSE) AS is_active,
                      is_manually_added
                 FROM _periods
           );
		   
		   
DROP VIEW IF EXISTS `duration_per_task`;

CREATE VIEW duration_per_task AS
    SELECT task_id,
           tasks.name,
           time(sum(ifnull([end], JULIANDAY('now', 'localtime')) - [begin]) + 0.5) AS total_time
      FROM periods
           INNER JOIN
           tasks ON periods.task_id = tasks.id
     GROUP BY task_id;


DROP VIEW IF EXISTS `duration_per_day`;

CREATE VIEW duration_per_day AS
WITH RECURSIVE dates AS (
        SELECT DATE(MIN([begin]) ) daydate,
               DATE(MIN([begin]), '+1 DAY') nextdate,
               DATE(MAX([end]) ) enddate
          FROM periods
        UNION ALL
        SELECT nextdate,
               DATE(nextdate, '+1 DAY'),
               enddate
          FROM dates
         WHERE daydate < enddate
    )
    SELECT dates.daydate AS day,
           SUM(strftime('%s', MIN(dates.nextdate, DATETIME(periods.[end]) ) ) - strftime('%s', MAX(dates.daydate, DATETIME(periods.[begin]) ) ) ) / (24.0 * 60 * 60) AS duration
      FROM dates
           JOIN
           periods ON dates.daydate < DATETIME(periods.[end]) AND 
                      DATETIME(periods.[begin]) < dates.nextdate
     GROUP BY dates.daydate;
