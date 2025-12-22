const CATEGORY_KEYWORDS = {
  scheduling: ['meeting', 'schedule', 'call', 'appointment', 'deadline'],
  finance: ['payment', 'invoice', 'bill', 'budget', 'cost', 'expense'],
  technical: ['bug', 'fix', 'error', 'install', 'repair', 'maintain'],
  safety: ['safety', 'hazard', 'inspection', 'compliance', 'ppe'],
};

const PRIORITY_KEYWORDS = {
  high: ['urgent', 'asap', 'immediately', 'today', 'critical', 'emergency'],
  medium: ['soon', 'this week', 'important'],
  low: [], // default
};

const SUGGESTED_ACTIONS_BY_CATEGORY = {
  scheduling: ['Block calendar', 'Send invite', 'Prepare agenda', 'Set reminder'],
  finance: ['Check budget', 'Get approval', 'Generate invoice', 'Update records'],
  technical: ['Diagnose issue', 'Check resources', 'Assign technician', 'Document fix'],
  safety: ['Conduct inspection', 'File report', 'Notify supervisor', 'Update checklist'],
};

function normalizeText(text = '') {
  return String(text || '').toLowerCase().trim();
}

/**
 * Returns the detected category based on keyword presence.
 * If multiple categories match, the first match in the ordered list wins.
 *
 * @param {string} text
 * @returns {'scheduling'|'finance'|'technical'|'safety'|'general'}
 */
function detectCategory(text = '') {
  const t = normalizeText(text);
  if (!t) return 'general';

  /** If analyst wants different tie-breaking, change this order. */
  const ordered = ['scheduling', 'finance', 'technical', 'safety'];

  for (const category of ordered) {
    const keywords = CATEGORY_KEYWORDS[category] || [];
    if (keywords.some(k => t.includes(k))) return category;
  }
  return 'general';
}

/**
 * Returns detected priority from urgency indicators.
 *
 * @param {string} text
 * @returns {'high'|'medium'|'low'}
 */
function detectPriority(text = '') {
  const t = normalizeText(text);
  if (!t) return 'low';

  // High wins over medium.
  if (PRIORITY_KEYWORDS.high.some(k => t.includes(k))) return 'high';
  if (PRIORITY_KEYWORDS.medium.some(k => t.includes(k))) return 'medium';
  return 'low';
}

/**
 * Entity extraction: heuristic parsing from description.
 *
 * Extracts:
 * - dates/times: common formats + tokens (today/tomorrow)
 * - person: after "with", "by", "assign to"
 * - location: after "at", "in", "on"
 * - action verbs: based on a small allowlist
 *
 * @param {string} text
 * @returns {{
 *   dates: string[],
 *   people: string[],
 *   locations: string[],
 *   actionVerbs: string[]
 * }}
 */
function extractEntities(text = '') {
  const raw = String(text || '');
  const t = normalizeText(raw);

  if (!t) {
    return { dates: [], people: [], locations: [], actionVerbs: [] };
  }

  // Dates/times: keep as strings (no timezone assumptions).
  const dateMatches = new Set();

  // Tokens
  ['today', 'tomorrow'].forEach(token => {
    if (t.includes(token)) dateMatches.add(token);
  });

  // ISO-ish: 2025-12-31 or 2025/12/31
  const isoLike = raw.match(/\b\d{4}[-/]\d{2}[-/]\d{2}\b/g) || [];
  isoLike.forEach(m => dateMatches.add(m));

  // Day-month-year: 31-12-2025 or 31/12/2025
  const dmy = raw.match(/\b\d{1,2}[-/]\d{1,2}[-/]\d{4}\b/g) || [];
  dmy.forEach(m => dateMatches.add(m));

  // Time: 2pm, 2:30pm, 14:30
  const times = raw.match(/\b(\d{1,2}:\d{2}\s?(am|pm)?)\b|\b(\d{1,2}\s?(am|pm))\b/gi) || [];
  times.forEach(m => dateMatches.add(m.trim()));

  // Person names: after "with", "by", "assign to"
  const people = new Set();

  const HONORIFIC =
    '(?:Dr\\.?|Mr\\.?|Ms\\.?|Mrs\\.?|Prof\\.?|Sir|Madam)\\s+';
  const NAME_PART = '[A-Z][a-z]+';
  // 2..4 name parts (e.g., Emily Smith, Emily Jane Smith, Emily Jane Ann Smith)
  const FULL_NAME = `(?:${HONORIFIC})?(${NAME_PART}(?:\\s+${NAME_PART}){1,3})`;

  const personRegexes = [
    new RegExp(`\\bwith\\s+${FULL_NAME}\\b`, 'g'),
    new RegExp(`\\bby\\s+${FULL_NAME}\\b`, 'g'),
    new RegExp(`\\bassign\\s+to\\s+${FULL_NAME}\\b`, 'g'),
    new RegExp(`\\bAssign\\s+to\\s+${FULL_NAME}\\b`, 'g'),
  ];

  for (const re of personRegexes) {
    let m;
    while ((m = re.exec(raw)) !== null) {
      people.add(m[1].trim());
    }
  }

  // Locations: after "at/in/on <Words>"
  const locations = new Set();
  const locationRegexes = [
    /\bat\s+([A-Z][\w]+(?:\s+[A-Z][\w]+){0,4})\b/g,
    /\bin\s+([A-Z][\w]+(?:\s+[A-Z][\w]+){0,4})\b/g,
    /\bon\s+([A-Z][\w]+(?:\s+[A-Z][\w]+){0,4})\b/g,
  ];
  for (const re of locationRegexes) {
    let m;
    while ((m = re.exec(raw)) !== null) {
      locations.add(m[1].trim());
    }
  }

  // Action verbs: small allowlist, first occurrence order.
  const verbAllowlist = [
    'call', 'meet', 'schedule', 'book', 'send', 'prepare', 'review',
    'pay', 'invoice', 'approve', 'update', 'define', 'check',
    'debug', 'built', 'solve', 'implement', 'improve',
    'fix', 'install', 'repair', 'maintain', 'diagnose', 'document',
    'inspect', 'audit', 'notify', 'file', 'led', 'direct', 'plan'
  ];
  const actionVerbs = [];
  for (const v of verbAllowlist) {
    if (t.includes(v)) actionVerbs.push(v);
  }

  return {
    dates: Array.from(dateMatches),
    people: Array.from(people),
    locations: Array.from(locations),
    actionVerbs,
  };
}

/**
 * Suggested actions based on category.
 *
 * @param {string} category
 * @returns {string[]}
 */
function getSuggestedActions(category) {
  return SUGGESTED_ACTIONS_BY_CATEGORY[category] || [];
}

/**
 * Full enrichment for a task description.
 *
 * @param {string} description
 * @returns {{
 *   category: string,
 *   priority: string,
 *   extracted_entities: object,
 *   suggested_actions: object
 * }}
 */
function classifyTask(description = '') {
  const category = detectCategory(description);
  const priority = detectPriority(description);

  const extracted_entities = extractEntities(description);
  const suggested_actions = {
    category,
    actions: getSuggestedActions(category),
  };

  return { category, priority, extracted_entities, suggested_actions };
}

module.exports = {
  // granular exports (easy to test)
  detectCategory,
  detectPriority,
  extractEntities,
  getSuggestedActions,
  classifyTask,
};
