import { Router } from "express";
import {
  addProduct,
  addMultipleProducts,
  updateProduct,
  deleteProduct,
  getProductById,
  getAllProducts
} from "../controllers/product.controller.js";

const router = Router();

router.get("/", getAllProducts);

router.get("/:id", getProductById);

router.post("/", addProduct);

router.post("/bulk", addMultipleProducts);

router.put("/:id", updateProduct);

router.delete("/:id", deleteProduct);

export default router;