"""Tests for addon:docker Dockerfile, .dockerignore, Compose, and structure-test gates."""

from __future__ import annotations

import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace

VALID_MULTISTAGE_DOCKERFILE = """\
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS builder
WORKDIR /app
COPY pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache/uv echo "cached build"
COPY . /app

FROM ghcr.io/astral-sh/uv:python3.12-alpine AS runtime
RUN apk add --no-cache curl && addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app /app
USER appuser
HEALTHCHECK --interval=30s --timeout=5s CMD ["curl", "-f", "http://127.0.0.1:8000/health"]
CMD ["python", "-m", "app"]
"""

VALID_DOCKERIGNORE = """\
.git
.env
.env.*
.venv
__pycache__
"""

VALID_COMPOSE_YAML = """\
services:
  db:
    image: postgres:17.2-alpine
    volumes:
      - pg_data:/var/lib/postgresql/data
    networks:
      - backend
    secrets:
      - db_password
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
    restart: unless-stopped

  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: runtime
    environment:
      - APP_ENV=production
      - API_TOKEN=${API_TOKEN:?required}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - backend
    secrets:
      - api_secret
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:8000/health"]
    restart: unless-stopped

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_secret:
    file: ./secrets/api_secret.txt

volumes:
  pg_data:

networks:
  backend:
"""


def _assert_lint_fails(
    test_case: unittest.TestCase,
    ws: RepoTestWorkspace,
    proj: Path,
    target_file: Path,
    bad_cases: tuple[tuple[str, str], ...],
) -> None:
    """Write each bad content snippet to target_file and assert task lint fails with expected substring."""
    for content, expected_msg in bad_cases:
        target_file.write_text(content, encoding="utf-8")
        proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
        output = proc.stdout + proc.stderr
        test_case.assertNotEqual(proc.returncode, 0, f"Expected failure for {expected_msg}")
        test_case.assertIn(expected_msg, output)


class DockerStackTests(unittest.TestCase):
    """Verify rigorous Dockerfile, .dockerignore, Compose, and container-structure-test gates."""

    def test_dockerfile_security_and_instruction_hygiene_gates(self) -> None:
        """Verify Dockerfile rejects unpinned images, bypass comments, root USER, sudo, and shell CMD."""
        bad_dockerfiles = (
            ("FROM alpine:latest\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "':latest' image tag"),
            ("FROM alpine\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "Untagged base image"),
            ("# hadolint ignore=DL3006\nFROM alpine:3.21\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "bypass pragma"),
            ("FROM alpine:3.21\nUSER root\nHEALTHCHECK CMD [\"true\"]\n", "cannot be 'root'"),
            ("FROM alpine:3.21\nUSER app\nHEALTHCHECK NONE\n", "'HEALTHCHECK NONE' is forbidden"),
            ("FROM alpine:3.21\nUSER app\n", "Missing mandatory 'HEALTHCHECK'"),
            ("FROM alpine:3.21\nRUN sudo apk update\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "'sudo' is forbidden"),
            ("FROM alpine:3.21\nRUN apk add curl\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "--no-cache"),
            ("FROM alpine:3.21\nWORKDIR rel/dir\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "Relative WORKDIR"),
            ("FROM alpine:3.21\nADD https://x.io/a /a\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "remote URL"),
            ("FROM alpine:3.21\nUSER app\nHEALTHCHECK CMD [\"true\"]\nCMD sh -c 'run'\n", "JSON exec array"),
            ("FROM alpine:3.21\nENV API_KEY=secret123\nUSER app\nHEALTHCHECK CMD [\"true\"]\n", "Hardcoded secret"),
        )
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("df-sec")
            ws.init_project(proj, "core,addon:docker")
            self.assertTrue((proj / ".hadolint.yaml").is_file())
            self.assertTrue((proj / ".guardrails" / "ast" / "docker.yml").is_file())
            _assert_lint_fails(self, ws, proj, proj / "Dockerfile", bad_dockerfiles)

    def test_dockerfile_multistage_and_dockerignore_gates(self) -> None:
        """Verify multi-stage alias uniqueness, COPY --from integrity, unused stages, and .dockerignore."""
        bad_multistage = (
            (
                "FROM alpine:3.21 AS dup\nFROM alpine:3.21 AS dup\nUSER app\nHEALTHCHECK CMD [\"true\"]\n",
                "Duplicate multi-stage alias",
            ),
            (
                "FROM alpine:3.21\nCOPY --from=ghost /a /b\nUSER app\nHEALTHCHECK CMD [\"true\"]\n",
                "undefined build stage 'ghost'",
            ),
            (
                "FROM alpine:3.21 AS dead_stage\nFROM alpine:3.21\nUSER app\nHEALTHCHECK CMD [\"true\"]\n",
                "Unused multi-stage build stage 'dead_stage'",
            ),
            (
                "FROM alpine:3.21\nCOPY . /app\nUSER app\nHEALTHCHECK CMD [\"true\"]\n",
                "without a '.dockerignore' file",
            ),
        )
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("df-multi")
            ws.init_project(proj, "core,addon:docker")
            df = proj / "Dockerfile"
            _assert_lint_fails(self, ws, proj, df, bad_multistage)

            (proj / ".dockerignore").write_text(".git\n", encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)

            (proj / ".dockerignore").write_text(VALID_DOCKERIGNORE, encoding="utf-8")
            df.write_text(VALID_MULTISTAGE_DOCKERFILE, encoding="utf-8")
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_compose_security_and_service_hardening_gates(self) -> None:
        """Verify Compose rejects version:, privileged, host namespaces, docker.sock, and missing healthcheck."""
        base_svc = (
            "services:\n  web:\n    image: nginx:1.27-alpine\n"
            "    security_opt:\n      - no-new-privileges:true\n"
            "    healthcheck:\n      test: [\"CMD\", \"true\"]\n"
            "    restart: unless-stopped\n"
        )
        bad_composes = (
            ("version: '3.8'\n" + base_svc, "Obsolete top-level 'version:'"),
            (base_svc.replace("nginx:1.27-alpine", "nginx:latest"), "':latest' image tag"),
            (base_svc + "    privileged: true\n", "privileged: true"),
            (base_svc + "    network_mode: host\n", "Host namespace sharing"),
            (base_svc + "    user: root\n", "Running service as root"),
            (base_svc + "    volumes:\n      - /var/run/docker.sock:/var/run/docker.sock\n", "docker.sock"),
            (base_svc + "    environment:\n      - DB_PASSWORD=plaintext\n", "Plaintext secret"),
            (base_svc.replace("no-new-privileges:true", "seccomp:unconfined"), "no-new-privileges:true"),
            (base_svc.replace("test: [\"CMD\", \"true\"]", "disable: true"), "Disabling healthcheck"),
        )
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("compose-sec")
            ws.init_project(proj, "core,compose")
            _assert_lint_fails(self, ws, proj, proj / "compose.yaml", bad_composes)

    def test_compose_topology_dag_and_reference_testing_gates(self) -> None:
        """Verify Compose tests undeclared secrets/volumes/networks, depends_on cycles, and build targets."""
        cycle_compose = (
            "services:\n"
            "  a:\n    image: alpine:3.21\n    depends_on: [b]\n    security_opt: [no-new-privileges:true]\n"
            "    healthcheck:\n      test: [\"CMD\", \"true\"]\n    restart: always\n"
            "  b:\n    image: alpine:3.21\n    depends_on: [a]\n    security_opt: [no-new-privileges:true]\n"
            "    healthcheck:\n      test: [\"CMD\", \"true\"]\n    restart: always\n"
        )
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("compose-dag")
            ws.init_project(proj, "core,addon:docker")
            (proj / ".dockerignore").write_text(VALID_DOCKERIGNORE, encoding="utf-8")
            (proj / "Dockerfile").write_text(VALID_MULTISTAGE_DOCKERFILE, encoding="utf-8")
            cf = proj / "compose.yaml"

            _assert_lint_fails(
                self,
                ws,
                proj,
                cf,
                (
                    (cycle_compose, "Circular dependency cycle"),
                    (VALID_COMPOSE_YAML.replace("target: runtime", "target: missing_stage"), "target stage"),
                    (VALID_COMPOSE_YAML.replace("  pg_data:", "  other_vol:"), "undeclared named volume 'pg_data'"),
                    (VALID_COMPOSE_YAML.replace("api_secret:", "unused_sec:"), "undeclared secret 'api_secret'"),
                ),
            )
            cf.write_text(VALID_COMPOSE_YAML, encoding="utf-8")
            cst = proj / "container-structure-test.yaml"
            cst.write_text('schemaVersion: "2.0.0"\n', encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "test"], cwd=proj, check=False).returncode, 0)
            cst.write_text('schemaVersion: "2.0.0"\nmetadataTest:\n  user: "appuser"\n', encoding="utf-8")
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_docker_fail_closed_when_missing_container_specs(self) -> None:
        """Verify task test fails closed in non-fixture mode when no Dockerfile or Compose file exists."""
        with RepoTestWorkspace(fixture_mode=False) as ws:
            proj = ws.project_dir("fc-docker")
            ws.init_project(proj, "core,addon:docker")
            proc = ws.run_cmd(["task", "test"], cwd=proj, check=False)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("fail-closed", proc.stderr + proc.stdout)

            (proj / ".dockerignore").write_text(VALID_DOCKERIGNORE, encoding="utf-8")
            (proj / "Dockerfile").write_text(VALID_MULTISTAGE_DOCKERFILE, encoding="utf-8")
            ws.run_cmd(["task", "test"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
