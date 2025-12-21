function classifyText(text = '') {
  const t = text.toLowerCase();
  if (!t) return 'uncategorized';
  if (t.includes('bug') || t.includes('error') || t.includes('fix')) return 'bug';
  if (t.includes('feature') || t.includes('request') || t.includes('enhance')) return 'feature';
  if (t.includes('doc') || t.includes('readme')) return 'documentation';
  return 'task';
}

module.exports = { classifyText };
