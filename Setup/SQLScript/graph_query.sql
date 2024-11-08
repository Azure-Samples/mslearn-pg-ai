
LOAD 'age';
SET search_path = public, ag_catalog, "$user";

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
),
graph AS (
	select id, COUNT(ref_id) AS refs
	from (
	    SELECT semantic_ranked.id, graph_query.ref_id, c2.opinions_vector <=> embedding AS ref_cosine
		FROM semantic_ranked, embedding_query
		LEFT JOIN cypher('case_graph', $$
	            MATCH (s)-[r:REF]->(n)
	            RETURN n.case_id AS case_id, s.case_id AS ref_id
	        $$) as graph_query(case_id TEXT, ref_id TEXT)
		ON semantic_ranked.id::text = graph_query.case_id
		LEFT JOIN cases c2
		ON c2.id::text = graph_query.ref_id
		WHERE semantic_ranked.semantic_rank <= 25
		ORDER BY ref_cosine
		LIMIT 200
	)
	group by id
),
graph2 as (
	select semantic_ranked.*, graph.refs 
	from semantic_ranked
	left join graph
	on semantic_ranked.id = graph.id
),
graph_ranked AS (
    SELECT RANK() OVER (ORDER BY COALESCE(graph2.refs, 0) DESC) AS graph_rank, graph2.*
    FROM graph ORDER BY graph_rank DESC
),
rrf AS (
    select
    	gold_dataset.label,
        COALESCE(1.0 / (60 + graph_ranked.graph_rank), 0.0) +
        COALESCE(1.0 / (60 + graph_ranked.semantic_rank), 0.0) AS score,
        graph_ranked.*
    FROM graph_ranked
	left join gold_dataset
	on id = gold_id
    ORDER BY score DESC
)
select label,score,graph_rank,semantic_rank,vector_rank,id,case_name,"date","data",refs,relevance
FROM rrf
order by score DESC;