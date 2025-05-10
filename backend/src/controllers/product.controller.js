import { Product } from "../models/product.models.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import asyncHandler from "../utils/asyncHandler.js";

export const addProduct = asyncHandler(async (req, res) => {
  const productData = req.body;

  if (!productData || Object.keys(productData).length === 0) {
    throw new ApiError(400, "Product data is required");
  }

  const product = await Product.create(productData);

  if (!product) {
    throw new ApiError(500, "Something went wrong while creating product");
  }

  return res
    .status(201)
    .json(new ApiResponse(201, product, "Product created successfully"));
});

export const addMultipleProducts = asyncHandler(async (req, res) => {
  const productsArray = req.body;

  if (!Array.isArray(productsArray) || productsArray.length === 0) {
    throw new ApiError(400, "Valid products array is required");
  }

  const products = await Product.insertMany(productsArray);

  if (!products || products.length === 0) {
    throw new ApiError(500, "Failed to add products");
  }

  return res
    .status(201)
    .json(new ApiResponse(201, products, "Products added successfully"));
});

export const updateProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  if (!updateData || Object.keys(updateData).length === 0) {
    throw new ApiError(400, "Update data is required");
  }

  const updatedProduct = await Product.findByIdAndUpdate(id, updateData, {
    new: true,
    runValidators: true,
  });

  if (!updatedProduct) {
    throw new ApiError(404, "Product not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, updatedProduct, "Product updated successfully"));
});

export const deleteProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const deletedProduct = await Product.findByIdAndDelete(id);

  if (!deletedProduct) {
    throw new ApiError(404, "Product not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Product deleted successfully"));
});

export const getProductById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const product = await Product.findById(id);

  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, product, "Product retrieved successfully"));
});

export const getAllProducts = asyncHandler(async (req, res) => {
  const {
    category,
    minPrice,
    maxPrice,
    minRating,
    page = 1,
    limit = 10,
    sortBy = "createdAt",
    sortOrder = "desc",
  } = req.query;

  const filterOptions = {};

  if (category) filterOptions.category = category;
  if (minPrice || maxPrice) {
    filterOptions.price = {};
    if (minPrice) filterOptions.price.$gte = Number(minPrice);
    if (maxPrice) filterOptions.price.$lte = Number(maxPrice);
  }
  if (minRating) filterOptions.rating = { $gte: Number(minRating) };

  const sortOptions = {};
  sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

  const skip = (Number(page) - 1) * Number(limit);

  const products = await Product.find(filterOptions)
    .sort(sortOptions)
    .skip(skip)
    .limit(Number(limit));

  const totalProducts = await Product.countDocuments(filterOptions);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        products,
        pagination: {
          total: totalProducts,
          page: Number(page),
          limit: Number(limit),
          totalPages: Math.ceil(totalProducts / Number(limit)),
        },
      },
      "Products retrieved successfully"
    )
  );
});