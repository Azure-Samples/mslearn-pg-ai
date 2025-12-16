------------------------------------------------------------------------------
-- AI integration setup and sample queries
------------------------------------------------------------------------------

-- 1. Install the necessary extensions and set up Azure OpenAI credentials
CREATE EXTENSION IF NOT EXISTS azure_ai;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_diskann;

SELECT azure_ai.set_setting('azure_openai.endpoint', 'https://XXXX.openai.azure.com/');
SELECT azure_ai.set_setting('azure_openai.subscription_key', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890');

SELECT azure_ai.get_setting('azure_openai.endpoint')
-- 2. Create embeddings for the product descriptions
ALTER TABLE public.products
ADD COLUMN embeddings vector(1536);

UPDATE public.products
SET
  embeddings = azure_openai.create_embeddings(
      'text-embedding-3-small',
      description
      )::vector

-- 3. Create a diskann index by using Cosine distance operator
CREATE INDEX demo_embedding_diskann_idx ON products USING diskann (embeddings vector_cosine_ops);


------------------------------------------------------------------------------
-- VECTOR SEARCH AND AI-POWERED ANALYTICS SAMPLE QUERIES
------------------------------------------------------------------------------

-- Using Normal Vector Search
select id as product_id, name as product_name, description
     from products
     order by embeddings <=> azure_openai.create_embeddings(
                                'text-embedding-3-small',
                                'headphones with highest playtime and good for calling')::vector asc
     limit 10;

------------------------------------------------------------------------------
-- AI FUNCTIONS SAMPLE QUERIES
-- .generate(), .rank(), .is_true(), .extract()
------------------------------------------------------------------------------

-- 1. Using .generate() to create product descriptions
SELECT id as product_id, name as product_name,
       azure_ai.generate('Create a short and catchy product description for the following product name: ' || name,
                         'gpt-4o') AS generated_description
  FROM products
 LIMIT 5;


-- 2. Using .rank() to rerank results
-- Using better model to rerank will improve the results
with potential_headphones as (
     select id as product_id, name as product_name, description
     from products
     order by description_emb <=> azure_openai.create_embeddings(
                                'text-embedding-3-small',
                                'headphones with highest playtime and good for calling')::vector asc
     limit 50
), reranked_results as (
    select id as row_id, rank
      from azure_ai.rank('headphones with highest playtime and good for calling',
                         array(select 'Product Description: ' || description from potential_headphones),
                         array(select product_id from potential_headphones),
                         'gpt-4o'
                        )
)   select ph.product_id, ph.product_name,
           ph.description
      from potential_headphones ph
           left join reranked_results rr on rr.row_id = ph.product_id
  order by rr.rank asc
     limit 10;

-- 3. Using .is_true() to filter reviews mentioning specific features
SELECT r.product_id,
        r.review_text,
        f.feature_name
FROM product_features f 
JOIN reviews r 
ON azure_ai.is_true('Review mentions the feature. The review:' || r.review_text || 
                    'The feature: ' || f.feature_name,
                    'gpt-4o')
LIMIT 3; 

-- 4. Using .extract() to analyze sentiment about specific features in reviews
SELECT f.id, 
       r.review_text, 
       f.feature_name, 
       azure_ai.extract('Review: ' || r.review_text|| 
                        ' Feature: ' || f.feature_name,  
                        array['sentiment - sentiment about the feature as in positive, negative, or neutral'],
                        'gpt-4o') 
                        ->> 'sentiment' 
                AS sentiment 
FROM product_features f 
JOIN reviews r  
ON azure_ai.is_true('Review mentions the feature. Review: ' || r.review_text
                              || ' Feature: ' || f.feature_name, 
                              'gpt-4o') 
LIMIT 3;