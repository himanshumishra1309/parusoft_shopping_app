import cors from "cors";
import express from "express";
import cookieParser from "cookie-parser";

const app = express();

app.use((req, res, next) => {
  console.log(
    `[${new Date().toISOString()}] ${req.method} ${req.originalUrl} from ${
      req.ip
    }`
  );
  next();
});

app.use(
  cors({
    origin: function (origin, callback) {
      if (!origin) return callback(null, true);

      const allowedOrigins =
        "*" ||
        process.env.CORS_ORIGIN ||
        "http://localhost:5173" ||
        "http://localhost:5174";

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(null, true);
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization", "user-id"],
  })
);

app.use(
  express.json({
    limit: "16kb",
  })
);

app.use(
  express.urlencoded({
    extended: true,
    limit: "16kb",
  })
);

app.use(express.static("public"));

app.use(cookieParser());

import productRouter from "./routes/product.routes.js";
import cartRouter from "./routes/cart.routes.js";
import userRouter from "./routes/user.routes.js";

app.get("/api/v1", (_, res) => {
  res.status(200).json({
    status: "success",
    message: "Welcome to Parusoft Shopping API",
    apiVersion: "1.0.0",
    endpoints: {
      products: "/api/v1/products",
      productById: "/api/v1/products/:id",
      cart: "/api/v1/cart",
    },
  });
});

app.use("/api/v1/products", productRouter);

app.use("/api/v1/cart", cartRouter);

app.use("/api/v1/users", userRouter);

export { app };
