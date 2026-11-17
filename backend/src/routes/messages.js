import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { Conversation } from '../models/Conversation.js';
import { Listing } from '../models/Listing.js';
import { Message } from '../models/Message.js';
import { Notification } from '../models/Notification.js';
import { User } from '../models/User.js';

const router = Router();
router.use(requireAuth);

router.get('/users', async (req, res) => {
  const query = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  if (query.length < 2) return res.json({ users: [] });
  const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const users = await User.find({
    _id: { $ne: req.user.id },
    $or: [
      { name: { $regex: escaped, $options: 'i' } },
      { email: { $regex: escaped, $options: 'i' } },
    ],
  })
    .select('name')
    .sort({ name: 1 })
    .limit(20)
    .lean();
  return res.json({
    users: users.map((user) => ({ id: user._id.toString(), name: user.name })),
  });
});

router.get('/conversations', async (req, res) => {
  const conversations = await Conversation.find({ participants: req.user.id })
    .sort({ lastMessageAt: -1 })
    .populate('participants', 'name')
    .populate('listing', 'title price images')
    .lean();
  return res.json({
    conversations: conversations.map((conversation) => {
      const other = conversation.participants.find(
        (participant) => participant._id.toString() !== req.user.id,
      );
      return {
        id: conversation._id.toString(),
        userId: other?._id.toString() ?? '',
        userName: other?.name ?? 'PlotPost user',
        lastMessage: conversation.lastMessage,
        lastMessageAt: conversation.lastMessageAt,
        listing: conversation.listing
          ? {
              id: conversation.listing._id.toString(),
              title: conversation.listing.title,
              price: conversation.listing.price,
            }
          : null,
      };
    }),
  });
});

router.post('/conversations', async (req, res) => {
  const parsed = z
    .object({
      recipientId: z.string().min(1),
      listingId: z.string().optional(),
    })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.issues[0].message });
  }
  if (parsed.data.recipientId === req.user.id) {
    return res.status(400).json({ error: 'You cannot message yourself.' });
  }
  const recipient = await User.findById(parsed.data.recipientId).select('_id');
  if (!recipient) return res.status(404).json({ error: 'Recipient not found.' });
  if (parsed.data.listingId) {
    const listing = await Listing.findById(parsed.data.listingId).select('_id');
    if (!listing) return res.status(404).json({ error: 'Listing not found.' });
  }

  const participantIds = [req.user.id, recipient.id].sort();
  const filter = {
    participants: { $all: participantIds, $size: 2 },
    listing: parsed.data.listingId ?? null,
  };
  let conversation = await Conversation.findOne(filter);
  if (!conversation) {
    conversation = await Conversation.create({
      participants: participantIds,
      listing: parsed.data.listingId ?? null,
    });
  }
  return res.status(200).json({ conversation: { id: conversation.id } });
});

router.get('/conversations/:id/messages', async (req, res) => {
  const conversation = await Conversation.findOne({
    _id: req.params.id,
    participants: req.user.id,
  }).select('_id');
  if (!conversation) {
    return res.status(404).json({ error: 'Conversation not found.' });
  }

  const messages = await Message.find({ conversation: conversation.id })
    .sort({ createdAt: 1 })
    .limit(200)
    .populate('sender', 'name')
    .lean();
  await Message.updateMany(
    { conversation: conversation.id, sender: { $ne: req.user.id }, readAt: null },
    { $set: { readAt: new Date() } },
  );
  return res.json({
    messages: messages.map((message) => ({
      id: message._id.toString(),
      senderId: message.sender._id.toString(),
      senderName: message.sender.name,
      text: message.text,
      createdAt: message.createdAt,
    })),
  });
});

router.post('/conversations/:id/messages', async (req, res) => {
  const parsed = z.object({ text: z.string().trim().min(1).max(2000) }).safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.issues[0].message });
  }
  const conversation = await Conversation.findOne({
    _id: req.params.id,
    participants: req.user.id,
  });
  if (!conversation) {
    return res.status(404).json({ error: 'Conversation not found.' });
  }

  const message = await Message.create({
    conversation: conversation.id,
    sender: req.user.id,
    text: parsed.data.text,
  });
  conversation.lastMessage = message.text;
  conversation.lastMessageAt = message.createdAt;
  await conversation.save();

  const recipientId = conversation.participants.find(
    (participant) => participant.toString() !== req.user.id,
  );
  await Notification.create({
    recipient: recipientId,
    actor: req.user.id,
    type: 'message_received',
    message: `${req.user.name} sent you a message.`,
    conversation: conversation.id,
  });
  return res.status(201).json({
    message: {
      id: message.id,
      senderId: req.user.id,
      senderName: req.user.name,
      text: message.text,
      createdAt: message.createdAt,
    },
  });
});

export default router;
