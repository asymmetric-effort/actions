import * as path from "path";
import * as core from "@actions/core";
import * as tc from "@actions/tool-cache";
import * as exec from "@actions/exec";
import type { VersionInfo } from "./version";

const TOOL_NAME = "bun";

export interface InstallResult {
  version: string;
  bunPath: string;
  cacheHit: boolean;
}

export async function install(
  versionInfo: VersionInfo,
  noCache: boolean
): Promise<InstallResult> {
  const { resolvedVersion, downloadUrl } = versionInfo;

  // Check tool cache first
  if (!noCache && resolvedVersion !== "canary") {
    const cachedPath = tc.find(TOOL_NAME, resolvedVersion);
    if (cachedPath) {
      core.info(`Found Bun ${resolvedVersion} in tool cache`);
      const bunPath = path.join(cachedPath, getBinaryName());
      addToPath(cachedPath);
      return { version: resolvedVersion, bunPath, cacheHit: true };
    }
  }

  core.info(`Downloading Bun from ${downloadUrl}`);
  const downloadedPath = await tc.downloadTool(downloadUrl);

  core.info("Extracting archive...");
  const extractedPath = await tc.extractZip(downloadedPath);

  // Find the bun binary inside the extracted directory
  const bunDir = await findBunDirectory(extractedPath);

  // Cache the tool (skip for canary since version changes)
  let toolPath: string;
  if (!noCache && resolvedVersion !== "canary") {
    toolPath = await tc.cacheDir(bunDir, TOOL_NAME, resolvedVersion);
  } else {
    toolPath = bunDir;
  }

  const bunPath = path.join(toolPath, getBinaryName());
  addToPath(toolPath);

  return { version: resolvedVersion, bunPath, cacheHit: false };
}

async function findBunDirectory(extractedPath: string): Promise<string> {
  // The zip extracts to a folder like bun-linux-x64/
  const fs = await import("fs");
  const entries = fs.readdirSync(extractedPath);

  for (const entry of entries) {
    const fullPath = path.join(extractedPath, entry);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory() && entry.startsWith("bun-")) {
      return fullPath;
    }
  }

  // If no subdirectory, assume the binary is in the root
  return extractedPath;
}

function getBinaryName(): string {
  return process.platform === "win32" ? "bun.exe" : "bun";
}

function addToPath(dir: string): void {
  core.addPath(dir);
  core.info(`Added ${dir} to PATH`);
}

export async function getBunVersion(bunPath: string): Promise<string> {
  let output = "";
  await exec.exec(bunPath, ["--version"], {
    listeners: {
      stdout: (data: Buffer) => {
        output += data.toString();
      },
    },
    silent: true,
  });
  return output.trim();
}
