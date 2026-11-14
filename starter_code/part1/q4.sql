-- Steady work

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q4 CASCADE;

CREATE TABLE Q4 (
	group_id integer NOT NULL,
	first_file varchar(25) DEFAULT NULL,
	first_time timestamp DEFAULT NULL,
	first_submitter varchar(25) DEFAULT NULL,
	last_file varchar(25) DEFAULT NULL,
	last_time timestamp DEFAULT NULL,
	last_submitter varchar(25) DEFAULT NULL,
	elapsed_time interval DEFAULT NULL
);

DROP VIEW IF EXISTS q4_submission_limits CASCADE;
DROP VIEW IF EXISTS q4_a1_groups CASCADE;

CREATE VIEW q4_a1_groups AS
SELECT g.group_id
FROM AssignmentGroup AS g
JOIN Assignment AS a ON a.assignment_id = g.assignment_id
WHERE a.description = 'A1';

CREATE VIEW q4_submission_limits AS
SELECT g.group_id,
       MIN(s.submission_date) AS first_time,
       MAX(s.submission_date) AS last_time
FROM q4_a1_groups AS g
LEFT JOIN Submissions AS s ON s.group_id = g.group_id
GROUP BY g.group_id;

-- Every tied first row joins every tied last row; do not discard duplicates.
INSERT INTO Q4
SELECT times.group_id,
       first_sub.file_name, first_sub.submission_date, first_sub.username,
       last_sub.file_name, last_sub.submission_date, last_sub.username,
       times.last_time - times.first_time
FROM q4_submission_limits AS times
LEFT JOIN Submissions AS first_sub
    ON first_sub.group_id = times.group_id
   AND first_sub.submission_date = times.first_time
LEFT JOIN Submissions AS last_sub
    ON last_sub.group_id = times.group_id
   AND last_sub.submission_date = times.last_time;
