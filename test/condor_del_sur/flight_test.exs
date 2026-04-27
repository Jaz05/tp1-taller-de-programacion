defmodule CondorDelSur.FlightTest do
  use ExUnit.Case, async: true

  alias CondorDelSur.{Flight, Passenger, Reservation}

  defp setup_flight() do
    Flight.new("AR1", "BUE", "BRC", ["1A", "1B", "1C"])
  end

  test "iniciar reserva sobre un asiento disponible" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")

    assert {:ok, _new_flight, %Reservation{status: :pending}} =
             Flight.start_reservation(flight, p1, "1A")
  end

  test "no se puede reservar un asiento ya reservado" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    p2 = Passenger.new("p2", "Pedro", "22222222")
    {:ok, flight, _} = Flight.start_reservation(flight, p1, "1A")
    assert {:error, :seat_unavailable} = Flight.start_reservation(flight, p2, "1A")
  end

  test "confirmar una reserva pendiente" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    {:ok, flight, reservation} = Flight.start_reservation(flight, p1, "1A")
    assert reservation.status == :pending
    {:ok, flight, reservation} = Flight.confirm_reservation(flight, reservation.id)
    assert reservation.status == :confirmed
    assert flight.seats["1A"].status == :confirmed
  end

  test "cancelar una reserva pendiente libera el asiento" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    {:ok, flight, reservation} = Flight.start_reservation(flight, p1, "1A")
    assert reservation.status == :pending
    {:ok, flight, reservation} = Flight.cancel_reservation(flight, reservation.id)
    assert reservation.status == :cancelled
    assert flight.seats["1A"].status == :available
  end

  test "no se puede cancelar una reserva ya confirmada" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    {:ok, flight, reservation} = Flight.start_reservation(flight, p1, "1A")
    assert reservation.status == :pending
    {:ok, flight, reservation} = Flight.confirm_reservation(flight, reservation.id)
    assert reservation.status == :confirmed
    {:error, motivo} = Flight.cancel_reservation(flight, reservation.id)
    assert motivo == :cant_cancel_confirmed
  end

  test "expirar una reserva pendiente libera el asiento" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    {:ok, flight, reservation} = Flight.start_reservation(flight, p1, "1A")
    assert reservation.status == :pending
    {:ok, flight, reservation} = Flight.expire_reservation(flight, reservation.id)
    assert reservation.status == :expired
    assert flight.seats["1A"].status == :available
  end

  test "expirar una reserva ya confirmada NO la modifica" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    {:ok, flight, reservation} = Flight.start_reservation(flight, p1, "1A")
    assert reservation.status == :pending
    {:ok, flight, reservation} = Flight.confirm_reservation(flight, reservation.id)
    assert reservation.status == :confirmed
    {:error, motivo} = Flight.expire_reservation(flight, reservation.id)
    assert motivo == :confirmed
  end

  test "no se puede cancelar una reserva ya expirada" do
    flight = setup_flight()
    p1 = Passenger.new("p1", "Juan", "11111111")
    {:ok, flight, reservation} = Flight.start_reservation(flight, p1, "1A")
    {:ok, flight, _} = Flight.expire_reservation(flight, reservation.id)
    assert {:error, :expired} = Flight.cancel_reservation(flight, reservation.id)
  end
end
