import express from 'express';
import cookies from 'cookie-parser';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';

const app = express();

app.use(cookies());

app.get('/api/config', async (req, res) => {
  return res.json({
    env: process.env
  });
});

app.get('/api/s3', async (req, res) => {
  let object: any = {};
  let err = {};

  try {
    const s3Client = new S3Client({ region: 'ap-southeast-2' });
    object = await s3Client.send(new GetObjectCommand({
      Bucket: 'api-ao-alerts-data-uat',
      Key: 'MIP.xml',
    }));
  } catch (error) {
    err = error;
  } finally {
    return res.json({
      objectMetadata: object['$metadata'],
      err
    });
  }
});

app.get('*', async (req, res) => {
  return res.json({
    method: req.method,
    path: req.path,
    query: req.query,
    headers: req.headers,
    cookies: req.cookies
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});

export default app;
