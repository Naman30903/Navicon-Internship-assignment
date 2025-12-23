const tasksService = require('../services/tasks.service');
const historyService = require('../services/history.service');
const classificationService = require('../services/classification.service');

/**
 * Create a new task
 */
async function createTask(req, res) {
    try {
        const result = await tasksService.createTask(req.body);

        if (!result.success) {
            return res.status(400).json({
                success: false,
                message: result.error || 'Failed to create task'
            });
        }

        return res.status(201).json({
            success: true,
            data: result.data
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

/**
 * Preview classification/enrichment for a task description without creating a task.
 *
 * Route: POST /api/tasks/classify
 * Body: { description: string }
 */
async function classifyTask(req, res) {
    try {
        const { description } = req.body || {};

        if (!description || typeof description !== 'string' || !description.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Validation error',
                errors: [{ message: 'Description is required' }]
            });
        }

        const data = classificationService.classifyTask(description);

        return res.status(200).json({
            success: true,
            data
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

/**
 * Get all tasks with filters and pagination
 */
async function getTasks(req, res) {
    try {
        const filters = {
            limit: parseInt(req.query.limit) || 10,
            offset: parseInt(req.query.offset) || 0,
            status: req.query.status,
            category: req.query.category,
            priority: req.query.priority
        };

        const result = await tasksService.getTasks(filters);

        if (!result.success) {
            return res.status(400).json({
                success: false,
                message: result.error || 'Failed to fetch tasks'
            });
        }

        return res.status(200).json({
            success: true,
            data: result.data,
            pagination: result.pagination
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

/**
 * Get a single task by ID
 */
async function getTaskById(req, res) {
    try {
        const { id } = req.params;
        const result = await tasksService.getTaskById(id);

        if (!result.success) {
            return res.status(404).json({
                success: false,
                message: result.message || 'Task not found'
            });
        }

        return res.status(200).json({
            success: true,
            data: result.data
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

/**
 * Update a task
 */
async function updateTask(req, res) {
    try {
        const { id } = req.params;
        const result = await tasksService.updateTask(id, req.body);

        if (!result.success) {
            const statusCode = result.message === 'Task not found' ? 404 : 400;
            return res.status(statusCode).json({
                success: false,
                message: result.message || result.error || 'Failed to update task'
            });
        }

        return res.status(200).json({
            success: true,
            data: result.data
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

/**
 * Delete a task
 */
async function deleteTask(req, res) {
    try {
        const { id } = req.params;
        const result = await tasksService.deleteTask(id);

        if (!result.success) {
            const statusCode = result.message === 'Task not found' ? 404 : 400;
            return res.status(statusCode).json({
                success: false,
                message: result.message || result.error || 'Failed to delete task'
            });
        }

        return res.status(200).json({
            success: true,
            message: result.message
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

/**
 * Get task history
 */
async function getTaskHistory(req, res) {
    try {
        const { id } = req.params;
        const result = await historyService.getTaskHistory(id);

        if (!result.success) {
            return res.status(400).json({
                success: false,
                message: result.error || 'Failed to fetch task history'
            });
        }

        return res.status(200).json({
            success: true,
            data: result.data
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
}

module.exports = {
    createTask,
    classifyTask,
    getTasks,
    getTaskById,
    updateTask,
    deleteTask,
    getTaskHistory
};