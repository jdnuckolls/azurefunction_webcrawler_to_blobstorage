# Three-repo architecture

This repository is part of a three-repo Azure AI reference architecture for public-sector website knowledge.

```text
Government or public website
  -> azurefunction_webcrawler_to_blobstorage
  -> Azure Blob Storage normalized JSON corpus
  -> Azure AI Search integrated vectorization
  -> standalone or popup chatbot
```

## Repository roles

| Repository | Role |
| --- | --- |
| [`azurefunction_webcrawler_to_blobstorage`](https://github.com/jdnuckolls/azurefunction_webcrawler_to_blobstorage) | Acquisition and normalization. Crawls websites with the native crawler, Firecrawl, or Apify and writes normalized JSON to Blob Storage. |
| [`simple-azure-openai-gov-chatbot`](https://github.com/jdnuckolls/simple-azure-openai-gov-chatbot) | Standalone reference app. Demonstrates direct Azure AI Search RAG from the crawler-generated index. |
| [`azurewebapp_popup_openai_chatbot`](https://github.com/jdnuckolls/azurewebapp_popup_openai_chatbot) | Embeddable widget. Uses the same retrieval contract as the standalone app but packages the UX as a popup assistant. |

## Flow

The crawler is responsible for acquisition and normalization:

```text
Website -> crawler engine -> normalized JSON -> Blob Storage
```

Azure AI Search is responsible for indexing and retrieval preparation:

```text
Blob Storage -> indexer -> split skill -> embedding skill -> chunk index
```

The chatbot repositories are responsible for retrieval and response generation:

```text
Browser -> chatbot app -> Azure AI Search -> Azure OpenAI -> cited answer
```

## Shared search contract

The crawler's `infra/azure-search` templates create the shared index contract consumed by both chatbot apps:

| Field | Purpose |
| --- | --- |
| `content` | Retrieved grounding text. |
| `content_vector` | Vector field populated by Azure AI Search integrated vectorization. |
| `title` | Human-readable citation label. |
| `url` | Public source URL for citations. |
| `canonical_url` | Normalized URL fallback. |
| `site`, `path`, `content_type`, `source_engine` | Filters and source metadata. |
| `crawl_timestamp`, `last_modified` | Freshness metadata. |
