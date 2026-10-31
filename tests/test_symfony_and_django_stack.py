"""Tests for PHP Symfony 7.x+ (fw:symfony / symphony) and Python Django 5.x+ (fw:django) stacks."""

from __future__ import annotations

import unittest

from tests.helpers import RepoTestWorkspace


class SymfonyAndDjangoStackTests(unittest.TestCase):
    """Verify Deptrac/Twig gates for Symfony and Services/Selectors/DJ001/djLint gates for Django."""

    def test_symfony_deptrac_controller_thinness_twig_a11y_and_verify(self) -> None:
        """Verify Symfony ('symphony' alias) blocks Domain coupling, Controller flush, and Twig |raw."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("symfony-hexagonal")
            ws.init_project(proj, "core,lang:php,symphony,addon:testing-fortress")
            self.assertIn("fw:symfony", ws.read_manifest_modules(proj))
            self.assertTrue((proj / "deptrac.yaml").is_file())

            dom_dir = proj / "src" / "Domain"
            dom_dir.mkdir(parents=True, exist_ok=True)
            dom_file = dom_dir / "Order.php"
            dom_file.write_text(
                "<?php\ndeclare(strict_types=1);\nnamespace App\\Domain;\nuse Doctrine\\ORM\\Mapping as ORM;\nfinal class Order {}\n",
                encoding="utf-8",
            )
            dom_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(dom_proc.returncode, 0)
            self.assertIn("SYMFONY DEPTRAC GATE", dom_proc.stderr + dom_proc.stdout)

            dom_file.write_text(
                "<?php\ndeclare(strict_types=1);\nnamespace App\\Domain;\nfinal readonly class Order {}\n",
                encoding="utf-8",
            )

            ctrl_dir = proj / "src" / "Controller"
            ctrl_dir.mkdir(parents=True, exist_ok=True)
            ctrl_file = ctrl_dir / "OrderController.php"
            flush_call = "$entityManager->" + "flush();"
            ctrl_file.write_text(
                f"<?php\ndeclare(strict_types=1);\nnamespace App\\Controller;\nfinal class OrderController {{ public function create(object $entityManager): void {{ {flush_call} }} }}\n",
                encoding="utf-8",
            )
            ctrl_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(ctrl_proc.returncode, 0)

            ctrl_file.write_text(
                "<?php\ndeclare(strict_types=1);\nnamespace App\\Controller;\nfinal readonly class OrderController {}\n",
                encoding="utf-8",
            )

            tpl_dir = proj / "templates" / "order"
            tpl_dir.mkdir(parents=True, exist_ok=True)
            twig_file = tpl_dir / "show.html.twig"
            raw_filter = "{{ summary|" + "raw }}"
            twig_file.write_text(f"<main>{raw_filter}<img src=\"/hero.png\"></main>\n", encoding="utf-8")
            twig_proc = ws.run_cmd(["task", "a11y"], cwd=proj, check=False)
            self.assertNotEqual(twig_proc.returncode, 0)

            twig_file.write_text(
                '<main>{{ summary }}<img src="/hero.png" alt="Order hero banner"></main>\n',
                encoding="utf-8",
            )
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_django_services_selectors_dj001_settings_and_templates_verify(self) -> None:
        """Verify Django blocks ORM writes in views, DJ001 null=True CharField, and |safe in templates."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("django-enterprise")
            ws.init_project(proj, "core,lang:python,fw:django,addon:testing-fortress")
            self.assertIn("fw:django", ws.read_manifest_modules(proj))
            self.assertTrue((proj / ".djlintrc").is_file())

            orders_dir = proj / "src" / "orders"
            orders_dir.mkdir(parents=True, exist_ok=True)

            models_file = orders_dir / "models.py"
            bad_field = "models.CharField(max_length=120, " + "null=True)"
            models_file.write_text(f"class Order:\n    sku = {bad_field}\n", encoding="utf-8")
            dj001_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(dj001_proc.returncode, 0)
            self.assertIn("DJ001", dj001_proc.stderr + dj001_proc.stdout)

            models_file.write_text(
                'class Order:\n    sku = ""\n\n    def __str__(self) -> str:\n        return self.sku\n',
                encoding="utf-8",
            )

            views_file = orders_dir / "views.py"
            bad_write = "Order.objects." + "create(sku='A1')"
            views_file.write_text(f"def create_order_view() -> None:\n    {bad_write}\n", encoding="utf-8")
            view_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(view_proc.returncode, 0)
            self.assertIn("DJANGO ARCHITECTURE", view_proc.stderr + view_proc.stdout)

            views_file.write_text(
                "def list_orders_view(user_id: int) -> dict[str, int]:\n    return {'user_id': user_id}\n",
                encoding="utf-8",
            )

            settings_file = orders_dir / "settings.py"
            debug_true = "DEBUG = " + "True"
            settings_file.write_text(f"{debug_true}\n", encoding="utf-8")
            sec_proc = ws.run_cmd(["task", "sec"], cwd=proj, check=False)
            self.assertNotEqual(sec_proc.returncode, 0)
            settings_file.write_text("import os\nDEBUG = os.getenv('DJANGO_DEBUG', 'false') == 'true'\n", encoding="utf-8")

            tpl_dir = proj / "templates" / "orders"
            tpl_dir.mkdir(parents=True, exist_ok=True)
            html_file = tpl_dir / "list.html"
            safe_filter = "{{ description|" + "safe }}"
            html_file.write_text(f"<section>{safe_filter}<img src=\"/box.png\"></section>\n", encoding="utf-8")
            a11y_proc = ws.run_cmd(["task", "a11y"], cwd=proj, check=False)
            self.assertNotEqual(a11y_proc.returncode, 0)

            html_file.write_text(
                '<section>{{ description }}<img src="/box.png" alt="Package preview"></section>\n',
                encoding="utf-8",
            )
            ws.run_cmd(["task", "verify"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
