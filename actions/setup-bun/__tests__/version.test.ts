import * as core from "@actions/core";
import * as httpClient from "@actions/http-client";
import {
  readVersionFromFile,
  readVersionFromPackageJson,
  readVersionFromToolVersions,
  resolveLatestVersion,
  resolveVersion,
} from "../src/version";

// Mock @actions/core before it tries fs.promises
jest.mock("@actions/core");
jest.mock("@actions/http-client");

// Mock fs with automatic mock but preserve promises
jest.mock("fs", () => ({
  ...jest.requireActual<typeof import("fs")>("fs"),
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
}));

jest.mock("path", () => ({
  ...jest.requireActual<typeof import("path")>("path"),
  resolve: jest.fn((...args: string[]) => args.join("/")),
  basename: jest.fn((p: string) => {
    const parts = p.split("/");
    return parts[parts.length - 1];
  }),
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const fs = require("fs");
// eslint-disable-next-line @typescript-eslint/no-var-requires
const path = require("path");
const mockedCore = jest.mocked(core);

describe("version", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("readVersionFromPackageJson", () => {
    it("reads version from packageManager field", () => {
      const content = JSON.stringify({ packageManager: "bun@1.1.0" });
      expect(readVersionFromPackageJson(content)).toBe("1.1.0");
    });

    it("reads version from engines.bun field", () => {
      const content = JSON.stringify({ engines: { bun: ">=1.0.0" } });
      expect(readVersionFromPackageJson(content)).toBe(">=1.0.0");
    });

    it("prioritizes packageManager over engines.bun", () => {
      const content = JSON.stringify({
        packageManager: "bun@1.2.0",
        engines: { bun: ">=1.0.0" },
      });
      expect(readVersionFromPackageJson(content)).toBe("1.2.0");
    });

    it("returns null when no bun version found", () => {
      const content = JSON.stringify({ name: "test-pkg" });
      expect(readVersionFromPackageJson(content)).toBeNull();
    });

    it("returns null for invalid JSON", () => {
      expect(readVersionFromPackageJson("not json")).toBeNull();
      expect(mockedCore.warning).toHaveBeenCalledWith("Failed to parse package.json");
    });

    it("ignores non-bun packageManager", () => {
      const content = JSON.stringify({ packageManager: "npm@9.0.0" });
      expect(readVersionFromPackageJson(content)).toBeNull();
    });

    it("returns null if engines exists but no bun key", () => {
      const content = JSON.stringify({ engines: { node: ">=18" } });
      expect(readVersionFromPackageJson(content)).toBeNull();
    });

    it("returns null if engines.bun is not a string", () => {
      const content = JSON.stringify({ engines: { bun: 123 } });
      expect(readVersionFromPackageJson(content)).toBeNull();
    });
  });

  describe("readVersionFromToolVersions", () => {
    it("reads bun version from .tool-versions", () => {
      const content = "nodejs 20.0.0\nbun 1.0.5\npython 3.11";
      expect(readVersionFromToolVersions(content)).toBe("1.0.5");
    });

    it("returns null when bun not listed", () => {
      const content = "nodejs 20.0.0\npython 3.11";
      expect(readVersionFromToolVersions(content)).toBeNull();
    });

    it("handles extra whitespace", () => {
      const content = "  bun   1.0.5  ";
      expect(readVersionFromToolVersions(content)).toBe("1.0.5");
    });

    it("returns null for empty content", () => {
      expect(readVersionFromToolVersions("")).toBeNull();
    });

    it("handles bun as only entry", () => {
      expect(readVersionFromToolVersions("bun 1.2.3")).toBe("1.2.3");
    });
  });

  describe("readVersionFromFile", () => {
    it("reads from package.json", () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(
        JSON.stringify({ packageManager: "bun@1.1.0" })
      );
      path.basename.mockReturnValue("package.json");

      expect(readVersionFromFile("package.json")).toBe("1.1.0");
    });

    it("reads from .tool-versions", () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue("bun 1.0.5\n");
      path.basename.mockReturnValue(".tool-versions");

      expect(readVersionFromFile(".tool-versions")).toBe("1.0.5");
    });

    it("reads plain text version from other files", () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue("1.0.5\n");
      path.basename.mockReturnValue(".bun-version");

      expect(readVersionFromFile(".bun-version")).toBe("1.0.5");
    });

    it("returns null for empty plain text file", () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue("");
      path.basename.mockReturnValue(".bun-version");

      expect(readVersionFromFile(".bun-version")).toBeNull();
    });

    it("returns null and warns when file not found", () => {
      fs.existsSync.mockReturnValue(false);

      expect(readVersionFromFile("nonexistent.json")).toBeNull();
      expect(mockedCore.warning).toHaveBeenCalled();
    });
  });

  describe("resolveLatestVersion", () => {
    it("fetches latest version from GitHub API", async () => {
      const mockClient = {
        getJson: jest.fn().mockResolvedValue({
          statusCode: 200,
          result: { tag_name: "bun-v1.1.0" },
        }),
      };
      jest
        .spyOn(httpClient, "HttpClient")
        .mockImplementation(() => mockClient as unknown as httpClient.HttpClient);

      const result = await resolveLatestVersion("test-token");
      expect(result).toBe("1.1.0");
    });

    it("throws on API error", async () => {
      const mockClient = {
        getJson: jest.fn().mockResolvedValue({
          statusCode: 403,
          result: null,
        }),
      };
      jest
        .spyOn(httpClient, "HttpClient")
        .mockImplementation(() => mockClient as unknown as httpClient.HttpClient);

      await expect(resolveLatestVersion("test-token")).rejects.toThrow(
        "Failed to fetch latest Bun release: HTTP 403"
      );
    });
  });

  describe("resolveVersion", () => {
    const originalPlatform = process.platform;
    const originalArch = process.arch;

    beforeEach(() => {
      Object.defineProperty(process, "platform", { value: "linux" });
      Object.defineProperty(process, "arch", { value: "x64" });
    });

    afterEach(() => {
      Object.defineProperty(process, "platform", { value: originalPlatform });
      Object.defineProperty(process, "arch", { value: originalArch });
    });

    it("resolves canary version", async () => {
      const result = await resolveVersion("canary", undefined, "token");
      expect(result.version).toBe("canary");
      expect(result.downloadUrl).toContain("canary");
    });

    it("resolves explicit version", async () => {
      const result = await resolveVersion("1.0.5", undefined, "token");
      expect(result.version).toBe("1.0.5");
      expect(result.downloadUrl).toContain("bun-v1.0.5");
      expect(result.downloadUrl).toContain("linux-x64");
    });

    it("strips leading v from version", async () => {
      const result = await resolveVersion("v1.0.5", undefined, "token");
      expect(result.version).toBe("1.0.5");
    });

    it("resolves from version file when version is latest", async () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(
        JSON.stringify({ packageManager: "bun@1.2.0" })
      );
      path.basename.mockReturnValue("package.json");

      const result = await resolveVersion("latest", "package.json", "token");
      expect(result.version).toBe("1.2.0");
    });

    it("falls back to latest when version file has no bun version", async () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(JSON.stringify({ name: "test" }));
      path.basename.mockReturnValue("package.json");

      const mockClient = {
        getJson: jest.fn().mockResolvedValue({
          statusCode: 200,
          result: { tag_name: "bun-v1.3.0" },
        }),
      };
      jest
        .spyOn(httpClient, "HttpClient")
        .mockImplementation(() => mockClient as unknown as httpClient.HttpClient);

      const result = await resolveVersion("latest", "package.json", "token");
      expect(result.version).toBe("1.3.0");
    });

    it("builds correct download URL for darwin arm64", async () => {
      Object.defineProperty(process, "platform", { value: "darwin" });
      Object.defineProperty(process, "arch", { value: "arm64" });

      const result = await resolveVersion("1.0.0", undefined, "token");
      expect(result.downloadUrl).toContain("darwin-aarch64");
    });

    it("builds correct download URL for windows x64", async () => {
      Object.defineProperty(process, "platform", { value: "win32" });
      Object.defineProperty(process, "arch", { value: "x64" });

      const result = await resolveVersion("1.0.0", undefined, "token");
      expect(result.downloadUrl).toContain("windows-x64");
    });

    it("throws for unsupported platform", async () => {
      Object.defineProperty(process, "platform", { value: "freebsd" });
      await expect(resolveVersion("1.0.0", undefined, "token")).rejects.toThrow(
        "Unsupported platform"
      );
    });

    it("throws for unsupported architecture", async () => {
      Object.defineProperty(process, "arch", { value: "ia32" });
      await expect(resolveVersion("1.0.0", undefined, "token")).rejects.toThrow(
        "Unsupported architecture"
      );
    });
  });
});
