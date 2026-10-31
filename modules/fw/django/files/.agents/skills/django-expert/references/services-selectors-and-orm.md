# Django 5.x+ Reference: Services, Selectors, `django-stubs` & `pytest-django`

## 1. Canonical Selector (`selectors.py`) — N+1 Free Reads
```python
from django.db.models import QuerySet
from apps.orders.models import Order


def get_active_orders_for_user(*, user_id: int) -> QuerySet[Order]:
    return (
        Order.objects.filter(user_id=user_id, is_active=True)
        .select_related("customer", "shipping_address")
        .prefetch_related("line_items")
    )
```

## 2. Canonical Service (`services.py`) — Transactional Writes
```python
from decimal import Decimal
from django.db import transaction
from apps.orders.models import Order
from apps.users.models import User


@transaction.atomic
def create_order(*, customer: User, sku: str, unit_price: Decimal) -> Order:
    order = Order(customer=customer, sku=sku, total_amount=unit_price)
    order.full_clean()
    order.save()
    return order
```

## 3. Thin View (`views.py`)
```python
from django.http import HttpRequest, HttpResponse, JsonResponse
from apps.orders.selectors import get_active_orders_for_user


def list_orders_view(request: HttpRequest, user_id: int) -> HttpResponse:
    orders = get_active_orders_for_user(user_id=user_id)
    payload = [{"id": item.pk, "sku": item.sku} for item in orders]
    return JsonResponse({"orders": payload})
```

## 4. `pyproject.toml` Configuration for `django-stubs` & `pytest-django`
```toml
[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["mypy_django_plugin.main", "pydantic.mypy"]

[tool.django-stubs]
django_settings_module = "config.settings"

[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
addopts = "--reuse-db -ra -q"
testpaths = ["tests"]
```
