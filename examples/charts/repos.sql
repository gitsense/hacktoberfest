SELECT
    owner||'/'||name,
    latest_pr AS x,
    authors AS y
FROM
    hf_pr_repos
WHERE
    type='all' AND
    day=TO_CHAR(now(),'YYYY-MM-DD') 
LIMIT 10;

