import { NextResponse } from "next/server";

// Health check endpoint — called by Docker HEALTHCHECK in Dockerfile.prod.
// Extend this as you add subsystems (database, queues, external services).
// See workshop/health/README.md for the contract and extension pattern.
export async function GET() {
  return NextResponse.json({ ok: true });
}
