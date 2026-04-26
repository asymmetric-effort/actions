jest.mock("@actions/core");
jest.mock("fs", () => ({
  ...jest.requireActual<typeof import("fs")>("fs"),
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
}));

import * as core from "@actions/core";
import { getConfig } from "../src/config";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require("fs");
const mockedCore = jest.mocked(core);

describe("config", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockedCore.getInput.mockImplementation((name: string) => {
      const inputs: Record<string, string> = {
        tag_name: "v1.0.0",
        name: "Release v1.0.0",
        body: "Test release",
        body_path: "",
        files: "",
        working_directory: "/workspace",
        repository: "owner/repo",
        token: "test-token",
        target_commitish: "",
        make_latest: "",
      };
      return inputs[name] || "";
    });
    mockedCore.getBooleanInput.mockImplementation((name: string) => {
      const inputs: Record<string, boolean> = {
        draft: false,
        prerelease: false,
        overwrite_files: true,
        fail_on_unmatched_files: false,
        generate_release_notes: false,
      };
      return inputs[name] ?? false;
    });
  });

  it("parses basic config", () => {
    const config = getConfig();

    expect(config.tagName).toBe("v1.0.0");
    expect(config.releaseName).toBe("Release v1.0.0");
    expect(config.body).toBe("Test release");
    expect(config.draft).toBe(false);
    expect(config.prerelease).toBe(false);
    expect(config.owner).toBe("owner");
    expect(config.repo).toBe("repo");
    expect(config.token).toBe("test-token");
  });

  it("defaults release name to tag name when empty", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "name") return "";
      if (name === "tag_name") return "v2.0.0";
      if (name === "repository") return "owner/repo";
      if (name === "working_directory") return "/workspace";
      return "";
    });

    const config = getConfig();
    expect(config.releaseName).toBe("v2.0.0");
  });

  it("reads body from file when body_path is set", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "body_path") return "CHANGELOG.md";
      if (name === "body") return "";
      if (name === "repository") return "owner/repo";
      if (name === "tag_name") return "v1.0.0";
      if (name === "working_directory") return "/workspace";
      return "";
    });
    fs.existsSync.mockReturnValue(true);
    fs.readFileSync.mockReturnValue("# Changelog\n\n- Feature A");

    const config = getConfig();
    expect(config.body).toBe("# Changelog\n\n- Feature A");
  });

  it("throws when body_path file does not exist", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "body_path") return "MISSING.md";
      if (name === "repository") return "owner/repo";
      if (name === "tag_name") return "v1.0.0";
      if (name === "working_directory") return "/workspace";
      return "";
    });
    fs.existsSync.mockReturnValue(false);

    expect(() => getConfig()).toThrow("body_path file not found");
  });

  it("parses multiline file patterns", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "files") return "dist/*.tar.gz\ndist/*.zip\n";
      if (name === "repository") return "owner/repo";
      if (name === "tag_name") return "v1.0.0";
      if (name === "working_directory") return "/workspace";
      return "";
    });

    const config = getConfig();
    expect(config.files).toEqual(["dist/*.tar.gz", "dist/*.zip"]);
  });

  it("handles empty file patterns", () => {
    const config = getConfig();
    expect(config.files).toEqual([]);
  });

  it("throws on invalid repository format", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "repository") return "invalid-format";
      if (name === "tag_name") return "v1.0.0";
      if (name === "working_directory") return "/workspace";
      return "";
    });

    expect(() => getConfig()).toThrow("Invalid repository format");
  });

  it("uses cwd when working_directory is empty", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "working_directory") return "";
      if (name === "repository") return "owner/repo";
      if (name === "tag_name") return "v1.0.0";
      return "";
    });

    const config = getConfig();
    expect(config.workingDirectory).toBe(process.cwd());
  });

  it("filters empty lines from file patterns", () => {
    mockedCore.getInput.mockImplementation((name: string) => {
      if (name === "files") return "\n  \ndist/*.zip\n\n";
      if (name === "repository") return "owner/repo";
      if (name === "tag_name") return "v1.0.0";
      if (name === "working_directory") return "/workspace";
      return "";
    });

    const config = getConfig();
    expect(config.files).toEqual(["dist/*.zip"]);
  });
});
