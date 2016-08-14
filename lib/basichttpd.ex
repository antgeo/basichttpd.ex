defmodule BasicHttpd.App do
	use Application

	def start(_type, _args) do
		BasicHttpd.Supervisor.start_link
	end
end
