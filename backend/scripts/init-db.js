const { admin, db, isFirebaseReady } = require("../src/config/firebase");

const DEFAULT_CATEGORIES = [
  { key: "salary", name: "Salaire", icon: "payments", color: "#2E7D32" },
  { key: "freelance", name: "Freelance", icon: "work", color: "#1B5E20" },
  {
    key: "food",
    name: "Alimentation",
    icon: "restaurant",
    color: "#EF6C00",
  },
  {
    key: "transport",
    name: "Transport",
    icon: "directions_car",
    color: "#1565C0",
  },
  { key: "rent", name: "Loyer", icon: "home", color: "#6A1B9A" },
  { key: "health", name: "Sante", icon: "medical_services", color: "#C62828" },
  {
    key: "internet",
    name: "Internet",
    icon: "wifi",
    color: "#00838F",
  },
  { key: "leisure", name: "Loisirs", icon: "sports_esports", color: "#AD1457" },
  { key: "saving", name: "Epargne", icon: "savings", color: "#283593" },
];

const SAMPLE_TRANSACTIONS = [
  {
    key: "salary",
    type: "income",
    amount: 2500,
    currency: "USD",
    categoryKey: "salary",
    note: "Salaire mensuel",
    day: 1,
  },
  {
    key: "food",
    type: "expense",
    amount: 140,
    currency: "USD",
    categoryKey: "food",
    note: "Courses semaine",
    day: 5,
  },
  {
    key: "transport",
    type: "expense",
    amount: 35,
    currency: "USD",
    categoryKey: "transport",
    note: "Transport urbain",
    day: 8,
  },
];

function envBool(name) {
  const value = (process.env[name] || "").toLowerCase().trim();
  return value === "1" || value === "true" || value === "yes";
}

function parseArgs(argv) {
  const options = {
    uid: process.env.SEED_USER_UID || null,
    email: process.env.SEED_USER_EMAIL || null,
    password: process.env.SEED_USER_PASSWORD || null,
    allUsers: envBool("SEED_ALL_USERS"),
    withSamples: envBool("SEED_WITH_SAMPLE_DATA"),
    dryRun: envBool("SEED_DRY_RUN"),
  };

  for (const arg of argv) {
    if (arg === "--all-users") {
      options.allUsers = true;
      continue;
    }
    if (arg === "--with-samples") {
      options.withSamples = true;
      continue;
    }
    if (arg === "--dry-run") {
      options.dryRun = true;
      continue;
    }
    if (arg.startsWith("--uid=")) {
      options.uid = arg.slice("--uid=".length).trim();
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
    throw new Error(`Unknown argument: ${arg}`);
  }

  return options;
}

async function listAllUsers() {
  const users = [];
  let nextPageToken;

  do {
    const page = await admin.auth().listUsers(1000, nextPageToken);
    users.push(...page.users.map((u) => ({ uid: u.uid, email: u.email || null })));
    nextPageToken = page.pageToken;
  } while (nextPageToken);

  return users;
}

async function resolveSeedUsers(options) {
  if (options.allUsers) {
    if (options.uid || options.email) {
      throw new Error("Do not combine --all-users with --uid or --email.");
    }

    const users = await listAllUsers();
    if (!users.length) {
      throw new Error(
        "No Firebase users found. Provide --email and --password to create a seed user.",
      );
    }
    return users;
  }

  if (options.uid) {
    const user = await admin.auth().getUser(options.uid);
    return [{ uid: user.uid, email: user.email || null }];
  }

  if (options.email) {
    try {
      const user = await admin.auth().getUserByEmail(options.email);
      return [{ uid: user.uid, email: user.email || null }];
    } catch (error) {
      if (error.code !== "auth/user-not-found" || !options.password) {
        throw error;
      }

      const created = await admin.auth().createUser({
        email: options.email,
        password: options.password,
      });

      console.log(`Created Firebase Auth user: ${created.uid} (${options.email})`);
      return [{ uid: created.uid, email: created.email || options.email }];
    }
  }

  const users = await listAllUsers();
  if (!users.length) {
    throw new Error(
      "No Firebase users found. Provide --email and --password to create a seed user.",
    );
  }

  return users;
}

async function upsertWithTimestamps(ref, payload, dryRun) {
  if (dryRun) {
    return "dry-run";
  }

  const existing = await ref.get();
  const withUpdatedAt = {
    ...payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (existing.exists) {
    await ref.set(withUpdatedAt, { merge: true });
    return "updated";
  }

  await ref.set(
    {
      ...withUpdatedAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return "created";
}

function currentMonthTag() {
  const now = new Date();
  const year = String(now.getUTCFullYear());
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  return `${year}${month}`;
}

function sampleDate(day) {
  const now = new Date();
  const safeDay = Math.max(1, Math.min(day, 28));
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), safeDay, 12, 0, 0));
}

async function seedCategories(uid, dryRun) {
  const categoryIds = new Map();
  let created = 0;
  let updated = 0;

  for (const category of DEFAULT_CATEGORIES) {
    const id = `${uid}__cat__${category.key}`;
    categoryIds.set(category.key, id);

    const result = await upsertWithTimestamps(
      db.collection("categories").doc(id),
      {
        uid,
        name: category.name,
        icon: category.icon,
        color: category.color,
      },
      dryRun,
    );

    if (result === "created") created += 1;
    if (result === "updated") updated += 1;
  }

  return { created, updated, categoryIds };
}

async function seedSampleTransactions(uid, categoryIds, dryRun) {
  let created = 0;
  let updated = 0;
  const monthTag = currentMonthTag();

  for (const tx of SAMPLE_TRANSACTIONS) {
    const id = `${uid}__tx__${monthTag}__${tx.key}`;
    const categoryId = categoryIds.get(tx.categoryKey) || null;

    const result = await upsertWithTimestamps(
      db.collection("transactions").doc(id),
      {
        uid,
        type: tx.type,
        amount: tx.amount,
        currency: tx.currency,
        categoryId,
        note: tx.note,
        date: admin.firestore.Timestamp.fromDate(sampleDate(tx.day)),
      },
      dryRun,
    );

    if (result === "created") created += 1;
    if (result === "updated") updated += 1;
  }

  return { created, updated };
}

async function main() {
  if (!isFirebaseReady || !admin || !db) {
    throw new Error(
      "Firebase Admin not ready. Set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS.",
    );
  }

  const options = parseArgs(process.argv.slice(2));
  const users = await resolveSeedUsers(options);

  console.log(
    `Init DB for ${users.length} user(s). mode=${options.dryRun ? "dry-run" : "write"} samples=${
      options.withSamples
    }`,
  );

  let totalCategoriesCreated = 0;
  let totalCategoriesUpdated = 0;
  let totalSamplesCreated = 0;
  let totalSamplesUpdated = 0;

  for (const user of users) {
    const label = user.email ? `${user.uid} (${user.email})` : user.uid;
    const categoryResult = await seedCategories(user.uid, options.dryRun);

    totalCategoriesCreated += categoryResult.created;
    totalCategoriesUpdated += categoryResult.updated;

    let sampleResult = { created: 0, updated: 0 };
    if (options.withSamples) {
      sampleResult = await seedSampleTransactions(
        user.uid,
        categoryResult.categoryIds,
        options.dryRun,
      );
      totalSamplesCreated += sampleResult.created;
      totalSamplesUpdated += sampleResult.updated;
    }

    console.log(
      `- ${label}: categories(created=${categoryResult.created}, updated=${categoryResult.updated})` +
        (options.withSamples
          ? ` samples(created=${sampleResult.created}, updated=${sampleResult.updated})`
          : ""),
    );
  }

  console.log("Done.");
  console.log(
    `Summary categories: created=${totalCategoriesCreated}, updated=${totalCategoriesUpdated}`,
  );
  if (options.withSamples) {
    console.log(
      `Summary samples: created=${totalSamplesCreated}, updated=${totalSamplesUpdated}`,
    );
  }
}

main().catch((error) => {
  console.error("DB init failed:", error.message);
  process.exit(1);
});
