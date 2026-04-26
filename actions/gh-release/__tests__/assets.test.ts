jest.mock("@actions/core");
jest.mock("@actions/glob");
jest.mock("fs", () => ({
  ...jest.requireActual<typeof import("fs")>("fs"),
  statSync: jest.fn(),
  readFileSync: jest.fn(),
}));

import * as core from "@actions/core";
import * as glob from "@actions/glob";
import { resolveFiles, uploadAssets } from "../src/assets";
import type { ReleaseConfig } from "../src/config";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require("fs");
const mockedCore = jest.mocked(core);
const mockedGlob = jest.mocked(glob);

function createConfig(overrides: Partial<ReleaseConfig> = {}): ReleaseConfig {
  return {
    tagName: "v1.0.0",
    releaseName: "Release v1.0.0",
    body: "",
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

describe("assets", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("resolveFiles", () => {
    it("resolves glob patterns to file paths", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue(["/workspace/dist/app.tar.gz"]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);
      fs.statSync.mockReturnValue({ isFile: () => true });

      const files = await resolveFiles(["dist/*.tar.gz"], "/workspace", false);
      expect(files).toEqual(["/workspace/dist/app.tar.gz"]);
    });

    it("deduplicates files", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue(["/workspace/dist/app.tar.gz"]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);
      fs.statSync.mockReturnValue({ isFile: () => true });

      const files = await resolveFiles(
        ["dist/*.tar.gz", "dist/app.tar.gz"],
        "/workspace",
        false
      );
      expect(files).toEqual(["/workspace/dist/app.tar.gz"]);
    });

    it("filters out directories", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue(["/workspace/dist", "/workspace/dist/app.zip"]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);
      fs.statSync.mockImplementation((p: string) => {
        const isFile = String(p).endsWith(".zip");
        return { isFile: () => isFile };
      });

      const files = await resolveFiles(["dist/**"], "/workspace", false);
      expect(files).toEqual(["/workspace/dist/app.zip"]);
    });

    it("throws when failOnUnmatched and no files match", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue([]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);

      await expect(
        resolveFiles(["dist/*.missing"], "/workspace", true)
      ).rejects.toThrow("Glob pattern matched no files");
    });

    it("warns but does not throw when failOnUnmatched is false", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue([]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);

      const files = await resolveFiles(["dist/*.missing"], "/workspace", false);
      expect(files).toEqual([]);
      expect(mockedCore.warning).toHaveBeenCalled();
    });

    it("handles absolute patterns", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue(["/abs/path/file.zip"]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);
      fs.statSync.mockReturnValue({ isFile: () => true });

      const files = await resolveFiles(["/abs/path/*.zip"], "/workspace", false);
      expect(files).toEqual(["/abs/path/file.zip"]);
      expect(mockedGlob.create).toHaveBeenCalledWith("/abs/path/*.zip", expect.any(Object));
    });

    it("handles statSync errors gracefully", async () => {
      const mockGlobber = {
        glob: jest.fn().mockResolvedValue(["/workspace/dist/bad-file"]),
        getSearchPaths: jest.fn(),
      };
      mockedGlob.create.mockResolvedValue(mockGlobber as unknown as glob.Globber);
      fs.statSync.mockImplementation(() => {
        throw new Error("ENOENT");
      });

      const files = await resolveFiles(["dist/*"], "/workspace", false);
      expect(files).toEqual([]);
    });
  });

  describe("uploadAssets", () => {
    it("uploads files and returns metadata", async () => {
      const config = createConfig({ overwriteFiles: false });
      const mockOctokit = {
        rest: {
          repos: {
            uploadReleaseAsset: jest.fn().mockResolvedValue({
              data: {
                name: "app.tar.gz",
                size: 1024,
                url: "https://api.github.com/assets/1",
                browser_download_url: "https://github.com/downloads/app.tar.gz",
              },
            }),
            listReleaseAssets: jest.fn(),
            deleteReleaseAsset: jest.fn(),
          },
        },
      } as unknown as ReturnType<typeof import("@actions/github").getOctokit>;

      fs.statSync.mockReturnValue({ size: 1024 });
      fs.readFileSync.mockReturnValue(Buffer.from("data"));

      const result = await uploadAssets(
        mockOctokit,
        config,
        123,
        "https://uploads.github.com/...",
        ["/workspace/dist/app.tar.gz"]
      );

      expect(result).toHaveLength(1);
      expect(result[0].name).toBe("app.tar.gz");
      expect(result[0].size).toBe(1024);
    });

    it("deletes existing assets when overwrite is enabled", async () => {
      const config = createConfig({ overwriteFiles: true });
      const deleteAsset = jest.fn().mockResolvedValue({});
      const mockOctokit = {
        rest: {
          repos: {
            uploadReleaseAsset: jest.fn().mockResolvedValue({
              data: {
                name: "app.tar.gz",
                size: 1024,
                url: "https://api.github.com/assets/2",
                browser_download_url: "https://github.com/downloads/app.tar.gz",
              },
            }),
            listReleaseAssets: jest.fn().mockResolvedValue({
              data: [
                { id: 99, name: "app.tar.gz" },
                { id: 100, name: "other.zip" },
              ],
            }),
            deleteReleaseAsset: deleteAsset,
          },
        },
      } as unknown as ReturnType<typeof import("@actions/github").getOctokit>;

      fs.statSync.mockReturnValue({ size: 1024 });
      fs.readFileSync.mockReturnValue(Buffer.from("data"));

      await uploadAssets(
        mockOctokit,
        config,
        123,
        "https://uploads.github.com/...",
        ["/workspace/dist/app.tar.gz"]
      );

      expect(deleteAsset).toHaveBeenCalledTimes(1);
      expect(deleteAsset).toHaveBeenCalledWith(
        expect.objectContaining({ asset_id: 99 })
      );
    });

    it("sets correct content-type for zip files", async () => {
      const config = createConfig({ overwriteFiles: false });
      const uploadFn = jest.fn().mockResolvedValue({
        data: {
          name: "app.zip",
          size: 2048,
          url: "https://api.github.com/assets/3",
          browser_download_url: "https://github.com/downloads/app.zip",
        },
      });
      const mockOctokit = {
        rest: {
          repos: {
            uploadReleaseAsset: uploadFn,
            listReleaseAssets: jest.fn(),
            deleteReleaseAsset: jest.fn(),
          },
        },
      } as unknown as ReturnType<typeof import("@actions/github").getOctokit>;

      fs.statSync.mockReturnValue({ size: 2048 });
      fs.readFileSync.mockReturnValue(Buffer.from("zipdata"));

      await uploadAssets(
        mockOctokit,
        config,
        123,
        "https://uploads.github.com/...",
        ["/workspace/dist/app.zip"]
      );

      expect(uploadFn).toHaveBeenCalledWith(
        expect.objectContaining({
          headers: expect.objectContaining({
            "content-type": "application/zip",
          }),
        })
      );
    });

    it("uses application/octet-stream for unknown extensions", async () => {
      const config = createConfig({ overwriteFiles: false });
      const uploadFn = jest.fn().mockResolvedValue({
        data: {
          name: "app.xyz",
          size: 100,
          url: "url",
          browser_download_url: "dl-url",
        },
      });
      const mockOctokit = {
        rest: {
          repos: {
            uploadReleaseAsset: uploadFn,
            listReleaseAssets: jest.fn(),
            deleteReleaseAsset: jest.fn(),
          },
        },
      } as unknown as ReturnType<typeof import("@actions/github").getOctokit>;

      fs.statSync.mockReturnValue({ size: 100 });
      fs.readFileSync.mockReturnValue(Buffer.from("data"));

      await uploadAssets(mockOctokit, config, 123, "url", ["/workspace/app.xyz"]);

      expect(uploadFn).toHaveBeenCalledWith(
        expect.objectContaining({
          headers: expect.objectContaining({
            "content-type": "application/octet-stream",
          }),
        })
      );
    });

    it("uploads multiple files", async () => {
      const config = createConfig({ overwriteFiles: false });
      const uploadFn = jest.fn().mockImplementation(({ name }) =>
        Promise.resolve({
          data: { name, size: 100, url: "url", browser_download_url: "dl" },
        })
      );
      const mockOctokit = {
        rest: {
          repos: {
            uploadReleaseAsset: uploadFn,
            listReleaseAssets: jest.fn(),
            deleteReleaseAsset: jest.fn(),
          },
        },
      } as unknown as ReturnType<typeof import("@actions/github").getOctokit>;

      fs.statSync.mockReturnValue({ size: 100 });
      fs.readFileSync.mockReturnValue(Buffer.from("data"));

      const result = await uploadAssets(
        mockOctokit,
        config,
        123,
        "url",
        ["/workspace/a.zip", "/workspace/b.tar.gz"]
      );

      expect(uploadFn).toHaveBeenCalledTimes(2);
      expect(result).toHaveLength(2);
    });
  });
});
