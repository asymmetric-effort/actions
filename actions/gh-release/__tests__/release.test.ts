jest.mock("@actions/core");

import { findExistingRelease, createOrUpdateRelease } from "../src/release";
import type { ReleaseConfig } from "../src/config";

function createMockOctokit(overrides: Record<string, unknown> = {}): ReturnType<typeof import("@actions/github").getOctokit> {
  return {
    rest: {
      repos: {
        getReleaseByTag: jest.fn(),
        createRelease: jest.fn(),
        updateRelease: jest.fn(),
        ...overrides,
      },
    },
  } as unknown as ReturnType<typeof import("@actions/github").getOctokit>;
}

function createConfig(overrides: Partial<ReleaseConfig> = {}): ReleaseConfig {
  return {
    tagName: "v1.0.0",
    releaseName: "Release v1.0.0",
    body: "Test release body",
    draft: false,
    prerelease: false,
    files: [],
    workingDirectory: "/workspace",
    overwriteFiles: true,
    failOnUnmatchedFiles: false,
    targetCommitish: "",
    generateReleaseNotes: false,
    makeLatest: "",
    token: "test-token",
    owner: "owner",
    repo: "repo",
    ...overrides,
  };
}

describe("release", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("findExistingRelease", () => {
    it("returns release when found", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockResolvedValue({
          data: {
            id: 123,
            html_url: "https://github.com/owner/repo/releases/tag/v1.0.0",
            upload_url: "https://uploads.github.com/repos/owner/repo/releases/123/assets{?name,label}",
            body: "existing body",
          },
        }),
      });

      const result = await findExistingRelease(octokit, createConfig());
      expect(result).not.toBeNull();
      expect(result!.id).toBe(123);
      expect(result!.body).toBe("existing body");
    });

    it("returns null when release not found (404)", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
      });

      const result = await findExistingRelease(octokit, createConfig());
      expect(result).toBeNull();
    });

    it("rethrows non-404 errors", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 500, message: "Server error" }),
      });

      await expect(findExistingRelease(octokit, createConfig())).rejects.toEqual({
        status: 500,
        message: "Server error",
      });
    });
  });

  describe("createOrUpdateRelease", () => {
    it("creates a new release when none exists", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
        createRelease: jest.fn().mockResolvedValue({
          data: {
            id: 456,
            html_url: "https://github.com/owner/repo/releases/tag/v1.0.0",
            upload_url: "https://uploads.github.com/...",
          },
        }),
      });

      const result = await createOrUpdateRelease(octokit, createConfig());
      expect(result.id).toBe(456);
      expect(octokit.rest.repos.createRelease).toHaveBeenCalledWith(
        expect.objectContaining({
          owner: "owner",
          repo: "repo",
          tag_name: "v1.0.0",
          name: "Release v1.0.0",
          body: "Test release body",
          draft: false,
          prerelease: false,
        })
      );
    });

    it("updates an existing release", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockResolvedValue({
          data: {
            id: 789,
            html_url: "https://github.com/owner/repo/releases/tag/v1.0.0",
            upload_url: "https://uploads.github.com/...",
            body: "old body",
          },
        }),
        updateRelease: jest.fn().mockResolvedValue({
          data: {
            id: 789,
            html_url: "https://github.com/owner/repo/releases/tag/v1.0.0",
            upload_url: "https://uploads.github.com/...",
          },
        }),
      });

      const result = await createOrUpdateRelease(octokit, createConfig());
      expect(result.id).toBe(789);
      expect(octokit.rest.repos.updateRelease).toHaveBeenCalledWith(
        expect.objectContaining({
          release_id: 789,
          tag_name: "v1.0.0",
        })
      );
    });

    it("passes target_commitish when specified", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
        createRelease: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload" },
        }),
      });

      await createOrUpdateRelease(
        octokit,
        createConfig({ targetCommitish: "abc123" })
      );

      expect(octokit.rest.repos.createRelease).toHaveBeenCalledWith(
        expect.objectContaining({ target_commitish: "abc123" })
      );
    });

    it("passes make_latest when specified", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
        createRelease: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload" },
        }),
      });

      await createOrUpdateRelease(
        octokit,
        createConfig({ makeLatest: "true" })
      );

      expect(octokit.rest.repos.createRelease).toHaveBeenCalledWith(
        expect.objectContaining({ make_latest: "true" })
      );
    });

    it("enables generate_release_notes", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
        createRelease: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload" },
        }),
      });

      await createOrUpdateRelease(
        octokit,
        createConfig({ generateReleaseNotes: true })
      );

      expect(octokit.rest.repos.createRelease).toHaveBeenCalledWith(
        expect.objectContaining({ generate_release_notes: true })
      );
    });

    it("creates a draft prerelease", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
        createRelease: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload" },
        }),
      });

      await createOrUpdateRelease(
        octokit,
        createConfig({ draft: true, prerelease: true })
      );

      expect(octokit.rest.repos.createRelease).toHaveBeenCalledWith(
        expect.objectContaining({ draft: true, prerelease: true })
      );
    });

    it("does not pass empty body as undefined on create", async () => {
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockRejectedValue({ status: 404 }),
        createRelease: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload" },
        }),
      });

      await createOrUpdateRelease(octokit, createConfig({ body: "" }));

      expect(octokit.rest.repos.createRelease).toHaveBeenCalledWith(
        expect.objectContaining({ body: undefined })
      );
    });

    it("passes target_commitish on update when specified", async () => {
      const updateFn = jest.fn().mockResolvedValue({
        data: { id: 1, html_url: "url", upload_url: "upload" },
      });
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload", body: "old" },
        }),
        updateRelease: updateFn,
      });

      await createOrUpdateRelease(octokit, createConfig({ targetCommitish: "abc123" }));
      expect(updateFn.mock.calls[0][0].target_commitish).toBe("abc123");
    });

    it("passes make_latest on update when specified", async () => {
      const updateFn = jest.fn().mockResolvedValue({
        data: { id: 1, html_url: "url", upload_url: "upload" },
      });
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload", body: "old" },
        }),
        updateRelease: updateFn,
      });

      await createOrUpdateRelease(octokit, createConfig({ makeLatest: "legacy" }));
      expect(updateFn.mock.calls[0][0].make_latest).toBe("legacy");
    });

    it("does not include body in update when empty", async () => {
      const updateFn = jest.fn().mockResolvedValue({
        data: { id: 1, html_url: "url", upload_url: "upload" },
      });
      const octokit = createMockOctokit({
        getReleaseByTag: jest.fn().mockResolvedValue({
          data: { id: 1, html_url: "url", upload_url: "upload", body: "old" },
        }),
        updateRelease: updateFn,
      });

      await createOrUpdateRelease(octokit, createConfig({ body: "" }));

      const updateCall = updateFn.mock.calls[0][0];
      expect(updateCall.body).toBeUndefined();
    });
  });
});
