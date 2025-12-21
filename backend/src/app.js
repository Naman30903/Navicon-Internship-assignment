const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// basic health route
app.get('/', (req, res) => res.json({ status: 'ok' }));

module.exports = app;
