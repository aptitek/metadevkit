### `fw:langchain` — LangChain LCEL, LangGraph `StateGraph` & Secret Hygiene
- **Quality Gates**: Enforces modern LCEL (`prompt | llm`) and LangGraph (`StateGraph`), bans deprecated `LLMChain`/`SequentialChain`/`initialize_agent`, requires `SecretStr` API key hygiene, and mandates 100% mocked external LLM/TTS/MCP calls in `tests/`.
