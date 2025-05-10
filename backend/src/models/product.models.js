import mongoose, { Schema } from 'mongoose';

const ProductSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true
  },
  category: {
    type: String,
    required: [true, 'Product category is required'],
    trim: true
  },
  price: {
    type: Number,
    required: [true, 'Product price is required'],
    min: [0, 'Price cannot be negative']
  },
  rating: {
    type: Number,
    default: 0,
    min: [0, 'Rating must be at least 0'],
    max: [5, 'Rating cannot exceed 5']
  },
  popularity: {
    type: Number,
    default: 0
  },
  release_date: {
    type: Date,
    default: Date.now
  },
  variants: [{
    color: {
      type: String,
      required: [true, 'Product variant color is required']
    },
    size: {
      type: String,
      required: [true, 'Product variant size is required']
    },
    stock: {
      type: Number,
      required: [true, 'Product variant stock is required'],
      min: [0, 'Stock cannot be negative']
    }
  }],
  images: [String],
  description: {
    type: String,
    required: [true, 'Product description is required']
  },
  reviews: [{
    user: {
      type: String,
      required: [true, 'Review user is required']
    },
    rating: {
      type: Number,
      required: [true, 'Review rating is required'],
      min: [1, 'Rating must be at least 1'],
      max: [5, 'Rating cannot exceed 5']
    },
    comment: {
      type: String
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }]
}, { timestamps: true });

export const Product = mongoose.model('Product', ProductSchema);