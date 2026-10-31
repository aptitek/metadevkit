"""Tests for PHP Symfony 7.x+ (fw:symfony) and Python Django 5.x+ (fw:django) stacks."""

from __future__ import annotations

import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


def _verify_symfony_domain_and_controller_gates(
    test_case: unittest.TestCase,
    ws: RepoTestWorkspace,
    proj: Path,
) -> None:
    """Verify Symfony Domain purity and Controller flush prohibition."""
    dom_dir = proj / "src" / "Domain"
    dom_dir.mkdir(parents=True, exist_ok=True)
    dom_file = dom_dir / "Order.php"
    dom_file.write_text(
        "<?php\ndeclare(strict_types=1);\nnamespace App\\Domain;\n"
        "use Doctrine\\ORM\\Mapping as ORM;\nfinal class Order {}\n"
    )
    dom_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
    test_case.assertNotEqual(dom_proc.returncode, 0)
    test_case.assertIn("SYMFONY DEPTRAC GATE", dom_proc.stderr + dom_proc.stdout)
    dom_file.write_text("<?php\ndeclare(strict_types=1);\nnamespace App\\Domain;\nfinal readonly class Order {}\n")

    ctrl_dir = proj / "src" / "Controller"
    ctrl_dir.mkdir(parents=True, exist_ok=True)
    ctrl_file = ctrl_dir / "OrderController.php"
    flush_call = "$entityManager->" + "flush();"
    ctrl_file.write_text(
        "<?php\ndeclare(strict_types=1);\nnamespace App\\Controller;\n"
        f"final class OrderController {{ public function create(object $entityManager): void {{ {flush_call} }} }}\n"
    )
    test_case.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
    ctrl_file.write_text(
        "<?php\ndeclare(strict_types=1);\nnamespace App\\Controller;\nfinal readonly class OrderController {}\n"
    )


def _verify_django_models_and_views_gates(
    test_case: unittest.TestCase,
    ws: RepoTestWorkspace,
    orders_dir: Path,
    proj: Path,
) -> None:
    """Verify Django DJ001 model check and Services/Selectors fat-free views gate."""
    models_file = orders_dir / "models.py"
    bad_field = "models.CharField(max_length=120, " + "null=True)"
    models_file.write_text(f"class Order:\n    sku = {bad_field}\n")
    dj001_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
    test_case.assertNotEqual(dj001_proc.returncode, 0)
    test_case.assertIn("DJ001", dj001_proc.stderr + dj001_proc.stdout)
    models_file.write_text('class Order:\n    sku = ""\n\n    def __str__(self) -> str:\n        return self.sku\n')

    views_file = orders_dir / "views.py"
    bad_write = "Order.objects." + "create(sku='A1')"
    views_file.write_text(f"def create_order_view() -> None:\n    {bad_write}\n")
    view_proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
    test_case.assertNotEqual(view_proc.returncode, 0)
    test_case.assertIn("DJANGO ARCHITECTURE", view_proc.stderr + view_proc.stdout)
    views_file.write_text("def list_orders_view(user_id: int) -> dict[str, int]:\n    return {'user_id': user_id}\n")


class SymfonyAndDjangoStackTests(unittest.TestCase):
    """Verify Deptrac/Twig gates for Symfony and Services/Selectors/DJ001/djLint gates for Django."""

    def test_symfony_deptrac_controller_thinness_twig_a11y_and_verify(self) -> None:
        """Verify Symfony (fw:symfony) blocks Domain coupling, Controller flush, and Twig |raw."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("symfony-hexagonal")
            ws.init_project(proj, "core,lang:php,fw:symfony,addon:testing-fortress")
            self.assertIn("fw:symfony", ws.read_manifest_modules(proj))
            self.assertTrue((proj / "deptrac.yaml").is_file())

            _verify_symfony_domain_and_controller_gates(self, ws, proj)

            tpl_dir = proj / "templates" / "order"
            tpl_dir.mkdir(parents=True, exist_ok=True)
            twig_file = tpl_dir / "show.html.twig"
            raw_filter = "{{ summary|" + "raw }}"
            twig_file.write_text(f'<main>{raw_filter}<img src="/hero.png"></main>\n')
            self.assertNotEqual(ws.run_cmd(["task", "a11y"], cwd=proj, check=False).returncode, 0)

            twig_file.write_text('<main>{{ summary }}<img src="/hero.png" alt="Order hero banner"></main>\n')
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_django_services_selectors_dj001_settings_and_templates_verify(self) -> None:
        """Verify Django blocks ORM writes in views, DJ001 null=True CharField, and |safe in templates."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("django-enterprise")
            ws.init_project(proj, "core,lang:python,fw:django,addon:testing-fortress")
            self.assertTrue((proj / ".djlintrc").is_file())

            orders_dir = proj / "src" / "orders"
            orders_dir.mkdir(parents=True, exist_ok=True)
            _verify_django_models_and_views_gates(self, ws, orders_dir, proj)

            settings_file = orders_dir / "settings.py"
            settings_file.write_text("DEBUG = " + "True\n")
            self.assertNotEqual(ws.run_cmd(["task", "sec"], cwd=proj, check=False).returncode, 0)
            settings_file.write_text("import os\nDEBUG = os.getenv('DJANGO_DEBUG', 'false') == 'true'\n")

            html_file = proj / "templates" / "orders" / "list.html"
            html_file.parent.mkdir(parents=True, exist_ok=True)
            html_file.write_text('<section>{{ description|' + 'safe }}<img src="/box.png"></section>\n')
            self.assertNotEqual(ws.run_cmd(["task", "a11y"], cwd=proj, check=False).returncode, 0)

            html_file.write_text('<section>{{ description }}<img src="/box.png" alt="Package preview"></section>\n')
            ws.run_cmd(["task", "verify"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
