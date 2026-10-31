# LangGraph `StateGraph`, `FastMCP` & Mocked Testing Reference

## 1. Custom `StateGraph` Separating Tool Execution from Structured Synthesis
```python
from typing import Annotated, TypedDict
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from pydantic import BaseModel


class GraphState(TypedDict):
    messages: Annotated[list[object], add_messages]
    report: dict[str, object] | None


class SynthesisReport(BaseModel):
    summary: str
    confidence: float


def build_graph(structured_llm: object) -> object:
    def synthesize_node(state: GraphState) -> dict[str, object]:
        output = structured_llm.invoke(state["messages"])
        return {"report": output.model_dump()}

    graph = StateGraph(GraphState)
    graph.add_node("synthesize", synthesize_node)
    graph.add_edge(START, "synthesize")
    graph.add_edge("synthesize", END)
    return graph.compile()
```

## 2. Typed `FastMCP` Tool Server (`mcp.server.fastmcp`)
```python
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, Field

mcp_server = FastMCP("AudioStudioTools")


class DurationEstimate(BaseModel):
    estimated_seconds: float = Field(description="Estimated speech duration in seconds")


@mcp_server.tool()
def estimate_speech_duration(word_count: int, words_per_minute: int = 145) -> DurationEstimate:
    """Estimate spoken duration in seconds given word count and speaking rate."""
    return DurationEstimate(estimated_seconds=round((word_count / max(words_per_minute, 1)) * 60.0, 2))
```
