import * as core from "@actions/core";
import * as fs from "fs";
import * as path from "path";

export interface ReleaseConfig {
  tagName: string;
  releaseName: string;
  body: string;
  draft: boolean;
  prerelease: boolean;
  files: string[];
  workingDirectory: string;
  overwriteFiles: boolean;
  failOnUnmatchedFiles: boolean;
  targetCommitish: string;
  generateReleaseNotes: boolean;
  makeLatest: string;
  token: string;
  owner: string;
  repo: string;
}

export function getConfig(): ReleaseConfig {
  const tagName = core.getInput("tag_name");
  const releaseName = core.getInput("name") || tagName;
  const bodyPath = core.getInput("body_path");
  const workingDirectory = core.getInput("working_directory") || process.cwd();
  const repository = core.getInput("repository");

  let body = core.getInput("body") || "";
  if (bodyPath) {
    const resolvedPath = path.resolve(workingDirectory, bodyPath);
    if (!fs.existsSync(resolvedPath)) {
      throw new Error(`body_path file not found: ${resolvedPath}`);
    }
    body = fs.readFileSync(resolvedPath, "utf-8");
  }

  const filesInput = core.getInput("files");
  const files = filesInput
    ? filesInput
        .split("\n")
        .map((f) => f.trim())
        .filter((f) => f.length > 0)
    : [];

  const [owner, repo] = repository.split("/");
  if (!owner || !repo) {
    throw new Error(`Invalid repository format: ${repository}. Expected owner/repo`);
  }

  return {
    tagName,
    releaseName,
    body,
    draft: core.getBooleanInput("draft"),
    prerelease: core.getBooleanInput("prerelease"),
    files,
    workingDirectory,
    overwriteFiles: core.getBooleanInput("overwrite_files"),
    failOnUnmatchedFiles: core.getBooleanInput("fail_on_unmatched_files"),
    targetCommitish: core.getInput("target_commitish"),
    generateReleaseNotes: core.getBooleanInput("generate_release_notes"),
    makeLatest: core.getInput("make_latest"),
    token: core.getInput("token"),
    owner,
    repo,
  };
}
