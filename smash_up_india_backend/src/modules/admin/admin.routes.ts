import { Router } from "express";
import {
  getAdminDashboardController,
  getUsersController,
  getUserDetailsController,
  suspendUserController,
  createManagerController,
  createAdminController,
  approveClubController,
  assignManagerController,
  resolveDisputeController,
  getAuditLogsController,
  getAdminPaymentHistoryController,
  processAdminRefundController,
} from "./admin.controller.js";
import {
  cancelGameController,
  submitMatchScoreController,
} from "../manager/manager.controller.js";
import cctvRoutes from "../cctv/cctv.routes.js";
import {
  authenticateToken,
  requireRole,
  requireOwner,
} from "../../middlewares/auth.middleware.js";

const router = Router();

router.use(authenticateToken);
router.use(requireRole([1]));

router.use("/cctv", cctvRoutes);

router.get("/dashboard", getAdminDashboardController);
router.get("/users", getUsersController);
router.get("/users/:id", getUserDetailsController);
router.patch("/users/:id/suspend", suspendUserController);

router.post("/managers", createManagerController);
router.post("/admins", requireOwner, createAdminController);

router.patch("/clubs/:id/approve", approveClubController);
router.post("/clubs/:id/assign-manager", assignManagerController);

router.post("/disputes/:id/resolve", resolveDisputeController);
router.post("/games/:id/cancel", cancelGameController);
router.post("/games/:id/score", submitMatchScoreController);
router.get("/audit-logs", getAuditLogsController);
router.get("/payments", getAdminPaymentHistoryController);
router.post("/payments/:id/refund", processAdminRefundController);

export default router;
