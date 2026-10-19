import request from "supertest";
import express, { Request, Response, NextFunction } from "express";
import multer from "multer";
import jwt from "jsonwebtoken";
import { ZodError, z } from "zod";
import { ApiError, ApiResponse } from "../utils/apiResponse.js";
import { errorHandler } from "../middlewares/error.middleware.js";
import { requestId } from "../middlewares/requestId.js";
import { parseDbError, isDbError } from "../utils/dbErrors.js";

describe("Comprehensive Error Handling Test Suite", () => {
  // Test Express application setup with universal error handler
  const testApp = express();
  testApp.use(requestId);
  testApp.use(express.json());

  // Test routes triggering each category of error
  testApp.get("/test/api-error-bad-request", () => {
    throw ApiError.badRequest(
      "Custom bad request message",
      "CUSTOM_BAD_REQUEST",
      { field: "testField" },
    );
  });

  testApp.get("/test/api-error-unauthorized", () => {
    throw ApiError.unauthorized("Token has been revoked");
  });

  testApp.get("/test/api-error-forbidden", () => {
    throw ApiError.forbidden("User does not have required permissions");
  });

  testApp.get("/test/api-error-not-found", () => {
    throw ApiError.notFound(
      "Requested tournament not found",
      "TOURNAMENT_NOT_FOUND",
    );
  });

  testApp.get("/test/api-error-conflict", () => {
    throw ApiError.conflict("Team slot is already taken");
  });

  testApp.get("/test/zod-error", () => {
    const schema = z.object({
      age: z.number().min(18, "Must be at least 18 years old"),
      email: z.string().email("Invalid email address format"),
    });
    schema.parse({ age: 15, email: "not-an-email" });
  });

  testApp.get("/test/jwt-expired-error", () => {
    const err = new jwt.TokenExpiredError("jwt expired", new Date());
    throw err;
  });

  testApp.get("/test/jwt-invalid-error", () => {
    const err = new jwt.JsonWebTokenError("invalid signature");
    throw err;
  });

  testApp.get("/test/multer-size-error", () => {
    const err = new (multer as any).MulterError("LIMIT_FILE_SIZE", "avatar");
    throw err;
  });

  testApp.get("/test/multer-unexpected-error", () => {
    const err = new (multer as any).MulterError(
      "LIMIT_UNEXPECTED_FILE",
      "unknownDoc",
    );
    throw err;
  });

  testApp.get("/test/pg-unique-email", () => {
    const err: any = new Error(
      "duplicate key value violates unique constraint",
    );
    err.code = "23505";
    err.detail = "Key (email)=(existing@example.com) already exists.";
    err.table = "users";
    throw err;
  });

  testApp.get("/test/pg-unique-phone", () => {
    const err: any = new Error(
      "duplicate key value violates unique constraint",
    );
    err.code = "23505";
    err.detail = "Key (phone)=(+919876543210) already exists.";
    err.table = "users";
    throw err;
  });

  testApp.get("/test/pg-unique-slot", () => {
    const err: any = new Error(
      "duplicate key value violates unique constraint",
    );
    err.code = "23505";
    err.detail = "Key (court_id, match_date, start_time)=(...) already exists.";
    err.table = "bookings";
    throw err;
  });

  testApp.get("/test/pg-foreign-key", () => {
    const err: any = new Error("foreign key constraint failure");
    err.code = "23503";
    err.detail = 'Key (club_id)=(clb_999) is not present in table "clubs".';
    err.table = "courts";
    throw err;
  });

  testApp.get("/test/pg-invalid-syntax", () => {
    const err: any = new Error("invalid input syntax for type uuid");
    err.code = "22P02";
    throw err;
  });

  testApp.get("/test/pg-raise-exception", () => {
    const err: any = new Error(
      "Game is not open for joining. Current status: COMPLETED",
    );
    err.code = "P0001";
    err.where = "PL/pgSQL function join_game_with_wallet line 102 at RAISE";
    throw err;
  });

  testApp.get("/test/pg-connection-down", () => {
    const err: any = new Error("connect ECONNREFUSED 127.0.0.1:5432");
    err.code = "ECONNREFUSED";
    throw err;
  });

  testApp.get("/test/unhandled-runtime-error", () => {
    throw new Error("Unexpected NullPointer or undefined property access");
  });

  // Catch-all 404 handler
  testApp.use((req: Request, _res: Response, next: NextFunction) => {
    next(
      ApiError.notFound(
        `Endpoint ${req.method} ${req.originalUrl} not found`,
        "ROUTE_NOT_FOUND",
        { method: req.method, url: req.originalUrl },
      ),
    );
  });

  // Global Error Handler
  testApp.use(errorHandler);

  it("1. Should handle ApiError.badRequest with custom code and details", async () => {
    const res = await request(testApp).get("/test/api-error-bad-request");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe("Custom bad request message");
    expect(res.body.error.code).toBe("CUSTOM_BAD_REQUEST");
    expect(res.body.error.details.field).toBe("testField");
    expect(res.body.error.requestId).toBeDefined();
  });

  it("2. Should handle ApiError.unauthorized with 401 status", async () => {
    const res = await request(testApp).get("/test/api-error-unauthorized");
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("UNAUTHORIZED");
  });

  it("3. Should handle ApiError.forbidden with 403 status", async () => {
    const res = await request(testApp).get("/test/api-error-forbidden");
    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("FORBIDDEN");
  });

  it("4. Should handle ApiError.notFound with 404 status", async () => {
    const res = await request(testApp).get("/test/api-error-not-found");
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("TOURNAMENT_NOT_FOUND");
  });

  it("5. Should handle ApiError.conflict with 409 status", async () => {
    const res = await request(testApp).get("/test/api-error-conflict");
    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("CONFLICT");
  });

  it("6. Should format Zod validation errors with field names and messages", async () => {
    const res = await request(testApp).get("/test/zod-error");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("VALIDATION_ERROR");
    expect(Array.isArray(res.body.error.details)).toBe(true);
    expect(res.body.error.details.length).toBe(2);
    expect(res.body.error.details[0].field).toBe("age");
    expect(res.body.error.details[1].field).toBe("email");
  });

  it("7. Should handle JWT TokenExpiredError with 401 and TOKEN_EXPIRED code", async () => {
    const res = await request(testApp).get("/test/jwt-expired-error");
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("TOKEN_EXPIRED");
    expect(res.body.message).toContain("expired");
  });

  it("8. Should handle JWT JsonWebTokenError with 401 and INVALID_TOKEN code", async () => {
    const res = await request(testApp).get("/test/jwt-invalid-error");
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("INVALID_TOKEN");
  });

  it("9. Should handle Multer LIMIT_FILE_SIZE with 400 and FILE_TOO_LARGE code", async () => {
    const res = await request(testApp).get("/test/multer-size-error");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("FILE_TOO_LARGE");
  });

  it("10. Should handle Multer LIMIT_UNEXPECTED_FILE with UNEXPECTED_FILE code", async () => {
    const res = await request(testApp).get("/test/multer-unexpected-error");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("UNEXPECTED_FILE");
    expect(res.body.message).toContain("unknownDoc");
  });

  it("11. Should handle PostgreSQL 23505 unique email constraint with friendly message", async () => {
    const res = await request(testApp).get("/test/pg-unique-email");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("DUPLICATE_ENTRY");
    expect(res.body.message).toBe(
      "An account with this email address already exists",
    );
  });

  it("12. Should handle PostgreSQL 23505 unique phone constraint with friendly message", async () => {
    const res = await request(testApp).get("/test/pg-unique-phone");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("DUPLICATE_ENTRY");
    expect(res.body.message).toBe(
      "An account with this phone number already exists",
    );
  });

  it("13. Should handle PostgreSQL 23505 court slot unique booking collision", async () => {
    const res = await request(testApp).get("/test/pg-unique-slot");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("DUPLICATE_ENTRY");
    expect(res.body.message).toContain("turf court slot is already booked");
  });

  it("14. Should handle PostgreSQL 23503 foreign key violation", async () => {
    const res = await request(testApp).get("/test/pg-foreign-key");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("FOREIGN_KEY_VIOLATION");
    expect(res.body.message).toBe("Referenced record does not exist");
  });

  it("15. Should handle PostgreSQL 22P02 invalid input/UUID syntax", async () => {
    const res = await request(testApp).get("/test/pg-invalid-syntax");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("INVALID_INPUT_SYNTAX");
  });

  it("16. Should handle PostgreSQL P0001 PL/pgSQL RAISE EXCEPTION with business message", async () => {
    const res = await request(testApp).get("/test/pg-raise-exception");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("BUSINESS_RULE_VIOLATION");
    expect(res.body.message).toBe(
      "Game is not open for joining. Current status: COMPLETED",
    );
  });

  it("17. Should handle PostgreSQL connection failure with 503 DATABASE_CONNECTION_ERROR", async () => {
    const res = await request(testApp).get("/test/pg-connection-down");
    expect(res.status).toBe(503);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("DATABASE_CONNECTION_ERROR");
  });

  it("18. Should handle undefined routes with 404 ROUTE_NOT_FOUND", async () => {
    const res = await request(testApp).get(
      "/api/v1/non-existent-endpoint-test",
    );
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("ROUTE_NOT_FOUND");
    expect(res.body.message).toContain(
      "Endpoint GET /api/v1/non-existent-endpoint-test not found",
    );
  });

  it("19. Should handle malformed JSON payload with 400 and INVALID_JSON_PAYLOAD code", async () => {
    const res = await request(testApp)
      .post("/test/api-error-bad-request")
      .set("Content-Type", "application/json")
      .send("{ invalid json: ");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("INVALID_JSON_PAYLOAD");
  });

  it("20. Should capture unexpected runtime error as 500 INTERNAL_SERVER_ERROR", async () => {
    const res = await request(testApp).get("/test/unhandled-runtime-error");
    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe("INTERNAL_SERVER_ERROR");
  });
});
