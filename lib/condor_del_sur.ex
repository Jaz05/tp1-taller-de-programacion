defmodule CondorDelSur do
  @moduledoc """
  Sistema de reserva de asientos de Cóndor del Sur.

  Para correr la demo:
      mix run -e "CondorDelSur.Demo.run()"

  Para correr los tests:
      mix test
  """

  def main(_args \\ []) do
    CondorDelSur.Demo.run()
  end
end
