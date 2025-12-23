const express = require('express');
const router = express.Router();
const tasksController = require('../controllers/tasks.controller');
const { validateTask, validateTaskUpdate, validateUUID } = require('../validators/tasks.schema');

// POST /api/tasks/classify - Preview auto-classification without creating a task
router.post('/classify', tasksController.classifyTask);

// POST /api/tasks - Create a new task
router.post('/', validateTask, tasksController.createTask);

// GET /api/tasks - Get all tasks with filters and pagination
router.get('/', tasksController.getTasks);

// GET /api/tasks/:id - Get a single task by ID
router.get('/:id', validateUUID, tasksController.getTaskById);

// PATCH /api/tasks/:id - Update a task
router.patch('/:id', validateUUID, validateTaskUpdate, tasksController.updateTask);

// DELETE /api/tasks/:id - Delete a task
router.delete('/:id', validateUUID, tasksController.deleteTask);

// GET /api/tasks/:id/history - Get task history
router.get('/:id/history', validateUUID, tasksController.getTaskHistory);

module.exports = router;