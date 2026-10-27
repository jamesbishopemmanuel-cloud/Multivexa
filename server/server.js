import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const PORT = Number(process.env.PORT || 8080);
const KIE_API_KEY = process.env.KIE_API_KEY;
const KIE_BASE_URL = (process.env.KIE_BASE_URL || 'https://api.kie.ai/api/v1').replace(/\/$/, '');

const defaultModels = {
  image: 'gpt-image-2-text-to-image',
  video: 'kling-2.6/text-to-video',
  music: 'ai-music-api/generate',
};
const allowedModels = {
  image: new Set([
    'gpt-image-2-text-to-image', 'gpt-image-2-image-to-image', 'gpt-image-2-5-flare-text-to-image',
    'nano-banana-2', 'nano-banana-2-1', ...(process.env.KIE_IMAGE_MODEL ? [process.env.KIE_IMAGE_MODEL] : []),
  ]),
  video: new Set([
    'kling-3.0/video', 'bytedance/seedance-2-5', 'runway', 'kling-2.6/text-to-video',
    ...(process.env.KIE_VIDEO_MODEL ? [process.env.KIE_VIDEO_MODEL] : []),
  ]),
  music: new Set(['ai-music-api/generate', ...(process.env.KIE_MUSIC_MODEL ? [process.env.KIE_MUSIC_MODEL] : [])]),
};
const models = {
  image: process.env.KIE_IMAGE_MODEL || defaultModels.image,
  video: process.env.KIE_VIDEO_MODEL || defaultModels.video,
  music: process.env.KIE_MUSIC_MODEL || defaultModels.music,
};

app.get('/api/options', (_req, res) => res.json({
  image: [...allowedModels.image], video: [...allowedModels.video], music: [...allowedModels.music],
}));

app.get('/health', (_req, res) => res.json({ ok: true, service: 'Multivexa KIE gateway' }));

app.post('/api/generate', async (req, res) => {
  try {
    if (!KIE_API_KEY) return res.status(503).json({ error: 'KIE_API_KEY is not configured on the server.' });
    const { type, prompt, input = {} } = req.body || {};
    if (!['image', 'video', 'music'].includes(type)) return res.status(400).json({ error: 'type must be image, video, or music.' });
    if (typeof prompt !== 'string' || !prompt.trim()) return res.status(400).json({ error: 'A non-empty prompt is required.' });

    const requestedModel = typeof req.body?.model === 'string' ? req.body.model : models[type];
    if (!allowedModels[type].has(requestedModel)) {
      return res.status(400).json({ error: `Unsupported ${type} model. Choose a model listed by /api/options.` });
    }
    const model = requestedModel;
    const taskInput = { ...input, prompt: prompt.trim() };
    const response = await fetch(`${KIE_BASE_URL}/jobs/createTask`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${KIE_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model, input: taskInput }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) return res.status(response.status).json({ error: payload.msg || payload.message || 'KIE task creation failed', details: payload });
    const taskId = payload.data?.taskId || payload.taskId || payload.data?.task_id;
    if (!taskId) return res.status(502).json({ error: 'KIE did not return a task ID. Check the configured model ID and input schema.', details: payload });
    res.json({ taskId, type, model, status: 'submitted', provider: 'KIE' });
  } catch (error) {
    res.status(500).json({ error: error?.message || 'Unexpected server error' });
  }
});

app.get('/api/tasks/:taskId', async (req, res) => {
  try {
    if (!KIE_API_KEY) return res.status(503).json({ error: 'KIE_API_KEY is not configured on the server.' });
    const response = await fetch(`${KIE_BASE_URL}/jobs/recordInfo?taskId=${encodeURIComponent(req.params.taskId)}`, {
      headers: { Authorization: `Bearer ${KIE_API_KEY}` },
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) return res.status(response.status).json({ error: payload.msg || payload.message || 'KIE task lookup failed', details: payload });
    res.json(payload);
  } catch (error) {
    res.status(500).json({ error: error?.message || 'Unexpected server error' });
  }
});

app.listen(PORT, '0.0.0.0', () => console.log(`Multivexa KIE gateway listening on ${PORT}`));
