import swaggerJSDoc from 'swagger-jsdoc';

const options: swaggerJSDoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'ALL STARS ARENA Football Backend API',
      version: '2.0.0',
      description:
        'Production-grade API for ALL STARS ARENA - Football Pitch Booking, Match Scheduling, Wallet Top-Ups, Live Football Scores, and CCTV Recording Control.',
    },
    servers: [
      {
        url: 'http://localhost:5000/api/v1',
        description: 'Development Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ['./src/routes/*.ts', './src/modules/**/*.ts'],
};

export const swaggerSpec = swaggerJSDoc(options);
