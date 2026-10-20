import {
  requireRole,
  requireAdminType,
  requireOwner,
} from "../middlewares/rbac.js";

describe("RBAC Middleware Tests", () => {
  let req: any;
  let res: any;
  let next: jest.Mock;

  beforeEach(() => {
    req = { user: null };
    res = {};
    next = jest.fn();
  });

  it("requireRole should allow authorized roles", () => {
    req.user = { roleId: 3 };
    const middleware = requireRole([3]);
    middleware(req, res, next);
    expect(next).toHaveBeenCalledWith();
  });

  it("requireRole should deny unauthorized roles", () => {
    req.user = { roleId: 3 };
    const middleware = requireRole([1, 2]);
    middleware(req, res, next);
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 403 }),
    );
  });

  it("requireAdminType should allow matching admin types", () => {
    req.user = { roleId: 1, adminType: "SUPER_ADMIN" };
    const middleware = requireAdminType(["SUPER_ADMIN"]);
    middleware(req, res, next);
    expect(next).toHaveBeenCalledWith();
  });

  it("requireAdminType should deny non-matching admin types", () => {
    req.user = { roleId: 1, adminType: "OPS_ADMIN" };
    const middleware = requireAdminType(["FINANCE_ADMIN"]);
    middleware(req, res, next);
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 403 }),
    );
  });

  it("requireOwner should allow platform owner", () => {
    req.user = { roleId: 1, isOwner: true };
    requireOwner(req, res, next);
    expect(next).toHaveBeenCalledWith();
  });

  it("requireOwner should deny non-owner users", () => {
    req.user = { roleId: 1, isOwner: false };
    requireOwner(req, res, next);
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ statusCode: 403 }),
    );
  });
});
