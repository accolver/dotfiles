# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Universal Reasoning Engine HTTP Adapter for Google ADK Agents.

Guarantees seamless multi-platform support across:
1. Gemini Enterprise / AgentSpace (internal streaming_agent_run_with_events protocol)
2. Vertex AI Console & Reasoning Engine API (:streamQuery & :query endpoints)
3. Direct HTTP & Agent-to-Agent (A2A) JSON-RPC clients
"""

import inspect
import json
import logging
from typing import Any, AsyncIterable, Iterable

from agentplatform.agent_engines.templates.adk import AdkApp
from fastapi import FastAPI, HTTPException, Request, encoders, responses

from app.app_utils import services

logger = logging.getLogger(__name__)


def _no_op_instrumentor_builder(project_id: str) -> None:
    """Retains startup telemetry and generate_content spans without duplicate setup."""
    return None


def attach_reasoning_engine_routes(app: FastAPI) -> None:
    """Registers reasoning_engine routes that dispatch to an AdkApp."""
    runtime: AdkApp | None = None
    streaming_methods: set[str] = set()
    sync_methods: set[str] = set()

    def get_runtime() -> AdkApp:
        nonlocal runtime, streaming_methods, sync_methods
        if runtime is None:
            from app.agent import app as adk_app

            runtime = AdkApp(
                app=adk_app,
                session_service_builder=services.get_session_service,
                artifact_service_builder=services.get_artifact_service,
                instrumentor_builder=_no_op_instrumentor_builder,
            )
            runtime.set_up()
            operations = runtime.register_operations()
            streaming_methods = set(operations.get("stream", [])) | set(
                operations.get("async_stream", [])
            )
            sync_methods = set(operations.get("", [])) | set(
                operations.get("async", [])
            )
        return runtime

    def resolve_method(class_method: str, *, streaming: bool):
        rt = get_runtime()
        allowed = streaming_methods if streaming else sync_methods

        if class_method not in allowed:
            if streaming and hasattr(rt, "async_stream_query"):
                class_method = "async_stream_query"
            elif not streaming and hasattr(rt, "query"):
                class_method = "query"
            else:
                raise HTTPException(
                    status_code=404,
                    detail=f"Unsupported reasoning_engine method: {class_method!r}",
                )
        return getattr(rt, class_method)

    def extract_payload(
        body: dict[str, Any], *, streaming: bool
    ) -> tuple[str, dict[str, Any]]:
        class_method = body.get("class_method") or body.get("classMethod")
        input_payload = body.get("input")

        if isinstance(input_payload, dict):
            kwargs = dict(input_payload)
        elif isinstance(input_payload, str):
            try:
                parsed_json = json.loads(input_payload)
                if isinstance(parsed_json, dict):
                    kwargs = parsed_json
                else:
                    kwargs = {"request_json": input_payload}
            except Exception:
                kwargs = {"request_json": input_payload}
        else:
            kwargs = {
                k: v
                for k, v in body.items()
                if k not in ("class_method", "classMethod", "input")
            }

        # Resolve default method if omitted
        if not class_method:
            if "request_json" in kwargs:
                class_method = "streaming_agent_run_with_events"
            elif streaming:
                class_method = "async_stream_query"
            else:
                class_method = "query"

        # Only inject default user_id if calling methods that require it
        if class_method in (
            "async_stream_query",
            "stream_query",
            "query",
            "async_query",
        ):
            if "user_id" not in kwargs:
                kwargs["user_id"] = "default_user"

        return class_method, kwargs

    async def handle_stream_query(request: Request) -> responses.StreamingResponse:
        try:
            body = await request.json()
        except Exception:
            body = {}
        class_method, kwargs = extract_payload(body, streaming=True)
        method = resolve_method(class_method, streaming=True)

        async def generator():
            try:
                output = method(**kwargs)
                if isinstance(output, AsyncIterable):
                    async for event in output:
                        json_event = encoders.jsonable_encoder(event)
                        yield json.dumps(json_event) + "\n"
                elif isinstance(output, Iterable):
                    for event in output:
                        json_event = encoders.jsonable_encoder(event)
                        yield json.dumps(json_event) + "\n"
                elif inspect.iscoroutine(output):
                    res = await output
                    json_event = encoders.jsonable_encoder(res)
                    yield json.dumps(json_event) + "\n"
            except Exception as e:
                logger.exception(
                    "Error streaming from reasoning engine method %s: %s",
                    class_method,
                    e,
                )
                raise

        return responses.StreamingResponse(
            content=generator(), media_type="application/json"
        )

    async def handle_query(request: Request) -> responses.JSONResponse:
        try:
            body = await request.json()
        except Exception:
            body = {}
        class_method, kwargs = extract_payload(body, streaming=False)
        method = resolve_method(class_method, streaming=False)
        output = (
            await method(**kwargs)
            if inspect.iscoroutinefunction(method)
            else method(**kwargs)
        )
        return responses.JSONResponse(
            content=encoders.jsonable_encoder({"output": output})
        )

    # Register on both /api prefix and root paths to handle all proxy modes
    app.post("/api/stream_reasoning_engine")(handle_stream_query)
    app.post("/stream_reasoning_engine")(handle_stream_query)
    app.post("/api/reasoning_engine")(handle_query)
    app.post("/reasoning_engine")(handle_query)
