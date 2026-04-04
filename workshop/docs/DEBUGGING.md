# Debugging

<!-- [Tricycler] The debug container is part of every tricycler stack.
     It runs the same production build as `make prod`, in a full environment
     with profiling tools pre-installed. -->

<!-- [TS-Example] This guide covers Node.js specific tools: clinic.js, 0x, and the Node inspector.
     For another stack, replace these with your runtime's profiler:
     py-spy (Python), pprof (Go), perf (C/Rust). -->

The debug container is your forensics environment — the spare tire you hope to never need but are glad to have. It runs the same production build as `make prod`, in a full Debian environment with Node.js profiling tools pre-installed.

---

## When to use it

<!-- [Tricycler] This applies to any stack — the debug container is always for post-incident forensics. -->
- Production is behaving unexpectedly and you need to reproduce it outside dev
- You need a heap snapshot or flame graph to diagnose a memory leak or CPU spike
- You want to step through the production build with a real debugger

---

## Build and run

<!-- [Tricycler] make debug + docker run pattern is universal. -->
```bash
make debug
docker run --rm -it \
    -p 3000:3000 \
    -p 9229:9229 \
    your-project-debug
```

<!-- [TS-Example] Port 9229 is the Node.js inspector port. Replace if your stack uses a different debugger port. -->
<!-- [Think] You land as root by design — profilers need full system access. -->

You land in a bash shell as root. The standalone server is at `/debug/server.js`.

---

## Node inspector — breakpoints and heap snapshots

<!-- [TS-Example] Node.js inspector protocol. Replace with your stack's debugger. -->

Start the app with the inspector enabled:

```bash
node --inspect=0.0.0.0:9229 server.js
```

Then connect from your host machine:

**Chrome DevTools:**
1. Open Chrome and go to `chrome://inspect`
2. Click **"Configure..."** and add `localhost:9229`
3. Your Node.js process appears under **Remote Target** — click **inspect**

**VS Code:**
Add this to `.vscode/launch.json`:

```json
{
  "type": "node",
  "request": "attach",
  "name": "Attach to debug container",
  "address": "localhost",
  "port": 9229,
  "localRoot": "${workspaceFolder}",
  "remoteRoot": "/debug"
}
```

---

## clinic.js — performance profiling

<!-- [TS-Example] clinic.js is a Node.js specific tool. Replace with your stack's profiler. -->

`clinic doctor` — detects what kind of problem you have (CPU, memory, I/O, async):

```bash
clinic doctor -- node server.js
```

`clinic flame` — CPU flame graph, shows where time is spent:

```bash
clinic flame -- node server.js
```

`clinic bubbleprof` — async operations map, shows where your app is waiting:

```bash
clinic bubbleprof -- node server.js
```

Each command runs your app, collects data while you exercise it, then generates an HTML report. Copy the report out of the container to view it:

```bash
docker cp <container-id>:/debug/<report-folder> ./debug-report
```

---

## 0x — quick flame graphs

<!-- [TS-Example] 0x is a Node.js specific tool. -->

Simpler than clinic for a fast flame graph:

```bash
0x server.js
```

Exercise the app, then Ctrl+C. Opens an interactive flame graph in your browser.

---

## Memory leak investigation

<!-- [TS-Example] Chrome DevTools heap snapshots are Node.js specific. -->

Take a heap snapshot while the app is running:

```bash
node --inspect=0.0.0.0:9229 server.js
```

In Chrome DevTools → **Memory** tab → **Take snapshot**. Take multiple snapshots over time and compare allocations to find what is growing.

---

## Testing as appuser

<!-- [Tricycler] appuser mirrors the production user in every stack. -->

The container runs as root by default. To reproduce a permission issue as the production user:

```bash
su - appuser
node server.js
```

---

## Environment variables

<!-- [Tricycler] Pass env vars with -e — applies to any stack. -->

The debug container inherits `NODE_ENV=production`. Pass additional variables with `-e`:

```bash
docker run --rm -it \
    -p 3000:3000 \
    -p 9229:9229 \
    -e DATABASE_URL=postgresql://... \
    your-project-debug
```
