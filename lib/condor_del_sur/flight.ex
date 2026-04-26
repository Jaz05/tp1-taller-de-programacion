defmodule CondorDelSur.Flight do
  defstruct [
    :id,
    :origin,
    :destination,
    :seats,
    :reservations,
    :passengers
  ]

  def new(id, origin, destination, seat_numbers) do
    %CondorDelSur.Flight{
      id: id,
      origin: origin,
      destination: destination,
      seats: create_seats(seat_numbers),
      reservations: %{},
      passengers: %{}
    }
  end

  defp create_seats(seat_numbers) do
    for numero_asiento <- seat_numbers, into: %{} do
      {numero_asiento, CondorDelSur.Seat.new(numero_asiento)}
    end
  end

  def available_seats(%CondorDelSur.Flight{seats: seats}) do
    Map.values(seats) |> Enum.filter(fn seat -> seat.status == :available end)
  end

  def start_reservation(%CondorDelSur.Flight{} = flight, passenger, seat_number) do
    with {:ok, seat} <- Map.fetch(flight.seats, seat_number),
         {:ok, seat_reservado} <- CondorDelSur.Seat.reserve(seat) do
      reservation =
        CondorDelSur.Reservation.new(System.unique_integer(), passenger.id, seat_number)

      flight_actualizado = %{
        flight
        | passengers: Map.put(flight.passengers, passenger.id, passenger),
          reservations: Map.put(flight.reservations, reservation.id, reservation),
          seats: Map.put(flight.seats, seat_reservado.number, seat_reservado)
      }

      {:ok, flight_actualizado, reservation}
    else
      :error -> {:error, :seat_not_found}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def confirm_reservation(%CondorDelSur.Flight{} = flight, reservation_id) do
    with {:ok, reservation} <- Map.fetch(flight.reservations, reservation_id),
         {:ok, seat_found} <- Map.fetch(flight.seats, reservation.seat_number),
         {:ok, confirmed_reservation} <- CondorDelSur.Reservation.confirm(reservation),
         {:ok, confirmed_seat} <- CondorDelSur.Seat.confirm(seat_found) do
      flight_actualizado = %{
        flight
        | reservations:
            Map.put(flight.reservations, confirmed_reservation.id, confirmed_reservation),
          seats: Map.put(flight.seats, confirmed_seat.number, confirmed_seat)
      }

      {:ok, flight_actualizado, confirmed_reservation}
    else
      :error -> {:error, :reservation_not_found}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def cancel_reservation(%CondorDelSur.Flight{} = flight, reservation_id) do
    with {:ok, reservation} <- Map.fetch(flight.reservations, reservation_id),
         {:ok, seat_found} <- Map.fetch(flight.seats, reservation.seat_number),
         {:ok, canceled_reservation} <- CondorDelSur.Reservation.cancel(reservation),
         {:ok, released_seat} <- CondorDelSur.Seat.release(seat_found) do
      flight_actualizado = %{
        flight
        | reservations:
            Map.put(flight.reservations, canceled_reservation.id, canceled_reservation),
          seats: Map.put(flight.seats, released_seat.number, released_seat)
      }

      {:ok, flight_actualizado, canceled_reservation}
    else
      :error -> {:error, :reservation_not_found}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def expire_reservation(%CondorDelSur.Flight{} = flight, reservation_id) do
    with {:ok, reservation} <- Map.fetch(flight.reservations, reservation_id),
         {:ok, seat_found} <- Map.fetch(flight.seats, reservation.seat_number),
         {:ok, expired_reservation} <- CondorDelSur.Reservation.expire(reservation),
         {:ok, released_seat} <- CondorDelSur.Seat.release(seat_found) do
      flight_actualizado = %{
        flight
        | reservations: Map.put(flight.reservations, expired_reservation.id, expired_reservation),
          seats: Map.put(flight.seats, released_seat.number, released_seat)
      }

      {:ok, flight_actualizado, expired_reservation}
    else
      :error -> {:error, :reservation_not_found}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def summary(%CondorDelSur.Flight{} = flight) do
    seats = Map.values(flight.seats)
    reservations = Map.values(flight.reservations)

    """
    ========================================
     Vuelo #{flight.id} | #{flight.origin} -> #{flight.destination}
    ========================================
     ASIENTOS
       Disponibles:  #{Enum.count(seats, fn s -> s.status == :available end)}
       Reservados:   #{Enum.count(seats, fn s -> s.status == :reserved end)}
       Confirmados:  #{Enum.count(seats, fn s -> s.status == :confirmed end)}

     RESERVAS
       Pendientes:   #{Enum.count(reservations, fn r -> r.status == :pending end)}
       Confirmadas:  #{Enum.count(reservations, fn r -> r.status == :confirmed end)}
       Canceladas:   #{Enum.count(reservations, fn r -> r.status == :cancelled end)}
       Expiradas:    #{Enum.count(reservations, fn r -> r.status == :expired end)}
    ========================================
    """
  end
end
