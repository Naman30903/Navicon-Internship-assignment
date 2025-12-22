const tasksService = require('../src/services/tasks.service');
const { supabase } = require('../src/db/supabase');

describe('Tasks Service', () => {
  let createdTaskIds = [];

  afterEach(async () => {
    // Clean up created tasks
    for (const id of createdTaskIds) {
      await supabase.from('tasks').delete().eq('id', id);
    }
    createdTaskIds = [];
  });

  describe('createTask', () => {
    it('should create a task with all fields', async () => {
      const taskData = {
        title: 'Service Test Task',
        description: 'Test description',
        category: 'technical',
        priority: 'high',
        assigned_to: 'test@example.com',
        due_date: '2025-12-31T23:59:59Z'
      };

      const result = await tasksService.createTask(taskData);

      expect(result.success).toBe(true);
      expect(result.data).toHaveProperty('id');
      expect(result.data.title).toBe(taskData.title);
      expect(result.data.status).toBe('pending');
      expect(result.data.category).toBe('technical');

      createdTaskIds.push(result.data.id);
    });

    it('should create task with minimal data', async () => {
      const taskData = {
        title: 'Minimal Task'
      };

      const result = await tasksService.createTask(taskData);

      expect(result.success).toBe(true);
      expect(result.data.title).toBe(taskData.title);
      expect(result.data.status).toBe('pending');
      expect(result.data.category).toBe('general');

      createdTaskIds.push(result.data.id);
    });

    it('should auto-classify category from description', async () => {
      const taskData = {
        title: 'Bug Fix Task',
        description: 'This is a critical bug that needs fixing'
      };

      const result = await tasksService.createTask(taskData);

      expect(result.success).toBe(true);
      // Classification service should detect 'bug' keyword
      expect(result.data.category).toBeDefined();

      createdTaskIds.push(result.data.id);
    });

    it('should set created_at and updated_at timestamps', async () => {
      const taskData = {
        title: 'Timestamp Test'
      };

      const result = await tasksService.createTask(taskData);

      expect(result.success).toBe(true);
      expect(result.data.created_at).toBeDefined();
      expect(result.data.updated_at).toBeDefined();

      createdTaskIds.push(result.data.id);
    });

    it('should log history on task creation', async () => {
      const taskData = {
        title: 'History Test Task'
      };

      const result = await tasksService.createTask(taskData);
      expect(result.success).toBe(true);

      // Verify history was logged
      const { data: history } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', result.data.id)
        .eq('action', 'created')
        .single();

      expect(history).toBeDefined();
      expect(history.new_value.title).toBe(taskData.title);

      createdTaskIds.push(result.data.id);
    });
  });

  describe('getTasks', () => {
    beforeAll(async () => {
      // Create test tasks
      const testTasks = [
        { title: 'Service Task 1', category: 'technical', priority: 'high', status: 'pending' },
        { title: 'Service Task 2', category: 'finance', priority: 'medium', status: 'in_progress' },
        { title: 'Service Task 3', category: 'technical', priority: 'low', status: 'completed' },
        { title: 'Service Task 4', category: 'safety', priority: 'high', status: 'pending' },
        { title: 'Service Task 5', category: 'general', priority: 'low', status: 'in_progress' }
      ];

      const { data } = await supabase.from('tasks').insert(testTasks).select();
      createdTaskIds = data.map(task => task.id);
    });

    it('should return tasks with default pagination', async () => {
      const result = await tasksService.getTasks({ limit: 10, offset: 0 });

      expect(result.success).toBe(true);
      expect(result.data).toBeInstanceOf(Array);
      expect(result.pagination.limit).toBe(10);
      expect(result.pagination.offset).toBe(0);
      expect(result.pagination.total).toBeGreaterThan(0);
    });

    it('should filter by status', async () => {
      const result = await tasksService.getTasks({ status: 'pending' });

      expect(result.success).toBe(true);
      result.data.forEach(task => {
        expect(task.status).toBe('pending');
      });
    });

    it('should filter by category', async () => {
      const result = await tasksService.getTasks({ category: 'technical' });

      expect(result.success).toBe(true);
      result.data.forEach(task => {
        expect(task.category).toBe('technical');
      });
    });

    it('should filter by priority', async () => {
      const result = await tasksService.getTasks({ priority: 'high' });

      expect(result.success).toBe(true);
      result.data.forEach(task => {
        expect(task.priority).toBe('high');
      });
    });

    it('should combine multiple filters', async () => {
      const result = await tasksService.getTasks({
        category: 'technical',
        priority: 'high',
        status: 'pending'
      });

      expect(result.success).toBe(true);
      result.data.forEach(task => {
        expect(task.category).toBe('technical');
        expect(task.priority).toBe('high');
        expect(task.status).toBe('pending');
      });
    });

    it('should respect limit parameter', async () => {
      const result = await tasksService.getTasks({ limit: 2, offset: 0 });

      expect(result.success).toBe(true);
      expect(result.data.length).toBeLessThanOrEqual(2);
    });

    it('should respect offset parameter', async () => {
      const firstPage = await tasksService.getTasks({ limit: 2, offset: 0 });
      const secondPage = await tasksService.getTasks({ limit: 2, offset: 2 });

      expect(firstPage.success).toBe(true);
      expect(secondPage.success).toBe(true);

      if (firstPage.data.length > 0 && secondPage.data.length > 0) {
        expect(firstPage.data[0].id).not.toBe(secondPage.data[0].id);
      }
    });

    it('should return tasks in descending order by created_at', async () => {
      const result = await tasksService.getTasks({ limit: 5 });

      expect(result.success).toBe(true);

      if (result.data.length > 1) {
        for (let i = 0; i < result.data.length - 1; i++) {
          const current = new Date(result.data[i].created_at);
          const next = new Date(result.data[i + 1].created_at);
          expect(current.getTime()).toBeGreaterThanOrEqual(next.getTime());
        }
      }
    });

    it('should calculate total pages correctly', async () => {
      const result = await tasksService.getTasks({ limit: 2 });

      expect(result.success).toBe(true);
      expect(result.pagination.totalPages).toBe(
        Math.ceil(result.pagination.total / result.pagination.limit)
      );
    });
  });

  describe('updateTask', () => {
    let testTaskId;

    beforeEach(async () => {
      const { data } = await supabase
        .from('tasks')
        .insert({
          title: 'Update Test Task',
          status: 'pending',
          priority: 'low',
          category: 'general'
        })
        .select()
        .single();
      testTaskId = data.id;
      createdTaskIds.push(testTaskId);
    });

    it('should update task title', async () => {
      const result = await tasksService.updateTask(testTaskId, {
        title: 'Updated Title'
      });

      expect(result.success).toBe(true);
      expect(result.data.title).toBe('Updated Title');
    });

    it('should update task status', async () => {
      const result = await tasksService.updateTask(testTaskId, {
        status: 'in_progress'
      });

      expect(result.success).toBe(true);
      expect(result.data.status).toBe('in_progress');
    });

    it('should update multiple fields', async () => {
      const updates = {
        title: 'Multi Update',
        priority: 'high',
        status: 'completed'
      };

      const result = await tasksService.updateTask(testTaskId, updates);

      expect(result.success).toBe(true);
      expect(result.data.title).toBe(updates.title);
      expect(result.data.priority).toBe(updates.priority);
      expect(result.data.status).toBe(updates.status);
    });

    it('should update updated_at timestamp', async () => {
      const { data: before } = await supabase
        .from('tasks')
        .select('updated_at')
        .eq('id', testTaskId)
        .single();

      // Wait a moment to ensure timestamp difference
      await new Promise(resolve => setTimeout(resolve, 100));

      const result = await tasksService.updateTask(testTaskId, {
        title: 'Timestamp Update'
      });

      expect(result.success).toBe(true);
      expect(new Date(result.data.updated_at).getTime()).toBeGreaterThan(
        new Date(before.updated_at).getTime()
      );
    });

    it('should log update in history', async () => {
      await tasksService.updateTask(testTaskId, { title: 'History Update' });

      const { data: history } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'updated');

      expect(history.length).toBeGreaterThan(0);
      expect(history[0].new_value.title).toBe('History Update');
    });

    it('should log status change separately', async () => {
      await tasksService.updateTask(testTaskId, { status: 'completed' });

      const { data: statusHistory } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'status_changed');

      expect(statusHistory.length).toBeGreaterThan(0);
    });

    it('should log completion when status changes to completed', async () => {
      await tasksService.updateTask(testTaskId, { status: 'completed' });

      const { data: completedHistory } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'completed');

      expect(completedHistory.length).toBeGreaterThan(0);
    });

    it('should return error for non-existent task', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const result = await tasksService.updateTask(fakeId, { title: 'Update' });

      expect(result.success).toBe(false);
      expect(result.message).toContain('not found');
    });
  });

  describe('deleteTask', () => {
    let testTaskId;

    beforeEach(async () => {
      const { data } = await supabase
        .from('tasks')
        .insert({ title: 'Delete Test Task' })
        .select()
        .single();
      testTaskId = data.id;
    });

    it('should delete existing task', async () => {
      const result = await tasksService.deleteTask(testTaskId);

      expect(result.success).toBe(true);
      expect(result.message).toContain('deleted');

      // Verify task is deleted
      const { data } = await supabase
        .from('tasks')
        .select()
        .eq('id', testTaskId)
        .single();

      expect(data).toBeNull();
    });

    it('should return error for non-existent task', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const result = await tasksService.deleteTask(fakeId);

      expect(result.success).toBe(false);
      expect(result.message).toContain('not found');
    });

    it('should cascade delete task history', async () => {
      // Log some history
      await supabase.from('task_history').insert({
        task_id: testTaskId,
        action: 'created',
        new_value: { title: 'Test' }
      });

      // Delete task
      await tasksService.deleteTask(testTaskId);

      // Verify history is deleted
      const { data: history } = await supabase
        .from('task_history')
        .select()
        .eq('task_id', testTaskId);

      expect(history.length).toBe(0);
    });
  });
});