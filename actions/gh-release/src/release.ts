import * as github from "@actions/github";
import * as core from "@actions/core";
import type { ReleaseConfig } from "./config";

type Octokit = ReturnType<typeof github.getOctokit>;

export interface ReleaseResult {
  id: number;
  url: string;
  uploadUrl: string;
}

interface ExistingRelease {
  id: number;
  html_url: string;
  upload_url: string;
  body?: string | null;
}

export async function findExistingRelease(
  octokit: Octokit,
  config: ReleaseConfig
): Promise<ExistingRelease | null> {
  try {
    const { data } = await octokit.rest.repos.getReleaseByTag({
      owner: config.owner,
      repo: config.repo,
      tag: config.tagName,
    });
    return {
      id: data.id,
      html_url: data.html_url,
      upload_url: data.upload_url,
      body: data.body,
    };
  } catch (error: unknown) {
    const err = error as { status?: number };
    if (err.status === 404) {
      return null;
    }
    throw error;
  }
}

export async function createOrUpdateRelease(
  octokit: Octokit,
  config: ReleaseConfig
): Promise<ReleaseResult> {
  const existing = await findExistingRelease(octokit, config);

  if (existing) {
    core.info(`Updating existing release for tag ${config.tagName}`);
    return updateRelease(octokit, config, existing);
  }

  core.info(`Creating new release for tag ${config.tagName}`);
  return createRelease(octokit, config);
}

async function createRelease(
  octokit: Octokit,
  config: ReleaseConfig
): Promise<ReleaseResult> {
  const params: Parameters<Octokit["rest"]["repos"]["createRelease"]>[0] = {
    owner: config.owner,
    repo: config.repo,
    tag_name: config.tagName,
    name: config.releaseName,
    body: config.body || undefined,
    draft: config.draft,
    prerelease: config.prerelease,
    generate_release_notes: config.generateReleaseNotes,
  };

  if (config.targetCommitish) {
    params.target_commitish = config.targetCommitish;
  }

  if (config.makeLatest) {
    params.make_latest = config.makeLatest as "true" | "false" | "legacy";
  }

  const { data } = await octokit.rest.repos.createRelease(params);

  return {
    id: data.id,
    url: data.html_url,
    uploadUrl: data.upload_url,
  };
}

async function updateRelease(
  octokit: Octokit,
  config: ReleaseConfig,
  existing: ExistingRelease
): Promise<ReleaseResult> {
  const params: Parameters<Octokit["rest"]["repos"]["updateRelease"]>[0] = {
    owner: config.owner,
    repo: config.repo,
    release_id: existing.id,
    tag_name: config.tagName,
    name: config.releaseName,
    draft: config.draft,
    prerelease: config.prerelease,
  };

  if (config.body) {
    params.body = config.body;
  }

  if (config.targetCommitish) {
    params.target_commitish = config.targetCommitish;
  }

  if (config.makeLatest) {
    params.make_latest = config.makeLatest as "true" | "false" | "legacy";
  }

  const { data } = await octokit.rest.repos.updateRelease(params);

  return {
    id: data.id,
    url: data.html_url,
    uploadUrl: data.upload_url,
  };
}
