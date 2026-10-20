export interface ParsedDbError {
  statusCode: number;
  code: string;
  message: string;
  details?: Record<string, any>;
}

export const isDbError = (err: any): boolean => {
  if (!err || typeof err !== "object") return false;
  return Boolean(
    (err.code &&
      typeof err.code === "string" &&
      (/^[0-9A-Z]{5}$/.test(err.code) ||
        ["ECONNREFUSED", "ENOTFOUND", "ETIMEDOUT", "ECONNRESET"].includes(
          err.code,
        ))) ||
    err.name === "DatabaseError" ||
    err.routine !== undefined ||
    err.severity !== undefined,
  );
};

export const parseDbError = (err: any): ParsedDbError => {
  const code = (err.code || "").toString();
  const detail = (err.detail || err.message || "").toString();
  const lowerDetail = detail.toLowerCase();

  if (code === "23505") {
    let message = "A record with these unique details already exists";
    if (lowerDetail.includes("email")) {
      message = "An account with this email address already exists";
    } else if (lowerDetail.includes("phone")) {
      message = "An account with this phone number already exists";
    } else if (lowerDetail.includes("username")) {
      message = "This username is already taken";
    } else if (
      lowerDetail.includes("court") ||
      lowerDetail.includes("booking") ||
      lowerDetail.includes("slot")
    ) {
      message = "This turf court slot is already booked for the selected time";
    } else {
      const match = detail.match(/Key \((.+?)\)=\((.+?)\) already exists/i);
      if (match && match[1]) {
        message = `A record with this ${match[1].replace(/_/g, " ")} already exists`;
      }
    }
    return {
      statusCode: 400,
      code: "DUPLICATE_ENTRY",
      message,
      details: {
        detail: err.detail,
        table: err.table,
        constraint: err.constraint,
      },
    };
  }

  if (code === "23503") {
    let message = "Referenced record does not exist";
    let statusCode = 400;
    let errCode = "FOREIGN_KEY_VIOLATION";

    if (lowerDetail.includes("is still referenced from table")) {
      message =
        "Cannot delete or alter this record because other records depend on it";
      statusCode = 409;
      errCode = "FOREIGN_KEY_CONFLICT";
    }

    return {
      statusCode,
      code: errCode,
      message,
      details: {
        detail: err.detail,
        table: err.table,
        constraint: err.constraint,
      },
    };
  }

  if (code === "23502") {
    const colName = err.column ? `'${err.column}'` : "A required column";
    return {
      statusCode: 400,
      code: "NOT_NULL_VIOLATION",
      message: `${colName} cannot be null or empty`,
      details: {
        column: err.column,
        table: err.table,
      },
    };
  }

  if (code === "23514") {
    return {
      statusCode: 400,
      code: "CHECK_CONSTRAINT_VIOLATION",
      message: `Database validation constraint failed (${err.constraint || "invalid value"})`,
      details: {
        constraint: err.constraint,
        table: err.table,
      },
    };
  }

  if (code === "23P01") {
    return {
      statusCode: 409,
      code: "TIME_SLOT_CONFLICT",
      message: "Conflicting booking or reservation time range detected",
      details: {
        constraint: err.constraint,
        table: err.table,
      },
    };
  }

  if (code === "22P02") {
    return {
      statusCode: 400,
      code: "INVALID_INPUT_SYNTAX",
      message: "Invalid identifier syntax or data format provided",
      details: {
        message: err.message,
      },
    };
  }

  if (code === "22001") {
    return {
      statusCode: 400,
      code: "STRING_TOO_LONG",
      message: "Input text exceeds the maximum allowable character length",
      details: {
        table: err.table,
        column: err.column,
      },
    };
  }

  if (code === "22003") {
    return {
      statusCode: 400,
      code: "NUMERIC_OUT_OF_RANGE",
      message: "Numeric value exceeds permitted numerical bounds",
      details: {
        message: err.message,
      },
    };
  }

  if (code === "22007" || code === "22008") {
    return {
      statusCode: 400,
      code: "INVALID_DATETIME_FORMAT",
      message: "Invalid date or timestamp format provided",
      details: {
        message: err.message,
      },
    };
  }

  if (code === "40P01") {
    return {
      statusCode: 409,
      code: "DATABASE_DEADLOCK",
      message: "A database deadlock occurred. Please retry your request.",
      details: {},
    };
  }

  if (code === "40001") {
    return {
      statusCode: 409,
      code: "CONCURRENCY_CONFLICT",
      message: "Concurrent transaction conflict detected. Please retry.",
      details: {},
    };
  }

  if (code === "42501") {
    return {
      statusCode: 403,
      code: "PERMISSION_DENIED",
      message: err.message || "Action prohibited by database security policy",
      details: {},
    };
  }

  if (code === "42P01" || code === "42703") {
    return {
      statusCode: 500,
      code: "DATABASE_SCHEMA_ERROR",
      message:
        process.env.NODE_ENV === "production"
          ? "Database configuration error"
          : err.message,
      details:
        process.env.NODE_ENV === "production"
          ? {}
          : { routine: err.routine, query: err.query },
    };
  }

  if (code === "57014") {
    return {
      statusCode: 504,
      code: "QUERY_TIMEOUT",
      message: "Database query execution timed out",
      details: {},
    };
  }

  if (code === "57P01" || code === "57P02" || code === "57P03") {
    return {
      statusCode: 503,
      code: "DATABASE_UNAVAILABLE",
      message: "Database service is temporarily unavailable",
      details: {},
    };
  }

  if (code === "P0001") {
    return {
      statusCode: 400,
      code: "BUSINESS_RULE_VIOLATION",
      message: err.message || "Operation rejected by database business logic",
      details: {
        where: err.where,
      },
    };
  }

  if (
    ["ECONNREFUSED", "ENOTFOUND", "ETIMEDOUT", "ECONNRESET"].includes(code) ||
    lowerDetail.includes("connection terminated") ||
    lowerDetail.includes("client has already been connected")
  ) {
    return {
      statusCode: 503,
      code: "DATABASE_CONNECTION_ERROR",
      message: "Database connection failed or timed out",
      details: {},
    };
  }

  return {
    statusCode: 500,
    code: "DATABASE_ERROR",
    message:
      process.env.NODE_ENV === "production"
        ? "Database error occurred"
        : err.message || "Database error occurred",
    details:
      process.env.NODE_ENV === "production"
        ? {}
        : { code: err.code, routine: err.routine },
  };
};
