SELECT
    label,
    orgs,
    repos,
    requests,
    authors
FROM
    hf_pr_labels
WHERE
    day=TO_CHAR(now(), 'YYYY-MM-DD')
ORDER BY requests DESC limit 10;
