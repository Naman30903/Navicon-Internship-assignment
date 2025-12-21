const classificationService = require('../src/services/classification.service');

test('classifyText returns bug for bug keywords', () => {
  expect(classificationService.classifyText('This has a bug')).toBe('bug');
});

test('classifyText returns feature for feature keywords', () => {
  expect(classificationService.classifyText('Add new feature')).toBe('feature');
});

test('classifyText falls back to task', () => {
  expect(classificationService.classifyText('Simple task description')).toBe('task');
});
