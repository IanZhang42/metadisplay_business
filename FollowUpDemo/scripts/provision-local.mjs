// Writes private dev secrets, without printing them. Not account credentials.
import { randomBytes } from 'node:crypto';
import { writeFileSync, mkdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../backend');
const template = readFileSync(path.join(root, '.env.example'), 'utf8');
const env = template.replace('APP_AUTH_TOKEN=\n', `APP_AUTH_TOKEN=${randomBytes(32).toString('hex')}\n`)
  .replace('DATA_ENCRYPTION_KEY=\n', `DATA_ENCRYPTION_KEY=${randomBytes(32).toString('hex')}\n`);
mkdirSync(path.join(root, '.data'), { recursive: true, mode: 0o700 });
writeFileSync(path.join(root, '.env'), env, { flag: 'wx', mode: 0o600 });
console.log('Private backend/.env created. Configure it in a private editor; never copy it to iOS/source control. Live sending is false.');
