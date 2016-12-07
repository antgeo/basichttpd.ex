defmodule BasicHttpd.App do
@moduledoc """
 Basic HTTP listener as an experiment in learning OTP and sockets
"""
	use Application

	def start(_type, _args) do
		BasicHttpd.Supervisor.start_link
	end
end
