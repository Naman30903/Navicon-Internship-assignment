const { z } = require('zod');

const taskSchema = z.object({
    title: z.string().min(1, 'Title is required'),
    description: z.string().optional()
});

function validateTask(req, res, next) {
    try {
        taskSchema.parse(req.body);
        next();
    } catch (error) {
        return res.status(400).json({ errors: error.errors });
    }
}

module.exports = { validateTask };