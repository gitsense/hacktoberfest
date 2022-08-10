SELECT
    author,
    orgs,
    repos,
    requests,
    latest_pr
FROM
    hf_pr_authors
WHERE
    type='all' AND
    day=TO_CHAR(now(), 'YYYY-MM-DD') 
ORDER BY requests DESC LIMIT 10;
