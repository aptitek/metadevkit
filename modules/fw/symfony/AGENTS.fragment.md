### `fw:symfony` — Symfony 7.x+ Deptrac Hexagonal & Twig Fortress
- **Locked Configs**: `deptrac.yaml`.
- **Quality Gates**: Deptrac Hexagonal layers (`Domain` has zero `Doctrine\*`/`Symfony\*` imports; `Controller` has zero `EntityManager` or `$this->container->get()`), thin invokable controllers with `#[MapRequestPayload]`, PHPStan Symfony+Doctrine `level: max`, and Twig-CS-Fixer + Twig XSS (`|raw` banned) & WCAG 2.2 AA a11y.
