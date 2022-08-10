SELECT
    'Number of authors with one or more ACCEPTED/SPAM Hacktoberfest PR' AS description,
    COUNT(*) AS authors
FROM
    hf_pr_authors
WHERE
    type='all' AND
    day=to_char(now(), 'YYYY-MM-DD')
UNION
SELECT
    'Number of authors with one or more SPAM Hacktoberfest PR' AS description,
    COUNT(*) AS authors
FROM
    hf_pr_authors
WHERE
    type='spam' AND
    day=to_char(now(), 'YYYY-MM-DD')
UNION
SELECT
    'Number of authors with one or more ACCEPTED Hacktoberfest PR' AS description,
    COUNT(*) AS authors
FROM
    hf_pr_authors
WHERE
    type='accepted' AND
    day=to_char(now(), 'YYYY-MM-DD');

SELECT
    'Number of authors with one or more ACCEPTED/SPAM Hacktoberfest PR from 7 days ago' AS description,
    COUNT(*) AS authors
FROM
    hf_pr_authors
WHERE
    type='all' AND
    day=to_char(now() - interval '7 days', 'YYYY-MM-DD');
