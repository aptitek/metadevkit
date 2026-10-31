---
name: langchain-expert
description: "Build LangChain LCEL, LangGraph StateGraph, Gemini, and FastMCP pipelines with SecretStr hygiene and mocked tests."
---

# LangChain, LangGraph & MCP Orchestration (`fw:langchain`)

## 1. Hard AI Orchestration Gates (`validate-langchain.sh` + `langchain.yml`)
| Gate | Forbidden Legacy / Unsafe Pattern | Required Modern Pattern |
| :--- | :--- | :--- |
| **Chain / Agent API** | `LLMChain`, `SequentialChain`, `ConversationChain`, `initialize_agent` | LCEL pipe (`prompt \| llm`) or LangGraph `StateGraph(State)` (`START`, `END`, `add_messages`) |
| **Structured Output vs Tools** | Binding MCP/tools and `.with_structured_output()` on the same single LLM node call | Separate `ToolNode` execution nodes from the final `.with_structured_output(Schema)` synthesis node |
| **API Key Security** | Hardcoded `api_key="..."` or `google_api_key="..."` literals | `settings.gemini_api_key.get_secret_value()` via `pydantic-settings` `SecretStr` |
| **MCP Servers (`mcp`)** | Untyped tool args or tearing down MCP sessions per node | `FastMCP` with Pydantic return schemas + persistent `async with` session lifecycle |
| **Test Isolation** | Live network calls to Gemini, OpenAI, Google TTS, or MCP in `tests/` | 100% mocked runnables (`FakeListChatModel` / `AsyncMock` / `monkeypatch`) |

## 2. Canonical LCEL + Structured Output Pattern
```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from pydantic import BaseModel, Field
from my_app.config import get_settings


class DialogueTurn(BaseModel):
    speaker: str = Field(description="Voice actor ID")
    ssml: str = Field(description="Valid SSML speech payload")


def build_dialogue_chain() -> object:
    cfg = get_settings()
    llm = ChatGoogleGenerativeAI(
        model="gemini-2.5-pro",
        google_api_key=cfg.gemini_api_key.get_secret_value(),
        temperature=0.3,
    )
    prompt = ChatPromptTemplate.from_messages([("system", "Return valid SSML."), ("human", "{topic}")])
    return prompt | llm.with_structured_output(DialogueTurn).with_retry(stop_after_attempt=3)
```

## 3. Deep References (Load On-Demand Only)
- LangGraph `StateGraph` + `FastMCP` server/adapter + `interrupt()` checkpointer + mocked `pytest` patterns: [references/langgraph-and-mcp.md](./references/langgraph-and-mcp.md)
