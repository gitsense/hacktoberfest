SELECT
    author,
    latest_pr AS x,
    requests AS y
FROM
    hf_pr_authors
WHERE
    type='all' AND
    day=TO_CHAR(now(), 'YYYY-MM-DD')
LIMIT 10;
