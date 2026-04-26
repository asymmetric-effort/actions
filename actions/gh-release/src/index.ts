import * as core from "@actions/core";
import * as github from "@actions/github";
import { getConfig } from "./config";
import { createOrUpdateRelease } from "./release";
import { resolveFiles, uploadAssets } from "./assets";

async function run(): Promise<void> {
  try {
    const config = getConfig();
    const octokit = github.getOctokit(config.token);

    // Create or update the release
    const release = await createOrUpdateRelease(octokit, config);
    core.info(`Release URL: ${release.url}`);

    // Set outputs
    core.setOutput("url", release.url);
    core.setOutput("id", release.id.toString());
    core.setOutput("upload_url", release.uploadUrl);

    // Upload assets if file patterns specified
    if (config.files.length > 0) {
      const filePaths = await resolveFiles(
        config.files,
        config.workingDirectory,
        config.failOnUnmatchedFiles
      );

      if (filePaths.length > 0) {
        core.info(`Uploading ${filePaths.length} asset(s)...`);
        const assets = await uploadAssets(
          octokit,
          config,
          release.id,
          release.uploadUrl,
          filePaths
        );
        core.setOutput("assets", JSON.stringify(assets));
      } else {
        core.info("No files matched the provided patterns");
        core.setOutput("assets", "[]");
      }
    } else {
      core.setOutput("assets", "[]");
    }
  } catch (error) {
    if (error instanceof Error) {
      core.setFailed(error.message);
    } else {
      core.setFailed("An unexpected error occurred");
    }
  }
}

run();
