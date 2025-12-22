const { z } = require('zod');

// Task creation schema
const taskSchema = z.object({
    title: z.string().min(1, 'Title is required'),
    description: z.string().optional(),
    category: z.enum(['scheduling', 'finance', 'technical', 'safety', 'general']).optional(),
    priority: z.enum(['high', 'medium', 'low']).optional(),
    status: z.enum(['pending', 'in_progress', 'completed']).optional(),
    assigned_to: z.string().email().optional().or(z.literal('')),
    due_date: z.string().datetime().optional().or(z.literal('')),
    extracted_entities: z.record(z.any()).optional(),
    suggested_actions: z.record(z.any()).optional()
});

// Task update schema (all fields optional)
const taskUpdateSchema = z.object({
    title: z.string().min(1).optional(),
    description: z.string().optional(),
    category: z.enum(['scheduling', 'finance', 'technical', 'safety', 'general']).optional(),
    priority: z.enum(['high', 'medium', 'low']).optional(),
    status: z.enum(['pending', 'in_progress', 'completed']).optional(),
    assigned_to: z.string().email().optional().or(z.literal('')),
    due_date: z.string().datetime().optional().or(z.literal('')),
    extracted_entities: z.record(z.any()).optional(),
    suggested_actions: z.record(z.any()).optional()
}).refine(data => Object.keys(data).length > 0, {
    message: 'At least one field must be provided for update'
});

// UUID validation schema
const uuidSchema = z.string().uuid('Invalid UUID format');

/**
 * Validate task creation
 */
function validateTask(req, res, next) {
    try {
        taskSchema.parse(req.body);
        next();
    } catch (error) {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: error.errors
        });
    }
}

/**
 * Validate task update
 */
function validateTaskUpdate(req, res, next) {
    try {
        taskUpdateSchema.parse(req.body);
        next();
    } catch (error) {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: error.errors
        });
    }
}

/**
 * Validate UUID parameter
 */
function validateUUID(req, res, next) {
    try {
        uuidSchema.parse(req.params.id);
        next();
    } catch (error) {
        return res.status(400).json({
            success: false,
            message: 'Invalid task ID format',
            errors: error.errors
        });
    }
}

module.exports = {
    validateTask,
    validateTaskUpdate,
    validateUUID
};