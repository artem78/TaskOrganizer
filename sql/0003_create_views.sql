/* Add new views */

CREATE VIEW IF NOT EXISTS `duration_per_day_and_task` AS
WITH RECURSIVE `dates` AS (
        SELECT DATE(MIN(`begin`) ) `date`,
               DATE(MIN(`begin`), '+1 DAY') `nextdate`,
               DATE(MAX(`end`) ) `enddate`
          FROM `periods`
        UNION ALL
        SELECT `nextdate`,
               DATE(`nextdate`, '+1 DAY'),
               `enddate`
          FROM `dates`
         WHERE `date` < `enddate`
    )
    SELECT `dates`.`date` AS `date`,-- SUM(strftime('%s', MIN(dates.nextdate, DATETIME(periods.[end]) ) ) - strftime('%s', MAX(dates.daydate, DATETIME(periods.[begin]) ) ) ) / (24.0 * 60 * 60) AS duration
           `task_id`,
           SUM(`duration`) AS `duration`/* ,
           
           duration */
      FROM `dates`
           JOIN
           `periods` ON `dates`.`date` < DATETIME(`periods`.`end`) AND 
                        DATETIME(`periods`.`begin`) < `dates`.`nextdate`
     GROUP BY `date`,
              `task_id`;
			  
CREATE VIEW IF NOT EXISTS `duration_per_month_and_task` AS
WITH RECURSIVE `dates` AS (
        SELECT DATETIME(MIN(`begin`), 'start of month') AS `date_start`,
               DATETIME(MIN(`begin`), 'start of month', '+1 MONTH', '-1 second') `date_end`,
               DATE(MAX(`end`), 'start of month', '+1 month', '-1 day') `enddate`
          FROM `periods`
        UNION ALL
        SELECT DATETIME(`date_start`, '+1 month'),
               DATETIME(`date_start`, '+2 month', 'start of month', '-1 second'),
               `enddate`
          FROM `dates`
         WHERE `date_start` < `enddate`
    )
    SELECT strftime('%Y-%m', `date_start`) AS `date`,
           `date_start`,
           `date_end`,
           `task_id`,
           SUM(`duration`) AS `duration`
      FROM `dates`
           JOIN
           `periods` ON `date_start` < DATETIME(`periods`.`end`) AND 
                        DATETIME(`periods`.`begin`) < `date_end`
     GROUP BY `date`,
              `task_id`;



CREATE VIEW IF NOT EXISTS `duration_per_year_and_task` AS
WITH RECURSIVE `dates` AS (
        SELECT DATETIME(MIN(`begin`), 'start of year') AS `date_start`,
               DATETIME(MIN(`begin`), 'start of year', '+1 year', '-1 second') `date_end`,
               DATE/* TIME */(MAX(`end`), 'start of year', '+1 year', '-1 day') `enddate`
          FROM `periods`
        UNION ALL
        SELECT DATETIME(`date_start`, '+1 year'),
               DATETIME(`date_start`, '+2 year', 'start of year', '-1 second'),
               `enddate`
          FROM `dates`
         WHERE `date_start` < `enddate`
    )
    SELECT strftime('%Y', `date_start`) AS `date`,
           `date_start`,
           `date_end`,
           `task_id`,
           SUM(`duration`) AS `duration`
      FROM `dates`
           JOIN
           `periods` ON `date_start` < DATETIME(`periods`.`end`) AND 
                        DATETIME(`periods`.`begin`) < `date_end`
     GROUP BY `date`,
              `task_id`;
