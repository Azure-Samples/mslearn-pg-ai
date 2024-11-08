-- Reranker Setup
select azure_ai.set_setting('azure_ml.scoring_endpoint','https://mlukrerankeraml-bgev2m3.southcentralus.inference.ml.azure.com/score');
select azure_ai.set_setting('azure_ml.endpoint_key', '');

-- Reranker
WITH
user_query as (
	select 'Water leaking into the apartment from the floor above.' as query_text
),
embedding_query AS (
    SELECT query_text, azure_openai.create_embeddings('text-embedding-3-small', query_text)::vector AS embedding
    from user_query
),
vector AS (
    SELECT cases.id, cases.name AS case_name, cases.decision_date AS date, cases.opinion as opinion, 
    RANK() OVER (ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', query_text)::vector) AS vector_rank,
	query_text
    FROM cases, embedding_query
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', query_text)::vector
    LIMIT 10
),
json_payload AS (
    SELECT jsonb_build_object(
        'pairs', 
        jsonb_agg(
            jsonb_build_array(
                query_text, 
                LEFT(opinion, 8000)
            )
        )
    ) AS json_pairs
    FROM vector
),
semantic AS (
    SELECT elem.relevance::DOUBLE precision as relevance, elem.ordinality
    FROM json_payload,
         LATERAL jsonb_array_elements(
             azure_ml.invoke(
                 json_pairs,
                 deployment_name => 'bge-v2-m3-1',
                 timeout_ms => 180000
             )
         ) WITH ORDINALITY AS elem(relevance)
),
semantic_ranked AS (
    SELECT RANK() OVER (ORDER BY relevance DESC) AS semantic_rank,
			semantic.*, vector.*
    FROM vector
    JOIN semantic ON vector.vector_rank = semantic.ordinality
    ORDER BY semantic.relevance DESC
)

select id, case_name, opinion
FROM semantic_ranked;
