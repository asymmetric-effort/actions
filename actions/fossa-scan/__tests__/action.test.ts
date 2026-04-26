import * as fs from "fs";
import * as path from "path";
import * as yaml from "yaml";

describe("fossa-scan action.yml", () => {
  let actionConfig: Record<string, unknown>;

  beforeAll(() => {
    const actionPath = path.resolve(__dirname, "..", "action.yml");
    const content = fs.readFileSync(actionPath, "utf-8");
    actionConfig = yaml.parse(content);
  });

  it("has required metadata fields", () => {
    expect(actionConfig.name).toBe("FOSSA Scan");
    expect(actionConfig.description).toBeTruthy();
    expect(actionConfig.author).toBe("Asymmetric Effort, LLC");
  });

  it("uses composite runs", () => {
    const runs = actionConfig.runs as Record<string, unknown>;
    expect(runs.using).toBe("composite");
  });

  it("defines api-key as required input", () => {
    const inputs = actionConfig.inputs as Record<string, Record<string, unknown>>;
    expect(inputs["api-key"]).toBeDefined();
    expect(inputs["api-key"].required).toBe(true);
  });

  it("defines optional inputs with defaults", () => {
    const inputs = actionConfig.inputs as Record<string, Record<string, unknown>>;
    expect(inputs["run-tests"].default).toBe("false");
    expect(inputs["endpoint"].default).toBe("https://app.fossa.com");
    expect(inputs["working-directory"].default).toBe(".");
    expect(inputs["cli-version"].default).toBe("latest");
    expect(inputs["debug"].default).toBe("false");
  });

  it("has install, analyze, and test steps", () => {
    const runs = actionConfig.runs as Record<string, Record<string, unknown>[]>;
    const steps = runs.steps;
    expect(steps.length).toBeGreaterThanOrEqual(3);

    const stepNames = steps.map((s) => s.name);
    expect(stepNames).toContain("Validate inputs");
    expect(stepNames).toContain("Install FOSSA CLI");
    expect(stepNames).toContain("Run FOSSA analyze");
    expect(stepNames).toContain("Run FOSSA test");
  });

  it("test step is conditional on run-tests input", () => {
    const runs = actionConfig.runs as Record<string, Record<string, unknown>[]>;
    const testStep = runs.steps.find((s) => s.name === "Run FOSSA test");
    expect(testStep).toBeDefined();
    expect(testStep!.if).toContain("run-tests");
  });

  it("all shell steps use bash", () => {
    const runs = actionConfig.runs as Record<string, Record<string, unknown>[]>;
    for (const step of runs.steps) {
      if (step.run) {
        expect(step.shell).toBe("bash");
      }
    }
  });

  it("install step uses set -euo pipefail", () => {
    const runs = actionConfig.runs as Record<string, Record<string, unknown>[]>;
    const installStep = runs.steps.find((s) => s.name === "Install FOSSA CLI");
    expect(installStep).toBeDefined();
    expect(String(installStep!.run)).toContain("set -euo pipefail");
  });

  it("analyze step sets FOSSA_API_KEY from input", () => {
    const runs = actionConfig.runs as Record<string, Record<string, unknown>[]>;
    const analyzeStep = runs.steps.find((s) => s.name === "Run FOSSA analyze");
    expect(analyzeStep).toBeDefined();
    const env = analyzeStep!.env as Record<string, string>;
    expect(env.FOSSA_API_KEY).toContain("inputs.api-key");
  });

  it("does not contain hardcoded secrets or tokens", () => {
    const content = fs.readFileSync(
      path.resolve(__dirname, "..", "action.yml"),
      "utf-8"
    );
    // Should not contain any hardcoded API keys or tokens
    expect(content).not.toMatch(/[A-Za-z0-9]{32,}/);
    // api-key references should be via inputs
    expect(content).not.toMatch(/FOSSA_API_KEY:\s*["'][^$]/);
  });
});
