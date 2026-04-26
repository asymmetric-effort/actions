import * as fs from "fs";
import * as path from "path";
import * as core from "@actions/core";
import * as httpClient from "@actions/http-client";

export interface VersionInfo {
  version: string;
  resolvedVersion: string;
  downloadUrl: string;
}

function getPlatform(): string {
  const platform = process.platform;
  switch (platform) {
    case "linux":
      return "linux";
    case "darwin":
      return "darwin";
    case "win32":
      return "windows";
    default:
      throw new Error(`Unsupported platform: ${platform}`);
  }
}

function getArch(): string {
  const arch = process.arch;
  switch (arch) {
    case "x64":
      return "x64";
    case "arm64":
      return "aarch64";
    default:
      throw new Error(`Unsupported architecture: ${arch}`);
  }
}

function buildDownloadUrl(version: string): string {
  const platform = getPlatform();
  const arch = getArch();
  const tag = version.startsWith("bun-v") ? version : `bun-v${version}`;
  const folder = `bun-${platform}-${arch}`;
  return `https://github.com/oven-sh/bun/releases/download/${tag}/${folder}.zip`;
}

function buildCanaryDownloadUrl(): string {
  const platform = getPlatform();
  const arch = getArch();
  const folder = `bun-${platform}-${arch}`;
  return `https://github.com/oven-sh/bun/releases/download/canary/${folder}.zip`;
}

export function readVersionFromFile(filePath: string): string | null {
  const absPath = path.resolve(filePath);
  if (!fs.existsSync(absPath)) {
    core.warning(`Version file not found: ${absPath}`);
    return null;
  }

  const content = fs.readFileSync(absPath, "utf-8");
  const basename = path.basename(filePath);

  if (basename === "package.json") {
    return readVersionFromPackageJson(content);
  }

  if (basename === ".tool-versions") {
    return readVersionFromToolVersions(content);
  }

  // Treat as plain text version
  const trimmed = content.trim();
  if (trimmed) {
    return trimmed;
  }
  return null;
}

export function readVersionFromPackageJson(content: string): string | null {
  try {
    const pkg = JSON.parse(content) as Record<string, unknown>;

    // Check packageManager field: "bun@1.0.0"
    const packageManager = pkg.packageManager;
    if (typeof packageManager === "string" && packageManager.startsWith("bun@")) {
      return packageManager.replace("bun@", "");
    }

    // Check engines.bun field
    const engines = pkg.engines;
    if (engines && typeof engines === "object" && "bun" in engines) {
      const bunVersion = (engines as Record<string, string>).bun;
      if (typeof bunVersion === "string") {
        return bunVersion;
      }
    }

    return null;
  } catch {
    core.warning("Failed to parse package.json");
    return null;
  }
}

export function readVersionFromToolVersions(content: string): string | null {
  const lines = content.split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith("bun ")) {
      const parts = trimmed.split(/\s+/);
      if (parts.length >= 2) {
        return parts[1];
      }
    }
  }
  return null;
}

export async function resolveLatestVersion(token: string): Promise<string> {
  const client = new httpClient.HttpClient("setup-bun-action", [], {
    headers: {
      Authorization: `token ${token}`,
      Accept: "application/vnd.github.v3+json",
    },
  });

  const response = await client.getJson<{ tag_name: string }>(
    "https://api.github.com/repos/oven-sh/bun/releases/latest"
  );

  if (response.statusCode !== 200 || !response.result) {
    throw new Error(
      `Failed to fetch latest Bun release: HTTP ${response.statusCode}`
    );
  }

  const tag = response.result.tag_name;
  // Tag format: "bun-v1.0.0"
  return tag.replace("bun-v", "");
}

export async function resolveVersion(
  requestedVersion: string,
  versionFile: string | undefined,
  token: string
): Promise<VersionInfo> {
  let version = requestedVersion;

  // Priority: explicit version > version file > latest
  if (versionFile && (!version || version === "latest")) {
    const fileVersion = readVersionFromFile(versionFile);
    if (fileVersion) {
      version = fileVersion;
      core.info(`Resolved Bun version from file: ${version}`);
    }
  }

  if (version === "canary") {
    return {
      version: "canary",
      resolvedVersion: "canary",
      downloadUrl: buildCanaryDownloadUrl(),
    };
  }

  if (!version || version === "latest") {
    version = await resolveLatestVersion(token);
    core.info(`Resolved latest Bun version: ${version}`);
  }

  // Strip leading 'v' if present
  version = version.replace(/^v/, "");

  return {
    version,
    resolvedVersion: version,
    downloadUrl: buildDownloadUrl(version),
  };
}
