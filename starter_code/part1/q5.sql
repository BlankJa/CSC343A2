-- Never solo by choice

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS Q5 CASCADE;

CREATE TABLE Q5 (
	username varchar(25) NOT NULL,
	group_average real DEFAULT NULL,
	solo_average real DEFAULT NULL
);

DROP VIEW IF EXISTS q5_student_grades CASCADE;
DROP VIEW IF EXISTS q5_eligible_students CASCADE;
DROP VIEW IF EXISTS q5_multimember_participation CASCADE;
DROP VIEW IF EXISTS q5_personal_submissions CASCADE;
DROP VIEW IF EXISTS q5_group_sizes CASCADE;
DROP VIEW IF EXISTS q5_assignment_weights CASCADE;

CREATE VIEW q5_assignment_weights AS
SELECT assignment_id, SUM(weight) AS total_weight
FROM RubricItem
GROUP BY assignment_id;

CREATE VIEW q5_group_sizes AS
SELECT group_id, COUNT(*) AS group_size
FROM Membership
GROUP BY group_id;

-- A teammate's submission does not count as this student's submission.
CREATE VIEW q5_personal_submissions AS
SELECT DISTINCT s.username, g.assignment_id
FROM Submissions AS s
JOIN AssignmentGroup AS g ON g.group_id = s.group_id;

CREATE VIEW q5_multimember_participation AS
SELECT m.username, g.assignment_id
FROM Membership AS m
JOIN AssignmentGroup AS g ON g.group_id = m.group_id
JOIN q5_group_sizes AS sizes ON sizes.group_id = g.group_id
WHERE sizes.group_size > 1;

CREATE VIEW q5_eligible_students AS
SELECT u.username
FROM MarkusUser AS u
WHERE u.type = 'student'
  AND NOT EXISTS (
      SELECT *
      FROM Assignment AS a
      WHERE NOT EXISTS (
          SELECT *
          FROM q5_personal_submissions AS p
          WHERE p.username = u.username
            AND p.assignment_id = a.assignment_id
      )
  )
  AND NOT EXISTS (
      SELECT *
      FROM Assignment AS a
      WHERE a.group_max > 1
        AND NOT EXISTS (
            SELECT *
            FROM q5_multimember_participation AS p
            WHERE p.username = u.username
              AND p.assignment_id = a.assignment_id
        )
  );

-- Join grades to memberships, not submissions, to avoid repeated grades.
CREATE VIEW q5_student_grades AS
SELECT m.username, a.assignment_id, a.group_max,
       r.mark / w.total_weight * 100 AS mark_percent
FROM Membership AS m
JOIN AssignmentGroup AS g ON g.group_id = m.group_id
JOIN Assignment AS a ON a.assignment_id = g.assignment_id
JOIN Result AS r ON r.group_id = g.group_id
JOIN q5_assignment_weights AS w ON w.assignment_id = a.assignment_id;

INSERT INTO Q5
SELECT e.username,
       AVG(CASE WHEN grades.group_max > 1 THEN grades.mark_percent END),
       AVG(CASE WHEN grades.group_max = 1 THEN grades.mark_percent END)
FROM q5_eligible_students AS e
LEFT JOIN q5_student_grades AS grades ON grades.username = e.username
GROUP BY e.username;
