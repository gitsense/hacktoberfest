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

CREATE TABLE IF NOT EXISTS hf_pr_repos(
    type HF_LABEL_TYPES NOT NULL,
    day VARCHAR(12) NOT NULL,
    repo_id INTEGER,
    owner TEXT NOT NULL,
    name TEXT NOT NULL,
    stars INTEGER,
    requests INTEGER,
    authors INTEGER,
    latest_pr TIMESTAMP(3) WITHOUT TIME ZONE,
    updated_at TIMESTAMP(3) WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY (type,day,repo_id)
);

CREATE TEMP TABLE tmp_hf_pr_repos(LIKE hf_pr_repos);

DO $$
DECLARE
    label_type HF_LABEL_TYPES;
BEGIN
FOR label_type IN (SELECT DISTINCT(type) FROM hf_labels) LOOP
    -- Create a temp table to store matching pull requests
    DROP TABLE IF EXISTS hf_prs;

    CREATE TEMP TABLE hf_prs AS
        SELECT
            repo_id,
            pull_id,
            author_login AS author,
            created_at 
        FROM
            gh_prs
        WHERE
            repo_id IN (SELECT repo_id FROM gh_topics where topic IN (SELECT topic FROM hf_topics)) AND
            label_names && (SELECT ARRAY_AGG(label) FROM hf_labels WHERE type=label_type);

    -- When populating the temp hacktoberfest repos table with the simple query below, we can
    -- only get the stars count. To get the number of pull requests, latest pull request and 
    -- number of unique authors, we'll have to create some staging tables later
    INSERT INTO tmp_hf_pr_repos
    	SELECT
            label_type,
            to_char(now(), 'YYYY-MM-DD'),
            id,
            owner,
            name,
            stars,
            0,
            0,
            NULL,
            now()::TIMESTAMP
        FROM 
            repos 
        WHERE 
            id IN (SELECT DISTINCT(repo_id) FROM hf_prs);

    -- requests_and_authors will be used to help us calculate the number of pull requests and authors
    DROP TABLE IF EXISTS requests_and_authors;
    
    CREATE TEMP TABLE requests_and_authors AS
        SELECT 
            repo_id, 
            COUNT(pull_id) AS requests,
            COUNT(DISTINCT(author)) AS authors
        FROM 
            hf_prs 
        GROUP BY repo_id;
  
    -- Find the latest pull request for each repo 
    DROP TABLE IF EXISTS latest_pr;

    CREATE TEMP TABLE latest_pr(
        repo_id INTEGER PRIMARY KEY, 
        created_at TIMESTAMP(3) WITHOUT TIME ZONE
    );
    
    INSERT INTO latest_pr
        SELECT
            repo_id,
            to_timestamp(created_at/1000.0)
        FROM
            hf_prs
        ORDER BY created_at DESC
        ON CONFLICT(repo_id) DO NOTHING;

    -- Update number of requests and authors
    UPDATE 
        tmp_hf_pr_repos as thr
    SET
        requests=paa.requests,
        authors=paa.authors
    FROM
        requests_and_authors AS paa
    WHERE
        thr.repo_id=paa.repo_id;
   
    -- Update the latest pull request time for each repo
    UPDATE 
        tmp_hf_pr_repos AS thr
    SET 
        latest_pr=lp.created_at
    FROM
        latest_pr AS lp
    WHERE
        thr.repo_id=lp.repo_id;

    -- Populate the hacktoberfest repos table
    INSERT INTO hf_pr_repos
        SELECT *
        FROM tmp_hf_pr_repos 
        ON CONFLICT(type,day,repo_id) DO 
        UPDATE SET
            day=EXCLUDED.day,
            stars=EXCLUDED.stars,
            requests=EXCLUDED.requests,
            authors=EXCLUDED.authors,
            latest_pr=EXCLUDED.latest_pr,
            updated_at=EXCLUDED.updated_at;

    DELETE FROM hf_pr_repos WHERE repo_id NOT IN (SELECT repo_id FROM tmp_hf_pr_repos);
END LOOP;
END; $$;

COMMIT;
