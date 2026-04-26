import * as fs from "fs";
import * as path from "path";
import * as core from "@actions/core";
import * as glob from "@actions/glob";
import * as github from "@actions/github";
import type { ReleaseConfig } from "./config";

type Octokit = ReturnType<typeof github.getOctokit>;

export interface UploadedAsset {
  name: string;
  size: number;
  url: string;
  browser_download_url: string;
}

const MIME_TYPES: Record<string, string> = {
  ".zip": "application/zip",
  ".tar": "application/x-tar",
  ".gz": "application/gzip",
  ".tgz": "application/gzip",
  ".bz2": "application/x-bzip2",
  ".xz": "application/x-xz",
  ".exe": "application/octet-stream",
  ".dmg": "application/octet-stream",
  ".deb": "application/vnd.debian.binary-package",
  ".rpm": "application/x-rpm",
  ".pkg": "application/octet-stream",
  ".msi": "application/octet-stream",
  ".js": "application/javascript",
  ".json": "application/json",
  ".txt": "text/plain",
  ".md": "text/markdown",
  ".sha256": "text/plain",
  ".sig": "application/pgp-signature",
  ".asc": "application/pgp-signature",
};

function getMimeType(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  return MIME_TYPES[ext] || "application/octet-stream";
}

export async function resolveFiles(
  patterns: string[],
  workingDirectory: string,
  failOnUnmatched: boolean
): Promise<string[]> {
  const allFiles: string[] = [];

  for (const pattern of patterns) {
    const absolutePattern = path.isAbsolute(pattern)
      ? pattern
      : path.join(workingDirectory, pattern);

    const globber = await glob.create(absolutePattern, { followSymbolicLinks: false });
    const matched = await globber.glob();

    // Filter out directories
    const files = matched.filter((f) => {
      try {
        return fs.statSync(f).isFile();
      } catch {
        return false;
      }
    });

    if (files.length === 0 && failOnUnmatched) {
      throw new Error(`Glob pattern matched no files: ${pattern}`);
    }

    if (files.length === 0) {
      core.warning(`Glob pattern matched no files: ${pattern}`);
    }

    allFiles.push(...files);
  }

  // Deduplicate
  return [...new Set(allFiles)];
}

export async function uploadAssets(
  octokit: Octokit,
  config: ReleaseConfig,
  releaseId: number,
  uploadUrl: string,
  filePaths: string[]
): Promise<UploadedAsset[]> {
  const uploaded: UploadedAsset[] = [];

  if (config.overwriteFiles) {
    await deleteExistingAssets(octokit, config, releaseId, filePaths);
  }

  for (const filePath of filePaths) {
    const fileName = path.basename(filePath);
    const fileSize = fs.statSync(filePath).size;
    const contentType = getMimeType(filePath);

    core.info(`Uploading ${fileName} (${fileSize} bytes, ${contentType})`);

    const data = fs.readFileSync(filePath);

    const { data: asset } = await octokit.rest.repos.uploadReleaseAsset({
      owner: config.owner,
      repo: config.repo,
      release_id: releaseId,
      name: fileName,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      data: data as any,
      headers: {
        "content-type": contentType,
        "content-length": fileSize,
      },
    });

    uploaded.push({
      name: asset.name,
      size: asset.size,
      url: asset.url,
      browser_download_url: asset.browser_download_url,
    });

    core.info(`Uploaded ${fileName} successfully`);
  }

  return uploaded;
}

async function deleteExistingAssets(
  octokit: Octokit,
  config: ReleaseConfig,
  releaseId: number,
  filePaths: string[]
): Promise<void> {
  const fileNames = new Set(filePaths.map((f) => path.basename(f)));

  const { data: existingAssets } = await octokit.rest.repos.listReleaseAssets({
    owner: config.owner,
    repo: config.repo,
    release_id: releaseId,
    per_page: 100,
  });

  for (const asset of existingAssets) {
    if (fileNames.has(asset.name)) {
      core.info(`Deleting existing asset: ${asset.name}`);
      await octokit.rest.repos.deleteReleaseAsset({
        owner: config.owner,
        repo: config.repo,
        asset_id: asset.id,
      });
    }
  }
}
