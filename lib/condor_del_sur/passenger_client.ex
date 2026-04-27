defmodule CondorDelSur.PassengerClient do
  alias CondorDelSur.FlightServer

  @random_sleep 500

  def start(passenger, action) do
    spawn(fn -> run(passenger, action) end)
  end

  defp run(passenger, {:reserve_and_confirm, seat_number}) do
    log(passenger, "intenta reservar #{seat_number}")

    case FlightServer.start_reservation(passenger, seat_number) do
      {:ok, reservation} ->
        log(passenger, "Reserva de asiento #{seat_number} con id: #{reservation.id}")
        Process.sleep(:rand.uniform(@random_sleep))

        case FlightServer.confirm_reservation(reservation.id) do
          {:ok, reservation} ->
            log(passenger, "Confirma #{seat_number} con id de reserva: #{reservation.id}")

          {:error, motivo} ->
            log(
              passenger,
              "no pudo confirmar el asiento #{seat_number} con id de reserva: #{reservation.id}. Motivo: #{motivo}"
            )
        end

      {:error, motivo} ->
        log(passenger, "no consiguió el asiento: #{seat_number}. Motivo:  #{motivo}")
    end
  end

  defp run(passenger, {:reserve_and_cancel, seat_number}) do
    log(passenger, "intenta reservar #{seat_number}")

    case FlightServer.start_reservation(passenger, seat_number) do
      {:ok, reservation} ->
        log(passenger, "Reserva de asiento #{seat_number} con id: #{reservation.id}")
        Process.sleep(:rand.uniform(@random_sleep))

        case FlightServer.cancel_reservation(reservation.id) do
          {:ok, reservation} ->
            log(passenger, "Cancela #{seat_number} con id de reserva: #{reservation.id}")

          {:error, motivo} ->
            log(
              passenger,
              "no pudo cancelar el asiento #{seat_number} con id de reserva: #{reservation.id}. Motivo: #{motivo}"
            )
        end

      {:error, motivo} ->
        log(passenger, "no consiguió el asiento #{seat_number}. Motivo: #{motivo}")
    end
  end

  defp run(passenger, {:reserve_and_let_expire, seat_number}) do
    log(passenger, "intenta reservar #{seat_number}")

    case FlightServer.start_reservation(passenger, seat_number) do
      {:ok, reservation} ->
        log(passenger, "Reserva de asiento #{seat_number} con id: #{reservation.id}")

      {:error, motivo} ->
        log(passenger, "no consiguió el asiento #{seat_number}. Motivo: #{motivo}")
    end
  end

  defp log(passenger, msg) do
    IO.puts("[Pasajero #{passenger.name}] #{msg}")
  end
end
