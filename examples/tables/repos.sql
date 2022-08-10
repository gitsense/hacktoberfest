SELECT
    owner,
    name,
    stars,
    requests,
    authors,
    latest_pr
FROM
    hf_pr_repos
WHERE
    type='all' AND
    day=to_char(now(), 'YYYY-MM-DD')
ORDER BY stars DESC, requests DESC, authors DESC
LIMIT 10;
