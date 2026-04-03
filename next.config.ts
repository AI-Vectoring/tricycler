import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Produces a self-contained build in .next/standalone —
  // no node_modules needed at runtime, ready to containerize.
  output: "standalone",
};

export default nextConfig;
