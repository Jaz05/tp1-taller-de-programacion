defmodule CondorDelSur.Reservation do
  defstruct [:id, :passenger_id, :seat_number, :status, :created_at]

  def new(id, passenger_id, seat_number) do
    %CondorDelSur.Reservation{
      id: id,
      passenger_id: passenger_id,
      seat_number: seat_number,
      status: :pending,
      created_at: System.system_time(:millisecond)
    }
  end

  def confirm(%CondorDelSur.Reservation{status: :pending} = reservation) do
    {:ok, %{reservation | status: :confirmed}}
  end

  def confirm(%CondorDelSur.Reservation{status: status}) do
    {:error, status}
  end

  def cancel(%CondorDelSur.Reservation{status: :pending} = reservation) do
    {:ok, %{reservation | status: :cancelled}}
  end

  def cancel(%CondorDelSur.Reservation{status: :confirmed} = _reservation) do
    {:error, :cant_cancel_confirmed}
  end

  def cancel(%CondorDelSur.Reservation{status: status}) do
    {:error, status}
  end

  def expire(%CondorDelSur.Reservation{status: :pending} = reservation) do
    {:ok, %{reservation | status: :expired}}
  end

  def expire(%CondorDelSur.Reservation{status: status}) do
    {:error, status}
  end
end
