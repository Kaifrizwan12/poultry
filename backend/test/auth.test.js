const request = require('supertest');
const app = require('../src/index');

describe('Auth routes (smoke)', () => {
  it('responds 404 for unknown', async () => {
    const res = await request(app).get('/notfound');
    expect(res.status).toBe(404);
  });
});
