import * as core from "@actions/core";
import { resolveVersion } from "./version";
import { install, getBunVersion } from "./installer";

async function run(): Promise<void> {
  try {
    const bunVersion = core.getInput("bun-version");
    const bunVersionFile = core.getInput("bun-version-file") || undefined;
    const noCache = core.getBooleanInput("no-cache");
    const token = core.getInput("token");

    const versionInfo = await resolveVersion(bunVersion, bunVersionFile, token);
    core.info(`Installing Bun ${versionInfo.resolvedVersion}...`);

    const result = await install(versionInfo, noCache);

    // Verify installation
    const installedVersion = await getBunVersion(result.bunPath);
    core.info(`Bun ${installedVersion} installed successfully`);

    // Set outputs
    core.setOutput("bun-version", installedVersion);
    core.setOutput("bun-path", result.bunPath);
    core.setOutput("cache-hit", result.cacheHit.toString());

    // Save state for post step
    core.saveState("bun-version", installedVersion);
    core.saveState("cache-hit", result.cacheHit.toString());
  } catch (error) {
    if (error instanceof Error) {
      core.setFailed(error.message);
    } else {
      core.setFailed("An unexpected error occurred");
    }
  }
}

run();
