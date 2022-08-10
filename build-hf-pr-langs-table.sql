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

CREATE TABLE IF NOT EXISTS hf_pr_langs(
    type HF_LABEL_TYPES NOT NULL,
    day VARCHAR(12) NOT NULL,
    lang TEXT NOT NULL,
    orgs INTEGER NOT NULL,
    repos INTEGER NOT NULL,
    requests INTEGER NOT NULL,
    authors INTEGER NOT NULL,
    updated_at TIMESTAMP(3) WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (type,day,lang)
);

-- Create a temp hacktoberfest lang stats table that will be used to populate
-- the hf_pr_langs table
CREATE TEMP TABLE tmp_hf_pr_langs(LIKE hf_pr_langs);

DO $$
DECLARE
    label_type HF_LABEL_TYPES;
BEGIN
FOR label_type IN (SELECT DISTINCT(type) FROM hf_labels) LOOP
    INSERT INTO tmp_hf_pr_langs 
        SELECT
            label_type,
            TO_CHAR(now(), 'YYYY-MM-DD') AS day,
            lang,
            COUNT(DISTINCT(repo_owner)) AS orgs,
            COUNT(DISTINCT(repo_id)) AS repos,
            COUNT(DISTINCT(pull_id)) AS requests,
            COUNT(DISTINCT(author)) AS authors,
            now()
        FROM (
            SELECT 
                gp.repo_id,
                gp.pull_id,
                owner AS repo_owner,
                author_login AS author,
                lang
            FROM
                gh_prs AS gp,
                gh_pr_changes AS gpc,
                gh_topics AS gt,
                repos AS r
            WHERE
                r.id=gt.repo_id AND
                gt.repo_id=gp.repo_id AND
                gpc.repo_id=gp.repo_id AND
                gp.pull_id=gpc.pull_id AND 
                gt.topic IN (SELECT topic FROM hf_topics) AND
                gp.label_names && (SELECT ARRAY_AGG(label) FROM hf_labels WHERE type=label_type)
        ) AS t
        GROUP BY lang;
END LOOP;
END; $$;

INSERT INTO hf_pr_langs
    SELECT
        *
    FROM
        tmp_hf_pr_langs
    ON CONFLICT (type,day,lang) DO UPDATE SET
        orgs=EXCLUDED.orgs,
        repos=EXCLUDED.repos,
        requests=EXCLUDED.requests,
        authors=EXCLUDED.authors;

COMMIT;
