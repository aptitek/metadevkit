# Symfony 7.x+ Reference: DTOs, Messenger CQRS, Doctrine & Voters

## 1. Invokable Controller with `#[MapRequestPayload]`
```php
<?php

declare(strict_types=1);

namespace App\Controller\Order;

use App\Application\Order\PlaceOrderCommand;
use App\Application\Order\PlaceOrderHandler;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Attribute\MapRequestPayload;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/orders', name: 'api_orders_create', methods: ['POST'])]
#[IsGranted('ROLE_USER')]
final class CreateOrderController extends AbstractController
{
    public function __construct(
        private readonly PlaceOrderHandler $handler,
    ) {
    }

    public function __invoke(
        #[MapRequestPayload] PlaceOrderCommand $command,
    ): JsonResponse {
        $orderId = ($this->handler)($command);

        return $this->json(['id' => $orderId->toRfc4122()], Response::HTTP_CREATED);
    }
}
```

## 2. Messenger / Application Handler (`#[AsMessageHandler]`)
```php
<?php

declare(strict_types=1);

namespace App\Application\Order;

use App\Domain\Order\Order;
use App\Domain\Order\OrderRepositoryInterface;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;
use Symfony\Component\Uid\Uuid;

#[AsMessageHandler]
final readonly class PlaceOrderHandler
{
    public function __construct(
        private OrderRepositoryInterface $orders,
    ) {
    }

    public function __invoke(PlaceOrderCommand $command): Uuid
    {
        $order = Order::place($command->customerId, $command->sku, $command->quantity);
        $this->orders->save($order);

        return $order->id();
    }
}
```

## 3. Doctrine Repository Hygiene
- Inject `ServiceEntityRepository` into domain repository implementations, never `EntityManagerInterface` into Controllers.
- Prefer `SELECT NEW App\Dto\OrderSummaryDto(...)` or scalar/array hydrators for read-only listing endpoints to avoid hydrating full unit-of-work entities.
