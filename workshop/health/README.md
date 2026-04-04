# Health Check Contract

<!-- [Tricycler] Every prod container must expose a health check endpoint.
     Docker polls it to know whether to route traffic or restart the container.
     The path, method, and response format below are the SelfCel convention. -->

## Overview

The Docker `HEALTHCHECK` in `Dockerfile.prod` calls:

```
GET /api/health
```

<!-- [TS-Example] /api/health is a Next.js API route (src/app/api/health/route.ts).
     For another stack: a Go HTTP handler, a Flask route, a Rails controller action, etc.
     The path can be anything — just keep it consistent with the HEALTHCHECK in Dockerfile.prod. -->

This is a Next.js API route that returns HTTP 200 when the application is healthy. Docker reads the HTTP status code via `wget` — success means healthy, failure means unhealthy.

---

## Contract

<!-- [Tricycler] This two-row contract is universal — keep it in every stack. -->

| HTTP status | Body          | Meaning                  |
|-------------|---------------|--------------------------|
| `200`       | `{"ok":true}` | Application is healthy   |
| non-200     | (any)         | One or more checks failed |

---

## Implementation Location

<!-- [TS-Example] Next.js API route path. Replace with your stack's equivalent file. -->

The health check route lives at:

```
src/app/api/health/route.ts
```

The stub always returns healthy. Extend it as you add subsystems — database connections, external service dependencies, queue consumers — to your application.

---

## Reference Implementation

<!-- [TS-Example] TypeScript / Next.js. Replace with your stack's language and framework. -->

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

<!-- [Think] Keep checks lightweight — a simple ping, not a full integration test.
     The health check must complete within the timeout set in Dockerfile.prod
     or Docker marks the container as unhealthy and stops routing traffic to it. -->

Keep checks lightweight — a simple ping, not a full integration test. The health check must complete in under 5 seconds or Docker marks it as failed.

---

## Timing

<!-- [Tricycler] These four parameters exist in every stack's Dockerfile.prod HEALTHCHECK.
     Tune start-period to match your app's actual startup time. -->

The `HEALTHCHECK` in `Dockerfile.prod` is configured as:

```
--interval=30s --timeout=5s --start-period=15s --retries=3
```

- Response must arrive in **under 5 seconds** or Docker marks it failed.
- `--start-period=15s` gives the app time to initialize before checks begin.

Adjust these values in `Dockerfile.prod` to match your application's startup time.
