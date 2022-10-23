import express from 'express';

const app = express();

app.get('*', async (req, res) => {
  return res.json({
    method: req.method,
    path: req.path,
    query: req.query,
    headers: req.headers
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});

export default app;
