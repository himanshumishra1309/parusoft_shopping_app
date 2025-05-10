import mongoose, { Schema } from 'mongoose';

const CartItemSchema = new Schema({
  product: {
    type: Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    min: [1, 'Quantity cannot be less than 1'],
    default: 1
  },
  variant: {
    type: Schema.Types.ObjectId,
    default: null
  }
});

const CartSchema = new Schema({
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  items: [CartItemSchema],
  totalAmount: {
    type: Number,
    required: true,
    default: 0
  }
}, { timestamps: true });

export const Cart = mongoose.model('Cart', CartSchema);