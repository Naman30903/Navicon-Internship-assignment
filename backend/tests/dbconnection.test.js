const dotenv = require('dotenv');
dotenv.config();

const { supabase } = require('../src/db/supabase');

test('Supabase connection works', async () => {
    const { data, error } = await supabase.from('tasks').select('count').limit(1);
    expect(error).toBeNull();
    expect(data).toBeDefined();
});