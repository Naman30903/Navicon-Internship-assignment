const tasksService = require('../src/services/tasks.service');
const request = require('supertest');
const app = require('../src/app');
const { supabase } = require('../src/db/supabase');

describe('Tasks Pagination', () => {
  let testTaskIds = [];

  beforeAll(async () => {
    // Clean up existing test data
    await supabase.from('tasks').delete().ilike('title', '%pagination test%');

    // Create 25 test tasks for pagination testing
    const tasks = [];
    for (let i = 1; i <= 25; i++) {
      tasks.push({
        title: `Pagination Test Task ${i}`,
        category: i % 2 === 0 ? 'technical' : 'finance',
        priority: i % 3 === 0 ? 'high' : i % 3 === 1 ? 'medium' : 'low',
        status: i % 3 === 0 ? 'completed' : i % 3 === 1 ? 'in_progress' : 'pending'
      });
    }

    const { data } = await supabase.from('tasks').insert(tasks).select();
    testTaskIds = data.map(task => task.id);
  });

  afterAll(async () => {
    // Clean up test tasks
    for (const id of testTaskIds) {
      await supabase.from('tasks').delete().eq('id', id);
    }
  });

  describe('Basic Pagination', () => {
    it('should return default limit of 10 tasks', async () => {
      const response = await request(app)
        .get('/api/tasks')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.pagination.limit).toBe(10);
      expect(response.body.data.length).toBeLessThanOrEqual(10);
    });

    it('should respect custom limit', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=5')
        .expect(200);

      expect(response.body.pagination.limit).toBe(5);
      expect(response.body.data.length).toBeLessThanOrEqual(5);
    });

    it('should handle offset for pagination', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=5&offset=5')
        .expect(200);

      expect(response.body.pagination.limit).toBe(5);
      expect(response.body.pagination.offset).toBe(5);
    });

    it('should calculate total pages correctly', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=10')
        .expect(200);

      const expectedPages = Math.ceil(response.body.pagination.total / 10);
      expect(response.body.pagination.totalPages).toBe(expectedPages);
    });

    it('should return different data for different pages', async () => {
      const page1 = await request(app)
        .get('/api/tasks?limit=5&offset=0')
        .expect(200);

      const page2 = await request(app)
        .get('/api/tasks?limit=5&offset=5')
        .expect(200);

      expect(page1.body.data.length).toBeGreaterThan(0);
      expect(page2.body.data.length).toBeGreaterThan(0);

      // First task of each page should be different
      expect(page1.body.data[0].id).not.toBe(page2.body.data[0].id);
    });

    it('should handle large offset gracefully', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=10&offset=1000')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual([]);
    });

    it('should handle limit of 1', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=1')
        .expect(200);

      expect(response.body.data.length).toBeLessThanOrEqual(1);
      expect(response.body.pagination.limit).toBe(1);
    });

    it('should handle large limit', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=100')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.pagination.limit).toBe(100);
    });
  });

  describe('Pagination with Filters', () => {
    it('should paginate filtered results by status', async () => {
      const response = await request(app)
        .get('/api/tasks?status=pending&limit=5')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBeLessThanOrEqual(5);
      response.body.data.forEach(task => {
        expect(task.status).toBe('pending');
      });
    });

    it('should paginate filtered results by category', async () => {
      const response = await request(app)
        .get('/api/tasks?category=technical&limit=5')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.category).toBe('technical');
      });
    });

    it('should paginate filtered results by priority', async () => {
      const response = await request(app)
        .get('/api/tasks?priority=high&limit=3')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.priority).toBe('high');
      });
    });

    it('should handle pagination with multiple filters', async () => {
      const response = await request(app)
        .get('/api/tasks?category=technical&priority=low&limit=5&offset=0')
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(task => {
        expect(task.category).toBe('technical');
        expect(task.priority).toBe('low');
      });
    });

    it('should calculate total correctly for filtered results', async () => {
      const response = await request(app)
        .get('/api/tasks?status=pending&limit=5')
        .expect(200);

      expect(response.body.pagination.total).toBeGreaterThan(0);
      expect(response.body.pagination.totalPages).toBeGreaterThan(0);
    });

    it('should support offset with filters', async () => {
      const page1 = await request(app)
        .get('/api/tasks?status=pending&limit=3&offset=0')
        .expect(200);

      const page2 = await request(app)
        .get('/api/tasks?status=pending&limit=3&offset=3')
        .expect(200);

      if (page1.body.data.length > 0 && page2.body.data.length > 0) {
        expect(page1.body.data[0].id).not.toBe(page2.body.data[0].id);
      }
    });
  });

  describe('Edge Cases', () => {
    it('should handle offset = 0 explicitly', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=5&offset=0')
        .expect(200);

      expect(response.body.pagination.offset).toBe(0);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should handle string limit and offset', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=5&offset=5')
        .expect(200);

      expect(response.body.pagination.limit).toBe(5);
      expect(response.body.pagination.offset).toBe(5);
    });

    it('should handle missing pagination params', async () => {
      const response = await request(app)
        .get('/api/tasks')
        .expect(200);

      expect(response.body.pagination.limit).toBe(10);
      expect(response.body.pagination.offset).toBe(0);
    });

    it('should return empty array when offset exceeds total', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=10&offset=10000')
        .expect(200);

      expect(response.body.data).toEqual([]);
    });

    it('should handle zero limit gracefully', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=0')
        .expect(200);

      // Should use default or minimum limit
      expect(response.body.data).toBeInstanceOf(Array);
    });
  });

  describe('Service Layer Pagination', () => {
    it('should return correct pagination metadata from service', async () => {
      const result = await tasksService.getTasks({ limit: 5, offset: 10 });

      expect(result.success).toBe(true);
      expect(result.pagination).toBeDefined();
      expect(result.pagination.limit).toBe(5);
      expect(result.pagination.offset).toBe(10);
      expect(result.pagination.total).toBeGreaterThanOrEqual(0);
      expect(result.pagination.totalPages).toBeGreaterThanOrEqual(0);
    });

    it('should handle pagination with all filters in service', async () => {
      const result = await tasksService.getTasks({
        limit: 3,
        offset: 0,
        status: 'pending',
        category: 'finance',
        priority: 'low'
      });

      expect(result.success).toBe(true);
      expect(result.pagination.limit).toBe(3);
      result.data.forEach(task => {
        expect(task.status).toBe('pending');
        expect(task.category).toBe('finance');
        expect(task.priority).toBe('low');
      });
    });
  });

  describe('Pagination Order', () => {
    it('should maintain consistent order across pages', async () => {
      const page1 = await request(app)
        .get('/api/tasks?limit=10&offset=0')
        .expect(200);

      const page2 = await request(app)
        .get('/api/tasks?limit=10&offset=10')
        .expect(200);

      if (page1.body.data.length > 0 && page2.body.data.length > 0) {
        const lastOfPage1 = new Date(page1.body.data[page1.body.data.length - 1].created_at);
        const firstOfPage2 = new Date(page2.body.data[0].created_at);
        
        // Page 1 last item should be created after or at same time as Page 2 first item
        expect(lastOfPage1.getTime()).toBeGreaterThanOrEqual(firstOfPage2.getTime());
      }
    });

    it('should order by created_at descending within page', async () => {
      const response = await request(app)
        .get('/api/tasks?limit=10')
        .expect(200);

      if (response.body.data.length > 1) {
        for (let i = 0; i < response.body.data.length - 1; i++) {
          const current = new Date(response.body.data[i].created_at);
          const next = new Date(response.body.data[i + 1].created_at);
          expect(current.getTime()).toBeGreaterThanOrEqual(next.getTime());
        }
      }
    });
  });
});