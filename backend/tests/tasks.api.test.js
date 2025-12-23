const request = require('supertest');
const app = require('../src/app');
const { supabase } = require('../src/db/supabase');

describe('Tasks API', () => {
  let createdTaskId;

  beforeAll(async () => {
    // Clean up test data
    await supabase.from('tasks').delete().ilike('title', '%test%');
  });

  afterAll(async () => {
    // Clean up test data
    if (createdTaskId) {
      await supabase.from('tasks').delete().eq('id', createdTaskId);
    }
  });

  describe('POST /api/tasks', () => {
    it('should create a new task with valid data', async () => {
      const newTask = {
        title: 'Test Task',
        description: 'Test description with bug keyword',
        category: 'technical',
        priority: 'high',
        assigned_to: 'test@example.com',
        due_date: '2025-12-31T23:59:59Z'
      };

      const response = await request(app)
        .post('/api/tasks')
        .send(newTask)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.title).toBe(newTask.title);
      expect(response.body.data.status).toBe('pending');

      createdTaskId = response.body.data.id;
    });

    it('should return 400 for missing title', async () => {
      const response = await request(app)
        .post('/api/tasks')
        .send({ description: 'No title' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });

    it('should return 400 for invalid category', async () => {
      const response = await request(app)
        .post('/api/tasks')
        .send({ title: 'Test', category: 'invalid_category' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should log task creation in history', async () => {
      const newTask = {
        title: 'History Test Task',
        description: 'Testing history logging'
      };

      const response = await request(app)
        .post('/api/tasks')
        .send(newTask)
        .expect(201);

      const taskId = response.body.data.id;

      // Check if history was logged
      const { data: history } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', taskId)
        .eq('action', 'created')
        .single();

      expect(history).toBeDefined();
      expect(history.new_value).toHaveProperty('title', newTask.title);

      // Cleanup
      await supabase.from('tasks').delete().eq('id', taskId);
    });
  });

  describe('POST /api/tasks/classify', () => {
    it('should return classification for a description', async () => {
      const response = await request(app)
        .post('/api/tasks/classify')
        .send({ description: 'Schedule a meeting with John Doe today at Site Office 2pm' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('category', 'scheduling');
      expect(response.body.data).toHaveProperty('priority', 'high');
      expect(response.body.data).toHaveProperty('extracted_entities');
      expect(response.body.data.extracted_entities.people).toEqual(
        expect.arrayContaining(['John Doe'])
      );
      expect(response.body.data).toHaveProperty('suggested_actions');
      expect(response.body.data.suggested_actions.actions).toEqual(
        expect.arrayContaining(['Block calendar'])
      );
    });

    it('should return 400 for missing description', async () => {
      const response = await request(app)
        .post('/api/tasks/classify')
        .send({})
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/tasks', () => {
    beforeAll(async () => {
      // Create test tasks
      await supabase.from('tasks').insert([
        { title: 'Test Task 1', category: 'technical', priority: 'high', status: 'pending' },
        { title: 'Test Task 2', category: 'finance', priority: 'medium', status: 'in_progress' },
        { title: 'Test Task 3', category: 'technical', priority: 'low', status: 'completed' }
      ]);
    });

    it('should return all tasks with default pagination', async () => {
      const response = await request(app)
        .get('/api/tasks')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.pagination).toBeDefined();
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter tasks by status', async () => {
      const response = await request(app)
        .get('/api/tasks?status=pending')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.status).toBe('pending');
      });
    });

    it('should filter tasks by category', async () => {
      const response = await request(app)
        .get('/api/tasks?category=technical')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.category).toBe('technical');
      });
    });

    it('should filter tasks by priority', async () => {
      const response = await request(app)
        .get('/api/tasks?priority=high')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.priority).toBe('high');
      });
    });

    it('should support pagination with limit and offset', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=2&offset=1')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBeLessThanOrEqual(2);
      expect(response.body.pagination.limit).toBe(2);
      expect(response.body.pagination.offset).toBe(1);
    });

    it('should combine multiple filters', async () => {
      const response = await request(app)
        .get('/api/tasks?category=technical&priority=high&status=pending')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.category).toBe('technical');
        expect(task.priority).toBe('high');
        expect(task.status).toBe('pending');
      });
    });
  });

  describe('GET /api/tasks/:id', () => {
    let testTaskId;

    beforeAll(async () => {
      const { data } = await supabase
        .from('tasks')
        .insert({ title: 'Single Task Test' })
        .select()
        .single();
      testTaskId = data.id;
    });

    afterAll(async () => {
      await supabase.from('tasks').delete().eq('id', testTaskId);
    });

    it('should return a task by id', async () => {
      const response = await request(app)
        .get(`/api/tasks/${testTaskId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(testTaskId);
      expect(response.body.data.title).toBe('Single Task Test');
    });

    it('should return 404 for non-existent task', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const response = await request(app)
        .get(`/api/tasks/${fakeId}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('not found');
    });

    it('should return 400 for invalid UUID', async () => {
      const response = await request(app)
        .get('/api/tasks/invalid-uuid')
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PATCH /api/tasks/:id', () => {
    let testTaskId;

    beforeEach(async () => {
      const { data } = await supabase
        .from('tasks')
        .insert({
          title: 'Update Test Task',
          status: 'pending',
          priority: 'low'
        })
        .select()
        .single();
      testTaskId = data.id;
    });

    afterEach(async () => {
      await supabase.from('tasks').delete().eq('id', testTaskId);
    });

    it('should update task fields', async () => {
      const updates = {
        title: 'Updated Title',
        priority: 'high'
      };

      const response = await request(app)
        .patch(`/api/tasks/${testTaskId}`)
        .send(updates)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe(updates.title);
      expect(response.body.data.priority).toBe(updates.priority);
    });

    it('should log task update in history', async () => {
      const updates = { status: 'in_progress' };

      await request(app)
        .patch(`/api/tasks/${testTaskId}`)
        .send(updates)
        .expect(200);

      const { data: history } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'updated')
        .order('changed_at', { ascending: false })
        .limit(1)
        .single();

      expect(history).toBeDefined();
      expect(history.old_value).toHaveProperty('status', 'pending');
      expect(history.new_value).toHaveProperty('status', 'in_progress');
    });

    it('should log status change separately', async () => {
      await request(app)
        .patch(`/api/tasks/${testTaskId}`)
        .send({ status: 'completed' })
        .expect(200);

      const { data: history } = await supabase
        .from('task_history')
        .select('*')
        .eq('task_id', testTaskId)
        .eq('action', 'status_changed');

      expect(history.length).toBeGreaterThan(0);
    });

    it('should return 404 for non-existent task', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const response = await request(app)
        .patch(`/api/tasks/${fakeId}`)
        .send({ title: 'Update' })
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return 400 for invalid update data', async () => {
      const response = await request(app)
        .patch(`/api/tasks/${testTaskId}`)
        .send({ status: 'invalid_status' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('DELETE /api/tasks/:id', () => {
    let testTaskId;

    beforeEach(async () => {
      const { data } = await supabase
        .from('tasks')
        .insert({ title: 'Delete Test Task' })
        .select()
        .single();
      testTaskId = data.id;
    });

    it('should delete a task', async () => {
      const response = await request(app)
        .delete(`/api/tasks/${testTaskId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('deleted');

      // Verify task is deleted
      const { data } = await supabase
        .from('tasks')
        .select()
        .eq('id', testTaskId)
        .single();

      expect(data).toBeNull();
    });

    it('should return 404 for non-existent task', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const response = await request(app)
        .delete(`/api/tasks/${fakeId}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });
});