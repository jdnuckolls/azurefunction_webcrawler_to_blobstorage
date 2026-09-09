# Azure AI Search integrated vectorization

This project writes normalized website documents to Azure Blob Storage. Azure AI Search can then pull those JSON blobs, split `content` into chunks, generate embeddings, and populate a vector-enabled search index.

## Flow

```text
Website
  -> native crawler, Firecrawl, or Apify
  -> normalized JSON blobs
  -> Azure AI Search Blob indexer
  -> Text Split skill
  -> Azure OpenAI embedding skill
  -> hybrid/vector search index
  -> Foundry IQ, agent, or custom RAG chatbot
```

## Templates

The `infra/azure-search` folder contains starter templates:

| File | Purpose |
| --- | --- |
| `index.json` | Chunk-level index with metadata, semantic configuration, vector search profile, and Azure OpenAI vectorizer. |
| `data-source.json` | Blob Storage data source that points to the crawler output container. |
| `skillset.json` | Text Split + Azure OpenAI embedding skillset with index projections. |
| `indexer.json` | Blob indexer configured for normalized JSON documents. |
| `deploy-search.ps1` | PowerShell helper that deploys the templates and starts the indexer. |

## Deploy the sample

From the repository root:

```powershell
.\infra\azure-search\deploy-search.ps1 `
  -SearchServiceName "<search-service-name>" `
  -AdminKey "<search-admin-key>" `
  -StorageConnectionString "<storage-connection-string>" `
  -AzureOpenAIEndpoint "https://<aoai-resource>.openai.azure.com" `
  -AzureOpenAIKey "<aoai-key>" `
  -AzureOpenAIEmbeddingDeployment "<embedding-deployment-name>" `
  -ContentContainerName "content"
```

The template defaults assume `text-embedding-3-small` with 1536 dimensions. If you use a different embedding model or dimension count, update both `index.json` and `skillset.json`.

## Query shape

After the indexer runs, query `website-knowledge-chunks` using hybrid retrieval over:

- `content` for keyword/semantic search
- `content_vector` for vector search
- metadata filters such as `site`, `source_engine`, `content_type`, `depth`, and `crawl_timestamp`

Example filters:

```text
site eq 'example.com'
source_engine eq 'firecrawl'
content_type eq 'text/markdown'
depth le 3
```

## Production notes

- Prefer managed identity or Key Vault references for secrets in production.
- Use private endpoints when Storage, Azure AI Search, and Azure OpenAI must stay off public networks.
- Tune `maximumPageLength` and `pageOverlapLength` in `skillset.json` for your content type.
- Keep Blob Storage as the durable corpus and rebuild the search index when chunking, embedding, or semantic settings change.
- Use Foundry IQ or your application layer above Azure AI Search for agent retrieval and response generation.
