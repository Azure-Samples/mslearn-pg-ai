@lab.Title

Login to your VM with the following credentials...

**Username: ++@lab.VirtualMachine(Win11-Pro-Base-VM).Username++**

**Password: +++@lab.VirtualMachine(Win11-Pro-Base-VM).Password+++**


# Part 0 - Log into Azure
Login to Azure Portal with the following credentials.

1. Go to [Azure portal](https://portal.azure.com/)
    - Username: +++@lab.CloudPortalCredential(User1).Username+++
    - Password:+++@lab.CloudPortalCredential(User1).Password+++

# Part 1 - Getting started with AI on Azure PostgreSQL flexible server

## Connect to your database using psql in the Azure Cloud Shell

In this task, you connect to the <code spellcheck="false">rentals</code> database on your Azure Database for PostgreSQL flexible server using the [psql command-line utility](https://www.postgresql.org/docs/current/app-psql.html) from the [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview).

1. In the [Azure portal](https://portal.azure.com/), navigate to **Resource Groups** and select the resource group with the prefix **rg-learn-postgres**
    ![Screenshot of the Azure Portal with Resource groups selected](./media/azure-portal.png)
    
2. In that resource group select the precreated **Azure Database for PostgreSQL flexible server** instance.
    ![Screenshot of the Resource group with Azure Database for PostgreSQL flexible server selected](./media/database_in_azure.png)
3. In the resource menu, under **Settings**, select **Databases** select **Connect** for the <code spellcheck="false">rentals</code> database.
<br>
    ![Screenshot of the Azure Database for PostgreSQL Databases page. Databases and Connect for the rentals database are highlighted by red boxes.](./media/postgresql-rentals-database-connect.png)
4. At the "Password for user pgAdmin" prompt in the Cloud Shell, enter the password for the **pgAdmin** login.
<br>
    Password: <code spellcheck="false">Pa$$word</code>
<br>
    Once logged in, the <code spellcheck="false">psql</code> prompt for the <code spellcheck="false">rentals</code> database is displayed.
5. Throughout the remainder of this exercise, you continue working in the Cloud Shell, so it may be helpful to expand the pane within your browser window by selecting the **Maximize** button at the top right of the pane.
<br>
    ![Screenshot of the Azure Cloud Shell pane with the Maximize button highlighted by a red box.](./media/azure-cloud-shell-pane-maximize.png)

## Populate the database with sample data

Before you explore the <code spellcheck="false">azure_ai</code> extension, add a couple of tables to the <code spellcheck="false">rentals</code> database and populate them with sample data so you have information to work with as you review the extension's functionality.

1. Run the following commands to create the <code spellcheck="false">cases</code> and <code spellcheck="false">reviews</code> tables for storing us cases law data:

    ```sql
    DROP TABLE IF EXISTS cases;
    
    CREATE TABLE cases(
        id SERIAL PRIMARY KEY,
        name TEXT,
        court_id INT,
        decision_date DATE,
        opinion TEXT
    );
    ```

2. Next, use the <code spellcheck="false">COPY</code> command to load data from CSV files into each table you created above. Start by running the following command to populate the <code spellcheck="false">temp_cases</code> table:

    ```sql
    \COPY temp_cases (data) FROM 'cases.csv' WITH (FORMAT csv, HEADER true);
    ```

    the command output should be <code spellcheck="false">COPY 377</code>, indicating that 377 rows were written into the table from the CSV file.

3. Finally, run the command below to load cases data into the <code spellcheck="false">cases</code> table:

    ```sql


    INSERT INTO cases
    SELECT
        (data#>>'{id}')::int AS id, 
        (data#>>'{name_abbreviation}')::text AS name, 
        (data#>>'{decision_date}')::date AS decision_date, 
        (data#>>'{court,id}')::int AS court_id, 
        array_to_string(ARRAY(SELECT jsonb_path_query(data, '$.casebody.opinions[*].text')), ', ') AS opinion
    FROM temp_cases;
    
    ```



## Install and configure the <code spellcheck="false">azure_ai</code> extension

Before using the <code spellcheck="false">azure_ai</code> extension, you must install it into your database and configure it to connect to your Azure AI Services resources. The <code spellcheck="false">azure_ai</code> extension allows you to integrate the Azure OpenAI and Azure AI Language services into your database. To enable the extension in your database, follow these steps:

1. Execute the following command at the <code spellcheck="false">psql</code> prompt to verify that the <code spellcheck="false">azure_ai</code> and the <code spellcheck="false">vector</code> extensions were successfully added to your server's *allowlist* by the Bicep deployment script you ran when setting up your environment:

```sql
SHOW azure.extensions;
```

The command displays the list of extensions on the server's *allowlist*. If everything was correctly installed, your output must include <code spellcheck="false">azure_ai</code> and <code spellcheck="false">vector</code>, like this:

    ```
     azure.extensions 
    ------------------
     azure_ai,vector
    ```

Before an extension can be installed and used in an Azure Database for PostgreSQL flexible server database, it must be added to the server's *allowlist*, as described in [how to use PostgreSQL extensions](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions).


2. Now, you are ready to install the <code spellcheck="false">azure_ai</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.

    ```sql
    CREATE EXTENSION IF NOT EXISTS azure_ai;
    ```

<code spellcheck="false">CREATE EXTENSION</code> loads a new extension into the database by running its script file. This script typically creates new SQL objects such as functions, data types, and schemas. An error is thrown if an extension of the same name already exists. Adding <code spellcheck="false">IF NOT EXISTS</code> allows the command to execute without throwing an error if it is already installed.

## Review the objects contained within the <code spellcheck="false">azure_ai</code> extension

Reviewing the objects within the <code spellcheck="false">azure_ai</code> extension can help you better understand its capabilities. In this task, you inspect the various schemas, user-defined functions (UDFs), and composite types added to the database by the extension.

1. When working with <code spellcheck="false">psql</code> in the Cloud Shell, enabling the extended display for query results may be helpful, as it improves the readability of output for subsequent commands. Execute the following command to allow the extended display to be automatically applied.

    ```sql
    \x auto
    ```
2. The [\dx](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-META-COMMAND-DX-LC) is used to list objects contained within an extension. Run the following from the <code spellcheck="false">psql</code> command prompt to view the objects in the <code spellcheck="false">azure_ai</code> extension. You may need to press the space bar to view the full list of objects.

    ```
    \dx+ azure_ai
    ```

    the meta-command output shows the <code spellcheck="false">azure_ai</code> extension creates four schemas, multiple user-defined functions (UDFs), several composite types in the database, and the <code spellcheck="false">azure_ai.settings</code> table. Other than the schemas, all object names are preceded by the schema to which they belong. Schemas are used to group related functions and types the extension adds into buckets. The table below lists the schemas added by the extension and provides a brief description of each:

    | Schema | Description |
    | ------ | ----------- |
    | <code spellcheck="false">azure_ai</code> | The principal schema where the configuration table and UDFs for interacting with the extension reside. |
    | <code spellcheck="false">azure_openai</code> | Contains the UDFs that enable calling an Azure OpenAI endpoint. |
    | <code spellcheck="false">azure_cognitive</code> | Provides UDFs and composite types related to integrating the database with Azure AI Services. |
    | <code spellcheck="false">azure_ml</code> | Includes the UDFs for integrating Azure Machine Learning (ML) services. |

### Explore the Azure AI schema

The <code spellcheck="false">azure_ai</code> schema provides the framework for directly interacting with Azure AI and ML services from your database. It contains functions for setting up connections to those services and retrieving them from the <code spellcheck="false">settings</code> table, which is also hosted in the same schema. The <code spellcheck="false">settings</code> table provides secure storage in the database for endpoints and keys associated with your Azure AI and ML services.

1. To review the functions defined in a schema, you can use the [\df](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-META-COMMAND-DF-LC), specifying the schema whose functions should be displayed. Run the following to view the functions in the <code spellcheck="false">azure_ai</code> schema:

    ```
    \df azure_ai.*
    ```

    the output of the command should be a table similar to this:

```sql
List of functions
     Schema |  Name  | Result data type | Argument data types | Type 
    ----------+-------------+------------------+----------------------+------
     azure_ai | get_setting | text      | key text      | func
     azure_ai | set_setting | void      | key text, value text | func
     azure_ai | version  | text      |           | func
```

the <code spellcheck="false">set_setting()</code> function lets you set the endpoint and key of your Azure AI and ML services so that the extension can connect to them. It accepts a **key** and the **value** to assign to it. The <code spellcheck="false">azure_ai.get_setting()</code> function provides a way to retrieve the values you set with the <code spellcheck="false">set_setting()</code> function. It accepts the **key** of the setting you want to view and returns the value assigned to it. For both methods, the key must be one of the following:

| Key | Description |
| --- | ----------- |
| <code spellcheck="false">azure_openai.endpoint</code> | A supported OpenAI endpoint (e.g., [https://example.openai.azure.com](https://example.openai.azure.com)). |
| <code spellcheck="false">azure_openai.subscription_key</code> | A subscription key for an Azure OpenAI resource. |
| <code spellcheck="false">azure_cognitive.endpoint</code> | A supported Azure AI Services endpoint (e.g., [https://example.cognitiveservices.azure.com](https://example.cognitiveservices.azure.com)). |
| <code spellcheck="false">azure_cognitive.subscription_key</code> | A subscription key for an Azure AI Services resource. |
| <code spellcheck="false">azure_ml.scoring_endpoint</code> | A supported Azure ML scoring endpoint (e.g., [https://example.eastus2.inference.ml.azure.com/score](https://example.eastus2.inference.ml.azure.com/score)) |
| <code spellcheck="false">azure_ml.endpoint_key</code> | An endpoint key for an Azure ML deployment. |

> Important
    > 
    > Because the connection information for Azure AI services, including API keys, is stored in a configuration table in the database, the <code spellcheck="false">azure_ai</code> extension defines a role called <code spellcheck="false">azure_ai_settings_manager</code> to ensure this information is protected and accessible only to users who have been assigned that role. This role enables reading and writing of settings related to the extension. Only members of the <code spellcheck="false">azure_ai_settings_manager</code> role can invoke the <code spellcheck="false">azure_ai.get_setting()</code> and <code spellcheck="false">azure_ai.set_setting()</code> functions. In an Azure Database for PostgreSQL flexible server, all admin users (those with the <code spellcheck="false">azure_pg_admin</code> role assigned) are also assigned the <code spellcheck="false">azure_ai_settings_manager</code> role.
    
2. To demonstrate how you use the <code spellcheck="false">azure_ai.set_setting()</code> and <code spellcheck="false">azure_ai.get_setting()</code> functions, configure the connection to your Azure OpenAI account.
<br>

    a. Using the same browser tab where your Cloud Shell is open, minimize or restore the Cloud Shell pane, then navigate to your **<code spellcheck="false">Azure OpenAI</code>** resource in the [Azure portal](https://portal.azure.com/).
<br>

    b. Once you are on the Azure OpenAI resource page, in the resource menu, under the **Resource Management** section, select **Keys and Endpoint**, then copy your endpoint and one of the available keys.
<br>
    ! [Screenshot of the Azure OpenAI service's Keys and Endpoints page is displayed, with the KEY 1 and Endpoint copy buttons highlighted by red boxes.](instructions276019/12-azure-openai-keys-and-endpoints.png)
<br>
    You can use either <code spellcheck="false">KEY 1</code> or <code spellcheck="false">KEY 2</code>. Always having two keys allows you to securely rotate and regenerate keys without causing service disruption.
3. Once you have your endpoint and key, maximize the Cloud Shell pane again, then use the commands below to add your values to the configuration table. Ensure you replace the <code spellcheck="false">{endpoint}</code> and <code spellcheck="false">{api-key}</code> tokens with the values you copied from the Azure portal.

    ```sql
    SELECT azure_ai.set_setting('azure_openai.endpoint', '{endpoint}');
    ```

    ```sql
    SELECT azure_ai.set_setting('azure_openai.subscription_key', '{api-key}');
    ```
4. You can verify the settings written into the <code spellcheck="false">azure_ai.settings</code> table using the <code spellcheck="false">azure_ai.get_setting()</code> function in the following queries:

    ```sql
    SELECT azure_ai.get_setting('azure_openai.endpoint');
    SELECT azure_ai.get_setting('azure_openai.subscription_key');
    ```

    the <code spellcheck="false">azure_ai</code> extension is now connected to your Azure OpenAI account.

### Review the Azure OpenAI schema

The <code spellcheck="false">azure_openai</code> schema provides the ability to integrate the creation of vector embedding of text values into your database using Azure OpenAI. Using this schema, you can [generate embeddings with Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/how-to/embeddings) directly from the database to create vector representations of input text, which can then be used in vector similarity searches, as well as consumed by machine learning models. The schema contains a single function, <code spellcheck="false">create_embeddings()</code>, with two overloads. One overload accepts a single input string, and the other expects an array of input strings.

1. As you did above, you can use the [\df](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-META-COMMAND-DF-LC) to view the details of the functions in the <code spellcheck="false">azure_openai</code> schema:

    ```
    \df azure_openai.*
    ```

    the output shows the two overloads of the <code spellcheck="false">azure_openai.create_embeddings()</code> function, allowing you to review the differences between the two versions of the function and the types they return. The <code spellcheck="false">Argument data types</code> property in the output reveals the list of arguments the two function overloads expect:

    | Argument | Type | Default | Description |
    | -------- | ---- | ------- | ----------- |
    | deployment_name | <code spellcheck="false">text</code> |  | Name of the deployment in Azure OpenAI Studio that contains the <code spellcheck="false">text-embedding-ada-002</code> model. |
    | input | <code spellcheck="false">text</code> or <code spellcheck="false">text[]</code> |  | Input text (or array of text) for which embeddings are created. |
    | batch_size | <code spellcheck="false">integer</code> | 100 | Only for the overload expecting an input of <code spellcheck="false">text[]</code>. Specifies the number of records to process at a time. |
    | timeout_ms | <code spellcheck="false">integer</code> | 3600000 | Timeout in milliseconds after which the operation is stopped. |
    | throw_on_error | <code spellcheck="false">boolean</code> | true | Flag indicating whether the function should, on error, throw an exception resulting in a rollback of the wrapping transaction. |
    | max_attempts | <code spellcheck="false">integer</code> | 1 | Number of times to retry the call to Azure OpenAI service in the event of a failure. |
    | retry_delay_ms | <code spellcheck="false">integer</code> | 1000 | Amount of time, in milliseconds, to wait before attempting to retry calling the Azure OpenAI service endpoint. |
2. To provide a simplified example of using the function, run the following query, which creates a vector embedding for the <code spellcheck="false">opinion</code> field in the <code spellcheck="false">cases</code> table. The <code spellcheck="false">deployment_name</code> parameter in the function is set to <code spellcheck="false">embedding</code>, which is the name of the deployment of the <code spellcheck="false">text-embedding-ada-002</code> model in your Azure OpenAI service (it was created with that name by the Bicep deployment script):

    ```sql
    SELECT
      id,
      name,
      azure_openai.create_embeddings('embedding', LEFT(opinion, 8000)) AS vector
    FROM cases
    LIMIT 1;
    ```

the output looks similar to this:


```
 id |      name       |              vector
----+-------------------------------+------------------------------------------------------------
  1 | Stylish One-Bedroom Apartment | {0.020068742,0.00022734122,0.0018286322,-0.0064167166,...}
```


for brevity, the vector embeddings are abbreviated in the above output.

[Embeddings](https://learn.microsoft.com/azure/postgresql/flexible-server/generative-ai-overview#embeddings) are a concept in machine learning and natural language processing (NLP) that involves representing objects such as words, documents, or entities, as [vectors](https://learn.microsoft.com/azure/postgresql/flexible-server/generative-ai-overview#vectors) in a multi-dimensional space. Embeddings allow machine learning models to evaluate how closely two pieces of information are related. This technique efficiently identifies relationships and similarities between data, allowing algorithms to identify patterns and make accurate predictions.

The <code spellcheck="false">azure_ai</code> extension allows you to generate embeddings for input text. To enable the generated vectors to be stored alongside the rest of your data in the database, you must install the <code spellcheck="false">vector</code> extension by following the guidance in the [enable vector support in your database](https://learn.microsoft.com/azure/postgresql/flexible-server/how-to-use-pgvector#enable-extension) documentation. However, that is outside of the scope of this exercise.

# Part 2 - Using AI-driven features in Postgres

In this section, we will explore how to leverage AI-driven features within PostgreSQL to enhance data processing and analysis. These features can help automate tasks, improve data insights, and provide advanced functionalities that traditional SQL queries may not offer.

## Using different approaches to enhance results from your application.

### Explore Database

1. First we will retrieve a sample of data from the cases table in our rental dataset. This allows us to examine the structure and content of the data stored in the database.

    ```sql
    SELECT * FROM cases
    LIMIT 5;
    ```

## Using Pattern matching for queries

We will explore how to use the <code spellcheck="false">ILIKE</code> clause in SQL to perform case-insensitive searches within text fields. This is particularly useful when you want to find specific cases or reviews that contain certain keywords.

1. We will searching for cases mentioning `"Water leaking into the apartment from the floor above."`. 

    ```sql
    SELECT id, name, opinion
    FROM cases
    WHERE opinion ILIKE '%Water leaking into the apartment from the floor above';
    ```

You'll get a result similar to this:

```
id | name | opinion
----+------+---------
(0 rows)
```

However, it fall short as the exact words are not mentioned in the opinion. As you can see there are no results for what to user wants to find. We need to try another appoach.


## Using Full Text Search

In this section, we will implement full-text search capabilities in PostgreSQL to enhance our ability to query text data efficiently. Full-text search allows for more sophisticated searching techniques compared to simple pattern matching, making it ideal for applications that require searching through large volumes of text.

1. We will need to create a [tsvector](https://www.postgresql.org/docs/current/datatype-textsearch.html) column to do full-text search

    ```sql
    ALTER TABLE cases
    ADD COLUMN textsearch tsvector
    GENERATED ALWAYS AS (to_tsvector('english', name || LEFT(opinion, 8000)) STORED;
    ```

1. We will perform a full-text search on the listings table to find entries that have a phrase `"Water leaking into the apartment from the floor above."`. It falls short returning only 1 result. <code spellcheck="false">websearch_to_tsquery</code>

    ```sql
    SELECT id, name, opinion
    FROM cases
    WHERE textsearch @@ websearch_to_tsquery('Water leaking into the apartment from the floor above.');
    ```

You'll get a result similar to this:
```
 id | name | opinion 
----+------+--------
4237124  | Pham v. Corbett | "Spearman, C.J.\n¶1 Landlord Lang Pham brought this unlawful detainer action against tenants Shakia Morgan and Shawn Corbett (Tenants)."
(1 rows)
```

Improvement from %ILIKE, but not great. As you can see there is only one result for what to user wants to find. We need to try another appoach.

## Using Sementic Search

In this section, we will focus on generating and storing embedding vectors, which are crucial for performing semantic searches in our dataset. Embedding vectors represent data points in a high-dimensional space, allowing for efficient similarity searches and advanced analytics.

### Create and store embedding vectors

Now that we have some sample data, it's time to generate and store the embedding vectors. The <code spellcheck="false">azure_ai</code> extension makes calling the Azure OpenAI embedding API easy.

1. Now, you are ready to install the <code spellcheck="false">vector</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.

    ```sql
    CREATE EXTENSION IF NOT EXISTS vector;
    ```
2. Add the embedding vector column.
<br>
    The <code spellcheck="false">text-embedding-ada-002</code> model is configured to return 1,536 dimensions, so use that for the vector column size.

    ```sql
    ALTER TABLE cases ADD COLUMN opinions_vector vector(1536);
    ```
3. Generate an embedding vector for the description of each listing by calling Azure OpenAI through the create_embeddings user-defined function, which is implemented by the azure_ai extension:

    ```sql
    UPDATE cases
    SET opinions_vector = azure_openai.create_embeddings('embedding',  name || LEFT(opinion, 8000), max_attempts => 5, retry_delay_ms => 500)::vector
    WHERE opinions_vector IS NULL;
    ```

    note that this may take several minutes, depending on the available quota.
<br>
    Using <code spellcheck="false">\df</code> to get a better understanding of that the create_embeddings funciton is doing.

    ```sql
    \df azure_openai.create_embeddings
    ```
4. See an example vector by running this query:

    ```sql
    SELECT opinions_vector FROM cases LIMIT 1;
    ```

    you will get a result similar to this, but with 1536 vector columns. The output will take up alot of your screen, just hit enter to move down the page to see all of the output:

    ```sql
    -[ RECORD 1 ]--+------ ...
    opinions_vector | [-0.0018742813,-0.04530062,0.055145424, ... ]
    ```

### Difference between <code spellcheck="false">tsvector</code> vs <code spellcheck="false">pgvector</code>

* **tsvector** is focused on text processing and full-text search capabilities, making it ideal for applications that need to search and rank text efficiently.
* **pgvector** is tailored for handling high-dimensional data, particularly in the context of machine learning, enabling similarity searches and advanced data analysis.

### Perform a semantic search query

Now that you have listing data augmented with embedding vectors, it's time to run a semantic search query. To do so, get the query string embedding vector, then perform a cosine search to find the cases whose descriptions are most semantically similar to the query.

1. Generate the embedding for the query string.

    ```sql
    SELECT azure_openai.create_embeddings('embedding', 'Water leaking into the apartment from the floor above.');
    ```

    you will get a result like this:

    ```sql
    -[ RECORD 1 ]-----+-- ...
    create_embeddings | {-0.0020871465,-0.002830255,0.030923981, ...}
    ```
2. Use the embedding in a cosine search (<code spellcheck="false"><=></code> represents cosine distance operation), fetching the top 10 most similar cases to the query.

    ```sql
    SELECT 
        id, name 
    FROM 
        cases
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('embedding', 'Water leaking into the apartment from the floor above.')::vector 
    LIMIT 10;
    ```

You'll get a result similar to this. Results may vary, as embedding vectors are not guaranteed to be deterministic:

    ```sql
    id |            opinion         
    ----+----------------------------

    ```
3. You may also project the <code spellcheck="false">description</code> column to be able to read the text of the matching rows whose descriptions were semantically similar. For example, this query returns the best match:

    ```sql
    SELECT 
    id, opinion
    FROM cases
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('embedding', 'Water leaking into the apartment from the floor above.')::vector 
    LIMIT 1;
    ```

which prints something like:

    ```sql
    id          | opinion
    ------------+----------------------------
    615468       | "Morris, J.\nAppeal from an order of nonsuit and dismissal, in an action brought by a tenant to recover damages for injuries to her goods, caused by leakage of water from an upper story. The facts, so far as they are pertinent to our inquiry, are about these: The Hardman Estate is the owner of a building on Yesler Way, in Seattle, the lower portion of which is divided into storerooms, and the upper is used as a hotel. Appellant, who was engaged in the millinery business, occupied one of the storerooms under a written lease...."
    ```

To intuitively understand semantic search, observe that the description mentioned downtown, but doesn't actually contain the terms `"Water leaking into the apartment from the floor above."`. However it does highlight a document with a section that says `"nonsuit and dismissal, in an action brought by a tenant to recover damages for injuries to her goods, caused by leakage of water from an upper story"`

## Hybrid Query

In this section, we will explore the concept of hybrid search, which combines both full-text search and semantic search capabilities. This approach enhances the search experience by leveraging the strengths of both methods, allowing for more accurate and relevant results.

### Perform a hybrid search query

1. With the following query we will perform a semantic and full text search together. This searches for listing “similar to” the input phrase: `"Water leaking into the apartment from the floor above."` AND have the phrase 'Seattle'.

    ```sql
    SELECT 
    id, name, opinions
    FROM cases
    WHERE textsearch @@ phraseto_tsquery('Seattle')
    ORDER BY listing_vector <=> azure_openai.create_embeddings('embedding', 'Water leaking into the apartment from the floor above.')::vector
    LIMIT 5;
    ```

You'll get a result similar to this. Results may vary, as embedding vectors are not guaranteed to be deterministic:

```sql


```

## Improving Performance with DiskANN vector index

DiskANN is a scalable approximate nearest neighbor search algorithm for efficient vector search at any scale. It offers high recall, high queries per second (QPS), and low query latency, even for billion-point datasets. This makes it a powerful tool for handling large volumes of data. [Learn more about DiskANN from Microsoft](https://www.microsoft.com/en-us/research/project/project-akupara-approximate-nearest-neighbor-search-for-large-scale-semantic-search/).

1. Now, you are ready to install the <code spellcheck="false">pg_diskann</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.

    ```sql
    CREATE EXTENSION IF NOT EXISTS pg_diskann;
    ```
2. Create the diskann index on a table column that contains vector data.

    ```sql
    CREATE INDEX cases_cosine_diskann ON cases USING diskann (opinions_vector vector_cosine_ops);
    ```
3. Postgres will automatically decide when to use the DiskANN index. However, you can use to following command to force the use of the DiskANN index.

    ```sql
    
    SET LOCAL enable_seqscan TO OFF; -- force index usage
    SELECT 
    id, name, opinion
    FROM cases
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('embedding', 'Water leaking into the apartment from the floor above.')::vector
    LIMIT 10;
    ```

you will get a result like this:


```sql
--sample OUTPUT
```


4. Use the following [EXPLAIN](https://www.postgresql.org/docs/current/sql-explain.html) command to understand how DiskANN works under the hood.

    ```sql
    
    SET LOCAL enable_seqscan TO OFF; -- force index usage
    EXPLAIN SELECT 
    id, name, opinion
    FROM cases
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('embedding', 'Water leaking into the apartment from the floor above.')::vector
    LIMIT 10;
    ```

you will get a result like this:

```sql
-[ RECORD 1 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN | Limit  (cost=479.20..484.14 rows=10 width=261) (actual time=1.207..1.270 rows=10 loops=1)
-[ RECORD 2 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN |   ->  Index Scan using listing_cosine_diskann on cases_diskann  (cost=479.20..1574.91 rows=2217 width=261) (actual time=1.206..1.268 rows=10 loops=1)
-[ RECORD 3 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN |         Order By: (description_vector <=> '[-0.016351668,-0.052834343,0.049271334,0.07909881,-0.028962178,...,-0.0071769194,0.004959582]'::vector)
-[ RECORD 4 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN | Planning Time: 70.183 ms
-[ RECORD 5 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN | Execution Time: 1.298 ms
```

as you scale your data to millions of rows, DiskANN makes vector search more effcient.


## Improving Performance with Reranking and Knowledge Graph

## What is a Reranker
In this section, we will explore the concept of hybrid search, which combines both full-text search and semantic search capabilities. This approach enhances the search experience by leveraging the strengths of both methods, allowing for more accurate and relevant results.

### Using a Reranker

1. 

2. Important snippent of code to understand
```sql
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
```

We have already create the file for your.. just run.
```sql
\i /mslearn-pg-ai/Setup/SQLScript/semantic_query.sql
```

## Using Graph Data in Postgres

### Using Graph to improve results accuracy

1. <Just show the slides and result..>

2. Important snippent of code to understand
```sql
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
)
```

We have already create the file for your.. just run.
```sql
\i /mslearn-pg-ai/Setup/SQLScript/graph_query.sql
```

## Compare Results

SELECT 2 for graph_query.sql
SELECT 2 for semantic_query.sql
SELECT 2 for graph_query.sql

Inspect with you think is better.

We think Graph..

# Bonus: How RAG chatbot accuracy improves with different technique

We will explore how to effectively utilize context within your Retrieval-Augmented Generation (RAG) chatbot. Context is crucial for enhancing the chatbot’s ability to provide relevant and accurate responses, making interactions more meaningful for users.

The Retrieval-Augmented Generation (RAG) system is a sophisticated architecture designed to enhance user interactions through a seamless integration of various technological components. At its core, RAG is composed of:

- App UX (web app) for the user experience
- App server or orchestrator (integration and coordination layer)
- Azure PostgreSQL Flexible Server - [pgvector extension](https://github.com/pgvector/pgvector) (information retrieval system)
- Azure OpenAI (LLM for generative AI)

![Screenshot about RAG](./media/azure-rag.png)

## Exploring Rental RAG application
We create a sample rental RAG application so you can explore with RAG application.

1. Go to our sample [RAG application](https://pg-rag-demo.azurewebsites.net/)

1. Enter your Azure OpenAI credentials in the sample app, to chat with the data.
![OpenAI credientials](./media/azure-open-ai-creds.png)

1.  To find your credentials, navigate to your **<code spellcheck="false">Azure OpenAI</code>** resource in the [Azure portal](https://portal.azure.com/).
<br>

1. Once you are on the Azure OpenAI resource page, in the resource menu, under the **Resource Management** section, select **Keys and Endpoint**, then copy your endpoint and one of the available keys.
<br>
    ![Screenshot of the Azure OpenAI service's Keys and Endpoints page is displayed, with the KEY 1 and Endpoint copy buttons highlighted by red boxes.](./media/azure-openai-keys-and-endpoints.png)
<br>

    You can use either <code spellcheck="false">KEY 1</code> or <code spellcheck="false">KEY 2</code>. Always having two keys allows you to securely rotate and regenerate keys without causing service disruption.

1. Go back to the [RAG application](https://pg-rag-demo.azurewebsites.net/) and explore the RAG application.

    ![RAG Final Results](./media/rag-final-results.png)
