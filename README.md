# Azure AI Website Knowledge Ingestion Pipeline

This project is an **Azure Function** that crawls websites, extracts clean source content, and stores normalized JSON documents in Azure Blob Storage for Azure AI Search, Foundry IQ, and RAG chatbot scenarios.

The modern pipeline is:

```text
Website -> crawler engine -> normalized JSON in Blob Storage -> Azure AI Search -> Foundry IQ / agent / chatbot
```

Azure Blob Storage is the durable source corpus. Azure AI Search should be the retrieval index, using indexers, skillsets, integrated vectorization, hybrid search, and semantic ranking where appropriate.

## Features

- Pluggable crawler engines:
  - `native`: built-in Azure Function crawler with Playwright, sitemap parsing, recursive depth, domain allow-listing, and file extraction
  - `firecrawl`: managed Firecrawl crawl API for LLM-ready markdown
  - `apify`: Apify Website Content Crawler or another compatible Actor
- Extracts HTML, PDF, DOCX, and XLSX content with the native crawler
- Stores normalized source documents and crawl logs as JSON in Azure Blob Storage
- Adds AI-ready metadata: URL, canonical URL, title, content type, crawl timestamp, last modified, site, path, depth, parent URL, content hash, and source engine
- Uses content hashes to avoid rewriting unchanged pages
- Keeps local chunking and Azure OpenAI embeddings as an optional legacy mode
- Skips binary and irrelevant files via regex filtering
- Application Insights support for tracking and monitoring
- Works as a timer-triggered Azure Function (scheduled crawl), with a simple HTTP health check endpoint
- Dockerfile included for easy container deployment

## Project Structure

```text
azurefunction_webcrawler_to_blobstorage/
├── .gitignore
├── Dockerfile
├── README.md
├── crawler.py
├── function_app.py
├── host.json
├── requirements.txt
├── .funcignore
├── .dockerignore
├── appsettings.json         # Not tracked; for Azure deployment only
├── local.settings.json      # Not tracked; for local development only
```


## Getting Started

### Prerequisites

- Python 3.9+
- [Azure Functions Core Tools](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- An Azure Subscription with access to Blob Storage
- Docker (optional, for container deployment)

### Setup

1. **Clone the repository:**
    ```bash
    git clone https://github.com/jdnuckolls/azurefunction_webcrawler_to_blobstorage.git
    cd azurefunction_webcrawler_to_blobstorage
    ```

2. **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3. **Configure settings:**

    - `local.settings.json` is used for local development (not included in repo; create your own based on the sample).
    - Set environment variables for storage accounts, crawl parameters, and Application Insights as needed.

4. **Run locally:**
    ```bash
    func start
    ```

5. **Deploy to Azure:**
    - Deploy using Azure Functions Core Tools or Azure Portal.
    - For Docker deployment, use the included Dockerfile.

### Usage

- The crawler runs on a schedule (default: daily at 2am UTC) via a timer trigger.
- To check health/status, send an HTTP GET to the `/api/ping` endpoint.

## Configuration

Main settings are provided via environment variables or `local.settings.json`:

- `STORAGE_ACCOUNT_NAME`, `CONTAINER_NAME`, `LOG_CONTAINER_NAME`
- `CRAWLER_ENGINE`: `native`, `firecrawl`, or `apify`
- `SOURCE_FORMAT`: `auto` by default, marking Firecrawl output as markdown and native extracted content as text
- `OUTPUT_MODE`: `source` by default, producing one normalized source document per crawled page or file
- `EMBED_LOCALLY`: set to `true` only if you want the crawler to chunk and embed locally; otherwise let Azure AI Search integrated vectorization handle chunking and embeddings
- `BASE_URLS` (semicolon-separated list of crawl entry points)
- `ALLOW_DOMAINS` (which domains to allow crawling)
- `MAX_DEPTH` (maximum crawl depth)
- `SKIP_REGEXES` (regex patterns for files/links to skip)
- `FIRECRAWL_API_KEY`, `FIRECRAWL_LIMIT` for Firecrawl
- `APIFY_API_TOKEN`, `APIFY_ACTOR_ID`, `APIFY_INPUT_JSON` for Apify
- See `appsettings.json` and `local.settings.json` for more.

## Normalized document shape

Each uploaded content blob is a JSON document similar to:

```json
{
  "id": "sha256-url",
  "url": "https://example.com/page",
  "canonical_url": "https://example.com/page",
  "title": "Page title",
  "content": "Clean page text or markdown",
  "content_format": "markdown",
  "content_type": "text/html",
  "crawl_timestamp": "2026-09-09T19:52:00Z",
  "last_modified": "2026-09-09T19:52:00Z",
  "site": "example.com",
  "path": "/page",
  "depth": 2,
  "parent_url": "https://example.com/section",
  "content_hash": "sha256-content",
  "source_engine": "native"
}
```

Configure an Azure AI Search Blob indexer over this container and use integrated vectorization to split `content`, generate embeddings, and populate your search index.

See [Azure AI Search integrated vectorization](docs/azure-ai-search.md) for starter index, data source, skillset, and indexer templates.

## Crawler engine options

### Native

```json
{
  "CRAWLER_ENGINE": "native",
  "BASE_URLS": "https://example.com",
  "ALLOW_DOMAINS": "example.com",
  "OUTPUT_MODE": "source"
}
```

Use this when you want an Azure-native implementation and control over link traversal, file extraction, robots behavior, and Blob output.

### Firecrawl

```json
{
  "CRAWLER_ENGINE": "firecrawl",
  "BASE_URLS": "https://example.com",
  "FIRECRAWL_API_KEY": "[YOUR FIRECRAWL KEY]",
  "FIRECRAWL_LIMIT": "1000"
}
```

Use this when you want managed JavaScript rendering, sitemap handling, deep crawling, and LLM-ready markdown with less crawler maintenance.

### Apify

```json
{
  "CRAWLER_ENGINE": "apify",
  "BASE_URLS": "https://example.com",
  "APIFY_API_TOKEN": "[YOUR APIFY TOKEN]",
  "APIFY_ACTOR_ID": "apify/website-content-crawler",
  "APIFY_MAX_CRAWL_PAGES": "1000"
}
```

Use this when you need a managed crawler platform, scalable Actors, proxy support, and production scraping controls.

## Security

- **DO NOT commit secrets** (such as connection strings or API keys) to this repository.
- The `.gitignore` is set up to exclude sensitive config files and local environments.

## License

MIT License (add your license here if different).

## Author

[Jeff Nuckolls](https://github.com/jdnuckolls)

---

*Inspired by best practices for large-scale content ingestion and search.*
