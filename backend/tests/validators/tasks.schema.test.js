const { validateTask, validateTaskUpdate, validateUUID } = require('../../src/validators/tasks.schema');
const { z } = require('zod');

describe('Task Validators', () => {
  describe('validateTask', () => {
    it('should pass for valid task data', () => {
      const req = {
        body: {
          title: 'Valid Task',
          description: 'Description',
          category: 'technical',
          priority: 'high',
          status: 'pending',
          assigned_to: 'user@example.com',
          due_date: '2025-12-31T23:59:59Z'
        }
      };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateTask(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should fail for missing title', () => {
      const req = { body: { description: 'No title' } };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateTask(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        success: false,
        message: 'Validation error'
      }));
    });

    it('should fail for invalid category', () => {
      const req = { body: { title: 'Test', category: 'invalid' } };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateTask(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
    });
  });

  describe('validateTaskUpdate', () => {
    it('should pass for valid update data', () => {
      const req = { body: { title: 'Updated Title' } };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateTaskUpdate(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should fail for empty update', () => {
      const req = { body: {} };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateTaskUpdate(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
    });
  });

  describe('validateUUID', () => {
    it('should pass for valid UUID', () => {
      const req = { params: { id: '123e4567-e89b-12d3-a456-426614174000' } };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateUUID(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('should fail for invalid UUID', () => {
      const req = { params: { id: 'invalid-uuid' } };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      const next = jest.fn();

      validateUUID(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
    });
  });
});