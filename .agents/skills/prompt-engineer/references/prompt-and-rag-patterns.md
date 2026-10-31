# Prompt Patterns, RAG Grounding & Evaluation Rubrics

## 1. Citation-Grounded RAG Prompt
```text
Answer the question using ONLY the provided <context>.
- Cite facts using [Source ID] immediately after each claim.
- If the <context> lacks the answer, return refusal_reason="INSUFFICIENT_CONTEXT".
<context>{retrieved_chunks}</context>
<question>{user_question}</question>
```

## 2. Prompt Optimization Checklist
1. **Measurable Criterion**: Define pass/fail rubric on >= 10 representative examples before tuning wording.
2. **Constraint Positivity**: State exact required output structure rather than open-ended prose.
3. **Token Parsimony**: Prune redundant persona prose; keep few-shot examples diverse and minimal (2–3 shots).
