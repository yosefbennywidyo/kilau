-- 100 posts for S2/S3 (spec §6.2). Titles and contents carry characters
-- both apps must escape, so the body diff checks escaping too.
WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 100)
INSERT INTO posts (title, content, created_at, updated_at)
SELECT 'Post ' || i || ' <b>&</b>', 'Isi "post" ' || i || ' & ''kutip''', 1790000000 + i, 1790000000 + i FROM n;
