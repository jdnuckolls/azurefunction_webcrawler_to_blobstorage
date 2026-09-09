FROM mcr.microsoft.com/azure-functions/python:4-python3.11-appservice

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    WEBSITES_INCLUDE_CLOUD_CERTS=true \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies for Chromium / Playwright
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fonts-liberation \
        gnupg \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libgbm1 \
        libgtk-3-0 \
        libnss3 \
        libxshmfence1 \
        libxss1 \
        wget \
        xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy your function code and requirements
COPY . /home/site/wwwroot
WORKDIR /home/site/wwwroot

RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt

# Install Playwright browser(s)
RUN playwright install --with-deps chromium

# EXPOSE 8000

# Explicitly set the entrypoint for Azure Functions Python worker
CMD [ "/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost" ]
