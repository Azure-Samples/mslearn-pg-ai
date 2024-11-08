@lab.Title

Login to your VM with the following credentials...

**Username: ++@lab.VirtualMachine(Win11-Pro-Base-VM).Username++**

**Password: +++@lab.VirtualMachine(Win11-Pro-Base-VM).Password+++**

<br>
***

# Part 0 - Log into Azure

Username: +++@lab.CloudPortalCredential(User1).Username+++

Password:+++@lab.CloudPortalCredential(User1).Password+++

....

# Part 1 - Getting started with AI on Azure PostgreSQL flexible server

## Connect to your database using psql in the Azure Cloud Shell

In this task, you connect to the <code spellcheck="false">rentals</code> database on your Azure Database for PostgreSQL flexible server using the [psql command-line utility](https://www.postgresql.org/docs/current/app-psql.html) from the [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview).

1. In the [Azure portal](https://portal.azure.com/), navigate to **Resource Groups** and select the resource group with the prefix **rg-learn-postgres**
    ![Screenshot of the Azure Portal with Resource groups selected](media/azure-portal.png)
    
2. In that resource group select the precreated **Azure Database for PostgreSQL flexible server** instance.
    ! [Screenshot of the Resource group with Azure Database for PostgreSQL flexible server selected](instructions276019/Screenshot 2024-10-25 at 4.28.45?PM.png)
3. In the resource menu, under **Settings**, select **Databases** select **Connect** for the <code spellcheck="false">rentals</code> database.
<br>
    ! [Screenshot of the Azure Database for PostgreSQL Databases page. Databases and Connect for the rentals database are highlighted by red boxes.](instructions276019/12-postgresql-rentals-database-connect.png)
4. At the "Password for user pgAdmin" prompt in the Cloud Shell, enter the password for the **pgAdmin** login.
<br>
    Password: <code spellcheck="false">Password$</code>
<br>
    Once logged in, the <code spellcheck="false">psql</code> prompt for the <code spellcheck="false">rentals</code> database is displayed.
5. Throughout the remainder of this exercise, you continue working in the Cloud Shell, so it may be helpful to expand the pane within your browser window by selecting the **Maximize** button at the top right of the pane.
<br>
    ! [Screenshot of the Azure Cloud Shell pane with the Maximize button highlighted by a red box.](instructions276019/12-azure-cloud-shell-pane-maximize.png)

## Populate the database with sample data

Before you explore the <code spellcheck="false">azure_ai</code> extension, add a couple of tables to the <code spellcheck="false">rentals</code> database and populate them with sample data so you have information to work with as you review the extension's functionality.

1. Run the following commands to create the <code spellcheck="false">listings</code> and <code spellcheck="false">reviews</code> tables for storing rental property listing and customer review data:

    ```sql
    DROP TABLE IF EXISTS listings;
    
    CREATE TABLE listings (
      id int,
      name varchar(100),
      description text,
      property_type varchar(25),
      room_type varchar(30),
      price numeric,
      weekly_price numeric
    );
    ```

    ```sql
    DROP TABLE IF EXISTS reviews;
    
    CREATE TABLE reviews (
      id int,
      listing_id int, 
      date date,
      comments text
    );
    ```
2. Next, use the <code spellcheck="false">COPY</code> command to load data from CSV files into each table you created above. Start by running the following command to populate the <code spellcheck="false">listings</code> table:

    ```sql
    \COPY listings FROM 'mslearn-postgresql/Allfiles/Labs/Shared/listings.csv' CSV HEADER
    ```

    the command output should be <code spellcheck="false">COPY 50</code>, indicating that 50 rows were written into the table from the CSV file.
3. Finally, run the command below to load customer reviews into the <code spellcheck="false">reviews</code> table:

    ```sql
    \COPY reviews FROM 'mslearn-postgresql/Allfiles/Labs/Shared/reviews.csv' CSV HEADER
    ```

    the command output should be <code spellcheck="false">COPY 354</code>, indicating that 354 rows were written into the table from the CSV file.

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
2. To provide a simplified example of using the function, run the following query, which creates a vector embedding for the <code spellcheck="false">description</code> field in the <code spellcheck="false">listings</code> table. The <code spellcheck="false">deployment_name</code> parameter in the function is set to <code spellcheck="false">embedding</code>, which is the name of the deployment of the <code spellcheck="false">text-embedding-ada-002</code> model in your Azure OpenAI service (it was created with that name by the Bicep deployment script):

    ```sql
    SELECT
      id,
      name,
      azure_openai.create_embeddings('embedding', description) AS vector
    FROM listings
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

1. First we will retrieve a sample of data from the listings table in our rental dataset. This allows us to examine the structure and content of the data stored in the database.

    ```sql
    SELECT 
    *
    FROM listings 
    LIMIT 5;
    ```

## Using Pattern matching for queries

We will explore how to use the <code spellcheck="false">ILIKE</code> clause in SQL to perform case-insensitive searches within text fields. This is particularly useful when you want to find specific listings or reviews that contain certain keywords.

1. We will searching for listings mentioning ‘dog' And those mentioning ‘downtown'.

    ```sql
    SELECT id, name, description, price
    FROM listings
    WHERE description ILIKE '%dog%'
    AND description ILIKE '%downtown%';
    ```

you'll get a result similar to this:


```
-[ RECORD 1 ]------------------------------------------------------------------------------------------------------------------------
id          | 12
name        | Private 1BR apartment
description | This is a bright 1BR apartment upstairs in a house in the popular Ballard neighborhood. It has two separate rooms and a small kitchen. Walking distance to lots of restaurants, stores, bars, big grocery store, bus to downtown Seattle and more! Perfect for longer stays! This is your own apartment for your visit! It's a bedroom with a queen futon, living room, kitchen and bathroom with a shower. It has 2 closets, should be plenty of room to store your stuff. I live downstairs, and we can have little or more contact, as you wish. I have a small dog, who doesn't have access to your space, but may bark behind my door when you enter or leave. There are slightly steep stairs to get up to the apartment. The kitchen is equipped with all the basics you need if you want to make your own meals, there is a coffeemaker, coffee and tea are provided. The comfortable living room has a sofa, lots of sunlight (if you're here in the sunny months) and a big window with a view of the neighborhood.
price       | 80.00
-[ RECORD 2 ]------------------------------------------------------------------------------------------------------------------------
id          | 16
name        | Private garden room
description | Women Only: This cozy room with ensuite bathroom and kitchenette, opens onto a private Northwest garden. House is located on a quiet street, 1 block from major bus lines, 8 blocks from Ballard's hip downtown. 12 minute drive from downtown Seattle. There is a private bathroom in the room and an adjacent kitchenette (microwave, Keurig coffee/tea maker, and small frig) just for you. There is wi-fi throughout the house. The bed (twin XL) is brand new! Sealy Posturepedic with pillow top--this is one darned comfortable bed made up with Egyptian linens and Scandia down comforter or fine blanket, depending on the season. I am an author and work at home. I have a small, very affectionate dog named Louis. He is a Bichon Frise (they are hair, not fur) so he is hypoallergenic. There is easy, free, safe, on-street parking 24 hours a day. Women Only: As a chef, I am often recipe-testing in the kitchen on the 2nd floor. So I ask guests to limit their food preparation.
price       | 75.00
```

2. However, it fall short is the exact words are not mentioned in the description. We can try again with natural language.

    ```sql
    SELECT id, name, description, price
    FROM listings
    WHERE description ILIKE '%House near downtown that are pet-friendly';
    ```

you'll get a result similar to this:


```
id | name | description | price 
----+------+-------------+-------
(0 rows)
```


3. As you can see there are no results for what to user wants to find. We need to try another appoach.

## Using Full Text Search

In this section, we will implement full-text search capabilities in PostgreSQL to enhance our ability to query text data efficiently. Full-text search allows for more sophisticated searching techniques compared to simple pattern matching, making it ideal for applications that require searching through large volumes of text.

1. We will need to create a [tsvector](https://www.postgresql.org/docs/current/datatype-textsearch.html) column to do full-text search

    ```sql
    ALTER TABLE listings
    ADD COLUMN textsearch tsvector
    
    GENERATED ALWAYS AS (to_tsvector('english', name || description)) STORED;
    ```
2. We will perform a full-text search on the listings table to find entries that mention both “downtown” and “dog.” This is accomplished using the to_tsquery function, which allows us to specify complex search criteria.

    ```sql
    SELECT id, name, description
    FROM listings
    WHERE textsearch @@ to_tsquery('english', 'downtown & dog');
    ```

you'll get a result similar to this:

```sql
------------------------------------------------------------------------------------------------------------------------
id          | 12
name        | Private 1BR apartment
description | This is a bright 1BR apartment upstairs in a house in the popular Ballard neighborhood. It has two separate rooms and a small kitchen. Walking distance to lots of restaurants, stores, bars, big grocery store, bus to downtown Seattle and more! Perfect for longer stays! This is your own apartment for your visit! It's a bedroom with a queen futon, living room, kitchen and bathroom with a shower. It has 2 closets, should be plenty of room to store your stuff. I live downstairs, and we can have little or more contact, as you wish. I have a small dog, who doesn't have access to your space, but may bark behind my door when you enter or leave. There are slightly steep stairs to get up to the apartment. The kitchen is equipped with all the basics you need if you want to make your own meals, there is a coffeemaker, coffee and tea are provided. The comfortable living room has a sofa, lots of sunlight (if you're here in the sunny months) and a big window with a view of the neighborhood.'

------------------------------------------------------------------------------------------------------------------------
id          | 16
name        | Private garden room
description | Women Only: This cozy room with ensuite bathroom and kitchenette, opens onto a private Northwest garden. House is located on a quiet street, 1 block from major bus lines, 8 blocks from Ballard's hip downtown. 12 minute drive from downtown Seattle. There is a private bathroom in the room and an adjacent kitchenette (microwave, Keurig coffee/tea maker, and small frig) just for you. There is wi-fi throughout the house. The bed (twin XL) is brand new! Sealy Posturepedic with pillow top--this is one darned comfortable bed made up with Egyptian linens and Scandia down comforter or fine blanket, depending on the season. I am an author and work at home. I have a small, very affectionate dog named Louis. He is a Bichon Frise (they are hair, not fur) so he is hypoallergenic. There is easy, free, safe, on-street parking 24 hours a day. Women Only: As a chef, I am often recipe-testing in the kitchen on the 2nd floor. So I ask guests to limit their food preparation.
```

3. However, it fall short is the exact words are not mentioned in the description. We can try again with natural language.. Explain <code spellcheck="false">websearch_to_tsquery</code>

    ```sql
    SELECT id, name, description
    FROM listings
    WHERE textsearch @@ websearch_to_tsquery('House near downtown that are pet-friendly');
    ```

you'll get a result similar to this:

```
 id | name | description | price 
----+------+-------------+-------
(0 rows)
```

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
    ALTER TABLE listings ADD COLUMN listing_vector vector(1536);
    ```
3. Generate an embedding vector for the description of each listing by calling Azure OpenAI through the create_embeddings user-defined function, which is implemented by the azure_ai extension:

    ```sql
    UPDATE listings
    SET listing_vector = azure_openai.create_embeddings('embedding',  name || description, max_attempts => 5, retry_delay_ms => 500)::vector
    WHERE listing_vector IS NULL;
    ```

    note that this may take several minutes, depending on the available quota.
<br>
    Using <code spellcheck="false">\df</code> to get a better understanding of that the create_embeddings funciton is doing.

    ```sql
    \df azure_openai.create_embeddings
    ```
4. See an example vector by running this query:

    ```sql
    SELECT listing_vector FROM listings LIMIT 1;
    ```

    you will get a result similar to this, but with 1536 vector columns. The output will take up alot of your screen, just hit enter to move down the page to see all of the output:

    ```sql
    -[ RECORD 1 ]--+------ ...
    listing_vector | [-0.0018742813,-0.04530062,0.055145424, ... ]
    ```

### Difference between <code spellcheck="false">tsvector</code> vs <code spellcheck="false">pgvector</code>

* **tsvector** is focused on text processing and full-text search capabilities, making it ideal for applications that need to search and rank text efficiently.
* **pgvector** is tailored for handling high-dimensional data, particularly in the context of machine learning, enabling similarity searches and advanced data analysis.

### Perform a semantic search query

Now that you have listing data augmented with embedding vectors, it's time to run a semantic search query. To do so, get the query string embedding vector, then perform a cosine search to find the listings whose descriptions are most semantically similar to the query.

1. Generate the embedding for the query string.

    ```sql
    SELECT azure_openai.create_embeddings('embedding', 'House near downtown that are pet-friendly');
    ```

    you will get a result like this:

    ```sql
    -[ RECORD 1 ]-----+-- ...
    create_embeddings | {-0.0020871465,-0.002830255,0.030923981, ...}
    ```
2. Use the embedding in a cosine search (<code spellcheck="false"><=></code> represents cosine distance operation), fetching the top 10 most similar listings to the query.

    ```sql
    SELECT 
        id, name 
    FROM 
        listings 
    ORDER BY listing_vector <=> azure_openai.create_embeddings('embedding', 'House near downtown that are pet-friendly')::vector 
    LIMIT 10;
    ```

you'll get a result similar to this. Results may vary, as embedding vectors are not guaranteed to be deterministic:

    ```sql
    id |            name            
    ----+----------------------------
    27 | Modern Cozy Bedroom
    39 | 2 Private Rooms
    23 | 1905 Craftsman Home!
    2 | Lovely 2 BR Cottage
    12 | Private 1BR apartment
    35 | Quiet Room in house
    16 | Private garden room
    37 | City Bedroom and Den
    11 | Ballard private room
    15 | Cozy 1BD in Storybook Home
    ```
3. You may also project the <code spellcheck="false">description</code> column to be able to read the text of the matching rows whose descriptions were semantically similar. For example, this query returns the best match:

    ```sql
    SELECT 
    id, description 
    FROM listings 
    ORDER BY listing_vector <=> azure_openai.create_embeddings('embedding', 'House near downtown that are pet-friendly')::vector 
    LIMIT 1;
    ```

which prints something like:

    ```sql
    id          | description
    ------------+----------------------------
    27          | This comfy cozy bedroom with modern touches is the perfect spot to unwind at the end of a work day or spend time on a weekend trip! It comfortably fits two people. You'll love taking a walk to greenlake or nearby shops and being seconds from I-5! Our large home in the Wallingford neighborhood is very cozy. Filled with sentimental knick-knacks, handcrafted furniture, and some modern touches, you'll feel right at home. With large windows in the front room, there is a ton of light in the common spaces! Our Weimaraner (think gray lab with eeyore's personality) Franklin may or may not greet you when you get home, and you can be sure to find him napping most of his days away. Because this house is across the bridge from downtown, the parking on the street is free and easy to find any time of day! Our guest bedroom is on the 1st floor and right next door to the bathroom. In the basement you will find a washer and dryer that is not coin operated - so feel free to do your laundry!
    ```

to intuitively understand semantic search, observe that the description mentioned downtown, but doesn't actually contain the terms "dog". However it does highlight " [Weimaraner](https://www.bing.com/search?pglt=675&q=Weimaraner&cvid=5046cad165114b4992b90990e26cfb26&gs_lcrp=EgRlZGdlKgYIABBFGDkyBggAEEUYOTIICAEQ6QcY_FXSAQczMzBqMGoxqAIAsAIA&FORM=ANNAB1&PC=U531)" and " [gray lab](https://www.bing.com/search?q=gray+labrador&qs=AS&pq=gray+lab&sk=AS1CT1&sc=6-8&cvid=D9D6AAE3C365479C8B1C29E9C0F1E6D0&FORM=QBRE&sp=3&lq=0)" which is a breed of dog. Hence this listing is near downtown AND is most likely pet-friendly.

## Using Hybrid search

In this section, we will explore the concept of hybrid search, which combines both full-text search and semantic search capabilities. This approach enhances the search experience by leveraging the strengths of both methods, allowing for more accurate and relevant results.

### Perform a hybrid search query

1. With the following query we will perform a semantic and full text searcxh together. This searches for listing “similar to” the input phrase: ‘House with a beach view and pet-friendly’ AND have the phrase 'Queer Anne' which is a popular Seattle neighborhood.

    ```sql
    SELECT 
    id, name, description
    FROM listings
    
    WHERE textsearch @@ phraseto_tsquery('Queen Anne')
    ORDER BY listing_vector <=> azure_openai.create_embeddings('embedding', 'House near downtown that are pet-friendly')::vector
    LIMIT 5;
    ```

you'll get a result similar to this. Results may vary, as embedding vectors are not guaranteed to be deterministic:

```
    -[ RECORD 1 ]------------------------------------------------------------------------------------------------------------------------
    id          | 39
    name        | 2 Private Rooms
    description | Our craftsman has a daylight basement with two private bedrooms and one bathroom. It is located on a quiet street within easy walking distance from both Fremont and the upper Queen Anne neighborhood. It's less than a 10 minute drive downtown and there are convenient bus lines nearby. Our house offers two private bedrooms and bath in the daylight basement. One bedroom has a double bed the other has a queen bed. There is also a closet and dresser available for your things. We have a nice, fenced back yard where you are welcome to relax. The wifi is available throughout the house. We both love to travel and meet new people. We do work full time, so we won't be around a lot during the day, but we are always up for hanging out on the front porch after work for a happy hour drink. Our collie, Emma, is very mellow and friendly and she will certainly become your new friend. Our three bedroom craftsman house is on the north side of Queen Anne hill.
    -[ RECORD 2 ]------------------------------------------------------------------------------------------------------------------------
    id          | 45
    name        | Gorgeous Downtown Apt
    description | My beautiful 2 BR apartment in a restored triplex has gorgeous finishes and is just a short three miles from downtown Seattle and close to great restaurants, shopping and sightseeing. Stay in the city for much less than a downtown hotel! My apartment in the top floor of a triplex has 2 bedrooms, 1 bath, a living room, dining room, office and gorgeous kitchen, all with beautiful finishes, including clawfoot bathtub with shower, granite countertops, crown moldings, stainless steel appliances, an Italian gas stove and range, hardwood and heated tile floors, tall ceilings, large windows that provide tons of natural light and a full-size washer and dryer. The kitchen is well equipped for cooks. I live in the Queen Anne neighborhood, which is just three miles from all the local sites to see - Space Needle, Downtown, Belltown, Pike Place Market, and the downtown waterfront. My apartment is within walking distance of great restaurants, boutiques and coffee shops on Queen Anne Avenue.
    -[ RECORD 3 ]------------------------------------------------------------------------------------------------------------------------
    id          | 3
    name        | Open Airy Condo
    description | Designer home situated on Queen Anne Hill overlooking Magnolia. Enjoy custom furnishings, gourmet kitchen, spa bathroom, and a cozy bedroom. Easy access to downtown Seattle, Ballard and Fremont. Whole Foods is just a walk away. *all building construction is finished. During the summer, there was construction on the building but they are finished now. The building has been completely updated on the outside and my unit is completely remodeled too. Guest have access to the all the kitchen items and laundry area. All the drawers and closet in the bedroom are off limits. This is a really quiet neighborhood with plenty of free street parking. Great walking neighborhood with parks close by and great stair climbs. There is a very convenient bus line a block away that will take you anywhere in the city. In the neighborhood, there is plenty of free street parking. My neighbors are really quiet and the condo doesn't share any walls with other units. The bedroom has blackout curtains.
    -[ RECORD 4 ]------------------------------------------------------------------------------------------------------------------------
    id          | 42
    name        | 5 star Luxury + Tranquility
    description | Our house looks unassuming from the outside, a Post War epoch in a quiet old Seattle neighborhood. Follow a lovely entry to a secret sanctuary, with spa bath, steam shower and dreamy bed. Nest Queen Anne is perfect for a single guest or couple. Amenities include: A new private apartment with beautiful finishes – stone; marble and clear fir; Spa bathroom with radiant heated floor, soaking tub and steam shower; Kitchenette with gas cooktop, microwave, stainless steel fridge and espresso; Environmentally friendly hot water heating system; Elegant modern fireplace; Wifi and Ethernet connectivity; Cloud-like comfort in W Hotel queen bed, fitted with luxurious linens. High efficiency Washer and Dryer Ample free parking Polite dogs welcome with prior approval. There is a $60 charge for up to two pre-approved dogs, to cover additional cleaning costs generated by even tidy pets. Seattle is a destination for those seeking cultural and outdoor adventures, and new career opportunities.
    -[ RECORD 5 ]------------------------------------------------------------------------------------------------------------------------
    id          | 19
    name        | Retro Flat
    description | Turn right & a 10 minute walk takes you to dinner at one of the great Fremont cafes. Hang a louie & in 1.7 miles you'll be at the base of the Space Needle. All of Seattle is easily accessible on foot, bus or Uber from our place. This is a vintage flat in a classic building in Upper Queen Anne, Seattle. That's a nice way of saying it's an old apartment. It has brand new carpet and new paint. However, there is a slight smoker smell when you first enter, open up the windows and it dissipates. We want anyone who is highly sensitive to be aware before booking. We are not smokers and have stayed here many nights, our feeling is that we don't notice it after 15 minutes. The apartment may be old, but everything in it is brand new and clean. The best part of our place is how close you are to everything you want to see and do. Whether you are in town for business or vacation this spot is central to multiple destinations.
```

## Improving Performance with DiskANN vector index

DiskANN is a scalable approximate nearest neighbor search algorithm for efficient vector search at any scale. It offers high recall, high queries per second (QPS), and low query latency, even for billion-point datasets. This makes it a powerful tool for handling large volumes of data. [Learn more about DiskANN from Microsoft](https://www.microsoft.com/en-us/research/project/project-akupara-approximate-nearest-neighbor-search-for-large-scale-semantic-search/).

1. Now, you are ready to install the <code spellcheck="false">pg_diskann</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.

    ```sql
    CREATE EXTENSION IF NOT EXISTS pg_diskann;
    ```
2. Create the diskann index on a table column that contains vector data.

    ```sql
    CREATE INDEX listing_cosine_diskann ON listings USING diskann (listing_vector vector_cosine_ops);
    ```
3. Postgres will automatically decide when to use the DiskANN index. However, you can use to following command to force the use of the DiskANN index.

    ```sql
    
    SET LOCAL enable_seqscan TO OFF; -- force index usage
    SELECT 
    id, name, description
    FROM listings
    ORDER BY listing_vector <=> azure_openai.create_embeddings('embedding', 'House near downtown that are pet-friendly')::vector
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
    id, name, description
    FROM listings
    ORDER BY listing_vector <=> azure_openai.create_embeddings('embedding', 'House near downtown that are pet-friendly')::vector
    LIMIT 10;
    ```

you will get a result like this:

```sql
-[ RECORD 1 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN | Limit  (cost=479.20..484.14 rows=10 width=261) (actual time=1.207..1.270 rows=10 loops=1)
-[ RECORD 2 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN |   ->  Index Scan using listing_cosine_diskann on listings_diskann  (cost=479.20..1574.91 rows=2217 width=261) (actual time=1.206..1.268 rows=10 loops=1)
-[ RECORD 3 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN |         Order By: (description_vector <=> '[-0.016351668,-0.052834343,0.049271334,0.07909881,-0.028962178,...,-0.0071769194,0.004959582]'::vector)
-[ RECORD 4 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN | Planning Time: 70.183 ms
-[ RECORD 5 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------
QUERY PLAN | Execution Time: 1.298 ms
```

as you scale your data to millions of rows, DiskANN makes vector search more effcient.

# Bonus: Using Context on your RAG chatbot

We will explore how to effectively utilize context within your Retrieval-Augmented Generation (RAG) chatbot. Context is crucial for enhancing the chatbot’s ability to provide relevant and accurate responses, making interactions more meaningful for users.

The Retrieval-Augmented Generation (RAG) system is a sophisticated architecture designed to enhance user interactions through a seamless integration of various technological components. At its core, RAG is composed of:

- App UX (web app) for the user experience
- App server or orchestrator (integration and coordination layer)
- Azure PostgreSQL Flexible Server - [pgvector extension](https://github.com/pgvector/pgvector) (information retrieval system)
- Azure OpenAI (LLM for generative AI)


!IMAGE[Screenshot 2024-11-03 at 10.59.24 PM.png](instructions276019/Screenshot 2024-11-03 at 10.59.24 PM.png)

## Exploring Rental RAG application
We create a sample rental RAG application so you can explore with RAG application.

1. Go to our sample [RAG application](https://pg-rag-demo.azurewebsites.net/)

1. Enter your Azure OpenAI credentials in the sample app, to chat with the data.
!IMAGE[Screenshot 2024-11-03 at 10.38.56 PM.png](instructions276019/Screenshot 2024-11-03 at 10.38.56 PM.png)

1.  To find your credentials, navigate to your **<code spellcheck="false">Azure OpenAI</code>** resource in the [Azure portal](https://portal.azure.com/).
<br>

1. Once you are on the Azure OpenAI resource page, in the resource menu, under the **Resource Management** section, select **Keys and Endpoint**, then copy your endpoint and one of the available keys.
<br>
    ! [Screenshot of the Azure OpenAI service's Keys and Endpoints page is displayed, with the KEY 1 and Endpoint copy buttons highlighted by red boxes.](instructions276019/12-azure-openai-keys-and-endpoints.png)
<br>

    You can use either <code spellcheck="false">KEY 1</code> or <code spellcheck="false">KEY 2</code>. Always having two keys allows you to securely rotate and regenerate keys without causing service disruption.

1. Go back to the [RAG application](https://pg-rag-demo.azurewebsites.net/) and explore the RAG application.

    !IMAGE[Screenshot 2024-11-03 at 11.22.33 PM.png](instructions276019/Screenshot 2024-11-03 at 11.22.33 PM.png)

# Bonus: Cognitive Services options

Azure AI Language Services offer a comprehensive suite of tools designed to enhance text processing and understanding. Here’s a high-level overview of what these services can do:

| Service Name | Description | Use Case |
| ------------ | ----------- | -------- |
| <code spellcheck="false">detect_language</code> | Identifies the language of a given text with a confidence score. | Adapting content based on user language preferences. |
| <code spellcheck="false">extract_key_phrases</code> | Extracts important phrases to summarize main topics or themes. | Content analysis and improving search functionality. |
| <code spellcheck="false">linked_entities</code> | Identifies and links entities to a knowledge base for additional context. | Enhancing data understanding in chatbots and information retrieval. |
| <code spellcheck="false">recognize_entities</code> | Detects and categorizes named entities like people, organizations, and locations. | Extracting structured information from unstructured text. |
| <code spellcheck="false">recognize_pii_entities</code> | Identifies personally identifiable information (PII) in the text. | Safeguarding sensitive information for compliance with data protection regulations. |
| <code spellcheck="false">summarize_abstractive</code> | Generates concise summaries by rephrasing and condensing content. | Creating summaries of long documents, articles, or reports. |
| <code spellcheck="false">summarize_extractive</code> | Extracts key sentences to create a summary while preserving original wording. | Quickly summarizing content for reports and articles. |
| <code spellcheck="false">translate</code> | Translates text from one language to another, supporting a wide range of languages. | Facilitating communication across language barriers for global applications. |

### Examine the azure_cognitive schema

The <code spellcheck="false">azure_cognitive</code> schema provides the framework for directly interacting with Azure AI Services from your database. The Azure AI services integrations in the schema offer a rich set of AI Language features accessible directly from the database. The functionalities include sentiment analysis, language detection, key phrase extraction, entity recognition, text summarization, and translation. These capabilities are enabled through the [Azure AI Language service](https://learn.microsoft.com/azure/ai-services/language-service/overview).

1. To review all of the functions defined in a schema, you can use the [\df](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-META-COMMAND-DF-LC) as you have done previously. To view the functions in the <code spellcheck="false">azure_cognitive</code> schema, run:

    ```sql
    \df azure_cognitive.*
    ```
2. There are numerous functions defined in this schema, so the output from the [\df](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-META-COMMAND-DF-LC) can be difficult to read, so it is best to break it apart into smaller chunks. Run the following to look at just the <code spellcheck="false">analyze_sentiment()</code> function:

    ```sql
    \df azure_cognitive.analyze_sentiment
    ```

    in the output, observe that the function has three overloads, with one accepting a single input string and the other two expecting arrays of text. The output shows the function's schema, name, result data type, and argument data types. This information can help you understand how to use the function.
3. Repeat the above command, replacing the <code spellcheck="false">analyze_sentiment</code> function name with each of the following function names, to inspect all of the available functions in the schema:
    * <code spellcheck="false">detect_language</code>
    * <code spellcheck="false">extract_key_phrases</code>
    * <code spellcheck="false">linked_entities</code>
    * <code spellcheck="false">recognize_entities</code>
    * <code spellcheck="false">recognize_pii_entities</code>
    * <code spellcheck="false">summarize_abstractive</code>
    * <code spellcheck="false">summarize_extractive</code>
    * <code spellcheck="false">translate</code>

    For each function, inspect the various forms of the function and their expected inputs and resulting data types.
4. Besides functions, the <code spellcheck="false">azure_cognitive</code> schema also contains several composite types used as return data types from the various functions. It is imperative to understand the structure of the data type that a function returns so you can correctly handle the output in your queries. As an example, run the following command to inspect the <code spellcheck="false">sentiment_analysis_result</code> type:

    ```sql
    \dT+ azure_cognitive.sentiment_analysis_result
    ```
5. The output of the above command reveals the <code spellcheck="false">sentiment_analysis_result</code> type is a <code spellcheck="false">tuple</code>. You can dig further into the structure of that <code spellcheck="false">tuple</code> by running the following command to look at the columns contained within the <code spellcheck="false">sentiment_analysis_result</code> type:

    ```sql
    \d+ azure_cognitive.sentiment_analysis_result
    ```

    the output of that command should look similar to the following:

    ```sql
             Composite type "azure_cognitive.sentiment_analysis_result"
       Column  |   Type   | Collation | Nullable | Default | Storage | Description 
    ----------------+------------------+-----------+----------+---------+----------+-------------
     sentiment   | text      |     |     |    | extended | 
     positive_score | double precision |     |     |    | plain  | 
     neutral_score | double precision |     |     |    | plain  | 
     negative_score | double precision |     |     |    | plain  |
    ```

    the <code spellcheck="false">azure_cognitive.sentiment_analysis_result</code> is a composite type containing the sentiment predictions of the input text. It includes the sentiment, which can be positive, negative, neutral, or mixed, and the scores for positive, neutral, and negative aspects found in the text. The scores are represented as real numbers between 0 and 1. For example, in (neutral, 0.26, 0.64, 0.09), the sentiment is neutral, with a positive score of 0.26, neutral of 0.64, and negative at 0.09.
6. As with the <code spellcheck="false">azure_openai</code> functions, to successfully make calls against Azure AI Services using the <code spellcheck="false">azure_ai</code> extension, you must provide the endpoint and a key for your **Azure AI Language service**.
<br>
    a. Using the same browser tab where the Cloud Shell is open, minimize or restore the Cloud Shell pane, and then navigate to your <code spellcheck="false">Language</code> service resource in the [Azure portal](https://portal.azure.com/).
<br>
    b. In the resource menu, under the **Resource Management** section, select **Keys and Endpoint**.
<br>
    ! [Screenshot of the Azure Language service's Keys and Endpoints page is displayed, with the KEY 1 and Endpoint copy buttons highlighted by red boxes.](instructions276019/12-azure-language-service-keys-and-endpoints.png)
7. Copy your endpoint and access key values, and replace the <code spellcheck="false">{endpoint}</code> and <code spellcheck="false">{api-key}</code> tokens with values you copied from the Azure portal. Maximize the Cloud Shell again, and run the commands from the <code spellcheck="false">psql</code> command prompt in the Cloud Shell to add your values to the configuration table.

    ```sql
    SELECT azure_ai.set_setting('azure_cognitive.endpoint', '{endpoint}');
    ```

    ```sql
    SELECT azure_ai.set_setting('azure_cognitive.subscription_key', '{api-key}');
    ```
8. Now, execute the following query to analyze the sentiment of a couple of reviews:

    ```sql
    SELECT
      id,
      comments,
      azure_cognitive.analyze_sentiment(comments, 'en') AS sentiment
    FROM reviews
    WHERE id IN (1, 3);
    ```

    observe the <code spellcheck="false">sentiment</code> values in the output, <code spellcheck="false">(mixed,0.71,0.09,0.2)</code> and <code spellcheck="false">(positive,0.99,0.01,0)</code>. These represent the <code spellcheck="false">sentiment_analysis_result</code> returned by the <code spellcheck="false">analyze_sentiment()</code> function in the above query. The analysis was performed over the <code spellcheck="false">comments</code> field in the <code spellcheck="false">reviews</code> table.

## Inspect the Azure ML schema

The <code spellcheck="false">azure_ml</code> schema lets functions connect to Azure ML services directly from your database.

1. To review the functions defined in a schema, you can use the [\df](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-META-COMMAND-DF-LC). To view the functions in the <code spellcheck="false">azure_ml</code> schema, run:

    ```sql
    \df azure_ml.*
    ```

    in the output, observe there are two functions defined in this schema, <code spellcheck="false">azure_ml.inference()</code> and <code spellcheck="false">azure_ml.invoke()</code>, the details of which are displayed below:

    ```sql
                  List of functions
    -----------------------------------------------------------------------------------------------------------
    Schema       | azure_ml
    Name        | inference
    Result data type  | jsonb
    Argument data types | input_data jsonb, deployment_name text DEFAULT NULL::text, timeout_ms integer DEFAULT NULL::integer, throw_on_error boolean DEFAULT true, max_attempts integer DEFAULT 1, retry_delay_ms integer DEFAULT 1000
    Type        | func
    ```

    the <code spellcheck="false">inference()</code> function uses a trained machine learning model to predict or generate outputs based on new, unseen data.
<br>
    By providing an endpoint and key, you can connect to an Azure ML deployed endpoint like you connected to your Azure OpenAI and Azure AI Services endpoints. Interacting with Azure ML requires having a trained and deployed model, so it is out of scope for this exercise, and you are not setting up that connection to try it out here.