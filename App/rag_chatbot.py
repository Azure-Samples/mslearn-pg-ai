import streamlit as st
import json
import os
import pandas as pd
from openai import AzureOpenAI
from dotenv import load_dotenv
import psycopg
import time

# Load environment variables from .env file
load_dotenv()
endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
api_key = os.getenv("AZURE_OPENAI_API_KEY")
deployment = os.getenv("DEPLOYMENT_NAME", "gpt-4o")

# Streamlit configuration
st.set_page_config(page_title="RAG Chatbot with PostgreSQL", page_icon="⚖️", layout="wide")

# UI elements
def render_cta_link(url, label, font_awesome_icon):
    st.markdown('<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">', unsafe_allow_html=True)
    button_code = f'''<a href="{url}" target=_blank><i class="fa {font_awesome_icon}"></i> {label}</a>'''
    return st.markdown(button_code, unsafe_allow_html=True)

@st.cache_resource
def get_db_connection():
    conn_str = os.getenv("AZURE_PG_CONNECTION")
    return psycopg.connect(conn_str)
 
def enable_sidebar():
    # Sidebar for API key and connection settings
    with st.sidebar:
        st.header("Configuration Settings")

        # Azure OpenAI API Configuration
        endpoint = st.text_input("Azure OpenAI Endpoint", value=os.getenv("AZURE_OPENAI_ENDPOINT"))
        api_key = st.text_input("API Key", type="password", value=os.getenv("AZURE_OPENAI_API_KEY"))
        deployment = st.text_input("Model Deployment", value=os.getenv("DEPLOYMENT_NAME", "gpt-4o"))

        # Initialize Azure OpenAI Client and store in session state
        if st.button("Connect to Azure OpenAI", on_click=get_db_connection.clear):
            try:
                client = AzureOpenAI(
                    azure_endpoint=endpoint,
                    api_key=api_key,
                    api_version="2024-05-01-preview",
                )
                st.session_state.client = client  # Store client in session state
                st.success("Connected to Azure OpenAI!")
            except Exception as e:
                st.error(f"Failed to connect to Azure OpenAI: {e}")

        render_cta_link(url="#", label="Docs", font_awesome_icon="fa-book")
        render_cta_link(url="#", label="Blog", font_awesome_icon="fa-windows")
        render_cta_link(url="https://aka.ms/pg-ai-ignite-lab", label="GitHub", font_awesome_icon="fa-github")

# Display PostgreSQL logo at the top of the page
st.image("https://sqltune.files.wordpress.com/2023/07/azure-database-for-postgresql-bigger.png", width=50)

# Streamlit UI setup
st.title("US Law Dataset Chatbot")
st.subheader("Semantic Re-ranker search enhanced by RAG (Retrieval Augmented Generation) on structured data")

# Display additional description or instructions for the users
st.write(
    """
    This demo leverages **[RAG (Retrieval Augmented Generation)](https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview)** on **PostgreSQL** for structured data retrieval and **Azure OpenAI** for enhanced understanding.
    Upload initial query results in JSON format, then interact with the AI chatbot to ask follow-up questions.
    """
)

# Header for the application
st.title("RAG Chatbot Demo with PostgreSQL")

enable_sidebar()


# Check if client is available in session state
if "client" in st.session_state:
    client = st.session_state.client
else:
    client = None

# File uploader for loading initial query results
st.subheader("Step 1: Query Data with Vector Search")

# Handler functions
def embedding_query(text_input):
    client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version="2024-02-01",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
        )

	# Generate embedding for each text input
    response = client.embeddings.create(
		input=text_input,
		model="text-embedding-3-small"  # Use the appropriate model
	)
    # Parse the JSON string
    json_response = response.model_dump_json(indent=2)
    parsed_response = json.loads(json_response)

	# Extract the embedding key
    emb = parsed_response['data'][0]['embedding']

    # Query the database for similar listings
    query = """
    SELECT name, opinion FROM cases
	ORDER BY opinions_vector <=> %s::vector
	LIMIT 10;
    """

    conn = get_db_connection()
    with conn.cursor() as cur:
        # Execute the query
        start_time = time.time()
        cur.execute(query, (emb,))
        # Fetch the results
        results = cur.fetchall()
        end_time = time.time()
        cur.close()

    return pd.DataFrame(results, columns=["name", "opinion"])


# Global variable to store initial context
if "initial_context_data" not in st.session_state:
    st.session_state.initial_context_data = None


if vector_search := st.text_input("Enter a text input to generate an embedding", "Water leaking into the apartment from the floor above"):
    st.session_state.initial_context_data = embedding_query(vector_search)

    st.write("Vector search query results, you can chat with this data:")
    st.dataframe(st.session_state.initial_context_data)

# Chatbot interaction section
st.subheader("Step 2: Ask Follow-up Questions")

with st.expander("Example Question", expanded=True):
    st.code("""
        Water leaking into the apartment from the floor above. What are the prominent legal precedents from cases in Washington on this problem?
        """, language="text")

if client is None:
    st.error("Azure OpenAI client is not initialized. Please enter connection in the sidebar.")
else:
    # Initialize a session state variable to store chat history
    if "messages" not in st.session_state:
        st.session_state.messages = []


    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])

    if question := st.chat_input("Ask a questions about your data?"):

        st.session_state.messages.append(
                {"role": "system", "content": "You are an AI assistant that helps answer questions based on initial context data."})

        st.session_state.messages.append(
                {"role": "user",  "content": f"DOCUMENT: {st.session_state.initial_context_data} QUESTION: {question}"})

        with st.chat_message("user"):
            st.markdown(question)

        with st.chat_message("assistant"):
            stream = client.chat.completions.create(
                model=deployment,
                messages=[
                    {"role": m["role"], "content": m["content"]}
                    for m in st.session_state.messages
                ],
                stream=True,
            )
            response = st.write_stream(stream)
        st.session_state.messages.append({"role": "assistant", "content": response})