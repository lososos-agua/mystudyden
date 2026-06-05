import http from "node:http";
import { readFileSync } from "node:fs";
import { join } from "node:path";

loadDotEnv();

const port = Number(process.env.PORT || 8787);
const llmProvider = (process.env.LLM_PROVIDER || "openrouter").toLowerCase();
const openAIModel = process.env.OPENAI_MODEL || "gpt-5-mini";
const openRouterModel = process.env.OPENROUTER_MODEL || "openrouter/free";
const geminiModel = process.env.GEMINI_MODEL || "gemini-2.5-flash-lite";
const activeModel = {
  gemini: geminiModel,
  openai: openAIModel,
  openrouter: openRouterModel
}[llmProvider] || openRouterModel;

const server = http.createServer(async (request, response) => {
  try {
    console.log(`${new Date().toISOString()} ${request.method} ${request.url}`);

    if (request.method === "GET" && request.url === "/") {
      writeJSON(response, 200, {
        ok: true,
        message: "MyStudyDen local server is running.",
        endpoints: ["GET /health", "POST /generate-study-packet"]
      });
      return;
    }

    if (request.method === "GET" && request.url === "/health") {
      writeJSON(response, 200, {
        ok: true,
        provider: llmProvider,
        model: activeModel,
        hasGeminiKey: Boolean(process.env.GEMINI_API_KEY),
        hasOpenAIKey: Boolean(process.env.OPENAI_API_KEY),
        hasOpenRouterKey: Boolean(process.env.OPENROUTER_API_KEY)
      });
      return;
    }

    if (request.method === "POST" && request.url === "/generate-study-packet") {
      const body = await readJSON(request);
      const draft = await generateStudyPacket(body);
      writeJSON(response, 200, { draft, provider: llmProvider, model: activeModel });
      return;
    }

    writeJSON(response, 404, { error: "Not found" });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    console.error(`${new Date().toISOString()} error ${statusCode}: ${error.message || error}`);
    writeJSON(response, statusCode, {
      error: error.message || "Unexpected server error"
    });
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`MyStudyDen server listening on http://127.0.0.1:${port}`);
});

async function generateStudyPacket({ course, source }) {
  if (!course || !source) {
    throw httpError(400, "Request must include course and source.");
  }

  if (llmProvider === "openrouter") {
    return generateWithOpenRouter(course, source);
  }

  if (llmProvider === "openai") {
    return generateWithOpenAI(course, source);
  }

  if (llmProvider === "gemini") {
    return generateWithGemini(course, source);
  }

  throw httpError(500, `Unsupported LLM_PROVIDER: ${llmProvider}`);
}

async function generateWithOpenRouter(course, source) {
  if (!process.env.OPENROUTER_API_KEY) {
    throw httpError(500, "OPENROUTER_API_KEY is missing. Create Server/.env from Server/.env.example.");
  }

  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
      "Content-Type": "application/json",
      "HTTP-Referer": process.env.APP_PUBLIC_URL || "http://localhost:8787",
      "X-Title": "MyStudyDen"
    },
    body: JSON.stringify({
      model: openRouterModel,
      messages: [
        {
          role: "system",
          content: [
            "You turn course materials into concise, useful study packets.",
            "Return only valid JSON matching this shape:",
            JSON.stringify(studyPacketDraftSchemaShape())
          ].join("\n")
        },
        {
          role: "user",
          content: buildStudyPacketPrompt(course, source)
        }
      ],
      response_format: { type: "json_object" },
      temperature: 0.2
    })
  });

  const payload = await response.json().catch(() => null);

  if (!response.ok) {
    throw httpError(response.status, payload?.error?.message || "OpenRouter request failed.");
  }

  const outputText = payload?.choices?.[0]?.message?.content;
  if (!outputText) {
    throw httpError(502, "OpenRouter response did not include message content.");
  }

  const draft = parseModelJSON(outputText);
  return normalizeStudyPacketDraft(draft, source, course);
}

async function generateWithGemini(course, source) {
  if (!process.env.GEMINI_API_KEY) {
    throw httpError(500, "GEMINI_API_KEY is missing. Create Server/.env from Server/.env.example.");
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(geminiModel)}:generateContent`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": process.env.GEMINI_API_KEY
    },
    body: JSON.stringify({
      systemInstruction: {
        parts: [
          {
            text: "You turn course materials into concise, useful study packets. Return JSON only."
          }
        ]
      },
      contents: [
        {
          role: "user",
          parts: [{ text: buildStudyPacketPrompt(course, source) }]
        }
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseJsonSchema: geminiStudyPacketDraftSchema(),
        temperature: 0.2
      }
    })
  });

  const payload = await response.json().catch(() => null);

  if (!response.ok) {
    throw httpError(response.status, payload?.error?.message || "Gemini request failed.");
  }

  const outputText = extractGeminiText(payload);
  if (!outputText) {
    throw httpError(502, "Gemini response did not include text output.");
  }

  const draft = parseModelJSON(outputText);
  return normalizeStudyPacketDraft(draft, source, course);
}

async function generateWithOpenAI(course, source) {
  if (!process.env.OPENAI_API_KEY) {
    throw httpError(500, "OPENAI_API_KEY is missing. Create Server/.env from Server/.env.example.");
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: openAIModel,
      input: [
        {
          role: "system",
          content: "You turn course materials into concise, useful study packets. Return only JSON matching the requested schema."
        },
        {
          role: "user",
          content: buildStudyPacketPrompt(course, source)
        }
      ],
      text: {
        format: {
          type: "json_schema",
          name: "study_packet_draft",
          strict: true,
          schema: studyPacketDraftSchema()
        }
      }
    })
  });

  const payload = await response.json().catch(() => null);

  if (!response.ok) {
    throw httpError(response.status, payload?.error?.message || "OpenAI request failed.");
  }

  const outputText = extractOutputText(payload);
  if (!outputText) {
    throw httpError(502, "OpenAI response did not include text output.");
  }

  const draft = parseModelJSON(outputText);
  return normalizeStudyPacketDraft(draft, source, course);
}

function buildStudyPacketPrompt(course, source) {
  return [
    `Course: ${course.title}`,
    course.courseCode ? `Course code: ${course.courseCode}` : null,
    course.instructor ? `Instructor: ${course.instructor}` : null,
    course.personalGoal ? `Student goal: ${course.personalGoal}` : null,
    `Source title: ${source.title}`,
    `Source type: ${source.type}`,
    `Student intent: ${source.intent}`,
    "",
    "Create a study packet that helps a student review this material.",
    "Keep it compact, concrete, and grounded in the source.",
    "",
    "Source text:",
    source.rawText
  ].filter(Boolean).join("\n");
}

function studyPacketDraftSchema() {
  return {
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "compactSummary",
      "outline",
      "studyGuide",
      "conceptChunks",
      "keyTerms",
      "reviewQuestions"
    ],
    properties: {
      title: { type: "string" },
      compactSummary: { type: "string" },
      outline: {
        type: "array",
        minItems: 2,
        maxItems: 6,
        items: { type: "string" }
      },
      studyGuide: { type: "string" },
      conceptChunks: {
        type: "array",
        minItems: 1,
        maxItems: 5,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["title", "summary", "keyPoints", "keywords"],
          properties: {
            title: { type: "string" },
            summary: { type: "string" },
            keyPoints: {
              type: "array",
              minItems: 1,
              maxItems: 5,
              items: { type: "string" }
            },
            keywords: {
              type: "array",
              minItems: 1,
              maxItems: 8,
              items: { type: "string" }
            }
          }
        }
      },
      keyTerms: {
        type: "array",
        minItems: 1,
        maxItems: 8,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["term", "definition"],
          properties: {
            term: { type: "string" },
            definition: { type: "string" }
          }
        }
      },
      reviewQuestions: {
        type: "array",
        minItems: 2,
        maxItems: 8,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["question", "answerHint", "difficulty"],
          properties: {
            question: { type: "string" },
            answerHint: { type: "string" },
            difficulty: { type: "integer", minimum: 1, maximum: 3 }
          }
        }
      }
    }
  };
}

function geminiStudyPacketDraftSchema() {
  return removeUnsupportedGeminiSchemaFields(studyPacketDraftSchema());
}

function removeUnsupportedGeminiSchemaFields(value) {
  if (Array.isArray(value)) {
    return value.map(removeUnsupportedGeminiSchemaFields);
  }

  if (!value || typeof value !== "object") {
    return value;
  }

  const copy = {};

  for (const [key, nestedValue] of Object.entries(value)) {
    if (["additionalProperties"].includes(key)) {
      continue;
    }

    copy[key] = removeUnsupportedGeminiSchemaFields(nestedValue);
  }

  return copy;
}

function studyPacketDraftSchemaShape() {
  return {
    title: "string",
    compactSummary: "string",
    outline: ["string"],
    studyGuide: "string",
    conceptChunks: [
      {
        title: "string",
        summary: "string",
        keyPoints: ["string"],
        keywords: ["string"]
      }
    ],
    keyTerms: [
      {
        term: "string",
        definition: "string"
      }
    ],
    reviewQuestions: [
      {
        question: "string",
        answerHint: "string",
        difficulty: 1
      }
    ]
  };
}

function normalizeStudyPacketDraft(draft, source, course) {
  return {
    title: nonEmptyString(draft.title, source.title || `${course.title} Study Packet`),
    compactSummary: nonEmptyString(draft.compactSummary, `A study packet for ${course.title}.`),
    outline: nonEmptyArray(draft.outline, ["Review the source", "Identify key ideas"]),
    studyGuide: nonEmptyString(draft.studyGuide, "Review the summary, explain each term, then answer the questions from memory."),
    conceptChunks: nonEmptyArray(draft.conceptChunks, [{
      title: "Main concept",
      summary: "The main idea from the source.",
      keyPoints: ["Review the source details"],
      keywords: ["source"]
    }]).map((concept) => ({
      title: nonEmptyString(concept.title, "Main concept"),
      summary: nonEmptyString(concept.summary, "A key idea from the source."),
      keyPoints: nonEmptyArray(concept.keyPoints, ["Review the source details"]),
      keywords: nonEmptyArray(concept.keywords, ["source"])
    })),
    keyTerms: nonEmptyArray(draft.keyTerms, [{
      term: "Key idea",
      definition: "An important idea from the source material."
    }]).map((term) => ({
      term: nonEmptyString(term.term, "Key idea"),
      definition: nonEmptyString(term.definition, "An important idea from the source material.")
    })),
    reviewQuestions: nonEmptyArray(draft.reviewQuestions, [{
      question: "What is the main idea of this source?",
      answerHint: "Use the compact summary.",
      difficulty: 1
    }]).map((question) => ({
      question: nonEmptyString(question.question, "What is the main idea of this source?"),
      answerHint: nonEmptyString(question.answerHint, "Use the compact summary."),
      difficulty: clampInteger(question.difficulty, 1, 3, 1)
    }))
  };
}

function extractOutputText(payload) {
  if (typeof payload?.output_text === "string") {
    return payload.output_text;
  }

  for (const item of payload?.output || []) {
    for (const content of item.content || []) {
      if (typeof content.text === "string") {
        return content.text;
      }
    }
  }

  return null;
}

function extractGeminiText(payload) {
  for (const candidate of payload?.candidates || []) {
    for (const part of candidate.content?.parts || []) {
      if (typeof part.text === "string") {
        return part.text;
      }
    }
  }

  return null;
}

function parseModelJSON(text) {
  try {
    return JSON.parse(text);
  } catch {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");

    if (start >= 0 && end > start) {
      return JSON.parse(text.slice(start, end + 1));
    }

    throw httpError(502, "Model response was not valid JSON.");
  }
}

function nonEmptyString(value, fallback) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function nonEmptyArray(value, fallback) {
  return Array.isArray(value) && value.length > 0 ? value : fallback;
}

function clampInteger(value, minimum, maximum, fallback) {
  return Number.isInteger(value) ? Math.min(Math.max(value, minimum), maximum) : fallback;
}

async function readJSON(request) {
  let body = "";

  for await (const chunk of request) {
    body += chunk;

    if (body.length > 200_000) {
      throw httpError(413, "Request body is too large.");
    }
  }

  try {
    return JSON.parse(body || "{}");
  } catch {
    throw httpError(400, "Request body must be valid JSON.");
  }
}

function writeJSON(response, statusCode, payload) {
  response.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  });
  response.end(JSON.stringify(payload, null, 2));
}

function httpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function loadDotEnv() {
  try {
    const envPath = join(process.cwd(), ".env");
    const contents = readFileSync(envPath, "utf8");

    for (const line of contents.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const [key, ...valueParts] = trimmed.split("=");
      if (key && !process.env[key]) {
        process.env[key] = valueParts.join("=").trim();
      }
    }
  } catch {
    // .env is optional; /health reports whether the key is present.
  }
}
