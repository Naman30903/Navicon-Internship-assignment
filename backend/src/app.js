const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const tasksRoutes = require('./routes/tasks.routes');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const swaggerPath = path.join(__dirname, '..', 'docs', 'swagger.yaml');
const swaggerDocument = YAML.load(swaggerPath);

app.get('/docs/swagger.yaml', (req, res) => {
    return res.sendFile(swaggerPath);
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// basic health route
app.get('/', (req, res) => res.json({ status: 'ok' }));

// Tasks routes
app.use('/api/tasks', tasksRoutes);

module.exports = app;
