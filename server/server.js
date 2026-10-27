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

const FLW_SECRET_KEY = process.env.FLW_SECRET_KEY;
const SUPABASE_URL = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const creditPacks = {
  starter: { amount: 1500, credits: 100 },
  creator: { amount: 5000, credits: 400 },
  studio: { amount: 10000, credits: 900 },
};

async function authenticateSupabase(req) {
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!token || !SUPABASE_URL || !process.env.SUPABASE_PUBLISHABLE_KEY) return null;
  const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: process.env.SUPABASE_PUBLISHABLE_KEY, Authorization: `Bearer ${token}` },
  });
  if (!response.ok) return null;
  const user = await response.json().catch(() => null);
  return user?.id && user?.email ? user : null;
}

async function supabaseRpc(name, body) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) throw new Error('Supabase server credentials are not configured.');
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
    method: 'POST',
    headers: { apikey: SUPABASE_SERVICE_ROLE_KEY, Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(payload.message || payload.details || 'Supabase wallet update failed.');
  return payload;
}

app.post('/api/payments/checkout', async (req, res) => {
  try {
    if (!FLW_SECRET_KEY) return res.status(503).json({ error: 'Flutterwave is not configured on the server.' });
    if (!process.env.PUBLIC_API_URL) return res.status(503).json({ error: 'PUBLIC_API_URL must be set to the deployed API origin.' });
    const user = await authenticateSupabase(req);
    if (!user) return res.status(401).json({ error: 'Sign in to purchase credits.' });
    const pack = creditPacks[req.body?.pack];
    if (!pack) return res.status(400).json({ error: 'Choose a valid credit pack.' });
    const txRef = `mvx_${user.id.replace(/-/g, '').slice(0, 12)}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const response = await fetch('https://api.flutterwave.com/v3/payments', {
      method: 'POST',
      headers: { Authorization: `Bearer ${FLW_SECRET_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tx_ref: txRef, amount: pack.amount, currency: 'NGN',
        redirect_url: `${process.env.PUBLIC_API_URL || ''}/api/payments/callback`,
        customer: { email: user.email, name: user.user_metadata?.full_name || user.email },
        meta: { user_id: user.id, credits: pack.credits, pack: req.body.pack },
        customizations: { title: 'Multivexa AI', description: `${pack.credits} AI creation credits`, logo: '' },
      }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || payload.status !== 'success' || !payload.data?.link) {
      return res.status(502).json({ error: payload.message || 'Could not start Flutterwave checkout.' });
    }
    res.json({ checkoutUrl: payload.data.link, txRef, amount: pack.amount, credits: pack.credits });
  } catch (error) {
    res.status(500).json({ error: error?.message || 'Could not create payment.' });
  }
});

app.get('/api/payments/callback', (_req, res) => res.type('html').send('<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>Multivexa payment</title></head><body style="font-family:system-ui;max-width:560px;margin:15vh auto;padding:24px"><h2>Payment page returned</h2><p>Return to Multivexa AI and tap <b>Verify payment</b>. Credits are only added after the server verifies the transaction.</p></body></html>'));

app.post('/api/payments/verify', async (req, res) => {
  try {
    if (!FLW_SECRET_KEY) return res.status(503).json({ error: 'Flutterwave is not configured on the server.' });
    const user = await authenticateSupabase(req);
    if (!user) return res.status(401).json({ error: 'Sign in to verify payment.' });
    const txRef = typeof req.body?.txRef === 'string' ? req.body.txRef : '';
    if (!txRef.startsWith(`mvx_${user.id.replace(/-/g, '').slice(0, 12)}_`)) return res.status(400).json({ error: 'Invalid payment reference.' });
    const lookup = await fetch(`https://api.flutterwave.com/v3/transactions?tx_ref=${encodeURIComponent(txRef)}`, {
      headers: { Authorization: `Bearer ${FLW_SECRET_KEY}` },
    });
    const found = await lookup.json().catch(() => ({}));
    const transaction = Array.isArray(found.data) ? found.data.find((item) => item.tx_ref === txRef) : found.data;
    if (!lookup.ok || found.status !== 'success' || !transaction) return res.status(404).json({ error: 'Payment has not been found yet. Complete checkout and try again.' });
    const verified = await fetch(`https://api.flutterwave.com/v3/transactions/${transaction.id}/verify`, {
      headers: { Authorization: `Bearer ${FLW_SECRET_KEY}` },
    });
    const result = await verified.json().catch(() => ({}));
    const payment = result.data;
    if (!verified.ok || result.status !== 'success' || payment?.status !== 'successful' || payment?.tx_ref !== txRef || payment?.currency !== 'NGN') {
      return res.status(402).json({ error: 'Payment is not verified as successful.' });
    }
    const pack = creditPacks[payment.meta?.pack];
    if (!pack || Number(payment.amount) < pack.amount || String(payment.customer?.email || '').toLowerCase() !== user.email.toLowerCase()) {
      return res.status(402).json({ error: 'Payment amount or customer details do not match the credit pack.' });
    }
    const wallet = await supabaseRpc('credit_multivexa_wallet', {
      p_user_id: user.id, p_tx_ref: txRef, p_transaction_id: String(payment.id),
      p_amount_ngn: pack.amount, p_credits: pack.credits,
    });
    res.json({ status: wallet?.credited ? 'success' : 'already_processed', credits: wallet?.credited ? pack.credits : 0, balance: wallet?.credits ?? null, amount: pack.amount, txRef });
  } catch (error) {
    res.status(500).json({ error: error?.message || 'Could not verify payment.' });
  }
});

app.get('/api/wallet/balance', async (req, res) => {
  try {
    const user = await authenticateSupabase(req);
    if (!user) return res.status(401).json({ error: 'Sign in to view your wallet.' });
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return res.status(503).json({ error: 'Supabase wallet server credentials are not configured.' });
    const url = new URL(`${SUPABASE_URL}/rest/v1/wallet_balances`);
    url.searchParams.set('select', 'credits');
    url.searchParams.set('user_id', `eq.${user.id}`);
    const response = await fetch(url, { headers: { apikey: SUPABASE_SERVICE_ROLE_KEY, Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` } });
    const rows = await response.json().catch(() => []);
    if (!response.ok) return res.status(502).json({ error: 'Could not load wallet balance.' });
    res.json({ credits: Array.isArray(rows) && rows.length ? Number(rows[0].credits) : 0 });
  } catch (error) {
    res.status(500).json({ error: error?.message || 'Could not load wallet.' });
  }
});

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
