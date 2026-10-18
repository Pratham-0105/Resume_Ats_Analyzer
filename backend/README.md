# Smart Resume Analyzer - Cloud Backend (Render Deployment)

This backend enables your **Smart Resume Analyzer** Flutter app to work on any mobile device (Android, iOS, or web) anywhere in the world.

## Features
- **100% Ollama API Compatible**: Implements `/api/tags` and `/api/generate`, allowing your Flutter app to point directly to your Render URL.
- **Dual Engine**:
  1. **Groq Llama 3.3 / 3.2** (Optional): Add your free `GROQ_API_KEY` in Render Environment Variables for real-time cloud LLM evaluation (~1 second inference).
  2. **Deterministic ATS Engine**: Built-in intelligent rule-based evaluator that never fails, even without an API key.
- **Render Free Tier Optimized**: Consumes < 50 MB RAM, perfectly within Render's 512 MB free tier.

---

## 🚀 How to Deploy on Render (Free in 2 Minutes)

1. Go to [Render.com](https://dashboard.render.com/) and Sign In with GitHub.
2. Click **New +** → **Web Service**.
3. Select your repository: `smart-resume-analyzer`.
4. Configure:
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: `Free`
5. *(Optional for Cloud AI)* Under **Environment Variables**, add:
   - `GROQ_API_KEY`: *(Get a free key in 30 seconds at [console.groq.com](https://console.groq.com/keys))*
6. Click **Create Web Service**!

Render will build and give you a public URL like:
`https://smart-resume-analyzer-backend.onrender.com`

---

## 📱 Connect Flutter App to Render URL

In your Flutter app:
1. Tap the **Settings** icon (top right of the Upload Screen).
2. Enter your Render URL (e.g. `https://smart-resume-analyzer-backend.onrender.com`).
3. Tap **Test Connection** → **Save**!
Your app will now evaluate resumes from any phone anywhere in the world!
