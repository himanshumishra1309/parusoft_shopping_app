import { Router } from "express";
import {
  addToCart,
  updateCartItem,
  removeFromCart,
  getCart,
  clearCart,
  adjustCartItemQuantity,
  checkProductInCart,
} from "../controllers/cart.controller.js";

const router = Router();

router.get("/", getCart);

router.post("/add", addToCart);

router.put("/update", updateCartItem);

router.delete("/item/:itemId", removeFromCart);

router.delete("/clear", clearCart);

router.patch("/item/:itemId/adjust", adjustCartItemQuantity);

router.get("/check/:productId", checkProductInCart);

export default router;
