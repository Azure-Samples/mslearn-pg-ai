CREATE EXTENSION IF NOT EXISTS pg_diskann;

CREATE INDEX cases_cosine_diskann ON cases USING diskann (opinions_vector vector_cosine_ops);

SET LOCAL enable_seqscan TO OFF; -- force index usage
SELECT 
id, name, opinion
FROM cases
ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector
LIMIT 10;

SET LOCAL enable_seqscan TO OFF; -- force index usage
EXPLAIN SELECT 
id, name, opinion
FROM cases
ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector
LIMIT 10;
