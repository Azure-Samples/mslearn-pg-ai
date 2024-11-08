-- Vector Search
SELECT id, name, opinion, 
RANK() OVER (ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector) AS vector_rank
FROM cases
ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector
LIMIT 10