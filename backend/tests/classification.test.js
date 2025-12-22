const classificationService = require('../src/services/classification.service');

describe('classification.service', () => {
  test('Category detection: scheduling keywords -> scheduling', () => {
    expect(classificationService.detectCategory('Schedule a meeting with John')).toBe('scheduling');
  });

  test('Priority detection: urgency indicators -> high', () => {
    expect(classificationService.detectPriority('This is urgent, please fix ASAP')).toBe('high');
  });

  test('Entity extraction: dates + person + location', () => {
    const entities = classificationService.extractEntities(
      'Schedule a meeting with John Doe today at Site Office 2pm'
    );

    expect(entities.dates).toEqual(expect.arrayContaining(['today', '2pm']));
    expect(entities.people).toEqual(expect.arrayContaining(['John Doe']));
    expect(entities.locations).toEqual(expect.arrayContaining(['Site Office']));
  });
});
