
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