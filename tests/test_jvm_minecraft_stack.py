"""Tests for JVM & Minecraft Modding stack (lang:java, lang:kotlin, fw:minecraft, fw:quilt, fw:fabric)."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


def _write_compliant_minecraft_fixtures(proj: Path) -> None:
    """Write compliant Quilt/Fabric descriptors, Mixin config, pack.mcmeta, and Kotlin service."""
    (proj / "gradle.properties").write_text(
        "minecraft_version=1.21.4\nquilt_loader_version=0.29.0\nfabric_loader_version=0.16.10\nmod_version=1.0.0\n",
        encoding="utf-8",
    )
    res_dir = proj / "src" / "main" / "resources"
    (res_dir / "assets" / "stellar_ops" / "lang").mkdir(parents=True, exist_ok=True)
    (res_dir / "data" / "stellar_ops" / "loot_table" / "blocks").mkdir(parents=True, exist_ok=True)
    (res_dir / "pack.mcmeta").write_text(
        json.dumps({"pack": {"pack_format": 46, "description": "Stellar Ops"}}),
        encoding="utf-8",
    )
    (res_dir / "stellar_ops.mixins.json").write_text(
        json.dumps(
            {
                "required": True,
                "package": "com.stellar.ops.mixin",
                "compatibilityLevel": "JAVA_21",
                "injectors": {"defaultRequire": 1},
                "mixins": [],
            }
        ),
        encoding="utf-8",
    )
    (res_dir / "quilt.mod.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "quilt_loader": {
                    "group": "com.stellar",
                    "id": "stellar_ops",
                    "version": "${version}",
                    "metadata": {"name": "Stellar Ops", "description": "Ops mod", "license": "MIT"},
                    "intermediate_mappings": "net.fabricmc:intermediary",
                    "entrypoints": {"init": ["com.stellar.ops.server.StellarOpsService"]},
                },
                "mixin": "stellar_ops.mixins.json",
            }
        ),
        encoding="utf-8",
    )
    (res_dir / "fabric.mod.json").write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "id": "stellar_ops",
                "version": "${version}",
                "name": "Stellar Ops",
                "description": "Ops mod",
                "license": "MIT",
                "environment": "*",
                "entrypoints": {"main": ["com.stellar.ops.server.StellarOpsService"]},
                "mixins": ["stellar_ops.mixins.json"],
                "depends": {"fabricloader": ">=0.16.10", "minecraft": "~1.21.4"},
            }
        ),
        encoding="utf-8",
    )
    srv_dir = proj / "src" / "main" / "kotlin" / "com" / "stellar" / "ops" / "server"
    srv_dir.mkdir(parents=True, exist_ok=True)
    (srv_dir / "StellarOpsService.kt").write_text(
        "package com.stellar.ops.server\n\nobject StellarOpsService {\n    fun isReady(): Boolean = true\n}\n",
        encoding="utf-8",
    )


class JvmMinecraftStackTests(unittest.TestCase):
    """Verify Client/Server side separation, Mixin @Overwrite ban, and Quilt/Fabric descriptors."""

    def test_minecraft_side_separation_mixin_safety_and_verify(self) -> None:
        """Test side isolation, @Overwrite rejection, and full verify on Quilt+Fabric mod."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("mc-mod")
            ws.init_project(proj, "core,lang:kotlin,fw:quilt")
            ws.run_cmd(["task", "feature:add", "--", "fabric"], cwd=proj)

            srv_dir = proj / "src" / "main" / "kotlin" / "com" / "stellar" / "ops" / "server"
            srv_dir.mkdir(parents=True, exist_ok=True)
            bad_srv = srv_dir / "BadServer.kt"
            bad_srv.write_text(
                "package com.stellar.ops.server\nimport net.minecraft.client.Minecraft\n",
                encoding="utf-8",
            )
            side_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(side_proc.returncode, 0)
            bad_srv.unlink()

            mixin_dir = proj / "src" / "main" / "java" / "com" / "stellar" / "ops" / "mixin"
            mixin_dir.mkdir(parents=True, exist_ok=True)
            bad_mixin = mixin_dir / "BadMixin.java"
            bad_mixin.write_text(
                "package com.stellar.ops.mixin;\nimport org.spongepowered.asm.mixin.Overwrite;\npublic class BadMixin { @Overwrite public String toString() { return \"\"; } }\n",
                encoding="utf-8",
            )
            mixin_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(mixin_proc.returncode, 0)
            bad_mixin.unlink()

            _write_compliant_minecraft_fixtures(proj)
            ws.run_cmd(["task", "verify"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
