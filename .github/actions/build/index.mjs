import { spawn } from "node:child_process";
import { appendFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";

const assemblyExpression = `
  configurations:
  builtins.mapAttrs (_: configuration: {
    toplevel = configuration.config.system.build.toplevel.drvPath;
    systemPath = configuration.config.system.path.drvPath;
    etc = configuration.config.system.build.etc.drvPath;
    homeManager = builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (_: user: [
          user.home.activationPackage.drvPath
          user.home.path.drvPath
        ]) configuration.config.home-manager.users
      )
    );
  }) configurations
`;

export function pruneGraph(graph, assemblyPaths) {
  const excluded = new Set(assemblyPaths);
  let changed = true;

  while (changed) {
    changed = false;

    for (const [drvPath, derivation] of Object.entries(graph)) {
      if (excluded.has(drvPath)) continue;

      const inputs = Object.keys(derivation.inputDrvs ?? {});
      if (inputs.some((input) => excluded.has(input))) {
        excluded.add(drvPath);
        changed = true;
      }
    }
  }

  return {
    candidates: Object.keys(graph).filter((drvPath) => !excluded.has(drvPath)),
    excluded,
  };
}

export function normalizeGraph(document, storeDir = "/nix/store") {
  if (!("derivations" in document)) return document;

  return Object.fromEntries(
    Object.entries(document.derivations).map(([drvPath, derivation]) => {
      const normalizePath = (path) => (path.startsWith("/") ? path : join(storeDir, path));
      const inputDrvs = Object.fromEntries(
        Object.entries(derivation.inputs?.drvs ?? {}).map(([inputPath, input]) => [
          normalizePath(inputPath),
          input,
        ]),
      );

      return [normalizePath(drvPath), { ...derivation, inputDrvs }];
    }),
  );
}

export function parseBuildPlan(output) {
  const plan = {
    willBuild: [],
    willFetch: [],
    unknown: [],
    unparsed: [],
  };
  let section;

  for (const line of output.split(/\r?\n/)) {
    if (/^(?:this derivation|these \d+ derivations) will be built:$/.test(line)) {
      section = "willBuild";
      continue;
    }

    if (/^(?:this path|these \d+ paths) will be fetched \(.+\):$/.test(line)) {
      section = "willFetch";
      continue;
    }

    if (/^don't know how to build these paths(?: \(.+\))?:$/.test(line)) {
      section = "unknown";
      continue;
    }

    const path = line.match(/^\s+(\/\S+)$/)?.[1];
    if (path && section) {
      plan[section].push(path);
    } else if (path) {
      plan.unparsed.push(path);
    } else if (line.trim() !== "") {
      section = undefined;
    }
  }

  return plan;
}

function getInput(name, defaultValue) {
  return process.env[`INPUT_${name.toUpperCase()}`]?.trim() || defaultValue;
}

function getBooleanInput(name, defaultValue) {
  const value = getInput(name, String(defaultValue)).toLowerCase();
  if (value === "true") return true;
  if (value === "false") return false;
  throw new Error(`${name} must be either true or false`);
}

function run(command, args, { cwd, input, capture = false, quiet = false } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      env: process.env,
      stdio: [
        input === undefined ? "ignore" : "pipe",
        capture ? "pipe" : "inherit",
        capture ? "pipe" : "inherit",
      ],
    });
    const stdout = [];
    const stderr = [];

    if (capture) {
      child.stdout.on("data", (chunk) => stdout.push(chunk));
      child.stderr.on("data", (chunk) => {
        stderr.push(chunk);
        if (!quiet) process.stderr.write(chunk);
      });
    }

    child.on("error", reject);
    child.on("close", (code, signal) => {
      if (code === 0) {
        resolve({
          stdout: Buffer.concat(stdout).toString(),
          stderr: Buffer.concat(stderr).toString(),
        });
        return;
      }

      const status = signal ? `signal ${signal}` : `exit code ${code}`;
      if (quiet) process.stderr.write(Buffer.concat(stderr));
      reject(new Error(`${command} ${args.join(" ")} failed with ${status}`));
    });

    if (input !== undefined) child.stdin.end(input);
  });
}

function formatInstallables(drvPaths) {
  return `${drvPaths.map((drvPath) => `${drvPath}^*`).join("\n")}\n`;
}

function group(name, operation) {
  console.log(`::group::${name}`);
  return Promise.resolve(operation()).finally(() => console.log("::endgroup::"));
}

async function writeSummary({ hosts, graph, candidates, excluded, plan, planOnly }) {
  if (!process.env.GITHUB_STEP_SUMMARY) return;

  const result = planOnly ? "Plan only" : plan.willBuild.length === 0 ? "Cache hit" : "Built";
  const summary = `
## Nix dependency build

| Result | Hosts | Derivations | Excluded | Selected | To build | To fetch |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| ${result} | ${hosts} | ${Object.keys(graph).length} | ${excluded.size} | ${candidates.length} | ${plan.willBuild.length} | ${plan.willFetch.length} |
`;

  await appendFile(process.env.GITHUB_STEP_SUMMARY, summary);
}

export async function main() {
  const cwd = process.env.GITHUB_WORKSPACE ?? process.cwd();
  const flake = getInput("flake", ".");
  const planOnly = getBooleanInput("plan-only", false);

  const assemblies = await group("Evaluate NixOS configurations", async () => {
    const { stdout } = await run(
      "nix",
      ["eval", "--json", `${flake}#nixosConfigurations`, "--apply", assemblyExpression],
      { cwd, capture: true },
    );
    return JSON.parse(stdout);
  });

  const hostAssemblies = Object.values(assemblies);
  if (hostAssemblies.length === 0) throw new Error("No NixOS configurations were found");

  const roots = hostAssemblies.map(({ toplevel }) => toplevel);
  const assemblyPaths = new Set(
    hostAssemblies.flatMap(({ toplevel, systemPath, etc, homeManager }) => [
      toplevel,
      systemPath,
      etc,
      ...homeManager,
    ]),
  );

  const graph = await group("Load derivation graph", async () => {
    const { stdout } = await run("nix", ["derivation", "show", "--recursive", ...roots], {
      cwd,
      capture: true,
    });
    return normalizeGraph(JSON.parse(stdout), dirname(roots[0]));
  });

  for (const drvPath of assemblyPaths) {
    if (!(drvPath in graph))
      throw new Error(`Assembly derivation is missing from the graph: ${drvPath}`);
  }

  const { candidates, excluded } = pruneGraph(graph, assemblyPaths);
  if (candidates.length === 0)
    throw new Error("No dependency derivations remain after excluding assembly outputs");

  const plan = await group("Query binary caches", async () => {
    const { stderr } = await run(
      "nix",
      ["build", "--stdin", "--dry-run", "--no-link", "--log-format", "raw"],
      { cwd, input: formatInstallables(candidates), capture: true, quiet: true },
    );
    return parseBuildPlan(stderr);
  });

  if (plan.unknown.length > 0) {
    throw new Error(`Nix does not know how to build:\n${plan.unknown.join("\n")}`);
  }

  if (plan.unparsed.length > 0) {
    throw new Error(
      `The Nix cache query contains unrecognized paths:\n${plan.unparsed.join("\n")}`,
    );
  }

  const candidateSet = new Set(candidates);
  const unexpected = plan.willBuild.filter((drvPath) => !candidateSet.has(drvPath));
  if (unexpected.length > 0) {
    throw new Error(`The build plan includes excluded derivations:\n${unexpected.join("\n")}`);
  }

  const buildPlan =
    plan.willBuild.length === 0
      ? { willBuild: [], willFetch: [], unknown: [], unparsed: [] }
      : await group("Plan uncached builds", async () => {
          const { stderr } = await run(
            "nix",
            ["build", "--stdin", "--dry-run", "--no-link", "--log-format", "raw"],
            { cwd, input: formatInstallables(plan.willBuild), capture: true },
          );
          return parseBuildPlan(stderr);
        });

  if (buildPlan.unknown.length > 0) {
    throw new Error(`Nix does not know how to build:\n${buildPlan.unknown.join("\n")}`);
  }

  if (buildPlan.unparsed.length > 0) {
    throw new Error(
      `The Nix build plan contains unrecognized paths:\n${buildPlan.unparsed.join("\n")}`,
    );
  }

  const unexpectedBuilds = buildPlan.willBuild.filter((drvPath) => !candidateSet.has(drvPath));
  if (unexpectedBuilds.length > 0) {
    throw new Error(
      `The final plan includes excluded derivations:\n${unexpectedBuilds.join("\n")}`,
    );
  }

  console.log(
    `Hosts: ${hostAssemblies.length}; graph: ${Object.keys(graph).length}; excluded: ${excluded.size}; selected: ${candidates.length}; build: ${buildPlan.willBuild.length}; fetch: ${buildPlan.willFetch.length}`,
  );

  if (!planOnly && buildPlan.willBuild.length > 0) {
    await group("Build uncached dependencies", () =>
      run("nix", ["build", "--stdin", "--no-link", "--keep-going", "--log-format", "raw"], {
        cwd,
        input: formatInstallables(buildPlan.willBuild),
      }),
    );
  }

  await writeSummary({
    hosts: hostAssemblies.length,
    graph,
    candidates,
    excluded,
    plan: buildPlan,
    planOnly,
  });
}

function escapeWorkflowCommand(value) {
  return value.replaceAll("%", "%25").replaceAll("\r", "%0D").replaceAll("\n", "%0A");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    const message = error instanceof Error ? (error.stack ?? error.message) : String(error);
    console.error(`::error::${escapeWorkflowCommand(message)}`);
    process.exitCode = 1;
  });
}
