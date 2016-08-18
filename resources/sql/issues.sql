-- :name add-issue<! :<! :1
-- :doc create a new issue
INSERT INTO support_issues (title, summary, detail, created_by, last_updated_by)
VALUES (:title, :summary, :detail, :user_id, :user_id)
RETURNING support_issue_id;

-- :name update-issue! :! :n
-- :doc Updates the issue using optimistic concurrency (last-in wins)
UPDATE support_issues
SET title           = :title,
    summary         = :summary,
    detail          = :detail,
    last_updated_by = :user_id,
    update_date     = now(),
    last_viewed     = now(),
    views           = views + 1
WHERE
  support_issue_id = :support_issue_id;

-- :name support-issue :? :1
-- :doc Gets the issue with the given support_issue_id
SELECT
  si.support_issue_id,
  si.title,
  si.summary,
  si.detail,
  si.create_date,
  si.update_date,
  si.delete_date,
  si.last_viewed,
  si.views,
  created.first_name AS created_by_first_name,
  created.last_name AS created_by_last_name,
  si.created_by,
  si.last_updated_by,
  updated.first_name AS updated_by_first_name,
  updated.last_name AS updated_by_last_name
FROM support_issues si
  INNER JOIN users created on si.created_by = created.user_id
  LEFT OUTER JOIN users updated on si.last_updated_by = updated.user_id
WHERE
  si.support_issue_id = :support_issue_id
GROUP BY si.support_issue_id, created.user_id , updated.user_id;

-- :name recently-viewed-issues :? :*
-- :doc Gets the top x number of issues, based on last views
SELECT
  support_issue_id,
  title,
  summary,
  detail,
  create_date,
  update_date,
  last_viewed,
  views
FROM support_issues si
WHERE si.delete_date IS NULL
ORDER BY last_viewed DESC
GROUP BY si.support_issue_id
LIMIT :limit;

-- :name issues-by-views :? :*
-- :doc Gets all the issues, ordered by views
SELECT
  support_issue_id,
  title,
  summary,
  create_date,
  update_date,
  last_viewed,
  views
FROM support_issues
WHERE delete_date IS NULL
GROUP BY support_issue_id
ORDER BY last_viewed DESC;

-- :name support-issues-by-tag :? :*
-- :doc Gets all the issues, in order of popularity, by a given tag.
SELECT
  si.support_issue_id,
  si.title,
  si.summary,
  si.create_date,
  si.update_date,
  si.last_viewed,
  si.views
FROM support_issues si
  INNER JOIN support_issues_tags sit ON si.support_issue_id = sit.support_issue_id
  INNER JOIN tags t ON sit.tag_id = t.tag_id
  LEFT OUTER JOIN support_issue_scores s ON si.support_issue_id = s.support_issue_id
WHERE
  t.tag = :tag AND
  delete_date IS NULL
GROUP BY
  si.support_issue_id
ORDER BY score;

-- :name delete-issue! :! :n
-- :doc Deletes the support issue with the given support_issue_id
UPDATE support_issues
SET delete_date = now()
WHERE support_issue_id = :support_issue_id;

-- :name search-issues :? :*
-- :doc Search all support issues and returns, in order of relevance, any matching issue.
SELECT
  si.support_issue_id,
  si.title,
  si.summary,
  si.create_date,
  si.update_date,
  si.last_viewed,
  si.views
FROM support_issues si
  INNER JOIN (SELECT DISTINCT
                support_issue_id,
                ts_rank_cd(search_vector, to_tsquery(:query)) AS rank
              FROM support_issues, to_tsquery(:query) query
              WHERE query @@ search_vector
              ORDER BY rank DESC
              OFFSET :offset
              LIMIT :limit) x ON x.support_issue_id = si.support_issue_id
GROUP BY si.support_issue_id;