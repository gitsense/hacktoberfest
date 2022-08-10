# About
SQL scripts to create and update GitSense Hacktoberfest tables

# Build Scripts

### build-hf-base-tables.sql

Creates the following tables

* hf_topics
* hf_labels

Once these tables have been created, they will not be updated if you execute this script again.  If you want to change the topics and/or labels, you will need to drop the table and run the script again.

### build-hf-pr-repos-table.sql

Creates and updates the hf_pr_repos table

### build-hf-pr-authors-table.sql

Creates and updates the hf_pr_authors table

### build-hf-pr-labels-table.sql

Creates and updates the hf_pr_labels table

### build-hf-pr-langs-table.sql

Creates and updates the hf_pr_langs table

# Tables

### hf_topics

```
 Column | Type | Collation | Nullable | Default 
--------+------+-----------+----------+---------
 topic  | text |           |          | 
```

Contains the GitHub repo topics associated with hacktoberfest repos. Currently we only consider 'hacktoberfest' but it might make sense to add 'hactoberfest' and other possible misspelled variations.

### hf_labels

```
 Column |      Type      | Collation | Nullable | Default 
--------+----------------+-----------+----------+---------
 type   | hf_label_types |           | not null | 
 label  | text           |           |          | 
```

#### type

Valid types include 'all', 'spam' and 'accepted'.

### hf_pr_repos

```
   Column   |              Type              | Collation | Nullable | Default 
------------+--------------------------------+-----------+----------+---------
 type       | hf_label_types                 |           | not null | 
 day        | character varying(12)          |           | not null | 
 repo_id    | integer                        |           | not null | 
 owner      | text                           |           | not null | 
 name       | text                           |           | not null | 
 stars      | integer                        |           |          | 
 requests   | integer                        |           |          | 
 authors    | integer                        |           |          | 
 latest_pr  | timestamp(3) without time zone |           |          | 
 updated_at | timestamp(3) without time zone |           | not null | 
```

The hf_pr_repos table contains all repos with a valid hacktoberfest topic and at least one pull request with a valid hacktoberfest label.  If a repo has a valid hacktoberfest topic but no valid pull requests, it won't be included in this table. 

#### type

Valid types include 'all', 'spam' and 'accepted'

#### day

Day as YYYY-MM-DD.

#### repo_id
Repository id

#### owner
Repository owner

#### name
Repository name

#### stars
Repository stars

#### requests
Number of pull requests

#### authors
Number of unique pull request authors

#### latest_pr
Latest created pull request time

#### updated_at
When this row was updated

### hf_pr_authors

```
   Column   |              Type              | Collation | Nullable | Default 
------------+--------------------------------+-----------+----------+---------
 type       | hf_label_types                 |           | not null | 
 day        | character varying(12)          |           | not null | 
 author     | text                           |           | not null | 
 orgs       | integer                        |           | not null | 
 repos      | integer                        |           | not null | 
 requests   | integer                        |           | not null | 
 latest_pr  | timestamp(3) without time zone |           |          | 
 updated_at | timestamp(3) without time zone |           | not null | 
```

hf_pr_authors contains all pull request authors that has one or more valid hacktoberfest pull request.


#### type
Label type with valid values bing 'all', 'spam' and 'accepted'

#### day
Day as YYYY-MM-DD

#### author
Pull request author 

#### orgs
Number of unique orgs containing one or more pull requests

#### repos
Number of unique repos containing one or more pull requests

#### requests
Number of pull requests owned by author

#### latest_pr
Latest created pull request time

#### updated_at
When this row was updated

### hf_pr_labels

```   
   Column   |              Type              | Collation | Nullable | Default 
------------+--------------------------------+-----------+----------+---------
 day        | character varying(12)          |           | not null | 
 label      | text                           |           | not null | 
 orgs       | integer                        |           | not null | 
 repos      | integer                        |           | not null | 
 requests   | integer                        |           | not null | 
 authors    | integer                        |           | not null | 
 updated_at | timestamp(3) without time zone |           | not null | 
```

hf_pr_labels contains analytics for hacktoberfest labels as defined in the `hf_labels` table.

#### day
Day as YYYY-MM-DD

#### label
Hacktoberfest label

#### orgs
Number of orgs associated with this label

#### repos
Number of repos associated with this label

#### requests
Number of pull requests with this label

#### authors
Number of unique authors that has this label associated with their pull request

#### updated_at
When this row was updated

### hf_pr_langs

```
   Column   |              Type              | Collation | Nullable | Default 
------------+--------------------------------+-----------+----------+---------
 type       | hf_label_types                 |           | not null | 
 day        | character varying(12)          |           | not null | 
 lang       | text                           |           | not null | 
 orgs       | integer                        |           | not null | 
 repos      | integer                        |           | not null | 
 requests   | integer                        |           | not null | 
 authors    | integer                        |           | not null | 
 updated_at | timestamp(3) without time zone |           | not null | 

```

hf_pr_langs contains stats for all languages that were changed by pull requests with a valid hacktoberfest label.

#### type
Label type with valid values being 'all', 'spam' and 'accepted'

#### day
Day as YYYY-MM-DD

#### lang
Language of file for files changed by a hacktoberfest pull request

#### orgs
Number of orgs associated with this lang

#### repos
Number of repos associated with this lang

#### requests
Number of pull requests with this lang

#### authors
Number of authors associated with this lang
