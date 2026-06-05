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

To test Gemini while staying inside a free development budget:

```text
LLM_PROVIDER=gemini
GEMINI_MODEL=gemini-2.5-flash-lite
GEMINI_FREE_ONLY=true
GEMINI_DAILY_REQUEST_LIMIT=50
```

Use one dedicated MyStudyDen development project/API key with billing disabled.
Do not create extra accounts or projects to bypass free-tier quota. If Gemini returns a quota error, the server surfaces the failure instead of falling back to a paid model or mock output.

When `GEMINI_FREE_ONLY=true`, the server writes a local daily request counter to:

```text
Server/logs/gemini-free-usage.json
```

To use Gemini later as a paid production candidate, keep the same provider/model settings but set:

```text
GEMINI_FREE_ONLY=false
```

## Run

```sh
npm start
```

The server listens on:

```text
http://127.0.0.1:8787
```

Server activity is also written to:

```text
Server/logs/server.log
```

## Endpoints

```text
GET /health
POST /generate-study-packet
```

The iOS simulator can call `http://127.0.0.1:8787`. A physical iPhone needs the Mac's local network IP address instead.
