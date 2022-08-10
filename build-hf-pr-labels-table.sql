BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables where table_name='hf_topics') THEN
        RAISE EXCEPTION 'hf_topics has not been created';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables where table_name='hf_labels') THEN
        RAISE EXCEPTION 'hf_labels has not been created';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='hf_label_types') THEN
        RAISE EXCEPTION 'hf_label_types has not been created';
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS hf_pr_labels(
    type TEXT NOT NULL,
    day VARCHAR(12) NOT NULL,
    label TEXT NOT NULL,
    orgs INTEGER NOT NULL,
    repos INTEGER NOT NULL,
    requests INTEGER NOT NULL,
    authors INTEGER NOT NULL,
    updated_at TIMESTAMP(3) WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (day,label)
);

-- Create a temp hacktoberfest label stats table that will be used to populate
-- the hf_pr_labels table
CREATE TEMP TABLE tmp_hf_pr_labels(LIKE hf_pr_labels);

INSERT INTO tmp_hf_pr_labels 
    SELECT
        TO_CHAR(now(), 'YYYY-MM-DD') AS day,
        label,
        COUNT(DISTINCT(owner)) AS orgs,
        COUNT(DISTINCT(repo_id)) AS repos,
        COUNT(DISTINCT(pull_id)) AS requests,
        COUNT(DISTINCT(author_login)) AS authors,
        now()
    FROM (
        SELECT
            repo_id,
            pull_id,
            label,
            owner,
            name,
            author_login
        FROM
            (
                SELECT 
                    gp.repo_id,
                    pull_id,
                    UNNEST(label_names) AS label,
                    author_login
                FROM
                    gh_prs AS gp,
                    gh_topics AS gt
                WHERE
                    gt.repo_id=gp.repo_id AND
                    gt.topic IN (SELECT topic FROM hf_topics) AND
                    gp.label_names && (SELECT ARRAY_AGG(label) FROM hf_labels WHERE type='all')
            ) AS t,
            repos AS r
        WHERE 
            label IN (SELECT label FROM hf_labels) AND
            r.id=t.repo_id
    ) AS t
    GROUP BY label;

INSERT INTO hf_pr_labels
    SELECT
        *
    FROM
        tmp_hf_pr_labels
    ON CONFLICT (day,label) DO UPDATE SET
        orgs=EXCLUDED.orgs,
        repos=EXCLUDED.repos,
        requests=EXCLUDED.requests,
        authors=EXCLUDED.authors;

COMMIT;
