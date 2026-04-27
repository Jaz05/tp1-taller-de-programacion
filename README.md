# Cóndor del Sur

Sistema de reservas concurrentes de asientos para una aerolínea, implementado
en Elixir usando procesos manuales (sin OTP).

> TP1 de Taller de Programación — Cátedra Camejo

---
## Disclaimer
Usé IA para escribir este README y para ayudarme a destrabar errores, no para escribir el código del proyecto.

## Requisitos

- Elixir 1.15 o superior
- Erlang/OTP 26 o superior

---

## Cómo compilar

```bash
mix compile
```

---

## Cómo correr la demo

```bash
mix run -e "CondorDelSur.Demo.run()"
```

La demo dura aproximadamente 7 segundos y muestra cuatro escenarios:

1. Tres pasajeros compitiendo por el mismo asiento — solo uno gana
2. Reserva con confirmación por pago
3. Reserva con cancelación voluntaria
4. Reserva que expira por timeout

---

## Cómo correr los tests

```bash
mix test
```

Los tests cubren la lógica de dominio pura: transiciones de estado de
asientos, reservas y vuelos, sin involucrar procesos ni concurrencia.

---

## Procesos del sistema

El sistema tiene tres tipos de procesos:

### Procesos centrales con estado

**`FlightServer`** — registrado como `:flight_server`

Mantiene el estado del vuelo. Es el único proceso que puede modificar
el vuelo, por lo que toda operación pasa por él secuencialmente. Esto
garantiza que dos pasajeros no puedan reservar el mismo asiento al mismo
tiempo: aunque los mensajes lleguen en paralelo, se encolan en el mailbox
y se procesan de a uno. No hay locks ni semáforos, solo un proceso que
atiende un mensaje a la vez.

**`AuditLog`** — registrado como `:audit_log`

Recibe eventos del sistema y los imprime en consola. Corre en un proceso
separado para no bloquear al `FlightServer` con la escritura de logs.

### Procesos cliente

**`PassengerClient`**

Cada pasajero corre en su propio proceso. Estos procesos compiten
concurrentemente entre sí mandando mensajes al `FlightServer`. Soporta
tres acciones:

- `{:reserve_and_confirm, asiento}` — reserva y confirma
- `{:reserve_and_cancel, asiento}` — reserva y cancela
- `{:reserve_and_let_expire, asiento}` — reserva y deja vencer el timeout

### Procesos puntuales

**`ExpirationTask`**

Cuando el `FlightServer` crea una reserva, spawnea una `ExpirationTask`
para esa reserva. Esta tarea espera N milisegundos y le manda al
`FlightServer` un mensaje `{:expire_reservation, id}`. Después de eso
el proceso muere solo. Si la reserva ya fue confirmada o cancelada antes,
el `FlightServer` ignora el mensaje.

---

## Dónde se usan `register` y `monitor`

### `register`

- `FlightServer` se registra como `:flight_server` con `Process.register/2`.
  Permite que cualquier proceso le mande mensajes con
  `send(:flight_server, ...)` sin necesitar su pid.

- `AuditLog` se registra como `:audit_log` por el mismo motivo.

### `monitor`

- El `FlightServer` monitorea al `AuditLog` con `Process.monitor/1`
  cuando arranca. Si la auditoría muere, el `FlightServer` recibe un
  mensaje `{:DOWN, ref, :process, pid, reason}` en su mailbox y sigue
  funcionando sin auditoría, en lugar de explotar en cascada.

---

## Estados del dominio

### Reserva

```
        start_reservation
   ─────────────────────────►  :pending
                               │
                               ├── confirm  ──► :confirmed
                               ├── cancel   ──► :cancelled
                               └── timeout  ──► :expired
```

### Asiento

```
   :available ──reserve──► :reserved ──confirm──► :confirmed
                               │
                               └── release ──► :available
                               (cancelación o expiración)
```

---

## Estructura del proyecto

```
condor_del_sur/
├── mix.exs
├── lib/
│   ├── condor_del_sur.ex
│   └── condor_del_sur/
│       ├── passenger.ex          # struct Passenger
│       ├── seat.ex               # struct Seat + transiciones de estado
│       ├── reservation.ex        # struct Reservation + transiciones de estado
│       ├── flight.ex             # lógica pura del vuelo (sin procesos)
│       ├── flight_server.ex      # proceso con estado, registrado, monitorea AuditLog
│       ├── audit_log.ex          # proceso de auditoría, registrado
│       ├── expiration_task.ex    # proceso puntual (expira reservas)
│       ├── passenger_client.ex   # proceso cliente concurrente
│       └── demo.ex               # demo reproducible
└── test/
    └── condor_del_sur/
        ├── flight_test.exs
        ├── reservation_test.exs
        └── seat_test.exs
```

---

## Decisiones de diseño

**Lógica de dominio pura separada del estado vivo.**
`Flight` es 100% puro: cada función recibe un `%Flight{}` y devuelve uno
nuevo. Eso lo hace fácil de testear sin necesitar procesos. `FlightServer`
lo envuelve en un proceso con estado.

**Toda mutación serializada en un solo proceso.**
El `FlightServer` procesa un mensaje a la vez. Si llegan tres pedidos para
el mismo asiento al mismo tiempo, se encolan en su mailbox y se resuelven
en orden. El segundo siempre ve el estado actualizado por el primero.

**Tareas con timeout en procesos aparte.**
La expiración no bloquea al `FlightServer`. Se delega a una `ExpirationTask`
que vive solo para eso, espera N milisegundos, manda el mensaje y termina.

**El pasajero se registra en el vuelo al hacer la primera reserva.**
No hay un paso separado de "registrar pasajero". Cuando `start_reservation`
tiene éxito, el pasajero queda guardado en el vuelo automáticamente.
