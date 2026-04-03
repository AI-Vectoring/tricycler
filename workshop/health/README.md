# Health Check Contract

## Overview

The Docker `HEALTHCHECK` in `Dockerfile.prod` calls:

```
GET /api/health
```

This is a Next.js API route that returns HTTP 200 when the application is healthy. Docker reads the HTTP status code via `wget` — success means healthy, failure means unhealthy.

---

## Contract

| HTTP status | Body          | Meaning                  |
|-------------|---------------|--------------------------|
| `200`       | `{"ok":true}` | Application is healthy   |
| non-200     | (any)         | One or more checks failed |

---

## Implementation Location

The health check route lives at:

```
src/app/api/health/route.ts
```

The stub always returns healthy. Extend it as you add subsystems — database connections, external service dependencies, queue consumers — to your application.

---

## Reference Implementation

```typescript
// src/app/api/health/route.ts
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ ok: true });
}
```

---

## Extending the Health Check

Add one check per subsystem:

```typescript
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export async function GET() {
  try {
    await db.$queryRaw`SELECT 1`;
  } catch {
    return NextResponse.json(
      { ok: false, reason: "database unreachable" },
      { status: 503 }
    );
  }

  return NextResponse.json({ ok: true });
}
```

Keep checks lightweight — a simple ping, not a full integration test. The health check must complete in under 5 seconds or Docker marks it as failed.

---

## Timing

The `HEALTHCHECK` in `Dockerfile.prod` is configured as:

```
--interval=30s --timeout=5s --start-period=15s --retries=3
```

- Response must arrive in **under 5 seconds** or Docker marks it failed.
- `--start-period=15s` gives Next.js time to initialize before checks begin.

Adjust these values in `Dockerfile.prod` to match your application's startup time.
