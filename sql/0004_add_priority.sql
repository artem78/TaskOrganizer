/* Add priority column to task */

ALTER TABLE `_tasks`
	ADD COLUMN `priority` INTEGER NOT NULL DEFAULT 0;
