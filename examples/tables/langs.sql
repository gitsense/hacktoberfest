SELECT
    lang,
    orgs,
    repos,
    requests,
    authors
FROM
    hf_pr_langs
WHERE
    type='all' AND
    day=TO_CHAR(now(),'YYYY-MM-DD')
ORDER BY requests DESC limit 10;

