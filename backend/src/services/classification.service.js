function classifyText(text = '') {
  const t = String(text || '').toLowerCase().trim();
  if (!t) return 'general';

  // Map keywords to DB-allowed categories:
  if (
    t.includes('bug') ||
    t.includes('error') ||
    t.includes('fix') ||
    t.includes('issue') ||
    t.includes('crash') ||
    t.includes('broken')
  ) {
    return 'technical';
  }

  if (
    t.includes('invoice') ||
    t.includes('payment') ||
    t.includes('budget') ||
    t.includes('cost') ||
    t.includes('billing') ||
    t.includes('purchase')
  ) {
    return 'finance';
  }

  if (
    t.includes('schedule') ||
    t.includes('meeting') ||
    t.includes('appointment') ||
    t.includes('calendar') ||
    t.includes('deadline')
  ) {
    return 'scheduling';
  }

  if (
    t.includes('safety') ||
    t.includes('hazard') ||
    t.includes('incident') ||
    t.includes('ppe') ||
    t.includes('risk')
  ) {
    return 'safety';
  }

  return 'general';
}

module.exports = { classifyText };
