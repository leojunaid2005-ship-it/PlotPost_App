import { randomBytes, createHash } from 'node:crypto';
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import { z } from 'zod';
import { User } from '../models/User.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();
const credentialsSchema = z.object({
  email: z.string().email().max(254),
  password: z.string().min(8).max(128),
});

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
  };
}

function issueToken(user) {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be configured with at least 32 characters.');
  }
  const token = jwt.sign({}, process.env.JWT_SECRET, {
    subject: user.id,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
  return { token, user: publicUser(user) };
}

router.post('/register', async (req, res) => {
  const parsed = z
    .object({
      name: z.string().trim().min(1).max(100),
      email: z.string().email().max(254),
      password: z.string().min(8).max(128),
      phone: z.string().trim().max(30).optional().default(''),
    })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.issues[0].message });
  }

  const email = parsed.data.email.toLowerCase();
  if (await User.exists({ email })) {
    return res.status(409).json({ error: 'An account with this email already exists.' });
  }
  const passwordHash = await bcrypt.hash(parsed.data.password, 12);
  const user = await User.create({ ...parsed.data, email, passwordHash });
  return res.status(201).json(issueToken(user));
});

router.post('/login', async (req, res) => {
  const parsed = credentialsSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.issues[0].message });
  }

  const user = await User.findOne({ email: parsed.data.email.toLowerCase() }).select(
    '+passwordHash',
  );
  if (!user || !(await bcrypt.compare(parsed.data.password, user.passwordHash))) {
    return res.status(401).json({ error: 'Email or password is incorrect.' });
  }
  return res.json(issueToken(user));
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ user: publicUser(req.user) });
});

router.post('/forgot-password', async (req, res) => {
  const parsed = z.object({ email: z.string().email().max(254) }).safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.issues[0].message });
  }
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASSWORD) {
    return res.status(503).json({ error: 'Password reset email is not configured.' });
  }

  const user = await User.findOne({ email: parsed.data.email.toLowerCase() });
  const response = {
    message: 'If that email is registered, a password reset link will be sent.',
  };
  if (!user) return res.json(response);

  const resetToken = randomBytes(32).toString('hex');
  user.resetTokenHash = createHash('sha256').update(resetToken).digest('hex');
  user.resetTokenExpiresAt = new Date(Date.now() + 30 * 60 * 1000);
  await user.save();

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD },
  });
  const resetUrl = new URL(process.env.APP_RESET_URL || 'plotpost://reset-password');
  resetUrl.searchParams.set('token', resetToken);
  await transporter.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to: user.email,
    subject: 'Reset your PlotPost password',
    text: `Use this link within 30 minutes to reset your password: ${resetUrl}`,
  });
  return res.json(response);
});

router.post('/reset-password', async (req, res) => {
  const parsed = z
    .object({
      token: z.string().min(32).max(256),
      password: z.string().min(8).max(128),
    })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.issues[0].message });
  }

  const tokenHash = createHash('sha256').update(parsed.data.token).digest('hex');
  const user = await User.findOne({
    resetTokenHash: tokenHash,
    resetTokenExpiresAt: { $gt: new Date() },
  }).select('+resetTokenHash +resetTokenExpiresAt');
  if (!user) {
    return res.status(400).json({ error: 'Reset link is invalid or expired.' });
  }

  user.passwordHash = await bcrypt.hash(parsed.data.password, 12);
  user.resetTokenHash = undefined;
  user.resetTokenExpiresAt = undefined;
  await user.save();
  return res.json({ message: 'Password updated. You can now sign in.' });
});

export default router;
