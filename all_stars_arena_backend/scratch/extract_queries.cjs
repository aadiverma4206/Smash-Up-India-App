const fs = require('fs');
const path = require('path');

function getFiles(dir, files = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== 'node_modules' && entry.name !== 'tests') getFiles(fullPath, files);
    } else if (entry.name.endsWith('.ts') || entry.name.endsWith('.js')) {
      files.push(fullPath);
    }
  }
  return files;
}

const allFiles = getFiles('./src');
const queries = [];

for (const file of allFiles) {
  const content = fs.readFileSync(file, 'utf8');
  // Match template literals `SELECT ...` or `WITH ...` or `INSERT ...` or `UPDATE ...`
  const regex = /`\s*(SELECT|INSERT|UPDATE|DELETE|WITH)[\s\S]*?`/gi;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const rawSql = match[0].slice(1, -1).trim();
    if (rawSql.length > 25 && !file.includes('db.config.ts') && !file.includes('scratch')) {
      queries.push({
        file: path.relative('.', file),
        sql: rawSql
      });
    }
  }
}

console.log('Total extracted SQL queries:', queries.length);
fs.writeFileSync('scratch/extracted_queries.json', JSON.stringify(queries, null, 2));
