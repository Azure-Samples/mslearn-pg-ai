-- Create product_features table first (referenced by others)
CREATE TABLE product_features (
    id integer NOT NULL,
    feature_name character varying(255) NOT NULL,
    CONSTRAINT product_features_pkey PRIMARY KEY (id),
    CONSTRAINT product_features_feature_name_key UNIQUE (feature_name)
);

-- Create products table
CREATE TABLE products (
    id integer NOT NULL,
    name text NOT NULL,
    category text,
    price numeric,
    brand text,
    description text,
    specifications jsonb,
    embeddings vector(1536),
    features jsonb,
    CONSTRAINT products_pkey PRIMARY KEY (id)
);

-- Create reviews table (references products)
CREATE TABLE reviews (
    id integer NOT NULL,
    product_id integer,
    user_name text,
    rating smallint,
    review_text text,
    created_at date,
    features jsonb,
    CONSTRAINT reviews_pkey PRIMARY KEY (id),
    CONSTRAINT reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id)
);


-- Import from CSV files

\COPY products FROM 'samples_data/products.csv' WITH CSV HEADER;
\COPY product_features FROM 'samples_data/product_features.csv' WITH CSV HEADER;
\COPY reviews FROM 'samples_data/reviews.csv' WITH CSV HEADER;

