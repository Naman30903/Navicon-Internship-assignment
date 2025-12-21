const app = require('./app');
const port = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(port, () => console.log(`Server listening on port ${port}`));
}

module.exports = { startServer: (p = port) => app.listen(p) };
