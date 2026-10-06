import { clubScope } from '../middlewares/clubScope.js';

describe('Club Scope Middleware Tests', () => {
  let req: any;
  let res: any;
  let next: jest.Mock;

  beforeEach(() => {
    req = { user: null, params: {}, body: {}, query: {} };
    res = {};
    next = jest.fn();
  });

  it('ADMIN (Role 1) should bypass club scope restriction', async () => {
    req.user = { roleId: 1 };
    await clubScope(req, res, next);
    expect(next).toHaveBeenCalledWith();
  });

  it('MANAGER (Role 2) should fail if no club ID is provided', async () => {
    req.user = { roleId: 2, id: 'mgr_1' };
    await clubScope(req, res, next);
    expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 400 }));
  });
});
