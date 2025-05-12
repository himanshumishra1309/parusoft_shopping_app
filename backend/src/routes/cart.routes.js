import { Router } from "express";
import {
  addToCart,
  updateCartItem,
  removeFromCart,
  getCart,
  clearCart,
  adjustCartItemQuantity,
  checkProductInCart,
  removeProductFromCart,
} from "../controllers/cart.controller.js";
import { verifyJWT } from "../middleware/auth.middleware.js";

const router = Router();

router.use(verifyJWT);

router.get("/", getCart);

router.post("/add", addToCart);

router.put("/update", updateCartItem);

router.delete("/item/:itemId", removeFromCart);

router.delete("/product/:productId", removeProductFromCart);

router.delete("/clear", clearCart);

router.patch("/item/:itemId/adjust", adjustCartItemQuantity);

router.get("/check/:productId", checkProductInCart);

export default router;
