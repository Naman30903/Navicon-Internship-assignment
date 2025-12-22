const historyService = require('../src/services/history.service');
const { supabase } = require('../src/db/supabase');

describe('History Service', () => {
  let testTaskId;

  beforeAll(async () => {
    // Create a test task
    const { data } = await supabase
      .from('tasks')
      .insert({ title: 'History Service Test Task' })
      .select()
      .single();
    testTaskId = data.id;
  });

  afterAll(async () => {
    // Clean up test task and its history
    await supabase.from('tasks').delete().eq('id', testTaskId);
  });

  afterEach(async () => {
    // Clean up history entries after each test
    await supabase.from('task_history').delete().eq('task_id', testTaskId);
  });

  describe('logTaskHistory', () => {
    it('should log task creation history', async () => {
      const result = await historyService.logTaskHistory({
        task_id: testTaskId,
        action: 'created',
        new_value: { title: 'New Task', status: 'pending' },
        changed_by: 'test@example.com'
      });

      expect(result.success).toBe(true);

      // Verify the history was logged
      const { data } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'created')
        .single();

      expect(data).toBeDefined();
      expect(data.action).toBe('created');
      expect(data.changed_by).toBe('test@example.com');
      expect(data.new_value).toEqual({ title: 'New Task', status: 'pending' });
    });

    it('should log task update history with old and new values', async () => {
      const oldValue = { title: 'Old Title', status: 'pending' };
      const newValue = { title: 'New Title', status: 'in_progress' };

      const result = await historyService.logTaskHistory({
        task_id: testTaskId,
        action: 'updated',
        old_value: oldValue,
        new_value: newValue,
        changed_by: 'updater@example.com'
      });

      expect(result.success).toBe(true);

      const { data } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'updated')
        .single();

      expect(data.old_value).toEqual(oldValue);
      expect(data.new_value).toEqual(newValue);
      expect(data.changed_by).toBe('updater@example.com');
    });

    it('should log status change history', async () => {
      const result = await historyService.logTaskHistory({
        task_id: testTaskId,
        action: 'status_changed',
        old_value: { status: 'pending' },
        new_value: { status: 'completed' },
        changed_by: 'system'
      });

      expect(result.success).toBe(true);

      const { data } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'status_changed')
        .single();

      expect(data.action).toBe('status_changed');
      expect(data.old_value.status).toBe('pending');
      expect(data.new_value.status).toBe('completed');
    });

    it('should log task completion history', async () => {
      const taskData = { title: 'Completed Task', status: 'completed' };

      const result = await historyService.logTaskHistory({
        task_id: testTaskId,
        action: 'completed',
        new_value: taskData,
        changed_by: 'completer@example.com'
      });

      expect(result.success).toBe(true);

      const { data } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'completed')
        .single();

      expect(data.action).toBe('completed');
      expect(data.new_value).toEqual(taskData);
    });

    it('should use default changed_by as system', async () => {
      const result = await historyService.logTaskHistory({
        task_id: testTaskId,
        action: 'created',
        new_value: { title: 'Test' }
      });

      expect(result.success).toBe(true);

      const { data } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .single();

      expect(data.changed_by).toBe('system');
    });

    it('should handle null old_value', async () => {
      const result = await historyService.logTaskHistory({
        task_id: testTaskId,
        action: 'created',
        old_value: null,
        new_value: { title: 'New Task' },
        changed_by: 'user@example.com'
      });

      expect(result.success).toBe(true);

      const { data } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .single();

      expect(data.old_value).toBeNull();
    });

    it('should return error for invalid task_id', async () => {
      const fakeTaskId = '00000000-0000-0000-0000-000000000000';

      const result = await historyService.logTaskHistory({
        task_id: fakeTaskId,
        action: 'created',
        new_value: { title: 'Test' }
      });

      // Should still attempt to log (foreign key constraint will fail on DB side)
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('getTaskHistory', () => {
    beforeEach(async () => {
      // Create multiple history entries
      await supabase.from('task_history').insert([
        {
          task_id: testTaskId,
          action: 'created',
          new_value: { title: 'Task Created' },
          changed_by: 'creator@example.com'
        },
        {
          task_id: testTaskId,
          action: 'updated',
          old_value: { title: 'Task Created' },
          new_value: { title: 'Task Updated' },
          changed_by: 'updater@example.com'
        },
        {
          task_id: testTaskId,
          action: 'status_changed',
          old_value: { status: 'pending' },
          new_value: { status: 'in_progress' },
          changed_by: 'system'
        },
        {
          task_id: testTaskId,
          action: 'completed',
          new_value: { status: 'completed' },
          changed_by: 'completer@example.com'
        }
      ]);
    });

    it('should retrieve all history for a task', async () => {
      const result = await historyService.getTaskHistory(testTaskId);

      expect(result.success).toBe(true);
      expect(result.data).toBeInstanceOf(Array);
      expect(result.data.length).toBe(4);
    });

    it('should return history in descending order by changed_at', async () => {
      const result = await historyService.getTaskHistory(testTaskId);

      expect(result.success).toBe(true);
      expect(result.data.length).toBeGreaterThan(0);

      // Check that timestamps are in descending order
      for (let i = 0; i < result.data.length - 1; i++) {
        const current = new Date(result.data[i].changed_at);
        const next = new Date(result.data[i + 1].changed_at);
        expect(current.getTime()).toBeGreaterThanOrEqual(next.getTime());
      }
    });

    it('should return empty array for task with no history', async () => {
      // Create a new task without history
      const { data: newTask } = await supabase
        .from('tasks')
        .insert({ title: 'Task Without History' })
        .select()
        .single();

      const result = await historyService.getTaskHistory(newTask.id);

      expect(result.success).toBe(true);
      expect(result.data).toEqual([]);

      // Cleanup
      await supabase.from('tasks').delete().eq('id', newTask.id);
    });

    it('should return success with empty array for non-existent task', async () => {
      const fakeTaskId = '00000000-0000-0000-0000-000000000000';
      const result = await historyService.getTaskHistory(fakeTaskId);

      expect(result.success).toBe(true);
      expect(result.data).toEqual([]);
    });

    it('should include all history fields', async () => {
      const result = await historyService.getTaskHistory(testTaskId);

      expect(result.success).toBe(true);
      expect(result.data.length).toBeGreaterThan(0);

      const historyEntry = result.data[0];
      expect(historyEntry).toHaveProperty('id');
      expect(historyEntry).toHaveProperty('task_id');
      expect(historyEntry).toHaveProperty('action');
      expect(historyEntry).toHaveProperty('changed_at');
      expect(historyEntry).toHaveProperty('changed_by');
    });
  });

  describe('History cascade deletion', () => {
    it('should delete history when task is deleted', async () => {
      // Create a temporary task with history
      const { data: tempTask } = await supabase
        .from('tasks')
        .insert({ title: 'Temp Task for Deletion' })
        .select()
        .single();

      await historyService.logTaskHistory({
        task_id: tempTask.id,
        action: 'created',
        new_value: { title: 'Temp Task' }
      });

      // Verify history exists
      let { data: historyBefore } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', tempTask.id);

      expect(historyBefore.length).toBeGreaterThan(0);

      // Delete the task
      await supabase.from('tasks').delete().eq('id', tempTask.id);

      // Verify history is cascade deleted
      const { data: historyAfter } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', tempTask.id);

      expect(historyAfter.length).toBe(0);
    });
  });
});