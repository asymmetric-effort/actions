/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/__tests__"],
  testMatch: ["**/*.test.ts"],
  coverageDirectory: "coverage",
  coverageReporters: ["text", "lcov", "clover"],
  clearMocks: true,
};
