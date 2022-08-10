SELECT 
    'Number of spam PRs today' AS age,
    SUM(requests) AS spam_prs 
FROM 
    hf_pr_repos 
WHERE
    type='spam' AND
    day=TO_CHAR(now(), 'YYYY-MM-DD')
UNION
SELECT 
    'Number of spam PRs from 7 days ago',
    SUM(requests) AS spam_prs
FROM 
    hf_pr_repos 
WHERE
    type='spam' AND
    day=TO_CHAR(now() - INTERVAL '7 days', 'YYYY-MM-DD');

-- Get the number of spam participating repos grouped by days
SELECT
    'Number of spam PRs on '||day AS day,
    SUM(requests) AS spam_prs
FROM
    hf_pr_repos
wHERE
    type='spam'
GROUP BY day ORDER BY day DESC;
