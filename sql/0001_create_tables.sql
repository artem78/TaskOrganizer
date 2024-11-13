/* Create tasks table */
CREATE TABLE IF NOT EXISTS `_tasks` (
      `id`          INTEGER PRIMARY KEY,
      `name`        VARCHAR,
      `description` VARCHAR,
      `created`     DATETIME,
      `modified`    DATETIME,
      `done`        BOOLEAN DEFAULT (FALSE) NOT NULL ON CONFLICT REPLACE
);


/* Create periods table */
CREATE TABLE IF NOT EXISTS `_periods` (
    `id`    INTEGER PRIMARY KEY,
    `begin` DATETIME,
    `end`   DATETIME,
    `task_id` INTEGER,
    `is_manually_added` BOOLEAN DEFAULT (FALSE) NOT NULL ON CONFLICT REPLACE,
    FOREIGN KEY (`task_id`)  REFERENCES `_tasks` (`id`) ON DELETE CASCADE
);


/* Create views */
CREATE VIEW IF NOT EXISTS `tasks` AS
  SELECT `_tasks`.*, IFNULL(`p`.`is_active`, FALSE) as `is_active`
  FROM `_tasks`
  LEFT JOIN
      (
          SELECT `task_id`, `is_active`
          FROM `periods`
          WHERE `is_active`
      ) AS `p`
      ON `p`.`task_id` = `_tasks`.`id`;


CREATE VIEW IF NOT EXISTS `periods` AS
	SELECT
		*,
		`end` - `begin` as `duration`
	FROM
		(
		SELECT
			`id`,
			`begin`,
			IFNULL(`end`, JULIANDAY('now', 'localtime') - 2415018.5) as `end`,
			`task_id`,
			IIF(`end` IS NULL, TRUE, FALSE) as `is_active`,
                  `is_manually_added`
		FROM `_periods`
		);


CREATE VIEW IF NOT EXISTS `duration_per_task` AS
    SELECT task_id,
           tasks.name,
           time(sum(ifnull(`end`, strftime('%J', 'now', 'localtime') - 2415018.5) - `begin`) + 0.5) AS total_time
      FROM periods
           INNER JOIN
           tasks ON periods.task_id = tasks.id
     GROUP BY task_id;

CREATE VIEW IF NOT EXISTS `duration_per_day` AS
WITH RECURSIVE dates AS (
        SELECT DATE(MIN([begin] + 2415018.5) ) daydate,
               DATE(MIN([begin] + 2415018.5), '+1 DAY') nextdate,
               DATE(MAX([end] + 2415018.5) ) enddate
          FROM periods
        UNION ALL
        SELECT nextdate,
               DATE(nextdate, '+1 DAY'),
               enddate
          FROM dates
         WHERE daydate < enddate
    )
    SELECT dates.daydate AS `day`,
           SUM(strftime('%s', MIN(dates.nextdate, DATETIME(periods.[end] + 2415018.5) ) ) - strftime('%s', MAX(dates.daydate, DATETIME(periods.[begin] + 2415018.5) ) ) ) / (24.0 * 60 * 60) AS `duration`
      FROM dates
           JOIN
           periods ON dates.daydate < DATETIME(periods.[end] + 2415018.5) AND
                      DATETIME(periods.[begin] + 2415018.5) < dates.nextdate
     GROUP BY dates.daydate;
