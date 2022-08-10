BEGIN;

-- Create the hacktoberfest topics table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables where table_name='hf_topics') THEN
        CREATE TABLE hf_topics(topic TEXT);
        INSERT INTO hf_topics VALUES('hactoberfest');
        INSERT INTO hf_topics VALUES('hacktoberfest');
    END IF;
END
$$;

-- Define the label enum types if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='hf_label_types') THEN
        CREATE TYPE hf_label_types AS ENUM('all','spam','accepted');
    END IF;
END
$$;

-- Populate the labels table if doesn't exist. Drop the table if you want to rebuild it
-- wit this script
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables where table_name='hf_labels') THEN
        CREATE TABLE hf_labels(
            type HF_LABEL_TYPES NOT NULL,
            label TEXT
        );

        INSERT INTO hf_labels VALUES('spam', 'bug');
        INSERT INTO hf_labels VALUES('spam', 'javascript');
        INSERT INTO hf_labels VALUES('accepted', 'python');

        -- The reason for creating an 'all' type is to make executing 
        -- SQL "for loops" easier.  Can we do better?
        INSERT INTO hf_labels 
            SELECT
                'all', 
                label
            FROM 
                hf_labels 
            WHERE 
                type IN (SELECT type FROM hf_labels WHERE type != 'all');
    END IF;
END
$$;

COMMIT;
