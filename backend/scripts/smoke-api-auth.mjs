import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import firebaseConfig from "../src/config/firebase.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function getFetch() {
  if (typeof globalThis.fetch === "function") {
    return globalThis.fetch.bind(globalThis);
  }

  const module = await import("node-fetch");
  return module.default;
}

function parseArgs(argv) {
  const options = {
    baseUrl: process.env.API_BASE_URL || "http://127.0.0.1:3000",
    apiKey: process.env.FIREBASE_WEB_API_KEY || null,
    email: process.env.AUTH_TEST_EMAIL || null,
    password: process.env.AUTH_TEST_PASSWORD || null,
    uid: process.env.AUTH_TEST_UID || null,
    showToken: false,
    onlyToken: false,
  };

  for (const arg of argv) {
    if (arg === "--show-token") {
      options.showToken = true;
      continue;
    }
    if (arg === "--only-token") {
      options.onlyToken = true;
      continue;
    }
    if (arg.startsWith("--base-url=")) {
      options.baseUrl = arg.slice("--base-url=".length).trim();
      continue;
    }
    if (arg.startsWith("--api-key=")) {
      options.apiKey = arg.slice("--api-key=".length).trim();
      continue;
    }
    if (arg.startsWith("--email=")) {
      options.email = arg.slice("--email=".length).trim();
      continue;
    }
    if (arg.startsWith("--password=")) {
      options.password = arg.slice("--password=".length).trim();
      continue;
    }
    if (arg.startsWith("--uid=")) {
      options.uid = arg.slice("--uid=".length).trim();
      continue;
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  return options;
}

function maskToken(token) {
  if (!token || token.length < 28) return token || "";
  return `${token.slice(0, 14)}...${token.slice(-10)}`;
}

function readApiKeyFromFlutterConfig() {
  const filePath = path.resolve(__dirname, "../../lib/firebase_options.dart");
  if (!fs.existsSync(filePath)) return null;

  const content = fs.readFileSync(filePath, "utf8");
  const webBlockMatch = /static const FirebaseOptions web[\s\S]*?apiKey:\s*'([^']+)'/.exec(
    content,
  );
  if (webBlockMatch?.[1]) return webBlockMatch[1];

  const firstKeyMatch = /apiKey:\s*'([^']+)'/.exec(content);
  return firstKeyMatch?.[1] ?? null;
}

// Use global fetch for Google Identity Toolkit (internet) - it already worked for you.
async function identityToolkitCall(endpoint, apiKey, payload) {
  const url = `https://identitytoolkit.googleapis.com/v1/${endpoint}?key=${apiKey}`;

  // If your Node doesn't have global fetch, fallback to node-fetch.
  const f = await getFetch();

  const response = await f(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  const data = await response.json();
  if (!response.ok) {
    const message = data?.error?.message || `HTTP ${response.status}`;
    throw new Error(`IdentityToolkit ${endpoint} failed: ${message}`);
  }
  return data;
}

async function getTokenByPassword(apiKey, email, password) {
  if (!email || !password) {
    throw new Error("Missing --email / --password for password login.");
  }

  const data = await identityToolkitCall("accounts:signInWithPassword", apiKey, {
    email,
    password,
    returnSecureToken: true,
  });

  return {
    idToken: data.idToken,
    uid: data.localId || null,
    email: data.email || email,
    provider: "password",
  };
}

async function getTokenByCustomToken(apiKey, uid) {
  if (!uid) throw new Error("Missing --uid for custom token login.");
  const { admin, isFirebaseReady } = firebaseConfig;

  if (!isFirebaseReady || !admin) {
    throw new Error(
      "Firebase Admin not ready. Set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS.",
    );
  }

  const customToken = await admin.auth().createCustomToken(uid);
  const data = await identityToolkitCall("accounts:signInWithCustomToken", apiKey, {
    token: customToken,
    returnSecureToken: true,
  });

  return {
    idToken: data.idToken,
    uid: data.localId || uid,
    email: data.email || null,
    provider: "custom_token",
  };
}

// Use nodeFetch for local API calls - avoids Windows undici crash
async function apiGet(url, token) {
  const f = await getFetch();
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const response = await f(url, { method: "GET", headers });

  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch (parseError) {
    const message = parseError instanceof Error ? parseError.message : String(parseError);
    console.warn(`Non-JSON response from ${url}: ${message}`);
    body = text;
  }
  return { status: response.status, body };
}

function unwrapData(body) {
  if (typeof body?.data === "object" && body.data !== null) {
    return body.data;
  }
  return body;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const apiKey = options.apiKey || readApiKeyFromFlutterConfig();
  if (!apiKey) {
    throw new Error("Firebase API key not found. Use --api-key or FIREBASE_WEB_API_KEY.");
  }

  const canUsePassword = options.email && options.password;
  const canUseCustomToken = options.uid;

  if (!canUsePassword && !canUseCustomToken) {
    throw new Error(
      "Provide either --email + --password, or --uid. Example: npm run api:smoke -- --uid=<FIREBASE_UID>",
    );
  }

  const authResult = canUsePassword
    ? await getTokenByPassword(apiKey, options.email, options.password)
    : await getTokenByCustomToken(apiKey, options.uid);

  const tokenLabel = options.showToken ? authResult.idToken : maskToken(authResult.idToken);

  console.log(
    `Token OK provider=${authResult.provider} uid=${authResult.uid} email=${
      authResult.email || "n/a"
    }`,
  );
  console.log(`ID token: ${tokenLabel}`);

  if (options.onlyToken) return;

  const baseUrl = options.baseUrl.replace(/\/+$/, "");

  // These require your API server to already be running (npm start)
  const health = await apiGet(`${baseUrl}/health`);
  const me = await apiGet(`${baseUrl}/me`, authResult.idToken);
  const categories = await apiGet(`${baseUrl}/categories`, authResult.idToken);
  const transactions = await apiGet(`${baseUrl}/transactions?limit=5`, authResult.idToken);
  const categoriesData = unwrapData(categories.body);
  const transactionsData = unwrapData(transactions.body);

  console.log(`GET /health -> ${health.status} ${JSON.stringify(health.body)}`);
  console.log(`GET /me -> ${me.status} ${JSON.stringify(me.body)}`);
  console.log(
    `GET /categories -> ${categories.status} count=${
      Array.isArray(categoriesData?.items) ? categoriesData.items.length : "n/a"
    }`,
  );
  console.log(
    `GET /transactions?limit=5 -> ${transactions.status} count=${
      Array.isArray(transactionsData?.items) ? transactionsData.items.length : "n/a"
    }`,
  );
}

try {
  await main();
} catch (error) {
  // Avoid hard crashing the event loop
  console.error("API smoke failed:", error?.message || error);
  process.exitCode = 1;
}
