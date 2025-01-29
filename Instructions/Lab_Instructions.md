@lab.Title

Login to your VM with the following credentials...

**Username: ++@lab.VirtualMachine(Win11-Pro-Base-VM).Username++**

**Password: +++@lab.VirtualMachine(Win11-Pro-Base-VM).Password+++**

# Table of Contents

1. [Part 0 - Log into Azure](#part-0---log-into-azure)
1. [Part 1 - Getting started with AI on Azure PostgreSQL flexible server](#part-1---getting-started-with-ai-on-azure-postgresql-flexible-server)
    1. [Clone Lab repo](#clone-lab-repo)
    1. [Connect to your database using psql in the Azure Cloud Shell](#connect-to-your-database-using-psql-in-the-azure-cloud-shell)
    1. [Populate the database with sample data](#populate-the-database-with-sample-data)
    1. [Setting up pgAdmin](#setting-up-pgadmin)
    1. [Install and configure the `azure_ai` extension](#install-and-configure-the-azure_ai-extension)
1. [Part 2 - Using AI-driven features in Postgres](#part-2---using-ai-driven-features-in-postgres)
    1. [Using Pattern matching for queries](#using-pattern-matching-for-queries)
    1. [Using Semantic Search and DiskANN](#using-semantic-search-and-diskann-index)
1. [Part 3 - Implementing a RAG chatbot](#part-3---implementing-a-rag-chatbot)
    1. [Exploring Cases RAG application](#exploring-cases-rag-application)


# Part 1 - Getting started with AI on Azure PostgreSQL flexible server

## Clone Lab repo

1. Open a web browser and navigate to the [Azure portal](https://portal.azure.com/).

2. Select the **Cloud Shell** icon in the Azure portal toolbar to open a new [Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview) pane at the bottom of your browser window.

    ![Screenshot of the Azure toolbar with the Cloud Shell icon highlighted by a red box.](./instructions276019/12-portal-toolbar-cloud-shell.png)

    If prompted, select the required options to open a *Bash* shell. If you have previously used a *PowerShell* console, switch it to a *Bash* shell. 
    ![Screenshot of the Azure toolbar with the Cloud Shell icon highlighted by a red box.](./instructions276019/select_bash.png)

    Also pick *No storage account required* and select your subscription.
    ![Screenshot of the Azure toolbar with the Cloud Shell icon highlighted by a red box.](./instructions276019/select_storage.png)

3. At the Cloud Shell prompt, enter the following to clone the GitHub repo containing exercise resources:

    ```
    git clone https://github.com/Azure-Samples/mslearn-pg-ai.git
    ```

## Running setup from needed resources

0. Skipped these steps if you already have a Postgres Database and OpenAI resource. 

1. Run the following commands

    Set the Subscription ID and create a Resource group for this Lab
    ```sh
    REGION=eastus
    RG_NAME=rg-learn-postgresql-ai-$REGION
    ADMIN_PASSWORD=passw0rd

    az account set --subscription 5c5037e5-d3f1-4e7b-b3a9-f6bf94902b30
    az group create --name $RG_NAME --location $REGION
    ```

    Make sure you create in a region with quota for **OpenAI**
    ```sh
    az deployment group create --resource-group $RG_NAME --template-file "deploy.bicep" --parameters restore=false adminLogin=pgAdmin adminLoginPassword=$ADMIN_PASSWORD
    ```


2. Wait 10-15 mins for Azure to deploy your **OpenAI and Postgres** resource.

## Connect to your database using psql in the Azure Cloud Shell

In this task, you connect to the <code spellcheck="false">cases</code> database on your Azure Database for PostgreSQL flexible server using the [psql command-line utility](https://www.postgresql.org/docs/current/app-psql.html) from the [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview).

1. In the [Azure portal](https://portal.azure.com/), navigate to **Resource Groups** and select the resource group with the your Postgres resource
    ![Screenshot of the Azure Portal with Resource groups selected](./instructions276019/azure-portal.png)
    
2. In that resource group select the precreated **Azure Database for PostgreSQL flexible server** instance.
    ![Screenshot of the Resource group with Azure Database for PostgreSQL flexible server selected](./instructions276019/database_in_azure_new.png)

3. In the resource menu, under **Settings**, select **Databases** select **Connect** for the <code spellcheck="false">cases</code> database.
<br>
    ![Screenshot of the Azure Database for PostgreSQL Databases page. Databases and Connect for the cases database are highlighted by red boxes.](./instructions276019/postgresql-cases-database-connect.png)

    If you don't you don't have this table, please create a `cases` table in your database. 


>[!hint]  This step will ask you to launch the new cloud shell instance, this is fine, you will not lose the previously cloned content.

4. At the "Password for user pgAdmin" prompt in the Cloud Shell, enter the password for the **pgAdmin** login.
    > [!alert]
    **MAKE SURE YOU TYPE IN YOUR PASSWORD, COPY & PASTE MAY NOT WORK**

    if you used the setup script in `Running setup from needed resources` section:

    **Password:** `passw0rd`

    if you used your own DB:

    **Password:** Enter your password

    Once logged in, the <code spellcheck="false">psql</code> prompt for the <code spellcheck="false">cases</code> database is displayed.

5. Throughout the remainder of this exercise, you continue working in the Cloud Shell, so it may be helpful to expand the pane within your browser window by selecting the **Maximize** button at the top right of the pane.
<br>
    ![Screenshot of the Azure Cloud Shell pane with the Maximize button highlighted by a red box.](./instructions276019/azure-cloud-shell-pane-maximize-new.png)

## Populate the database with sample data

Before you explore the <code spellcheck="false">azure_ai</code> extension, add a couple of tables to the <code spellcheck="false">cases</code> database and populate them with sample data so you have information to work with as you review the extension's functionality.

1. Run the following commands to create the <code spellcheck="false">cases</code> tables for storing us cases law data :

    ```
    \i mslearn-pg-ai/Setup/SQLScript/initialize_dataset.sql;
    ```

### Explore Database

1. When working with <code spellcheck="false">psql</code> in the Cloud Shell, enabling the extended display for query results may be helpful, as it improves the readability of output for subsequent commands. Execute the following command to allow the extended display to be automatically applied.
ata :

    `\x auto`

1. First we will retrieve a sample of data from the cases table in our cases dataset. This allows us to examine the structure and content of the data stored in the database.
ata :

   `SELECT * FROM cases
    LIMIT 1;`

===
## Setting up PGAdmin
Now you have explored the database in Azure and configured the Azure OpenAI endpoints. We are going to switch over to working in [pgAdmin](https://www.pgadmin.org/). pgAdmin is the most popular and feature-rich open-source administration and development platform for PostgreSQL, the most advanced open-source database in the world.

Using pgAdmin makes it easier to explore the output and understand how the AI features work in PostgreSQL. 

1. In a new tab, open the [Azure portal](https://portal.azure.com/), navigate to **Resource Groups** and select the resource group with the name **ResourceGroup1**
    ![Screenshot of the Azure Portal with Resource groups selected](./instructions276019/azure-portal.png)

1. In that resource group select the precreated **Azure Database for PostgreSQL flexible server** instance.
    ![Screenshot of the Resource group with Azure Database for PostgreSQL flexible server selected](./instructions276019/database_in_azure_new.png)

1. In the resource menu of your Azure Database for PostgreSQL Flexible Server instance, under **Settings**, select **Connect** and follow instructions in Azure Portal on how to connect to pgAdmin.
![Connecting to pgAdmin from Azure](./instructions276019/pgAdmin-from-azure.png)

    >[!tip] pgAdmin is already installed on your VM, you with find a *blue elephant icon* on your desktop.

    1. **Open pgAdmin 4:** Launch the pgAdmin 4 application on your computer. *This should be on your desktop.*

    1. **Register a new server:** In the pgAdmin 4 interface, *right-click* on "Servers" in the left-side browser tree, and select **"Register”** -> **“Server"**

    1. **Configure server details:** In the **"Register - Server"** window. Make sure:
        - **Hostname**: Find this in Azure Portal
        - **Maintenance database**: `cases`
        - **Username**: `pgAdmin`
        - **Password**: `passw0rd`
        - **Port**: `5432`

    1. **Save the configuration:** Click the "Save" button to save the server registration. pgAdmin 4 will now establish a connection to your Azure Database for PostgreSQL Flexible Server.

    1. **Access the database:** Once connected, you can expand the server in the browser tree to view databases, schemas, and tables. You can also interact with the server using the built-in query tool and manage your database objects.

1. Click the Query tool button on the top left to open the query tool and start working with queries in the upcoming sections.

    ![pgAdmin Query tool usage](./instructions276019/open-cases-database.png)


## Install and configure the <code spellcheck="false">azure_ai</code> extension

>[!alert] Make sure you are using **pgAdmin** for the following steps.

Before using the <code spellcheck="false">azure_ai</code> extension, you must install it into your database and configure it to connect to your Azure AI Services resources. The <code spellcheck="false">azure_ai</code> extension allows you to integrate the Azure OpenAI and Azure AI Language services into your database. To enable the extension in your database, follow these steps:

1. Execute the following command in **pgAdmin** to verify that the <code spellcheck="false">azure_ai</code>, <code spellcheck="false">vector</code>, <code spellcheck="false">age</code> and <code spellcheck="false">pg_diskann</code> extensions were successfully added to your server's *allowlist* by the Bicep deployment script you ran when setting up your environment:

```sql
SHOW azure.extensions;
```

The command displays the list of extensions on the server's *allowlist*. If everything was correctly installed, your output must include <code spellcheck="false">azure_ai</code>, <code spellcheck="false">vector</code>, <code spellcheck="false">age</code> and <code spellcheck="false">pg_diskann</code> like this:

```sql-nocopy
 azure.extensions 
------------------
 azure_ai,vector,age,pg_diskann
```

if you don't have these run the following:

```
CREATE EXTENSION IF NOT EXISTS azure_ai;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_diskann;
```

Before an extension can be installed and used in an Azure Database for PostgreSQL flexible server database, it must be added to the server's *allowlist*, as described in [how to use PostgreSQL extensions](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions).


2. Now, you are ready to install the <code spellcheck="false">azure_ai</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.


### Explore the Azure AI schema

The <code spellcheck="false">azure_ai</code> schema provides the framework for directly interacting with Azure AI and ML services from your database. It contains functions for setting up connections to those services and retrieving them from the <code spellcheck="false">settings</code> table, which is also hosted in the same schema. The <code spellcheck="false">settings</code> table provides secure storage in the database for endpoints and keys associated with your Azure AI and ML services.

1. Review the functions defined in the  <code spellcheck="false">azure_ai</code> schema. 
    - Review the schema in the [Microsoft documention](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/generative-ai-azure-overview#configure-the-azure_ai-extension)

         Schema |  Name  | Result data type | Argument data types | Type 
        ----------|-------------|------------------|----------------------|------
         azure_ai | get_setting | text      | key text      | func
         azure_ai | set_setting | void      | key text, value text | func
         azure_ai | version  | text      |           | func


> [!knowledge] Because the connection information for Azure AI services, including API keys, is stored in a configuration table in the database, the <code spellcheck="false">azure_ai</code> extension defines a role called <code spellcheck="false">azure_ai_settings_manager</code> to ensure this information is protected and accessible only to users who have been assigned that role. This role enables reading and writing of settings related to the extension. Only members of the <code spellcheck="false">azure_ai_settings_manager</code> role can invoke the <code spellcheck="false">azure_ai.get_setting()</code> and <code spellcheck="false">azure_ai.set_setting()</code> functions. In an Azure Database for PostgreSQL flexible server, all admin users (those with the <code spellcheck="false">azure_pg_admin</code> role assigned) are also assigned the <code spellcheck="false">azure_ai_settings_manager</code> role.
    
2. To demonstrate how you use the <code spellcheck="false">azure_ai.set_setting()</code> and <code spellcheck="false">azure_ai.get_setting()</code> functions, configure the connection to your Azure OpenAI account.
<br>

    a. Using the same browser tab where your Cloud Shell is open, minimize or restore the Cloud Shell pane, then navigate to your **<code spellcheck="false">Azure OpenAI</code>** resource in the [Azure portal](https://portal.azure.com/).
<br>

    b. Once you are on the Azure OpenAI resource page, in the resource menu, under the **Resource Management** section, select **Keys and Endpoint**, then copy your endpoint and one of the available keys.
<br>
    ![Screenshot of the Azure OpenAI service's Keys and Endpoints page is displayed, with the KEY 1 and Endpoint copy buttons highlighted by red boxes.](./instructions282962/azure-openai-keys-and-endpoints.png)
<br>
    You can use either <code spellcheck="false">KEY 1</code> or <code spellcheck="false">KEY 2</code>. Always having two keys allows you to securely rotate and regenerate keys without causing service disruption.
3. Once you have your endpoint and key, maximize the *pgAdmin* window, then use the commands below to add your values to the configuration table. Ensure you replace the <code spellcheck="false">{endpoint}</code> and <code spellcheck="false">{api-key}</code> tokens with the values you copied from the Azure portal.

    ```sql
    SELECT azure_ai.set_setting('azure_openai.endpoint', '{endpoint}');
    SELECT azure_ai.set_setting('azure_openai.subscription_key', '{api-key}');
    ```

    When you add the key, the command should look like: 
    * *SELECT azure_ai.set_setting('azure_openai.endpoint', 'https://oai-learn-eastus-123456.openai.azure.com/');*
    * *SELECT azure_ai.set_setting('azure_openai.subscription_key', 'd33a123456781');*

4. You can verify the settings written into the <code spellcheck="false">azure_ai.settings</code> table using the <code spellcheck="false">azure_ai.get_setting()</code> function in the following queries:

    ```sql
    SELECT azure_ai.get_setting('azure_openai.endpoint');
    SELECT azure_ai.get_setting('azure_openai.subscription_key');
    ```

    the <code spellcheck="false">azure_ai</code> extension is now connected to your Azure OpenAI account.

### Review the Azure OpenAI schema

The <code spellcheck="false">azure_openai</code> schema provides the ability to integrate the creation of vector embedding of text values into your database using Azure OpenAI. Using this schema, you can [generate embeddings with Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/how-to/embeddings) directly from the database to create vector representations of input text, which can then be used in vector similarity searches, as well as consumed by machine learning models. The schema contains a single function, <code spellcheck="false">create_embeddings()</code>, with two overloads. One overload accepts a single input string, and the other expects an array of input strings.

1. Review the details of the functions in the <code spellcheck="false">azure_openai</code> schema. 

    * Review in the [Microsoft documention](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/generative-ai-azure-openai#configure-openai-endpoint-and-key)

    The docs will shows the two overloads of the <code spellcheck="false">azure_openai.create_embeddings()</code> function, allowing you to review the differences between the two versions of the function and the types they return. 

2. To provide a simplified example of using the function, run the following query, which creates a vector embedding for a sample query. The <code spellcheck="false">deployment_name</code> parameter in the function is set to <code spellcheck="false">embedding</code>, which is the name of the deployment of the <code spellcheck="false">text-embedding-3-small</code> model in your Azure OpenAI service:

    ```sql
    SELECT azure_openai.create_embeddings('text-embedding-3-small', 'Sample text for PostgreSQL Lab') AS vector;
    ```

the output looks similar to this:


```sql-nocopy
 id |   vector
----+-----------------------------------------------------------
  1 | {0.020068742,0.00022734122,0.0018286322,-0.0064167166,...}
```


for brevity, the vector embeddings are abbreviated in the above output.

[Embeddings](https://learn.microsoft.com/azure/postgresql/flexible-server/generative-ai-overview#embeddings) are a concept in machine learning and natural language processing (NLP) that involves representing objects such as words, documents, or entities, as [vectors](https://learn.microsoft.com/azure/postgresql/flexible-server/generative-ai-overview#vectors) in a multi-dimensional space. Embeddings allow machine learning models to evaluate how closely two pieces of information are related. This technique efficiently identifies relationships and similarities between data, allowing algorithms to identify patterns and make accurate predictions.

The <code spellcheck="false">azure_ai</code> extension allows you to generate embeddings for input text. To enable the generated vectors to be stored alongside the rest of your data in the database, you must install the <code spellcheck="false">vector</code> extension by following the guidance in the [enable vector support in your database](https://learn.microsoft.com/azure/postgresql/flexible-server/how-to-use-pgvector#enable-extension) documentation. However, that is outside of the scope of this exercise.

===
# Part 2 - Using AI-driven features in Postgres

In this section, we will explore how to leverage AI-driven features within PostgreSQL to enhance data processing and analysis. These features can help automate tasks, improve data insights, and provide advanced functionalities that traditional SQL queries may not offer.

>[!alert] Make sure you are using **pgAdmin** for the following steps.

## Using Pattern matching for queries

We will explore how to use the <code spellcheck="false">ILIKE</code> clause in SQL to perform case-insensitive searches within text fields. This is particularly useful when you want to find specific cases or reviews that contain certain keywords.

1. We will searching for cases mentioning `"Water leaking into the apartment from the floor above."`

    ```sql
    SELECT id, name, opinion
    FROM cases
    WHERE opinion ILIKE '%Water leaking into the apartment from the floor above';
    ```

    You'll get a result similar to this:

    ```sql-nocopy
    id | name | opinion
    ----+------+---------
    (0 rows)
    ```

However, it fall short as the exact words are not mentioned in the opinion. As you can see there are no results for what to user wants to find. We need to try another appoach.

## Using Semantic Search and DiskANN Index

In this section, we will focus on generating and storing embedding vectors, which are crucial for performing semantic searches in our dataset. Embedding vectors represent data points in a high-dimensional space, allowing for efficient similarity searches and advanced analytics.

### Create, store and index embedding vectors

Now that we have some sample data, it's time to generate and store the embedding vectors. The <code spellcheck="false">azure_ai</code> extension makes calling the Azure OpenAI embedding API easy.

1. Now, you are ready to install the <code spellcheck="false">vector</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.

    ```sql
    CREATE EXTENSION IF NOT EXISTS vector;
    ```
1. Add the embedding vector column.
<br>
    The <code spellcheck="false">text-embedding-3-small</code> model is configured to return 1,536 dimensions, so use that for the vector column size.

    ```sql
    ALTER TABLE cases ADD COLUMN opinions_vector vector(1536);
    ```
1. Generate an embedding vector for the opinion of each case by calling Azure OpenAI through the create_embeddings user-defined function, which is implemented by the azure_ai extension:

    ```sql
    UPDATE cases
    SET opinions_vector = azure_openai.create_embeddings('text-embedding-3-small',  name || LEFT(opinion, 8000), max_attempts => 5, retry_delay_ms => 500)::vector
    WHERE opinions_vector IS NULL;
    ```

    >[!alert] This may take several minutes, depending on the available quota.

1. Adding an [DiskANN Vector Index](https://aka.ms/pg-diskann-docs) to improve vector search speed. 

    Using [DiskANN Vector Index in Azure Database for PostgreSQL](https://aka.ms/pg-diskann-blog) - DiskANN is a scalable approximate nearest neighbor search algorithm for efficient vector search at any scale. It offers high recall, high queries per second (QPS), and low query latency, even for billion-point datasets. This makes it a powerful tool for handling large volumes of data. [Learn more about DiskANN from Microsoft](https://aka.ms/pg-diskann-docs). Now, you are ready to install the <code spellcheck="false">pg_diskann</code> extension using the [CREATE EXTENSION](https://www.postgresql.org/docs/current/sql-createextension.html) command.

    ```sql
    CREATE EXTENSION IF NOT EXISTS pg_diskann;
    ```
1. Create the diskann index on a table column that contains vector data.

    ```sql
    CREATE INDEX cases_cosine_diskann ON cases USING diskann(opinions_vector vector_cosine_ops);
    ```
    as you scale your data to millions of rows, DiskANN makes vector search more effcient.

1. See an example vector by running this query:

    ```sql
    SELECT opinions_vector FROM cases LIMIT 1;
    ```

    you will get a result similar to this, but with 1536 vector columns. The output will take up alot of your screen, just hit enter to move down the page to see all of the output:

    ```sql-nocopy
    opinions_vector | 
    [-0.0018742813,-0.04530062,0.055145424, ... ]
    ```

### Perform a semantic search query

Now that you have listing data augmented with embedding vectors, it's time to run a semantic search query. To do so, get the query string embedding vector, then perform a cosine search to find the cases whose opinions that are most semantically similar to the query.

1. Generate the embedding for the query string.

    ```sql
    SELECT azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.');
    ```

    you will get a result like this:

    ```sql
    create_embeddings | 
    {-0.0020871465,-0.002830255,0.030923981, ...}
    ```
2. Use the embedding in a cosine search (<code spellcheck="false"><=></code> represents cosine distance operation), fetching the top 10 most similar cases to the query.

    ```sql
    SELECT 
        id, name 
    FROM 
        cases
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector 
    LIMIT 10;
    ```

    You'll get a result similar to this. Results may vary, as embedding vectors are not guaranteed to be deterministic:

    ```sql-nocopy
        id    |                          name                          
        ---------+--------------------------------------------------------
        615468 | Le Vette v. Hardman Estate
        768356 | Uhl Bros. v. Hull
        8848167 | Wilkening v. Watkins Distributors, Inc.
        558730 | Burns v. Dufresne
        594079 | Martindale Clothing Co. v. Spokane & Eastern Trust Co.
        1086651 | Bach v. Sarich
        869848 | Tailored Ready Co. v. Fourth & Pike Street Corp.
        2601920 | Pappas v. Zerwoodis
        4912975 | Conradi v. Arnold
        1091260 | Brant v. Market Basket Stores, Inc.
        (10 rows)

    ```
3. You may also project the <code spellcheck="false">opinion</code> column to be able to read the text of the matching rows whose opinions were semantically similar. For example, this query returns the best match:

    ```sql
    SELECT 
    id, opinion
    FROM cases
    ORDER BY opinions_vector <=> azure_openai.create_embeddings('text-embedding-3-small', 'Water leaking into the apartment from the floor above.')::vector 
    LIMIT 1;
    ```

which prints something like:

```sql-nocopy
    id          | opinion
    ------------+----------------------------
    615468       | "Morris, J.\nAppeal from an order of nonsuit and dismissal, in an action brought by a tenant to recover damages for injuries to her goods, caused by leakage of water from an upper story. The facts, so far as they are pertinent to our inquiry, are about these: The Hardman Estate is the owner of a building on Yesler Way, in Seattle, the lower portion of which is divided into storerooms, and the upper is used as a hotel. Appellant, who was engaged in the millinery business, occupied one of the storerooms under a written lease...."
```

To intuitively understand semantic search, observe that the opinion mentioned doesn't actually contain the terms <code spellcheck="false">"Water leaking into the apartment from the floor above."</code>. However it does highlight a document with a section that says <code spellcheck="false">"nonsuit and dismissal, in an action brought by a tenant to recover damages for injuries to her goods, caused by leakage of water from an upper story"</code> which is similar.

===
#  Part 3 - Implementing a RAG chatbot

We will explore how to effectively utilize context within your Retrieval-Augmented Generation (RAG) chatbot. Context is crucial for enhancing the chatbot’s ability to provide relevant and accurate responses, making interactions more meaningful for users.

## What is RAG
The Retrieval-Augmented Generation (RAG) system is a sophisticated architecture designed to enhance user interactions through a seamless integration of various technological components. At its core, RAG is composed of:

1. Raw data source, is chunked for embedding
2. Data is embedded with OpenAI embedding model and saved in Postgres
3. User can send in query from Application
4. Query is embedding with OpenAI embedding model and vectorized for search
5. Vector Search on Postgres using [pgvector extension](https://github.com/pgvector/pgvector)
6. Retrieved context is stored to be used in the prompt to an LLM (i.e GPT 4o)
7. Prompt and the retrieved context is fed into an LLM (i.e GPT 4o) for improved chat results
8. Generate output is fed to teh Chat application
9. User see the Chat Response
10. All responses can be tracked for future evaluation.

![Screenshot about RAG](./instructions282962/new-rag-diagram.png)

## Building simple RAG application with Legal Data
We already created a sample Legal Cases RAG application so you can explore RAG application. This application uses **larger subset of legal cases data** that what you have explored in this lab, to provide more in-depth answers.

1. Open VSCode

1. Clone the repo and correct branch.

1. Go to this file `App/rag_chatbot.py` file. We will discuss the important RAG elements (Vector Search, context setting, LLM) and how they were implemented.

### Setting up the environment file

Since the local app uses OpenAI models, you should first deploy it for the optimal experience.

1. Copy `.env.sample` into a `.env` file.
2. To use Azure OpenAI, fill in the values of `AZURE_OPENAI_ENDPOINT` and `AZURE_OPENAI_API_KEY` based on the deployed values.
3. Fill in the connection string value for `AZURE_PG_CONNECTION`, You can find this in the [Azure Portal](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/connect-python?tabs=bash%2Cpassword#add-authentication-code)

### Install dependencies
Install required Python packages and [streamlit application](https://docs.streamlit.io/get-started):

```python
python3 -m venv .diskann
source .diskann/bin/activate
```

```bash
cd src
pip install -r requirements.txt
```

### Running the application
From root directory

```bash
cd App
streamlit run rag_chatbot.py
```

When run locally run looking for website at http://localhost:8501/

