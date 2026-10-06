import request from 'supertest';
import app from '../app.js';
describe('ALL STARS ARENA Health API', () => {


  it('GET /api/v1/health should return 200 and success response', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('Server is healthy and running');
    expect(res.body.data).toHaveProperty('database');
  });
});
