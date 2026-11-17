import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { Notification } from '../models/Notification.js';

const router = Router();
router.use(requireAuth);

router.get('/', async (req, res) => {
  const notifications = await Notification.find({ recipient: req.user.id })
    .sort({ createdAt: -1 })
    .limit(100)
    .populate('actor', 'name')
    .lean();
  return res.json({
    notifications: notifications.map((notification) => ({
      id: notification._id.toString(),
      actorId: notification.actor?._id.toString() ?? null,
      actorName: notification.actor?.name ?? 'PlotPost',
      type: notification.type,
      message: notification.message,
      listingId: notification.listing?.toString() ?? null,
      conversationId: notification.conversation?.toString() ?? null,
      isRead: notification.readAt != null,
      createdAt: notification.createdAt,
    })),
  });
});

router.patch('/:id/read', async (req, res) => {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, recipient: req.user.id },
    { $set: { readAt: new Date() } },
    { new: true },
  ).lean();
  if (!notification) {
    return res.status(404).json({ error: 'Notification not found.' });
  }
  return res.json({ id: notification._id.toString(), isRead: true });
});

router.patch('/read-all', async (req, res) => {
  await Notification.updateMany(
    { recipient: req.user.id, readAt: null },
    { $set: { readAt: new Date() } },
  );
  return res.json({ message: 'Notifications marked as read.' });
});

export default router;
