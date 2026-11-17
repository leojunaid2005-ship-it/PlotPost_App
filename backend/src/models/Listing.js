import mongoose from 'mongoose';

const listingSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    platform: { type: String, trim: true, default: 'PlotPost', maxlength: 40 },
    title: { type: String, required: true, trim: true, maxlength: 140 },
    type: { type: String, required: true, trim: true, maxlength: 40 },
    deal: { type: String, required: true, trim: true, maxlength: 40 },
    price: { type: String, trim: true, maxlength: 80, default: '' },
    location: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, trim: true, maxlength: 5000, default: '' },
    socialUrl: { type: String, trim: true, maxlength: 2048, default: '' },
    sellerPhone: { type: String, trim: true, maxlength: 30, default: '' },
    area: { type: String, trim: true, maxlength: 80, default: '' },
    bedrooms: { type: String, trim: true, maxlength: 20, default: '' },
    bathrooms: { type: String, trim: true, maxlength: 20, default: '' },
    images: {
      type: [
        new mongoose.Schema(
          {
            url: { type: String, required: true },
            publicId: { type: String, required: true },
          },
          { _id: false },
        ),
      ],
      default: [],
      validate: [(images) => images.length <= 8, 'A listing can have at most 8 images.'],
    },
  },
  { timestamps: true },
);

listingSchema.index({ createdAt: -1 });
listingSchema.index({ title: 'text', description: 'text', location: 'text' });

export const Listing = mongoose.model('Listing', listingSchema);
