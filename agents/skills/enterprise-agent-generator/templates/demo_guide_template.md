# Customer Engineering Demo Guide: {{AGENT_DISPLAY_NAME}}

## 1. Executive Summary & Value Narrative
- **Customer / Domain**: {{CUSTOMER_NAME}} ({{CUSTOMER_DOMAIN}})
- **Primary Business Challenge**: {{BUSINESS_CHALLENGE_SUMMARY}}
- **Solution Overview**: An autonomous AI agent built on Google Agent Development Kit (ADK), deployed on Vertex AI Agent Engine, and published to Gemini Enterprise.
- **Key Outcomes**:
  - Reduction in manual review & research time from hours to seconds.
  - 100% audit compliance and citation integrity.
  - Accelerated project initiation and scoping milestones.

---

## 2. User Persona & Demo Setup
- **Demonstrator Role**: Senior Project Engineer / Operations Specialist
- **Persona Name**: {{AGENT_PERSONA_NAME}}
- **Access Point**: Gemini Enterprise App (`@{{AGENT_NAME}}` in chat interface)

---

## 3. The 3-Tier Demo Prompt Playbook

### Tier 1: Executive & Strategic Alignment
* **Goal**: Demonstrate macro understanding of legislative mandates, program funding, and organizational goals.
* **Prompt**:
  > *"{{PROMPT_TIER_1}}"*
* **Expected Agent Behavior**:
  - High-level executive synthesis.
  - Cites governing mandates, funding programs, and strategic targets.

### Tier 2: Operational & Technical Deep-Dive
* **Goal**: Demonstrate rigorous technical capability, tool invocation, and deterministic standards evaluation.
* **Prompt**:
  > *"{{PROMPT_TIER_2}}"*
* **Expected Agent Behavior**:
  - Automatically invokes validation tools and manual search.
  - Evaluates parameters against mandatory/advisory criteria.
  - Provides structured comparison table and explicit citations.

### Tier 3: Edge Case, Exception & Governance Workflow
* **Goal**: Demonstrate governance, strict boundaries, and non-hallucination on complex edge cases.
* **Prompt**:
  > *"{{PROMPT_TIER_3}}"*
* **Expected Agent Behavior**:
  - Flags non-standard proposal or missing documentation.
  - Outlines exact required exception fact sheet, safety analysis, and required approval hierarchy.

---

## 4. CE Technical Talking Points & Architecture Highlights
1. **Google ADK & Vertex AI Agent Engine**: Scalable serverless agent runtime with built-in OpenTelemetry tracing.
2. **Deterministic Tool Grounding**: Hybrid architecture combining LLM semantic reasoning with strict programmatic rule evaluation.
3. **Gemini Enterprise Fleet Integration**: Direct zero-code publishing to Gemini Enterprise chat assistant.
