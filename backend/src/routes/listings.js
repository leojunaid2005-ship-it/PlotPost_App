import { Router } from 'express';
import multer from 'multer';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { configureCloudinary, uploadImage } from '../config/cloudinary.js';
import { Listing } from '../models/Listing.js';

const router = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024, files: 8 },
  fileFilter: (req, file, callback) => {
    if (!file.mimetype.startsWith('image/')) {
      callback(new Error('Only image files can be uploaded.'));
      return;
    }
    callback(null, true);
  },
});
const listingSchema = z.object({
  platform: z.string().trim().max(40).optional().default('PlotPost'),
  title: z.string().trim().min(1).max(140),
  type: z.string().trim().min(1).max(40),
  deal: z.string().trim().min(1).max(40),
  price: z.string().trim().max(80).optional().default(''),
  location: z.string().trim().min(1).max(200),
  description: z.string().trim().max(5000).optional().default(''),
  socialUrl: z.string().trim().max(2048).optional().default(''),
  sellerPhone: z.string().trim().max(30).optional().default(''),
  area: z.string().trim().max(80).optional().default(''),
  bedrooms: z.string().trim().max(20).optional().default(''),
  bathrooms: z.string().trim().max(20).optional().default(''),
});

function parseListing(body) {
  const parsed = listingSchema.safeParse(body);
  return parsed.success
    ? { data: parsed.data }
    : { error: parsed.error.issues[0].message };
}

function parseExistingImages(value) {
  if (value == null) return [];
  try {
    const parsed = JSON.parse(value);
    if (Array.isArray(parsed) && parsed.every((url) => typeof url === 'string')) {
      return parsed;
    }
  } catch {
    return null;
  }
  return null;
}

function serializeListing(listing) {
  const source = listing.toObject ? listing.toObject() : listing;
  return {
    id: String(source._id),
    platform: source.platform,
    seller: source.owner?.name ?? 'PlotPost user',
    ownerId: String(source.owner?._id ?? source.owner),
    age: source.createdAt?.toISOString() ?? '',
    title: source.title,
    type: source.type,
    deal: source.deal,
    price: source.price,
    location: source.location,
    description: source.description,
    socialUrl: source.socialUrl,
    sellerPhone: source.sellerPhone,
    area: source.area,
    bedrooms: source.bedrooms,
    bathrooms: source.bathrooms,
    imagePaths: (source.images ?? []).map((image) => image.url),
  };
}

router.get('/', async (req, res) => {
  const page = Math.max(1, Number.parseInt(req.query.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, Number.parseInt(req.query.limit, 10) || 20));
  const query = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  const filter = {};
  if (query) {
    const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    filter.$or = [
      { title: { $regex: escaped, $options: 'i' } },
      { location: { $regex: escaped, $options: 'i' } },
      { description: { $regex: escaped, $options: 'i' } },
    ];
  }
  if (typeof req.query.type === 'string' && req.query.type.trim()) {
    filter.type = req.query.type.trim();
  }
  if (typeof req.query.deal === 'string' && req.query.deal.trim()) {
    filter.deal = req.query.deal.trim();
  }

  const [results, total] = await Promise.all([
    Listing.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('owner', 'name')
      .lean(),
    Listing.countDocuments(filter),
  ]);
  return res.json({
    listings: results.map(serializeListing),
    page,
    limit,
    total,
  });
});

router.get('/mine', requireAuth, async (req, res) => {
  const listings = await Listing.find({ owner: req.user.id })
    .sort({ createdAt: -1 })
    .populate('owner', 'name')
    .lean();
  return res.json({ listings: listings.map(serializeListing) });
});

router.post('/', requireAuth, upload.array('images', 8), async (req, res) => {
  const parsed = parseListing(req.body);
  if (parsed.error) return res.status(400).json({ error: parsed.error });

  const cloudinary = req.files?.length ? configureCloudinary() : null;
  const uploaded = [];
  try {
    for (const file of req.files ?? []) {
      const result = await uploadImage(cloudinary, file);
      uploaded.push({ url: result.secure_url, publicId: result.public_id });
    }
    const listing = await Listing.create({
      ...parsed.data,
      owner: req.user.id,
      images: uploaded,
    });
    await listing.populate('owner', 'name');
    return res.status(201).json({ listing: serializeListing(listing) });
  } catch (error) {
    if (cloudinary) {
      await Promise.all(
        uploaded.map((image) => cloudinary.uploader.destroy(image.publicId)),
      );
    }
    throw error;
  }
});

router.patch('/:id', requireAuth, upload.array('images', 8), async (req, res) => {
  const parsed = parseListing(req.body);
  if (parsed.error) return res.status(400).json({ error: parsed.error });

  const listing = await Listing.findOne({ _id: req.params.id, owner: req.user.id });
  if (!listing) return res.status(404).json({ error: 'Listing not found.' });

  const existing = parseExistingImages(req.body.existingImages);
  if (existing == null) {
    return res.status(400).json({ error: 'existingImages must be a JSON string array.' });
  }

  const normalizedExisting = existing.map((url) => url.trim());
  const retainedImages = listing.images.filter((image) =>
    normalizedExisting.includes(image.url),
  );
  if (retainedImages.length + (req.files?.length ?? 0) > 8) {
    return res.status(400).json({ error: 'A listing can have at most 8 images.' });
  }
  const removed = listing.images.filter(
    (image) => !normalizedExisting.includes(image.url),
  );
  const cloudinary =
    req.files?.length || removed.length ? configureCloudinary() : null;
  const uploaded = [];
  let listingSaved = false;
  try {
    for (const file of req.files ?? []) {
      const result = await uploadImage(cloudinary, file);
      uploaded.push({ url: result.secure_url, publicId: result.public_id });
    }
    Object.assign(listing, parsed.data);
    listing.images = [...retainedImages, ...uploaded];
    await listing.save();
    listingSaved = true;
    await listing.populate('owner', 'name');
    if (removed.length > 0) {
      await Promise.all(
        removed.map((image) => cloudinary.uploader.destroy(image.publicId)),
      );
    }
    return res.json({ listing: serializeListing(listing) });
  } catch (error) {
    if (cloudinary && !listingSaved) {
      await Promise.all(
        uploaded.map((image) => cloudinary.uploader.destroy(image.publicId)),
      );
    }
    throw error;
  }
});

router.delete('/:id', requireAuth, async (req, res) => {
  const listing = await Listing.findOne({
    _id: req.params.id,
    owner: req.user.id,
  });
  if (!listing) return res.status(404).json({ error: 'Listing not found.' });

  if (listing.images.length > 0) {
    const cloudinary = configureCloudinary();
    await Promise.all(
      listing.images.map((image) => cloudinary.uploader.destroy(image.publicId)),
    );
  }
  await listing.deleteOne();
  return res.status(204).end();
});

export default router;
