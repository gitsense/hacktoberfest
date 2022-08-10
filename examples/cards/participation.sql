-- Get the total number of repos with a hacktoberfest topic
-- with and without hacktoberfest pull requests
SELECT
    'Number of repos with or without a hacktoberfest PR' AS description,
    COUNT(*) AS repos
FROM
    gh_topics
WHERE
    gh_topics.topic IN (SELECT topic FROM hf_topics)
UNION
SELECT
    'Number of repos with one or more accepted/spam hacktoberfest PR',
    COUNT(*) 
FROM
    hf_pr_repos
WHERE
    type='all' AND
    day=TO_CHAR(now(), 'YYYY-MM-DD');


-- Get the participants for today and 7 days ago
SELECT 
    'Number of repos with one or more hacktoberfest PR from today' AS age,
    COUNT(*) AS repos
FROM 
    hf_pr_repos 
WHERE
    type='all' AND
    day=TO_CHAR(now(), 'YYYY-MM-DD')
UNION
SELECT 
    'Number of repos with one or more hackotberfest PR from 7 days ago',
    COUNT(*) AS repos
FROM 
    hf_pr_repos 
WHERE
    type='all' AND
    day=TO_CHAR(now() - INTERVAL '7 days', 'YYYY-MM-DD');

-- Get the number of all participating repos grouped by days
SELECT
    'Number of repos with hacktobfest PRs on '||day AS day,
    COUNT(*) AS repos
FROM
    hf_pr_repos
wHERE
    type='all'
GROUP BY day ORDER BY day DESC;
