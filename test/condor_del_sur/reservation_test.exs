defmodule CondorDelSur.ReservationTest do
  use ExUnit.Case, async: true

  alias CondorDelSur.Reservation

  test "una reserva nueva arranca en :pending" do
    reservation = Reservation.new("r1", "p1", "1A")
    assert reservation.status == :pending
  end

  test "confirm cambia :pending -> :confirmed" do
    reservation = Reservation.new("r1", "p1", "1A")
    {:ok, reservation} = Reservation.confirm(reservation)
    assert reservation.status == :confirmed
  end

  test "no se puede confirmar una reserva ya cancelada" do
    reservation = Reservation.new("r1", "p1", "1A")
    {:ok, reservation} = Reservation.cancel(reservation)
    assert reservation.status == :cancelled
    {:error, motivo} = Reservation.confirm(reservation)
    assert motivo == :cancelled
  end

  test "no se puede cancelar una reserva ya confirmada" do
    reservation = Reservation.new("r1", "p1", "1A")
    {:ok, reservation} = Reservation.confirm(reservation)
    {:error, motivo} = Reservation.cancel(reservation)
    assert motivo == :cant_cancel_confirmed
  end

  test "expire cambia :pending -> :expired" do
    reservation = Reservation.new("r1", "p1", "1A")
    {:ok, reservation} = Reservation.expire(reservation)
    assert reservation.status == :expired
  end
end
