import { mkdirSync, realpathSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function catalogueMetadata(repository, commit) {
  const normalizedRepository = repository.trim().toLowerCase();
  const normalizedCommit = commit.trim().toLowerCase();

  if (!/^[a-z0-9_.-]+\/[a-z0-9_.-]+$/.test(normalizedRepository)) {
    throw new Error('repository must be a GitHub owner/repository slug');
  }
  if (!/^(?:[a-f0-9]{40}|[a-f0-9]{64})$/.test(normalizedCommit)) {
    throw new Error('commit must be a full Git object ID');
  }

  return {
    schemaVersion: 1,
    repository: `github.com/${normalizedRepository}`,
    commit: normalizedCommit,
  };
}

function option(name) {
  const index = process.argv.indexOf(name);
  if (index === -1 || !process.argv[index + 1]) {
    throw new Error(`missing required option ${name}`);
  }
  return process.argv[index + 1];
}

export function main() {
  const output = option('--output');
  const metadata = catalogueMetadata(
    option('--repository'),
    option('--commit'),
  );

  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(output, `${JSON.stringify(metadata, null, 2)}\n`);
}

const invokedPath = process.argv[1];
if (invokedPath && realpathSync(fileURLToPath(import.meta.url)) === realpathSync(resolve(invokedPath))) {
  main();
}
