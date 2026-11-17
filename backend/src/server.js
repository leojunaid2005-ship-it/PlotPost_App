import 'dotenv/config';
import { createApp } from './app.js';
import { connectDatabase } from './config/database.js';

const port = Number(process.env.PORT || 3000);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error('PORT must be a valid TCP port.');
}

await connectDatabase();
const app = createApp();
app.listen(port, () => {
  console.info(`PlotPost API listening on port ${port}.`);
});
