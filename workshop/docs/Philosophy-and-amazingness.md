# The Philosophy of SelfCel

---

Deployment platforms are excellent. This is not a criticism of deployment platforms.

But excellent tools can still create dependencies you did not choose, costs that compound as you grow, and constraints you only discover when it's too late to care. SelfCel exists because the answer to "where does my app run?" should always be "wherever I want."

---

## The false choice

The industry presents self-hosting and developer experience as opposites. You can have the polished deployment workflow, the instant previews, the zero-config pipeline — or you can have ownership. Not both.

SelfCel refuses this trade-off.

Next.js with `output: 'standalone'` produces a self-contained server. Node.js runs everywhere. A VPS costs a fraction of what platform fees become at scale. The developer experience — hot reload, TypeScript, Tailwind, Prisma — is identical whether your production target is someone else's infrastructure or a machine you control.

The gap was never technical. It was a template gap. Nobody had assembled the pieces into something you could clone and ship.

That is what SelfCel is.

---

## Your app, your server, your rules

When your app runs on your VPS:

- You know exactly what it costs. Always.
- You can inspect it, profile it, restart it, move it.
- No vendor decides what runtimes or regions are available.
- No platform reads your logs to train anything.
- The bill does not change when you go viral.

These are not small things. They are the difference between building on ground you own and building on ground you rent from someone who can change the terms.

---

## The three containers

SelfCel's container model is not a DevOps configuration. It is a philosophy made concrete.

**Dev** is where you think. Hot reload, full toolchain, nothing optimized. The environment is maximally helpful because speed of iteration matters more than anything else at this stage.

**Stage** is where you verify. The same build as production, in an environment where you can still poke at it. The question stage answers is simple: does it actually work, or does it just work on my machine?

**Prod** is where you ship. Minimal. Locked down. Alpine. No shell, no dev tools, nothing that is not the app. Every capability removed is an attack surface eliminated.

Three containers. Three questions: *Can I build it? Does it work? Can I ship it?* One coherent system that answers all three.

---

## Why Next.js

Next.js is the closest thing the JavaScript ecosystem has to a complete, opinionated answer to web development. Server components, API routes, TypeScript by default, image optimization, routing, and a build system that actually works — all in one framework.

Its standalone build mode produces exactly the right artifact for self-hosting: a Node.js server with everything it needs bundled in. No platform dependency. No runtime surprise. Just a server you run on a machine you control.

SelfCel gives that artifact a home, a container model, and a path from first clone to production.

---

## The bearded man

Somewhere in this repo there is a bearded man on a tricycle, pedaling furiously, with VALGRIND and KERNEL DEV stickers on his baskets.

He does not care about platform lock-in. He is already in production.

---

*SelfCel. Your app. Your server. Your rules.*
