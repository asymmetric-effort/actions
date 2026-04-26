import * as core from "@actions/core";
import * as tc from "@actions/tool-cache";
import * as exec from "@actions/exec";
import { install, getBunVersion } from "../src/installer";
import type { VersionInfo } from "../src/version";

jest.mock("@actions/core");
jest.mock("@actions/tool-cache");
jest.mock("@actions/exec");

// Mock fs while preserving promises for @actions/core
jest.mock("fs", () => ({
  ...jest.requireActual<typeof import("fs")>("fs"),
  readdirSync: jest.fn().mockReturnValue(["bun-linux-x64"]),
  statSync: jest.fn().mockReturnValue({ isDirectory: () => true }),
}));

const mockedCore = jest.mocked(core);
const mockedTc = jest.mocked(tc);
const mockedExec = jest.mocked(exec);

describe("installer", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("install", () => {
    const versionInfo: VersionInfo = {
      version: "1.0.5",
      resolvedVersion: "1.0.5",
      downloadUrl: "https://github.com/oven-sh/bun/releases/download/bun-v1.0.5/bun-linux-x64.zip",
    };

    it("returns from cache when available", async () => {
      mockedTc.find.mockReturnValue("/cached/bun/1.0.5");

      const result = await install(versionInfo, false);

      expect(result.cacheHit).toBe(true);
      expect(result.version).toBe("1.0.5");
      expect(result.bunPath).toContain("bun");
      expect(mockedCore.addPath).toHaveBeenCalledWith("/cached/bun/1.0.5");
      expect(mockedTc.downloadTool).not.toHaveBeenCalled();
    });

    it("downloads and installs when not cached", async () => {
      mockedTc.find.mockReturnValue("");
      mockedTc.downloadTool.mockResolvedValue("/tmp/download.zip");
      mockedTc.extractZip.mockResolvedValue("/tmp/extracted");
      mockedTc.cacheDir.mockResolvedValue("/cached/bun/1.0.5");

      const result = await install(versionInfo, false);

      expect(result.cacheHit).toBe(false);
      expect(result.version).toBe("1.0.5");
      expect(mockedTc.downloadTool).toHaveBeenCalledWith(versionInfo.downloadUrl);
      expect(mockedTc.extractZip).toHaveBeenCalledWith("/tmp/download.zip");
      expect(mockedTc.cacheDir).toHaveBeenCalled();
      expect(mockedCore.addPath).toHaveBeenCalled();
    });

    it("skips cache check when noCache is true", async () => {
      mockedTc.downloadTool.mockResolvedValue("/tmp/download.zip");
      mockedTc.extractZip.mockResolvedValue("/tmp/extracted");

      const result = await install(versionInfo, true);

      expect(result.cacheHit).toBe(false);
      expect(mockedTc.find).not.toHaveBeenCalled();
      expect(mockedTc.downloadTool).toHaveBeenCalled();
    });

    it("skips caching for canary version", async () => {
      const canaryVersion: VersionInfo = {
        version: "canary",
        resolvedVersion: "canary",
        downloadUrl: "https://github.com/oven-sh/bun/releases/download/canary/bun-linux-x64.zip",
      };
      mockedTc.downloadTool.mockResolvedValue("/tmp/download.zip");
      mockedTc.extractZip.mockResolvedValue("/tmp/extracted");

      const result = await install(canaryVersion, false);

      expect(result.cacheHit).toBe(false);
      expect(mockedTc.cacheDir).not.toHaveBeenCalled();
    });

    it("sets correct binary name on Windows", async () => {
      const originalPlatform = process.platform;
      Object.defineProperty(process, "platform", { value: "win32" });

      mockedTc.find.mockReturnValue("/cached/bun/1.0.5");

      const result = await install(versionInfo, false);
      expect(result.bunPath).toContain("bun.exe");

      Object.defineProperty(process, "platform", { value: originalPlatform });
    });

    it("sets correct binary name on Linux", async () => {
      const originalPlatform = process.platform;
      Object.defineProperty(process, "platform", { value: "linux" });

      mockedTc.find.mockReturnValue("/cached/bun/1.0.5");

      const result = await install(versionInfo, false);
      expect(result.bunPath).toContain("bun");
      expect(result.bunPath).not.toContain("bun.exe");

      Object.defineProperty(process, "platform", { value: originalPlatform });
    });
  });

  describe("getBunVersion", () => {
    it("returns version string from bun --version", async () => {
      mockedExec.exec.mockImplementation(async (_cmd, _args, options) => {
        if (options?.listeners?.stdout) {
          options.listeners.stdout(Buffer.from("1.0.5\n"));
        }
        return 0;
      });

      const version = await getBunVersion("/usr/local/bin/bun");
      expect(version).toBe("1.0.5");
    });

    it("calls exec with --version flag and silent mode", async () => {
      mockedExec.exec.mockImplementation(async () => 0);

      await getBunVersion("/usr/local/bin/bun");

      expect(mockedExec.exec).toHaveBeenCalledWith(
        "/usr/local/bin/bun",
        ["--version"],
        expect.objectContaining({ silent: true })
      );
    });
  });
});
