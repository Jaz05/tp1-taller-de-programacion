defmodule CondorDelSur.Demo do
  alias CondorDelSur.{Flight, FlightServer, AuditLog, Passenger, PassengerClient}

  def run() do
    IO.puts("-----Cóndor del Sur - Demo de reservas-----\n")

    IO.puts(
      "Aclaraciones: Con el fin de hacer más corta la demo el timeout de confirmación de reserva se disminuyó a 5 segundos\n"
    )

    AuditLog.start()
    flight = Flight.new("AR1234", "BUE", "BRC", ["1A", "1B", "2A", "2B", "3A"])
    FlightServer.start(flight, 5000)
    IO.puts("Escenario 1: Tres pasajeros pelean por el asiento 1A\n")
    p1 = Passenger.new("p1", "Ana", "123123")
    p2 = Passenger.new("p2", "Carlos", "321321")
    p3 = Passenger.new("p3", "Maria", "456456")

    PassengerClient.start(p1, {:reserve_and_let_expire, "1A"})
    PassengerClient.start(p2, {:reserve_and_let_expire, "1A"})
    PassengerClient.start(p3, {:reserve_and_let_expire, "1A"})

    Process.sleep(200)
    IO.puts("\n\n Escenario 2: Reserva y confirmacion de un asiento\n")
    p4 = Passenger.new("p4", "Graciela", "987987")
    PassengerClient.start(p4, {:reserve_and_confirm, "2A"})
    Process.sleep(600)

    Process.sleep(200)
    IO.puts("\n\n Escenario 3: Reserva y cancelación\n")
    p5 = Passenger.new("p5", "Ezequiel", "555788")
    PassengerClient.start(p5, {:reserve_and_cancel, "2B"})
    Process.sleep(600)

    Process.sleep(200)
    IO.puts("\n\n Escenario 4: Reserva que expira\n")
    p6 = Passenger.new("p6", "Agustin", "885773")
    PassengerClient.start(p6, {:reserve_and_let_expire, "3A"})

    Process.sleep(1000)
    IO.puts("\n\nEsperando que terminen las operaciones\n")
    Process.sleep(6000)

    IO.puts("\n\n Estado final del vuelo\n")
    estado = FlightServer.get_state()
    IO.puts(Flight.summary(estado))
  end
end
