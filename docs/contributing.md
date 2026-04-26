# Contributing

Thank you for your interest in contributing to Asymmetric Effort Actions. This guide explains how to set up a development environment, make changes, and submit contributions.

## Prerequisites

- **Node.js 20** or later
- **npm** (included with Node.js)
- **Git**

## Repository Structure

```
actions/
  setup-bun/         # Bun runtime installer
    src/              # TypeScript source
    dist/             # Bundled JavaScript (committed)
    __tests__/        # Unit tests
    action.yml        # Action metadata
  fossa-scan/         # FOSSA scanning
    src/              # TypeScript source
    __tests__/        # Unit tests
    action.yml        # Composite action definition
  gh-release/         # GitHub Releases
    src/              # TypeScript source
    dist/             # Bundled JavaScript (committed)
    __tests__/        # Unit tests
    action.yml        # Action metadata
docs/                 # Documentation
scripts/              # Build and maintenance scripts
site/                 # Documentation site source
```

## Getting Started

1. **Fork and clone** the repository:

   ```bash
   git clone https://github.com/<your-username>/actions.git
   cd actions
   ```

2. **Install root dependencies**:

   ```bash
   npm install
   ```

3. **Install action-level dependencies**:

   ```bash
   cd actions/setup-bun && npm install && cd ../..
   cd actions/gh-release && npm install && cd ../..
   cd actions/fossa-scan && npm install && cd ../..
   ```

## Development Workflow

### Running Tests

Run all tests from the repository root:

```bash
npm test
```

Run tests for a specific action:

```bash
npm run test:setup-bun
npm run test:gh-release
npm run test:fossa-scan
```

### Building

Build all Node20 actions (bundles TypeScript into `dist/`):

```bash
npm run build
```

Build a specific action:

```bash
npm run build:setup-bun
npm run build:gh-release
```

### Linting

```bash
npm run lint
```

### Type Checking

```bash
npm run typecheck
```

### Version Synchronization

After updating the version, sync it across all packages:

```bash
npm run version:sync
```

## Making Changes

### For Node20 Actions (setup-bun, gh-release)

1. Edit TypeScript source files in `actions/<name>/src/`.
2. Run tests: `npm run test:<name>`.
3. Run the type checker: `npm run typecheck:<name>`.
4. Run the linter: `npm run lint:<name>`.
5. Build the dist bundle: `npm run build:<name>`.
6. **Commit both the source changes and the updated `dist/` directory.** The `dist/` files are what GitHub Actions actually executes.

### For Composite Actions (fossa-scan)

1. Edit the `action.yml` file directly -- composite actions are defined entirely in YAML.
2. Run tests: `npm run test:fossa-scan`.
3. Commit your changes.

## Submitting a Pull Request

1. Create a feature branch from `main`:

   ```bash
   git checkout -b feature/my-change
   ```

2. Make your changes following the workflow above.

3. Ensure all checks pass:

   ```bash
   npm test
   npm run lint
   npm run typecheck
   npm run build
   ```

4. Write a clear commit message describing the change and its motivation.

5. Push your branch and open a pull request against `main`.

6. In the PR description, include:
   - A summary of the changes
   - Motivation or link to a related issue
   - Any testing you performed beyond automated tests

## Guidelines

### Code Style

- Follow existing patterns in the codebase.
- Use TypeScript strict mode for Node20 actions.
- Use `set -euo pipefail` in all shell scripts (composite actions).
- Prefer explicit error messages using `::error::` annotations.

### Testing

- Write unit tests for all new functionality.
- Tests live in the `__tests__/` directory of each action.
- Use Jest as the test framework (configured via `jest.config.js`).
- Aim for meaningful test coverage -- focus on edge cases and error paths.

### Security

- Never introduce third-party action dependencies. This project only depends on official `actions/*` and `github/*` actions.
- Never log or expose secrets. Use environment variables, not CLI arguments, for sensitive values.
- Validate all inputs before use.
- See [Security Practices](./security.md) for full details.

### Documentation

- Update the relevant docs in `docs/` when adding or changing inputs, outputs, or behavior.
- Keep `action.yml` descriptions accurate and concise.

### Versioning

This project uses semantic versioning:

- **Patch** (v1.0.x): Bug fixes, documentation updates
- **Minor** (v1.x.0): New features, new optional inputs
- **Major** (vX.0.0): Breaking changes to inputs, outputs, or behavior

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](https://github.com/asymmetric-effort/actions/blob/main/LICENSE).
