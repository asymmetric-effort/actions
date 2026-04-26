import * as core from "@actions/core";

async function post(): Promise<void> {
  try {
    const cacheHit = core.getState("cache-hit");
    const version = core.getState("bun-version");

    if (cacheHit === "true") {
      core.info(`Bun ${version} was restored from cache. No save needed.`);
      return;
    }

    core.info(`Bun ${version} was freshly installed. Cache saved by tool-cache.`);
  } catch (error) {
    if (error instanceof Error) {
      core.warning(`Post step failed: ${error.message}`);
    }
  }
}

post();
