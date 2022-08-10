SELECT 
    'Number of accepted PRs today' AS age,
    SUM(requests) AS accepted_prs 
FROM 
    hf_pr_repos 
WHERE
    type='accepted' AND
    day=TO_CHAR(now(), 'YYYY-MM-DD')
UNION
SELECT 
    'Number of accepted PRs from 7 days ago',
    SUM(requests) AS accepted_prs
FROM 
    hf_pr_repos 
WHERE
    type='accepted' AND
    day=TO_CHAR(now() - INTERVAL '7 days', 'YYYY-MM-DD');

-- Get the number of accepted participating repos grouped by days
SELECT
    'Number of accepted PRs on '||day AS day,
    SUM(requests) AS accepted_prs
FROM
    hf_pr_repos
wHERE
    type='accepted'
GROUP BY day ORDER BY day DESC;
