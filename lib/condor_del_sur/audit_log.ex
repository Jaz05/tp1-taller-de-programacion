defmodule CondorDelSur.AuditLog do
  def start() do
    pid = spawn(fn -> loop() end)
    Process.register(pid, :audit_log)
    pid
  end

  def log(event) do
    send(:audit_log, {:log, event, System.system_time(:millisecond)})
  end

  defp loop() do
    receive do
      {:log, event, ts} ->
        IO.puts("[AUDIT #{ts}] #{inspect(event)}")
        loop()
    end
  end
end
