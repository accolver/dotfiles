---
name: enterprise-agent-generator
description: End-to-end framework to research any customer domain, author grounded ADK agent specifications, implement custom tools and universal reasoning engine adapters, compile and deploy to Vertex AI Agent Engine (Reasoning Engine), publish directly to Gemini Enterprise App, and generate comprehensive Customer Engineering demo playbooks. Use whenever the user asks to build, scaffold, deploy, or demo an ADK agent for any enterprise customer or industry.
metadata:
  author: Google Cloud Customer Engineering
  version: 1.0.0
---

# Enterprise Agent Generator (Google ADK & Gemini Enterprise)

A complete, customer-agnostic methodology and toolset to take any enterprise customer domain or problem statement from initial research through specification, implementation, Vertex AI Agent Engine deployment, Gemini Enterprise fleet publishing, and live demo delivery.

---

## 🎯 Workflow Overview

```
Phase 1: Customer Domain & Priority Discovery (Interactive Research)
   ↓
Phase 2: Use Case Formulation & Persona Synthesis (use-case.md)
   ↓
Phase 3: ADK Specification Authoring & Reference Data Staging (spec.md)
   ↓
Phase 4: Agent Implementation, Custom Tools & Universal Adapter
   ↓
Phase 5: Agent Runtime Compilation & Deployment (agents-cli)
   ↓
Phase 6: Multi-Contract Automated Verification (streamQuery, GE, A2A)
   ↓
Phase 7: Gemini Enterprise Fleet Publishing & Registration
   ↓
Phase 8: Customer Engineering Demo Guide & Presentation Deliverables
```

---

## 📋 Phase 1: Customer Domain & Priority Discovery

When invoked without explicit customer parameters, the skill prompts the user:
1. **Target Customer / Organization**: Name and official domain (e.g., `acme-logistics.com`, `state-agency.gov`).
2. **Industry / Vertical**: (e.g., Transportation, Financial Services, Retail, Healthcare, Public Sector).
3. **High-Level Objective / Pain Point**: Specific operational friction, policy compliance burden, or digital transformation goal.
4. **Target GCP Project & Gemini Enterprise App**: Target GCP Project ID and Discovery Engine Engine ID.

### Grounded Web Research Protocol
If an enterprise domain or organization name is supplied:
- Execute `search_web` to discover:
  - **Strategic Mandates & Funding Programs**: Legislative acts, executive priorities, annual budget reports, and public grants.
  - **3–5 High-Friction Operational Workflows**: Manual review pipelines, complex engineering manual consultations, or compliance bottlenecks.
  - **Authentic Domain Terminology**: Real regulatory codes, manual names, chapter numbers, and industry nomenclature.
- Present research findings back to the user to confirm the highest-value automation target.

---

## 📄 Phase 2: Use Case Formulation (`use-case.md`)

Generate a structured `use-case.md` document covering:
1. **Executive Context & Legislative/Business Mandate**: Why this project matters now, its funding sources, and executive sponsors.
2. **User Persona**:
   - **Name & Title**: Realistic operational role (e.g., Senior Project Engineer, Lead Underwriter).
   - **Daily Responsibilities & Pain Points**: Time spent cross-referencing PDFs, risk of non-compliance, manual exception preparation.
   - **Success Metrics**: Time saved per review, audit accuracy, cycle time reduction.
3. **Agent Persona**: Name, role, domain specialization, and behavioral tone.
4. **Architectural Boundary**: Scope of authority, escalation thresholds, and non-hallucination boundaries.

---

## 📐 Phase 3: ADK Specification (`spec.md`) & Reference Data

Author a comprehensive `spec.md` following Google ADK standards:

### Grounding & Limitation Rules
- **Strict Grounding**: Every answer must be strictly derived from verified reference documents or deterministic tools.
- **Mandatory vs. Advisory Standards**: Clearly categorize rules into hard constraints (requiring executive approval/exception sheets) vs. advisory guidance.
- **Section-Level Citations**: Require explicit citations (e.g., `[Manual Topic X.Y, Section Z]`).
- **Graceful Escalation**: If policy is missing or ambiguous, direct the user to the appropriate governing department without guessing.

### Reference Data Staging
- Place domain knowledge files (manuals, policy markdown, standard tables) in `app/data/` or `data/` for search retrieval.

---

## 💻 Phase 4: Agent Implementation & Universal Adapter

### 1. Root Agent & Tool Architecture (`app/agent.py`)
```python
from google.adk.agents import Agent
from app.tools.search_tools import search_domain_manuals
from app.tools.validation_tools import check_domain_standards

root_agent = Agent(
    name="enterprise_expert_agent",
    model="gemini-2.5-pro",  # or gemini-2.5-flash
    description="Domain specialist providing grounded technical and compliance guidance.",
    instruction="""You are an expert enterprise domain advisor...
Always ground your answers in official manuals and cite specific sections.
When proposed parameters deviate from mandatory standards, explicitly flag non-compliance and outline required exception procedures.""",
    tools=[search_domain_manuals, check_domain_standards],
)
```

### 2. Universal Reasoning Engine Adapter (`app/app_utils/reasoning_engine_adapter.py`)
> [!IMPORTANT]
> To ensure multi-platform compatibility across **Gemini Enterprise (AgentSpace)**, **Vertex AI Console Playground**, and **A2A**, the HTTP adapter must handle both standard `async_stream_query` and the internal `streaming_agent_run_with_events` contract.

Key requirements:
1. **Dynamic Method Dispatch**:
   - For Gemini Enterprise: Detects `streaming_agent_run_with_events` and passes `request_json: str` without injecting unexpected kwargs (such as `user_id`).
   - For Vertex AI / Playground: Dispatches to `async_stream_query` / `stream_query` and safely defaults `user_id="default_user"` if omitted.
2. **Flexible Route Mounting**: Mount on both `/api/stream_reasoning_engine`, `/stream_reasoning_engine`, `/api/reasoning_engine`, and `/reasoning_engine`.

*(See `templates/reasoning_engine_adapter.py` for the complete implementation).*

### 3. Unit Testing
Run tests before deploying:
```bash
uv run pytest tests/unit
```

---

## 🚀 Phase 5: Agent Runtime Deployment (`agents-cli`)

Deploy the agent to **Vertex AI Agent Engine (Reasoning Engine)**:

### Prerequisites & Location Setup
```bash
# Verify CLI installation
uv tool install google-agents-cli

# Set Gemini API location to global
export GOOGLE_CLOUD_LOCATION=global
```

### Deployment Command
```bash
agents-cli deploy \
  --update-env-vars GOOGLE_CLOUD_LOCATION=global \
  --no-confirm-project
```

### Credential Handling Pattern
If deploying in automated pipelines or when Application Default Credentials (ADC) require refresh:
```python
import subprocess, sys, google.auth, google.oauth2.credentials
from google.agents.cli.main import main

token = subprocess.check_output(['gcloud', 'auth', 'print-access-token']).decode().strip()
creds = google.oauth2.credentials.Credentials(token)
google.auth.default = lambda *args, **kwargs: (creds, subprocess.check_output(['gcloud', 'config', 'get-value', 'project']).decode().strip())

sys.argv = ['agents-cli', 'deploy', '--update-env-vars', 'GOOGLE_CLOUD_LOCATION=global', '--no-confirm-project']
main()
```

---

## 🧪 Phase 6: Automated Verification

Run automated test queries to verify all communication paths:

### 1. Vertex AI / Direct Stream Test
```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"input": {"message": "Test verification query", "user_id": "test_user"}}' \
  https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/reasoningEngines/${REASONING_ENGINE_ID}:streamQuery
```

### 2. Gemini Enterprise (AgentSpace) Contract Test
```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"class_method": "streaming_agent_run_with_events", "input": {"request_json": "{\"message\": {\"role\": \"user\", \"parts\": [{\"text\": \"Test GE query\"}]}, \"user_id\": \"ge_user\"}"}}' \
  https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/reasoningEngines/${REASONING_ENGINE_ID}:streamQuery
```

---

## 🌐 Phase 7: Gemini Enterprise Fleet Publishing

Publish the Reasoning Engine endpoint to your Gemini Enterprise App:

```bash
agents-cli publish gemini-enterprise \
  --engine-id ${GEMINI_ENTERPRISE_ENGINE_ID} \
  --location ${DISCOVERY_ENGINE_LOCATION:-us}
```

Verify status in Google Cloud Console:
- Navigation: **Vertex AI** > **Agent Builder** > **Gemini Enterprise** > **Assistants** > **Agents**
- Confirm agent status is `ENABLED`.

---

## 🏆 Phase 8: CE Demo Kit & Presentation Assets

Generate `ce_demo_guide.md` containing:
1. **Executive Pitch & ROI Narrative**: The 2-minute elevator pitch for customer stakeholders.
2. **The 3-Tier Demo Prompt Playbook**:
   - **Tier 1 (Executive & Strategic)**: High-level policy, budget alignment, and strategic impact.
   - **Tier 2 (Operational Deep-Dive)**: Complex technical review triggering custom tools and grounded comparison tables.
   - **Tier 3 (Edge Case & Compliance)**: Proposing non-compliant parameters to demonstrate strict guardrails and exception sheet requirements.
3. **Multi-Format Export**: Provide Markdown, HTML slide deck format, and quick cheat sheets for Customer Engineers.

---

## 🛠️ Common Pitfalls & Troubleshooting

| Symptom | Root Cause | Solution |
| :--- | :--- | :--- |
| `404 Not Found: Publisher Model` | `GOOGLE_CLOUD_LOCATION` set to regional instead of `global` | Set `GOOGLE_CLOUD_LOCATION=global` in deployment env vars. |
| `400 FAILED_PRECONDITION: KeyError: 'class_method'` | Adapter assumed `class_method` is always passed | Default to `async_stream_query` when `class_method` is missing. |
| `400 Stream closed cleanly without producing any events` | Injected `user_id` into `streaming_agent_run_with_events` kwargs | Pass `request_json` directly without injecting `user_id` to AgentSpace methods. |
| `ADC RefreshError` | Local application-default token expired | Run `gcloud auth application-default login` or inject active `gcloud auth print-access-token`. |
