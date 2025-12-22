const { supabase } = require('../db/supabase');
const historyService = require('./history.service');
const classificationService = require('./classification.service');

/**
 * Create a new task
 */
async function createTask(taskData) {
    try {
        // Auto-classify/enrich from description if present.
        // Only fill fields that aren't explicitly provided by client.
        if (taskData.description) {
            const enrichment = classificationService.classifyTask(taskData.description);

            if (!taskData.category) taskData.category = enrichment.category;
            if (!taskData.priority) taskData.priority = enrichment.priority;

            if (!taskData.extracted_entities) {
                taskData.extracted_entities = enrichment.extracted_entities;
            }
            if (!taskData.suggested_actions) {
                taskData.suggested_actions = enrichment.suggested_actions;
            }
        }

        // Set defaults
        const task = {
            ...taskData,
            status: taskData.status || 'pending',
            category: taskData.category || 'general',
            priority: taskData.priority || 'low',
        };

        // Insert task
        const { data, error } = await supabase
            .from('tasks')
            .insert(task)
            .select()
            .single();

        if (error) {
            return { success: false, error: error.message };
        }

        // Log creation in history
        await historyService.logTaskHistory({
            task_id: data.id,
            action: 'created',
            new_value: data,
            changed_by: taskData.assigned_to || 'system'
        });

        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

/**
 * Get all tasks with filters and pagination
 */
async function getTasks(filters = {}) {
    try {
        const {
            limit = 10,
            offset = 0,
            status,
            category,
            priority
        } = filters;

        const parsedLimit = Math.max(1, parseInt(limit, 10) || 10);
        const parsedOffset = Math.max(0, parseInt(offset, 10) || 0);

        let baseQuery = supabase
            .from('tasks')
            .select('*', { count: 'exact' });

        if (status) baseQuery = baseQuery.eq('status', status);
        if (category) baseQuery = baseQuery.eq('category', category);
        if (priority) baseQuery = baseQuery.eq('priority', priority);

        const { count, error: countError } = await baseQuery;
        if (countError) return { success: false, error: countError.message };

        const total = count || 0;
        const totalPages = Math.ceil(total / parsedLimit);

        if (parsedOffset >= total) {
            return {
                success: true,
                data: [],
                pagination: { total, limit: parsedLimit, offset: parsedOffset, totalPages }
            };
        }

        let pageQuery = supabase
            .from('tasks')
            .select('*');

        if (status) pageQuery = pageQuery.eq('status', status);
        if (category) pageQuery = pageQuery.eq('category', category);
        if (priority) pageQuery = pageQuery.eq('priority', priority);

        const { data, error } = await pageQuery
            .order('created_at', { ascending: false })
            .order('id', { ascending: false })
            .range(parsedOffset, parsedOffset + parsedLimit - 1);

        if (error) return { success: false, error: error.message };

        return {
            success: true,
            data: data || [],
            pagination: { total, limit: parsedLimit, offset: parsedOffset, totalPages }
        };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

/**
 * Get a single task by ID
 */
async function getTaskById(id) {
    try {
        const { data, error } = await supabase
            .from('tasks')
            .select('*')
            .eq('id', id)
            .maybeSingle();

        if (error) {
            return { success: false, error: error.message };
        }

        if (!data) {
            return { success: false, message: 'Task not found' };
        }

        // Normalize defaults for tests/tasks created with minimal fields
        const normalized = {
            ...data,
            status: data.status || 'pending',
            category: data.category || 'general',
            priority: data.priority || 'low',
        };

        return { success: true, data: normalized };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

/**
 * Update a task
 */
async function updateTask(id, updates) {
    try {
        // Get old task data
        const { data: oldTask } = await supabase
            .from('tasks')
            .select('*')
            .eq('id', id)
            .single();

        if (!oldTask) {
            return { success: false, message: 'Task not found' };
        }

        // Update task
        const { data, error } = await supabase
            .from('tasks')
            .update({ ...updates, updated_at: new Date().toISOString() })
            .eq('id', id)
            .select()
            .single();

        if (error) {
            return { success: false, error: error.message };
        }

        // Log update in history
        await historyService.logTaskHistory({
            task_id: id,
            action: 'updated',
            old_value: oldTask,
            new_value: data,
            changed_by: updates.assigned_to || 'system'
        });

        // Log status change separately if status changed
        if (updates.status && updates.status !== oldTask.status) {
            await historyService.logTaskHistory({
                task_id: id,
                action: 'status_changed',
                old_value: { status: oldTask.status },
                new_value: { status: updates.status },
                changed_by: updates.assigned_to || 'system'
            });

            // Log completion if status changed to completed
            if (updates.status === 'completed') {
                await historyService.logTaskHistory({
                    task_id: id,
                    action: 'completed',
                    new_value: data,
                    changed_by: updates.assigned_to || 'system'
                });
            }
        }

        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

/**
 * Delete a task
 */
async function deleteTask(id) {
    try {
        // Check if task exists
        const { data: task } = await supabase
            .from('tasks')
            .select('id')
            .eq('id', id)
            .single();

        if (!task) {
            return { success: false, message: 'Task not found' };
        }

        // Delete task (history will be cascade deleted)
        const { error } = await supabase
            .from('tasks')
            .delete()
            .eq('id', id);

        if (error) {
            return { success: false, error: error.message };
        }

        return { success: true, message: 'Task deleted successfully' };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

module.exports = {
    createTask,
    getTasks,
    getTaskById,
    updateTask,
    deleteTask
};