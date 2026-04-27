defmodule CondorDelSur.FlightServer do
  alias CondorDelSur.{Flight, AuditLog, ExpirationTask}

  def start(flight, expiration_seconds) do
    Process.monitor(Process.whereis(:audit_log))
    pid = spawn(fn -> loop(flight, expiration_seconds) end)
    Process.register(pid, :flight_server)
    pid
  end

  def start_reservation(passenger_id, seat_number) do
    call({:start_reservation, passenger_id, seat_number})
  end

  def confirm_reservation(reservation_id) do
    call({:confirm_reservation, reservation_id})
  end

  def cancel_reservation(reservation_id) do
    call({:cancel_reservation, reservation_id})
  end

  def get_state() do
    call(:get_state)
  end

  defp call(request) do
    send(:flight_server, {request, self()})

    receive do
      {:response, response} -> response
    after
      5000 -> {:error, :timeout}
    end
  end

  defp loop(flight, expiration_seconds) do
    receive do
      {{:start_reservation, passenger, seat_number}, from} ->
        case Flight.start_reservation(flight, passenger, seat_number) do
          {:ok, new_flight, reservation} ->
            AuditLog.log({:reservation_started, reservation.id})
            ExpirationTask.start(reservation.id, expiration_seconds)
            send(from, {:response, {:ok, reservation}})
            loop(new_flight, expiration_seconds)

          {:error, motivo} ->
            send(from, {:response, {:error, motivo}})
            loop(flight, expiration_seconds)
        end

      {{:confirm_reservation, reservation_id}, from} ->
        case Flight.confirm_reservation(flight, reservation_id) do
          {:ok, new_flight, reservation} ->
            AuditLog.log({:reservation_confirmed, reservation.id})
            send(from, {:response, {:ok, reservation}})
            loop(new_flight, expiration_seconds)

          {:error, motivo} ->
            send(from, {:response, {:error, motivo}})
            loop(flight, expiration_seconds)
        end

      {{:cancel_reservation, reservation_id}, from} ->
        case Flight.cancel_reservation(flight, reservation_id) do
          {:ok, new_flight, reservation} ->
            AuditLog.log({:reservation_canceled, reservation.id})
            send(from, {:response, {:ok, reservation}})
            loop(new_flight, expiration_seconds)

          {:error, motivo} ->
            send(from, {:response, {:error, motivo}})
            loop(flight, expiration_seconds)
        end

      {:get_state, from} ->
        send(from, {:response, flight})
        loop(flight, expiration_seconds)

      {:expire_reservation, reservation_id} ->
        case Flight.expire_reservation(flight, reservation_id) do
          {:ok, new_flight, reservation} ->
            AuditLog.log({:reservation_expired, reservation.id})
            loop(new_flight, expiration_seconds)

          {:error, motivo} ->
            AuditLog.log({:reservation_expired_error, motivo})
            loop(flight, expiration_seconds)
        end

      {:DOWN, _audit_ref, :process, _pid, reason} ->
        IO.puts("[FlightServer] La AuditLog murió: #{inspect(reason)}. Sigo sin auditoría.")
        loop(flight, expiration_seconds)

      otro ->
        IO.puts("[FlightServer] Mensaje inesperado: #{inspect(otro)}")
        loop(flight, expiration_seconds)
    end
  end
end
