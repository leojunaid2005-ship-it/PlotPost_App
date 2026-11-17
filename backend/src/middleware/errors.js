export function notFound(req, res) {
  res.status(404).json({ error: 'Route not found.' });
}

export function errorHandler(error, req, res, next) {
  if (res.headersSent) {
    return next(error);
  }
  if (error.name === 'MulterError') {
    return res.status(400).json({ error: error.message });
  }
  if (error.message === 'Only image files can be uploaded.') {
    return res.status(400).json({ error: error.message });
  }
  if (error.name === 'ValidationError') {
    return res.status(400).json({ error: error.message });
  }
  if (error.name === 'CastError') {
    return res.status(400).json({ error: 'Invalid resource identifier.' });
  }
  if (error.code === 11000) {
    return res.status(409).json({ error: 'A record with that value already exists.' });
  }

  console.error(error);
  return res.status(500).json({ error: 'An unexpected server error occurred.' });
}
