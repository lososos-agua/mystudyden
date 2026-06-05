import http from "node:http";
import { appendFileSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";

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
const logFilePath = process.env.LOG_FILE || join(process.cwd(), "logs", "server.log");

const server = http.createServer(async (request, response) => {
  try {
    logEvent("request", { method: request.method, url: request.url });

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
      logEvent("generation.success", {
        provider: llmProvider,
        model: activeModel,
        sourceTitle: body.source?.title,
        packetTitle: draft.title
      });
      writeJSON(response, 200, { draft, provider: llmProvider, model: activeModel });
      return;
    }

    logEvent("route.not_found", { method: request.method, url: request.url });
    writeJSON(response, 404, { error: "Not found" });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    logEvent("error", { statusCode, message: error.message || String(error) });
    writeJSON(response, statusCode, {
      error: error.message || "Unexpected server error"
    });
  }
});

server.listen(port, "0.0.0.0", () => {
  logEvent("server.start", {
    url: `http://127.0.0.1:${port}`,
    provider: llmProvider,
    model: activeModel
  });
});

function logEvent(event, details = {}) {
  const payload = {
    timestamp: new Date().toISOString(),
    event,
    ...details
  };
  const line = JSON.stringify(payload);
  console.log(line);

  try {
    mkdirSync(dirname(logFilePath), { recursive: true });
    appendFileSync(logFilePath, `${line}\n`, "utf8");
  } catch (error) {
    console.error(`Failed to write log file: ${error.message || error}`);
  }
}

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
    logEvent("generation.source_fallback", {
      provider: llmProvider,
      model: activeModel,
      sourceTitle: source.title,
      reason: "OpenRouter response did not include message content."
    });
    return normalizeStudyPacketDraft({}, source, course);
  }

  let draft;
  try {
    draft = parseModelJSON(outputText);
  } catch (error) {
    logEvent("generation.source_fallback", {
      provider: llmProvider,
      model: activeModel,
      sourceTitle: source.title,
      reason: error.message || String(error)
    });
    draft = {};
  }

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

function normalizeStudyPacketDraft(draft = {}, source, course) {
  const fallback = sourceBackedStudyPacketDraft(source, course);

  return {
    title: nonEmptyString(draft.title, fallback.title),
    compactSummary: nonEmptyString(draft.compactSummary, fallback.compactSummary),
    outline: nonEmptyArray(draft.outline, fallback.outline),
    studyGuide: nonEmptyString(draft.studyGuide, fallback.studyGuide),
    conceptChunks: nonEmptyArray(draft.conceptChunks, fallback.conceptChunks).map((concept, index) => {
      const fallbackConcept = fallback.conceptChunks[index] || fallback.conceptChunks[0];

      return {
        title: nonEmptyString(concept.title, fallbackConcept.title),
        summary: nonEmptyString(concept.summary, fallbackConcept.summary),
        keyPoints: nonEmptyArray(concept.keyPoints, fallbackConcept.keyPoints),
        keywords: nonEmptyArray(concept.keywords, fallbackConcept.keywords)
      };
    }),
    keyTerms: nonEmptyArray(draft.keyTerms, fallback.keyTerms).map((term, index) => {
      const fallbackTerm = fallback.keyTerms[index] || fallback.keyTerms[0];

      return {
        term: nonEmptyString(term.term, fallbackTerm.term),
        definition: nonEmptyString(term.definition, fallbackTerm.definition)
      };
    }),
    reviewQuestions: nonEmptyArray(draft.reviewQuestions, fallback.reviewQuestions).map((question, index) => {
      const fallbackQuestion = fallback.reviewQuestions[index] || fallback.reviewQuestions[0];

      return {
        question: nonEmptyString(question.question, fallbackQuestion.question),
        answerHint: nonEmptyString(question.answerHint, fallbackQuestion.answerHint),
        difficulty: clampInteger(question.difficulty, 1, 3, fallbackQuestion.difficulty)
      };
    })
  };
}

function sourceBackedStudyPacketDraft(source, course) {
  const sentences = splitSentences(source.rawText);
  const paragraphs = splitParagraphs(source.rawText);
  const keyTerms = extractKeyTerms(source.rawText, sentences);
  const conceptChunks = makeConceptChunks(paragraphs, sentences, keyTerms);
  const compactSummary = sentences.slice(0, 2).join(" ") || `Review ${source.title} for ${course.title}.`;
  const outline = sentences.slice(0, 4).map(shortenSentence);

  return {
    title: `${source.title || course.title} Study Packet`,
    compactSummary,
    outline: outline.length > 0 ? outline : [`Review ${source.title || course.title}`],
    studyGuide: [
      "Read the compact summary first.",
      "Explain the key terms without looking at the source.",
      "Answer each review question from memory, then check the source text."
    ].join(" "),
    conceptChunks,
    keyTerms,
    reviewQuestions: makeReviewQuestions(keyTerms, sentences)
  };
}

function splitParagraphs(text) {
  return String(text || "")
    .split(/\n{2,}|\r\n{2,}/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean);
}

function splitSentences(text) {
  return String(text || "")
    .replace(/\s+/g, " ")
    .match(/[^.!?]+[.!?]+|[^.!?]+$/g)
    ?.map((sentence) => sentence.trim())
    .filter(Boolean) || [];
}

function shortenSentence(sentence) {
  const words = sentence.replace(/[.!?]+$/g, "").split(/\s+/).filter(Boolean);
  return words.slice(0, 18).join(" ");
}

function makeConceptChunks(paragraphs, sentences, keyTerms) {
  const sourceParagraphs = paragraphs.length > 0 ? paragraphs.slice(0, 3) : [sentences.join(" ")];
  const chunks = sourceParagraphs
    .map((paragraph, index) => {
      const paragraphSentences = splitSentences(paragraph);
      const summary = paragraphSentences[0] || paragraph;
      const keyPoints = paragraphSentences.slice(1, 4).map(shortenSentence);
      const keywords = keyTerms.slice(index, index + 3).map((term) => term.term);

      return {
        title: titleFromSentence(summary),
        summary,
        keyPoints: keyPoints.length > 0 ? keyPoints : [shortenSentence(summary)],
        keywords: keywords.length > 0 ? keywords : [titleFromSentence(summary)]
      };
    })
    .filter((chunk) => chunk.summary);

  return chunks.length > 0 ? chunks : [{
    title: "Source Review",
    summary: "Review the source material and identify the main learning points.",
    keyPoints: ["Connect each idea to the course goal."],
    keywords: ["review"]
  }];
}

function titleFromSentence(sentence) {
  const words = sentence
    .replace(/[^a-zA-Z0-9 -]/g, "")
    .split(/\s+/)
    .filter((word) => word.length > 2)
    .slice(0, 5);

  return words.length > 0 ? titleCase(words.join(" ")) : "Main Concept";
}

function extractKeyTerms(text, sentences) {
  const normalizedText = String(text || "").toLowerCase();
  const stopwords = new Set([
    "the", "and", "that", "this", "with", "from", "during", "there", "while", "student",
    "students", "source", "material", "learning", "study", "studying", "information",
    "important", "process", "often", "helps", "more", "less", "later", "before"
  ]);
  const words = normalizedText
    .replace(/[^a-z0-9 -]/g, " ")
    .split(/\s+/)
    .filter((word) => word.length > 2 && !stopwords.has(word));
  const scores = new Map();

  for (let size = 1; size <= 3; size += 1) {
    for (let index = 0; index <= words.length - size; index += 1) {
      const phrase = words.slice(index, index + size).join(" ");
      const score = size * size;
      scores.set(phrase, (scores.get(phrase) || 0) + score);
    }
  }

  const terms = [...scores.entries()]
    .filter(([phrase]) => !phrase.split(" ").some((word) => stopwords.has(word)))
    .sort((lhs, rhs) => rhs[1] - lhs[1] || rhs[0].length - lhs[0].length)
    .slice(0, 4)
    .map(([phrase]) => ({
      term: titleCase(phrase),
      definition: definitionForPhrase(phrase, sentences)
    }));

  return terms.length > 0 ? terms : [{
    term: titleCase(sourceTitleFallback(text)),
    definition: "A central idea from the source material."
  }];
}

function definitionForPhrase(phrase, sentences) {
  const matchingSentence = sentences.find((sentence) =>
    sentence.toLowerCase().includes(phrase.toLowerCase())
  );

  return matchingSentence
    ? shortenSentence(matchingSentence)
    : `A recurring idea in the source: ${titleCase(phrase)}.`;
}

function makeReviewQuestions(keyTerms, sentences) {
  const questions = keyTerms.slice(0, 3).map((term, index) => ({
    question: `How does ${term.term} connect to the source's main argument?`,
    answerHint: term.definition,
    difficulty: Math.min(index + 1, 3)
  }));

  if (sentences.length > 1) {
    questions.push({
      question: "What study habit or action does the source recommend?",
      answerHint: shortenSentence(sentences[sentences.length - 1]),
      difficulty: 2
    });
  }

  return questions.length > 0 ? questions : [{
    question: "What should you remember from this source?",
    answerHint: "Use the compact summary and key terms.",
    difficulty: 1
  }];
}

function titleCase(value) {
  return String(value || "")
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function sourceTitleFallback(text) {
  const words = String(text || "").split(/\s+/).filter(Boolean).slice(0, 3);
  return words.join(" ") || "key idea";
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
