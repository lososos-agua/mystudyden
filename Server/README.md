# MyStudyDen Local Server

This small local server keeps LLM API keys off the iOS app during development.
It defaults to OpenRouter so you can use free models while prototyping.

## Setup

```sh
cp .env.example .env
```

Edit `.env` and set `OPENROUTER_API_KEY`.

The default development config is:

```text
LLM_PROVIDER=openrouter
OPENROUTER_MODEL=openrouter/free
```

To use OpenAI instead:

```text
LLM_PROVIDER=openai
OPENAI_MODEL=gpt-5-mini
```

## Run

```sh
npm start
```

The server listens on:

```text
http://127.0.0.1:8787
```

## Endpoints

```text
GET /health
POST /generate-study-packet
```

The iOS simulator can call `http://127.0.0.1:8787`. A physical iPhone needs the Mac's local network IP address instead.
