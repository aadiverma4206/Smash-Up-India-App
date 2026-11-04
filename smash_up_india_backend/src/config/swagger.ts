import swaggerJSDoc from "swagger-jsdoc";

const options: swaggerJSDoc.Options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "SMASH UP INDIA Sports Backend API",
      version: "2.0.0",
      description:
        "Production-grade API for SMASH UP INDIA - Pitch Booking, Match Scheduling, Wallet Top-Ups, Live Scores, and CCTV Recording Control.",
    },
    servers: [
      {
        url: `http://localhost:${process.env.PORT || "8599"}/api/v1`,
        description: "Development Server",
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ["./src/routes/*.ts", "./src/modules/**/*.ts"],
};

export const swaggerSpec = swaggerJSDoc(options);
