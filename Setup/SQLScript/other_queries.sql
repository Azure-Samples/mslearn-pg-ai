-- Setup Full Text Search
ALTER TABLE cases
ADD COLUMN textsearch tsvector
GENERATED ALWAYS AS (to_tsvector('english', name || LEFT(opinion, 8000)) STORED;
	
-- Run Full Text Search
SELECT id, name, opinion
FROM cases
WHERE textsearch @@ websearch_to_tsquery('Water leaking into the apartment from the floor above.');

-- Setup OpenAI
SELECT azure_ai.set_setting('azure_openai.endpoint', '');
SELECT azure_ai.set_setting('azure_openai.subscription_key', '');

-- Add Embeddings
ALTER TABLE cases ADD COLUMN opinions_vector vector(1536);
UPDATE cases
SET opinions_vector = azure_openai.create_embeddings('text-embedding-3-small',  name || LEFT(opinion, 8000), max_attempts => 5, retry_delay_ms => 500)::vector
WHERE opinions_vector IS NULL;


-- Vector Search with Full Text Search
SELECT id, name, opinion,
RANK() OVER (ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector) AS vector_rank
FROM cases
WHERE textsearch @@ websearch_to_tsquery('Seattle')
ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector
LIMIT 10
