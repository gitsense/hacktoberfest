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

CREATE TABLE IF NOT EXISTS hf_pr_authors(
    type HF_LABEL_TYPES NOT NULL,
    day VARCHAR(12) NOT NULL,
    author TEXT NOT NULL,
    orgs INTEGER NOT NULL,
    repos INTEGER NOT NULL,
    requests INTEGER NOT NULL,
    latest_pr TIMESTAMP(3) WITHOUT TIME ZONE,
    updated_at TIMESTAMP(3) WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (type,day,author)
);

-- Create a temp hacktoberfest authors table that will be used to populate
-- the hf_pr_authors table
CREATE TEMP TABLE tmp_hf_pr_authors(LIKE hf_pr_authors);

-- Populate the temp hacktoberfest authors table by looking at pull requests that belong
-- to repos with hacktoberfest topics as defined in the hf_topics table and has labels
-- associated with all, spam and accepted labels
DO $$
DECLARE
    label_type HF_LABEL_TYPES;
BEGIN
FOR label_type IN (SELECT DISTINCT(type) FROM hf_labels) LOOP
    -- Create a temp table to store matching pull requests
    DROP TABLE IF EXISTS hf_prs;

    CREATE TEMP TABLE hf_prs AS
        SELECT
            label_type AS type,
            owner,
            repo_id,
            pull_id
        FROM
            gh_prs AS gp,
            repos AS r
        WHERE
            gp.repo_id=r.id AND
            repo_id IN (SELECT repo_id FROM gh_topics where topic IN (SELECT topic FROM hf_topics)) AND
            label_names && (SELECT ARRAY_AGG(label) FROM hf_labels WHERE type=label_type);

    -- Populate the temp authors table
    INSERT INTO tmp_hf_pr_authors
    	SELECT
            label_type,
            to_char(now(), 'YYYY-MM-DD') AS day,
            author_login,
            COUNT(DISTINCT(owner)) AS orgs,
            COUNT(DISTINCT(gp.repo_id)) AS repos,
            COUNT(*) AS requests,
            NULL,
            now()::TIMESTAMP
        FROM 
            gh_prs AS gp,
            hf_prs AS hp
        WHERE
            gp.repo_id=hp.repo_id AND
            gp.pull_id=hp.pull_id
        GROUP BY label_type,day,author_login;

    -- latest_requests will be used to determine the author's latest created pull request
    DROP TABLE IF EXISTS latest_requests;

    CREATE TEMP TABLE latest_requests(
        author TEXT PRIMARY KEY,
        created_at TIMESTAMP(3) WITHOUT TIME ZONE
    );

    -- Since we are sorting by created_at desc we know that the first match 
    -- will be the author's latest created_at time.  And because author is
    -- a primary key, we can ignore all subsequenty author pull request
    -- created_at time
    INSERT INTO latest_requests
        SELECT
            author_login,
            TO_TIMESTAMP(created_at/1000.0)
        FROM
            gh_prs AS gp,
            hf_prs AS hp
        WHERE
            gp.repo_id=hp.repo_id AND
            gp.pull_id=hp.pull_id
        ORDER BY created_at DESC
        ON CONFLICT(author) DO NOTHING;

    -- Now that we have the latest created time for each matching author, we can
    -- update the temp authors table
    UPDATE 
        tmp_hf_pr_authors AS tha
    SET
        latest_pr=lp.created_at
    FROM
        latest_requests AS lp
    WHERE
        tha.author=lp.author;
      
    -- Populate the hacktoberfest authors table
    INSERT INTO hf_pr_authors
        SELECT *
        FROM tmp_hf_pr_authors 
        ON CONFLICT(type,day,author) DO 
        UPDATE SET
            day=EXCLUDED.day,
            requests=EXCLUDED.requests,
            updated_at=EXCLUDED.updated_at;

    -- Delete from the hacktoberfest authors table where author is not found
    -- in the temp hacktoberfest table
    DELETE FROM hf_pr_authors WHERE author NOT IN (SELECT author FROM tmp_hf_pr_authors);
END LOOP;
END; $$;

COMMIT;
