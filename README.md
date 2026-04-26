# Cóndor del Sur

Sistema de reservas concurrentes de asientos para una aerolínea, implementado
en Elixir usando procesos manuales (sin OTP).

> TP de Taller de Programación — Cátedra Camejo

## Cómo correr el proyecto

### Requisitos

- Elixir 1.15 o superior
- Erlang/OTP 26 o superior

### Compilar

```bash
mix compile
```

### Correr la demo

```bash
mix run -e "CondorDelSur.Demo.run()"
```

### Correr los tests

```bash
mix test
```

## Procesos del sistema

Hay tres tipos de procesos:

### Procesos centrales con estado

- **`FlightServer`** (registrado como `:flight_server`)
  Mantiene el estado del vuelo. Toda mutación pasa por acá secuencialmente,
  por lo que es imposible que dos pasajeros reserven el mismo asiento
  al mismo tiempo. Recibe pedidos vía mensajes y los procesa en su loop.

- **`AuditLog`** (registrado como `:audit_log`)
  Acumula los eventos del sistema (reservas iniciadas, confirmadas,
  canceladas, expiradas). Es un proceso aparte para no frenar al
  `FlightServer` con la auditoría. El `FlightServer` lo monitorea.

### Procesos cliente

- **`PassengerClient`**
  Cada pasajero que interactúa con el sistema corre en su propio proceso.
  Compiten concurrentemente entre sí mandando mensajes al `FlightServer`.

### Procesos puntuales (one-shot)

- **`ExpirationTask`**
  Cuando se inicia una reserva, el `FlightServer` spawnea uno de estos.
  Espera 30 segundos y le manda al `FlightServer` un mensaje
  `{:expire_reservation, id}`. Si la reserva ya se confirmó o canceló,
  el mensaje se ignora.

## Dónde se usan `register` y `monitor`

### `register`

- `FlightServer` se registra como `:flight_server`. Esto permite que
  cualquier proceso (clientes, tareas) pueda mandarle mensajes con
  `send(:flight_server, ...)` sin tener que conocer su pid.
- `AuditLog` se registra como `:audit_log` por el mismo motivo.

### `monitor`

- El `FlightServer` monitorea al `AuditLog` cuando arranca.
  Si la auditoría se cae por algún motivo, el `FlightServer` recibe un
  mensaje `{:DOWN, ref, :process, pid, reason}` y sigue funcionando sin
  auditoría (degradación elegante en vez de crash en cascada).

## Estados del dominio

### Reserva

```
        start_reservation
   ─────────────────────────►  :pending
                               │
                               ├── confirm  ──► :confirmed
                               ├── cancel   ──► :cancelled
                               └── (30s)    ──► :expired
```

### Asiento

```
   :available  ──reserve──►  :reserved  ──confirm──►  :confirmed
                                  │
                                  └── release ──►  :available
                                  (cancelación o expiración)
```

## Estructura del proyecto

```
condor_del_sur/
├── mix.exs
├── .formatter.exs
├── README.md
├── lib/
│   ├── condor_del_sur.ex                    # módulo CondorDelSur
│   └── condor_del_sur/                      # submódulos del proyecto
│       ├── passenger.ex                     # CondorDelSur.Passenger
│       ├── seat.ex                          # CondorDelSur.Seat
│       ├── reservation.ex                   # CondorDelSur.Reservation
│       ├── flight.ex                        # CondorDelSur.Flight
│       ├── flight_server.ex                 # CondorDelSur.FlightServer
│       ├── audit_log.ex                     # CondorDelSur.AuditLog
│       ├── expiration_task.ex               # CondorDelSur.ExpirationTask
│       ├── passenger_client.ex              # CondorDelSur.PassengerClient
│       └── demo.ex                          # CondorDelSur.Demo
└── test/
    ├── test_helper.exs
    └── condor_del_sur/
        ├── flight_test.exs
        ├── reservation_test.exs
        └── seat_test.exs
```

## Decisiones de diseño

- **Lógica de dominio pura separada del estado vivo.**
  `Flight` es 100% puro: cada operación recibe un `%Flight{}` y devuelve
  uno nuevo. Eso lo hace fácil de testear. `FlightServer` lo envuelve en
  un proceso con estado.

- **Toda mutación serializada en un solo proceso.**
  Como el `FlightServer` procesa un mensaje a la vez, no necesitamos
  locks ni semáforos. Si llegan tres pedidos para el mismo asiento, se
  encolan en su mailbox y se resuelven en orden.

- **Tareas largas en procesos aparte.**
  La expiración no se hace con un `sleep` dentro del `FlightServer`
  (lo bloquearía). Se delega a un `ExpirationTask` que vive sólo
  para eso.

## Demo

La demo cubre los escenarios pedidos por el TP:

1. Tres pasajeros compiten por el asiento `1A`. Solo uno gana.
2. Un pasajero reserva `2A` y paga (confirmación).
3. Un pasajero reserva `2B` y cancela antes de pagar.
4. Un pasajero reserva `3A` y no hace nada (expira).
5. Estado final del vuelo y log de auditoría.
