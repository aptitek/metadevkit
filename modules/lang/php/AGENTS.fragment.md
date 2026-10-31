### `lang:php` — PHP 8.3+ Strict Types, PHPStan & Infection Fortress
- **Locked Configs**: `pint.json`, `phpstan.neon.dist`, `infection.json5`.
- **Quality Gates**: Mandatory `declare(strict_types=1);` in every `.php` file, Laravel Pint formatting, PHPStan `level: max`, Pest `>= 85%` coverage, and Infection PHP + PHPStan `>= 85%` MSI (`>= 90%` Covered MSI).
