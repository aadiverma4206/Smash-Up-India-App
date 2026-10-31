import { Router } from "express";
import {
  getClubsController,
  getCourtsController,
  getCourtByIdController,
  getAvailabilityController,
  getPriceQuoteController,
} from "./courts.controller.js";

const router = Router();

router.get("/clubs", getClubsController);
router.get("/", getCourtsController);
router.get("/:id", getCourtByIdController);
router.get("/:id/availability", getAvailabilityController);
router.get("/:id/slots", getAvailabilityController);
router.get("/:id/price-quote", getPriceQuoteController);

export default router;
