defmodule CondorDelSur.Demo do
  alias CondorDelSur.{Flight, FlightServer, AuditLog, Passenger, PassengerClient}

  def run() do
    IO.puts(" Cóndor del Sur - Demo de reservas\n")

    AuditLog.start()
    flight = Flight.new("AR1234", "BUE", "BRC", ["1A", "1B", "2A", "2B", "3A"])
    FlightServer.start(flight, 5000)
    IO.puts("Tres pasajeros pelean por el asiento 1A\n")
    p1 = Passenger.new("p1", "Ana", "123123")
    p2 = Passenger.new("p2", "Carlos", "321321")
    p3 = Passenger.new("p3", "Maria", "456456")

    PassengerClient.start(p1, {:reserve_and_let_expire, "1A"})
    PassengerClient.start(p2, {:reserve_and_let_expire, "1A"})
    PassengerClient.start(p3, {:reserve_and_let_expire, "1A"})

    IO.puts("Reserva y confirmacion de un asiento\n")
    p4 = Passenger.new("p4", "Graciela", "987987")
    PassengerClient.start(p4, {:reserve_and_confirm, "2A"})

    IO.puts("Reserva y cancelación\n")
    p5 = Passenger.new("p5", "Ezequiel", "555788")
    PassengerClient.start(p5, {:reserve_and_cancel, "2B"})

    IO.puts("Reserva que expira\n")
    p6 = Passenger.new("p6", "Agustin", "885773")
    PassengerClient.start(p6, {:reserve_and_let_expire, "3A"})

    IO.puts("Esperando que terminen las operaciones\n")
    Process.sleep(7000)

    IO.puts(" Estado final del vuelo\n")
    estado = FlightServer.get_state()
    IO.puts(Flight.summary(estado))
  end
end
