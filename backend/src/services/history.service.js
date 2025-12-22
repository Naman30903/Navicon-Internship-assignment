const { supabase } = require('../db/supabase');

/**
 * Log task history
 */
async function logTaskHistory(historyData) {
    try {
        const {
            task_id,
            action,
            old_value = null,
            new_value = null,
            changed_by = 'system'
        } = historyData;

        const { data, error } = await supabase
            .from('task_history')
            .insert({
                task_id,
                action,
                old_value,
                new_value,
                changed_by
            })
            .select()
            .single();

        if (error) {
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

/**
 * Get task history
 */
async function getTaskHistory(taskId) {
    try {
        const { data, error } = await supabase
            .from('task_history')
            .select('*')
            .eq('task_id', taskId)
            .order('changed_at', { ascending: false });

        if (error) {
            return { success: false, error: error.message };
        }

        return { success: true, data: data || [] };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

module.exports = {
    logTaskHistory,
    getTaskHistory
};