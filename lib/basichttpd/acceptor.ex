defmodule BasicHttpd.Acceptor do
@moduledoc """
Module accepting the socket
"""
	use GenServer
	require Logger

	defmodule SockState do
		@moduledoc """
		Struct for socket state
		"""
		defstruct socket: nil,
				  data:   "",
				  pid: nil
	end

	def init(socket) do
		Logger.debug "Starting"
		GenServer.cast(self, :accept)
		{:ok, %SockState{socket: socket, pid: self}}
	end

	def start_link(socket) do
		GenServer.start_link(__MODULE__ ,socket)
	end

	def handle_cast(:accept, state) do
		{:ok, newsocket} = :gen_tcp.accept(state.socket)
		Logger.debug "Accepting new socket"
		Task.start_link(fn -> watchdog(state.pid) end)
		BasicHttpd.Supervisor.start_socket
		{:noreply, %{state | socket: newsocket}}
	end

	def handle_cast(:shut, state) do
		Logger.debug("Watchdog has killed this process")
		:gen_tcp.close(state.socket)
		{:stop, :normal, state}
	end

	def handle_cast(a,state) do
		Logger.debug "Uncaught info: #{inspect a}"
		{:noreply, state}
	end

	def handle_info({:tcp, socket, data}, state) do
		newdata = state.data <> data
		#Logger.debug "New data \"#{newdata}\""
		if  Regex.match?(~r/.*\r\n\r\n/,newdata) do
				[_, dir] = Regex.run(~r/^GET (.*) HTTP\/1\.\d\r\n.*/,newdata)
				Logger.info("Dir: #{dir} Requested")
				:gen_tcp.send(socket,"HTTP/1.1 200 OK\nConnection: Closed")
				:gen_tcp.send(socket,"Content-Type: text/html\n\n Hello World")
				:gen_tcp.close(socket)
				{:stop, :normal, state}
		else
			{:noreply, %{state | data: newdata}}
		end
	end

	def handle_info({:tcp_closed, _socket}, state) do
		Logger.info "Connection closed"
		{:stop, :normal, state}
	end

	def handle_info(a,state) do
		Logger.debug "Uncaught info: #{inspect a}"
		{:noreply, state}
	end

	def handle_call(:idle, _from, state = %{data: ""}) do
		{:reply, :true, state}
	end

	def handle_call(:idle, _from, state) do
		{:reply, :false, state}
	end


	defp watchdog(pid) do
		# If we have no data after 5 seconds
		Process.sleep(5000)
		if GenServer.call(pid, :idle) == :true do
			GenServer.cast(pid, :shut)
			exit(:normal)
		end
		# If we have been alive 30 seconds
		Process.sleep(25_000)
		GenServer.cast(pid, :shut)
		exit(:normal)
	end
end
