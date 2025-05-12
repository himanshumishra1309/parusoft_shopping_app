import { Cart } from "../models/cart.models.js";
import { Product } from "../models/product.models.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import asyncHandler from "../utils/asyncHandler.js";

export const addToCart = asyncHandler(async (req, res) => {
  const { productId, quantity = 1 } = req.body;

  const userId = req.user._id;

  if (!productId) {
    throw new ApiError(400, "Product ID is required");
  }

  const product = await Product.findById(productId);
  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  if (req.body.variantId) {
    const variant = product.variants.id(req.body.variantId);
    if (!variant) {
      throw new ApiError(404, "Product variant not found");
    }
    if (variant.stock < quantity) {
      throw new ApiError(400, "Not enough stock available");
    }
  }

  let cart = await Cart.findOne({ user: userId });

  if (!cart) {
    cart = await Cart.create({
      user: userId,
      items: [],
      totalAmount: 0,
    });
  }

  const existingItemIndex = cart.items.findIndex(
    (item) => item.product.toString() === productId
  );

  if (existingItemIndex > -1) {
    cart.items[existingItemIndex].quantity += quantity;
  } else {
    cart.items.push({
      product: productId,
      quantity,
      variant: req.body.variantId,
    });
  }

  await cart.populate("items.product", "name price images");
  cart.totalAmount = cart.items.reduce((total, item) => {
    return total + item.product.price * item.quantity;
  }, 0);

  await cart.save();

  return res
    .status(200)
    .json(new ApiResponse(200, cart, "Product added to cart successfully"));
});

export const updateCartItem = asyncHandler(async (req, res) => {
  const { itemId, quantity } = req.body;

  const userId = req.user._id;

  if (!itemId || !quantity) {
    throw new ApiError(400, "Item ID and quantity are required");
  }

  if (quantity < 1) {
    throw new ApiError(400, "Quantity must be at least 1");
  }

  const cart = await Cart.findOne({ user: userId });
  if (!cart) {
    throw new ApiError(404, "Cart not found");
  }

  const itemIndex = cart.items.findIndex(
    (item) => item._id.toString() === itemId
  );
  if (itemIndex === -1) {
    throw new ApiError(404, "Item not found in cart");
  }

  cart.items[itemIndex].quantity = quantity;

  await cart.populate("items.product", "name price images");
  cart.totalAmount = cart.items.reduce((total, item) => {
    return total + item.product.price * item.quantity;
  }, 0);

  await cart.save();

  return res
    .status(200)
    .json(new ApiResponse(200, cart, "Cart updated successfully"));
});

export const removeFromCart = asyncHandler(async (req, res) => {
  const { itemId } = req.params;

  const userId = req.user._id;

  if (!itemId) {
    throw new ApiError(400, "Item ID is required");
  }

  const cart = await Cart.findOne({ user: userId });
  if (!cart) {
    throw new ApiError(404, "Cart not found");
  }

  cart.items = cart.items.filter((item) => item._id.toString() !== itemId);

  await cart.populate("items.product", "name price images");
  cart.totalAmount = cart.items.reduce((total, item) => {
    return total + item.product.price * item.quantity;
  }, 0);

  await cart.save();

  return res
    .status(200)
    .json(new ApiResponse(200, cart, "Item removed from cart successfully"));
});

export const getCart = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  const cart = await Cart.findOne({ user: userId }).populate({
    path: "items.product",
    select: "name price images description category variants",
  });

  if (!cart) {
    return res
      .status(200)
      .json(
        new ApiResponse(200, { items: [], totalAmount: 0 }, "Cart is empty")
      );
  }

  return res
    .status(200)
    .json(new ApiResponse(200, cart, "Cart retrieved successfully"));
});

export const clearCart = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  const cart = await Cart.findOne({ user: userId });

  if (!cart) {
    throw new ApiError(404, "Cart not found");
  }

  cart.items = [];
  cart.totalAmount = 0;
  await cart.save();

  return res
    .status(200)
    .json(new ApiResponse(200, cart, "Cart cleared successfully"));
});

export const adjustCartItemQuantity = asyncHandler(async (req, res) => {
  const { itemId } = req.params;
  const { action } = req.body;

  const userId = req.user._id;

  if (!["increase", "decrease"].includes(action)) {
    throw new ApiError(400, "Action must be either increase or decrease");
  }

  const cart = await Cart.findOne({ user: userId });
  if (!cart) {
    throw new ApiError(404, "Cart not found");
  }

  const itemIndex = cart.items.findIndex(
    (item) => item._id.toString() === itemId
  );
  if (itemIndex === -1) {
    throw new ApiError(404, "Item not found in cart");
  }

  if (action === "increase") {
    cart.items[itemIndex].quantity += 1;
  } else {
    if (cart.items[itemIndex].quantity <= 1) {
      cart.items = cart.items.filter((item) => item._id.toString() !== itemId);
    } else {
      cart.items[itemIndex].quantity -= 1;
    }
  }

  await cart.populate("items.product", "name price images");
  cart.totalAmount = cart.items.reduce((total, item) => {
    return total + item.product.price * item.quantity;
  }, 0);

  await cart.save();

  return res
    .status(200)
    .json(new ApiResponse(200, cart, `Item quantity ${action}d successfully`));
});

export const removeProductFromCart = asyncHandler(async (req, res) => {
  const { productId } = req.params;

  const userId = req.user._id;

  if (!productId) {
    throw new ApiError(400, "Product ID is required");
  }

  const cart = await Cart.findOne({ user: userId });
  if (!cart) {
    throw new ApiError(404, "Cart not found");
  }

  cart.items = cart.items.filter(
    (item) => item.product.toString() !== productId
  );

  await cart.populate("items.product", "name price images");
  cart.totalAmount = cart.items.reduce((total, item) => {
    return total + item.product.price * item.quantity;
  }, 0);

  await cart.save();

  return res
    .status(200)
    .json(new ApiResponse(200, cart, "Product removed from cart successfully"));
});

export const checkProductInCart = asyncHandler(async (req, res) => {
  const { productId } = req.params;

  const userId = req.user._id;

  const cart = await Cart.findOne({
    user: userId,
    "items.product": productId,
  });

  const isInCart = !!cart;
  const quantity = cart
    ? cart.items.find((i) => i.product.toString() === productId)?.quantity
    : 0;

  return res
    .status(200)
    .json(
      new ApiResponse(200, { isInCart, quantity }, "Cart status retrieved")
    );
});
