defmodule CondorDelSur.Passenger do

  defstruct [:id, :name, :document]

  def new(id, name, document) do
    %CondorDelSur.Passenger{id: id, name: name, document: document}
  end
end
