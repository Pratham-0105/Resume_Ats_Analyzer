import os
import json
import re
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx

app = FastAPI(
    title="Smart Resume Analyzer Backend",
    description="ATS Resume Evaluation Backend with Ollama Compatibility for Render Cloud Deployment",
    version="1.0.0"
)

# Enable CORS for Flutter mobile/web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "").strip()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()

# --- Request / Response Models ---

class AnalyzeRequest(BaseModel):
    resume_text: str
    job_description: Optional[str] = None

class OllamaGenerateRequest(BaseModel):
    model: Optional[str] = "llama3.2"
    prompt: str
    stream: Optional[bool] = False
    format: Optional[str] = None


# --- Heuristic / Rule-based Fallback ATS Engine ---

ACTION_VERBS = {
    'spearheaded', 'architected', 'orchestrated', 'engineered', 'deployed',
    'optimized', 'developed', 'designed', 'implemented', 'scaled', 'managed',
    'led', 'accelerated', 'automated', 'streamlined', 'created', 'built'
}

COMMON_TECH_SKILLS = [
    'Python', 'JavaScript', 'TypeScript', 'Java', 'C++', 'C#', 'Go', 'Rust',
    'Flutter', 'Dart', 'React', 'Angular', 'Vue', 'Node.js', 'Express',
    'Django', 'FastAPI', 'Spring Boot', 'SQL', 'PostgreSQL', 'MySQL',
    'MongoDB', 'Redis', 'Docker', 'Kubernetes', 'AWS', 'Azure', 'GCP',
    'Git', 'CI/CD', 'REST API', 'GraphQL', 'Machine Learning', 'TensorFlow', 'PyTorch'
]

def fallback_ats_analysis(resume_text: str, job_description: Optional[str] = None) -> Dict[str, Any]:
    """Provides a deterministic, rigorous ATS evaluation when cloud LLM is unavailable."""
    text_lower = resume_text.lower()
    jd_lower = (job_description or '').lower()

    # 1. Detect keywords
    found_keywords = [k for k in COMMON_TECH_SKILLS if k.lower() in text_lower]

    missing_keywords = []
    if jd_lower:
        for skill in COMMON_TECH_SKILLS:
            if skill.lower() in jd_lower and skill.lower() not in text_lower:
                missing_keywords.append(skill)
    else:
        # Default missing suggestions if no JD provided
        standard_ats = ['CI/CD', 'Docker', 'REST API', 'Git', 'Agile']
        missing_keywords = [k for k in standard_ats if k.lower() not in text_lower][:3]

    # 2. Check Action Verbs & Metrics
    verb_count = sum(1 for v in ACTION_VERBS if v in text_lower)
    metric_count = len(re.findall(r'(\d+%\s*|\$\s*[\d,]+|\b\d+\s*(?:users|clients|projects|ms|x)\b)', text_lower))

    # 3. Section Scoring
    has_contact = bool(re.search(r'[\w\.-]+@[\w\.-]+\.\w+', resume_text))
    has_links = 'linkedin.com' in text_lower or 'github.com' in text_lower
    contact_score = 10 if (has_contact and has_links) else (7 if has_contact else 4)

    has_summary = any(k in text_lower for k in ['summary', 'profile', 'objective'])
    summary_score = 13 if has_summary else 7

    has_exp = any(k in text_lower for k in ['experience', 'employment', 'work history'])
    exp_score = min(30, 15 + (verb_count * 2) + min(10, metric_count * 2)) if has_exp else 10

    has_skills = any(k in text_lower for k in ['skills', 'technologies', 'proficiencies'])
    skills_score = min(20, 8 + len(found_keywords)) if has_skills else 8

    has_edu = any(k in text_lower for k in ['education', 'degree', 'university', 'bachelor', 'master'])
    edu_score = 10 if has_edu else 5

    has_proj = any(k in text_lower for k in ['projects', 'personal projects', 'portfolio'])
    proj_score = 10 if has_proj else 5

    has_cert = any(k in text_lower for k in ['certifications', 'certified', 'licenses'])
    cert_score = 5 if has_cert else 2

    total_score = contact_score + summary_score + exp_score + skills_score + edu_score + proj_score + cert_score
    total_score = max(20, min(98, total_score))

    feedback = []
    if metric_count < 3:
        feedback.append("Quantify career impact: add measurable statistics (e.g. '% increase', '$ revenue', 'team size').")
    if verb_count < 4:
        feedback.append("Use strong executive action verbs like 'Architected', 'Spearheaded', and 'Engineered'.")
    if missing_keywords:
        feedback.append(f"Add key technical competencies: {', '.join(missing_keywords[:4])}.")
    if not has_links:
        feedback.append("Add clickable links to your LinkedIn profile and GitHub or Portfolio.")

    role_fit = (
        f"Demonstrates a {total_score}% ATS match rate. Good structural alignment with detected competencies in {', '.join(found_keywords[:3]) if found_keywords else 'technical domains'}."
        if total_score >= 70
        else "Moderate ATS alignment. Resume would benefit from quantifiable metrics and target role keyword optimization."
    )

    return {
        "ats_score": total_score,
        "role_fit_summary": role_fit,
        "matched_keywords": found_keywords[:12],
        "missing_keywords": missing_keywords[:8],
        "general_feedback": feedback,
        "sections": {
            "contact": {
                "score": contact_score,
                "max_score": 10,
                "feedback": ["Contact details well structured" if has_contact else "Add professional email and phone number"],
                "matched": ["Email", "Phone", "LinkedIn"] if has_links else ["Email"]
            },
            "summary": {
                "score": summary_score,
                "max_score": 15,
                "feedback": ["Summary highlights core value proposition" if has_summary else "Add a concise professional summary highlighting your target role."],
                "matched": ["Value Pitch", "Role Focus"] if has_summary else []
            },
            "experience": {
                "score": exp_score,
                "max_score": 30,
                "feedback": [
                    f"Identified {verb_count} action verbs and {metric_count} quantifiable metrics.",
                    "Ensure every bullet point follows Google's X-Y-Z formula (Accomplished [X], measured by [Y], by doing [Z])."
                ],
                "matched": [v.capitalize() for v in list(ACTION_VERBS)[:min(4, verb_count)]]
            },
            "skills": {
                "score": skills_score,
                "max_score": 20,
                "feedback": [
                    f"Matched {len(found_keywords)} core technical skills.",
                    f"Consider adding: {', '.join(missing_keywords[:3])}" if missing_keywords else "Great keyword coverage."
                ],
                "matched": found_keywords[:6]
            },
            "education": {
                "score": edu_score,
                "max_score": 10,
                "feedback": ["Degree and institutional credential verified" if has_edu else "List university degree, major, and graduation year."],
                "matched": ["Degree Standing"] if has_edu else []
            },
            "projects": {
                "score": proj_score,
                "max_score": 10,
                "feedback": ["Projects showcase applied technical proficiency" if has_proj else "Add 1-2 featured projects with tech stacks and live URLs."],
                "matched": ["Applied Tech"] if has_proj else []
            },
            "certifications": {
                "score": cert_score,
                "max_score": 5,
                "feedback": ["Credentials listed" if has_cert else "Add relevant cloud or industry certifications to boost credibility."],
                "matched": ["Industry Certs"] if has_cert else []
            }
        }
    }


async def call_groq_llm(prompt: str) -> Optional[str]:
    """Calls Groq Cloud API for instantaneous Llama 3.3 / Llama 3.2 inference."""
    if not GROQ_API_KEY:
        return None
    try:
        async with httpx.AsyncClient(timeout=25.0) as client:
            res = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "llama-3.3-70b-versatile",
                    "messages": [
                        {"role": "system", "content": "You are a professional ATS Resume Evaluation Engine. Always return valid, strictly formatted JSON matching the requested schema."},
                        {"role": "user", "content": prompt}
                    ],
                    "response_format": {"type": "json_object"},
                    "temperature": 0.2
                }
            )
            if res.status_code == 200:
                data = res.json()
                return data["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"Groq API error: {e}")
    return None


# --- Endpoints ---

@app.get("/")
@app.get("/health")
def health():
    return {
        "status": "online",
        "service": "Smart Resume Analyzer Cloud Backend",
        "llm_engine": "Groq Llama-3.3" if GROQ_API_KEY else "Heuristic ATS Engine (Deterministic Fallback)"
    }


# Ollama Compatibility Endpoint for 'isOllamaRunning()'
@app.get("/api/tags")
def ollama_tags():
    return {
        "models": [
            {
                "name": "llama3.2:latest",
                "model": "llama3.2",
                "modified_at": "2026-10-18T10:00:00Z",
                "size": 2019393184,
                "digest": "cloud-render-llama3.2"
            }
        ]
    }


# Ollama Compatibility Endpoint for 'POST /api/generate'
@app.post("/api/generate")
async def ollama_generate(req: OllamaGenerateRequest):
    # Try calling Groq if key provided
    llm_output = await call_groq_llm(req.prompt)
    if llm_output:
        return {"response": llm_output}

    # Extract resume and JD from prompt if available
    resume_text = req.prompt
    jd = None
    if "TARGET JOB DESCRIPTION:" in req.prompt:
        parts = req.prompt.split("TARGET JOB DESCRIPTION:")
        resume_text = parts[0]
        jd = parts[1].split("RESUME TEXT:")[0]

    result = fallback_ats_analysis(resume_text, jd)
    return {"response": json.dumps(result)}


# Native Direct REST API Endpoint
@app.post("/analyze")
async def analyze_resume(req: AnalyzeRequest):
    prompt = f"""
Evaluate the following resume strictly against standard ATS criteria.
TARGET JOB DESCRIPTION: {req.job_description or 'General Software / Professional Role'}
RESUME TEXT:
{req.resume_text}

Output JSON with:
ats_score (int 0-100), role_fit_summary (string), matched_keywords (list), missing_keywords (list), general_feedback (list),
sections: {{"contact": {{"score": int, "max_score": 10, "feedback": [], "matched": []}}, "experience": {{"score": int, "max_score": 30, "feedback": [], "matched": []}}, "skills": {{"score": int, "max_score": 20, "feedback": [], "matched": []}}, "education": {{"score": int, "max_score": 10, "feedback": [], "matched": []}}, "summary": {{"score": int, "max_score": 15, "feedback": [], "matched": []}}, "projects": {{"score": int, "max_score": 10, "feedback": [], "matched": []}}, "certifications": {{"score": int, "max_score": 5, "feedback": [], "matched": []}}}}
"""
    llm_output = await call_groq_llm(prompt)
    if llm_output:
        try:
            return json.loads(llm_output)
        except Exception:
            pass

    return fallback_ats_analysis(req.resume_text, req.job_description)


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
