defmodule CondorDelSur.SeatTest do
  use ExUnit.Case, async: true

  alias CondorDelSur.Seat

  test "un asiento nuevo está :available" do
    seat = Seat.new("1A")
    assert seat.status == :available
  end

  test "reserve sobre :available pasa a :reserved" do
    seat = Seat.new("1A")
    {:ok, seat} = Seat.reserve(seat)
    assert seat.status == :reserved
  end

  test "no se puede reservar un asiento ya reservado" do
    seat = Seat.new("1A")
    {:ok, seat} = Seat.reserve(seat)
    {:error, motivo} = Seat.reserve(seat)
    assert motivo == :seat_unavailable
  end

  test "confirm sobre :reserved pasa a :confirmed" do
    seat = Seat.new("1A")
    {:ok, seat} = Seat.reserve(seat)
    {:ok, seat} = Seat.confirm(seat)
    assert seat.status == :confirmed
  end

  test "release sobre :reserved vuelve a :available" do
    seat = Seat.new("1A")
    {:ok, seat} = Seat.reserve(seat)
    {:ok, seat} = Seat.release(seat)
    assert seat.status == :available
  end
end
