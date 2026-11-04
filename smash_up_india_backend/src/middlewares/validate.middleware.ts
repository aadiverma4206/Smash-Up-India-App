import { Request, Response, NextFunction } from "express";
import { ZodError, ZodTypeAny } from "zod";
import { ApiError } from "../utils/apiResponse.js";

export const validateRequest = (schema: ZodTypeAny) => {
  return async (req: Request, _res: Response, next: NextFunction) => {
    try {
      const parsed = await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      if (parsed && typeof parsed === "object") {
        if ("body" in parsed && parsed.body !== undefined)
          req.body = parsed.body;
        if ("query" in parsed && parsed.query !== undefined)
          req.query = parsed.query;
        if ("params" in parsed && parsed.params !== undefined)
          req.params = parsed.params;
      }

      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          field: err.path.join("."),
          message: err.message,
        }));
        return next(
          new ApiError(
            400,
            "Validation Error",
            "VALIDATION_ERROR",
            formattedErrors,
          ),
        );
      }
      next(error);
    }
  };
};

export const validate = validateRequest;
