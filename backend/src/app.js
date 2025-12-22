const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const tasksRoutes = require('./routes/tasks.routes');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// basic health route
app.get('/', (req, res) => res.json({ status: 'ok' }));

// Tasks routes
app.use('/api/tasks', tasksRoutes);

module.exports = app;
