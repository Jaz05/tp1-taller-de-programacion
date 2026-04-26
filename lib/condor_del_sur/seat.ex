defmodule CondorDelSur.Seat do
  defstruct [:number, :status]

  def new(number) do
    %CondorDelSur.Seat{number: number, status: :available}
  end

  def reserve(%CondorDelSur.Seat{status: :available} = seat) do
    {:ok, %{seat | status: :reserved}}
  end

  def reserve(%CondorDelSur.Seat{status: _status}) do
    {:error, :seat_unavailable}
  end

  def confirm(%CondorDelSur.Seat{status: :reserved} = seat) do
    {:ok, %{seat | status: :confirmed}}
  end

  def confirm(%CondorDelSur.Seat{status: _status}) do
    {:error, :seat_not_reserved}
  end

  def release(%CondorDelSur.Seat{status: :reserved} = seat) do
    {:ok, %{seat | status: :available}}
  end

  def release(%CondorDelSur.Seat{status: :confirmed}) do
    {:error, :seat_already_confirmed}
  end

  def release(%CondorDelSur.Seat{} = seat) do
    {:ok, seat}
  end
end
