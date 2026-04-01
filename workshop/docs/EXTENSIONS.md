# Extensions

cluar5 is intentionally minimal. It provides a platform — not an opinion about what you build on top of it. This document describes the natural extension patterns for common needs.

None of these are included in the template. But we strongly recommend you take a look at them if you have needs thay solve.

---

## HTTP


### H2O (C-native HTTP/2)

H2O is a high-performance HTTP 1, 2 and 3! server written in C. It fits the cluar5 model very closely — C owns the server loop, and Lua (via H2O's mruby scripting, or via your own LuaJIT integration) handles routing and business logic. Better choice if you need HTTP as a transport but want C to remain the binding agent.

- [h2o.examp1e.net](https://h2o.examp1e.net)

---

## Databases

### PostgreSQL via libpq (C layer)

The most direct integration: link `libpq` into your C binary, open a connection in `main.c`, and expose query functions to Lua via FFI or to Scheme via C callbacks. No ORM, no extra process, no protocol overhead beyond the wire format itself.

```c
/* c/main.c */
#include <libpq-fe.h>
PGconn *db = PQconnectdb("host=localhost dbname=myapp");
```

Add to `Dockerfile.builder-base`:
```dockerfile
RUN apt-get install -y libpq-dev
```

### PostgreSQL via Lua (luapgsql or pgmoon)

If you prefer to keep database logic in the Lua layer, `pgmoon` (pure Lua, works with LuaJIT) or `luapgsql` (FFI bindings) are the standard options. Install via LuaRocks inside the dev container.

### SQLite (embedded, zero dependencies)

For projects that don't need a separate database process, SQLite is a single `.c` file that links directly into your binary. The `lsqlite3` Lua binding makes it accessible from the Lua layer with minimal code.

---

## Frontend

cluar5 produces a backend binary. Frontend is a separate concern and should live in a separate repository. The backend exposes an API (HTTP, WebSocket, or custom protocol) — the frontend consumes it.

If you need server-side rendering, the Lua layer is the natural place to generate HTML. LuaJIT is fast enough that template rendering is rarely a bottleneck.

---

## Message queues

For event-driven architectures, the standard pattern in this stack is:

1. C owns the socket connection to the broker (AMQP, NATS, Redis Streams)
2. C deserializes the raw message and passes it to Lua as a table
3. Lua routes it to the appropriate handler
4. Complex processing moves to Scheme as needed

Libraries:
- **NATS**: `cnats` (C library, link directly)
- **Redis**: `hiredis` (C library, link directly, expose to Lua via FFI)
- **RabbitMQ**: `rabbitmq-c` (C library)

---

## The general pattern for adding any library

1. If a C library exists: link it in `Dockerfile.builder-base` and `c/main.c`, expose to Lua via FFI or manual bindings
2. If a pure Lua library exists and performance is acceptable: install via LuaRocks in the dev container, load in `lua/main.lua`
3. If neither: implement in Scheme if it's pure logic, or in C if it requires I/O

The stack is designed so that every layer can reach every other layer. There are no artificial boundaries.
