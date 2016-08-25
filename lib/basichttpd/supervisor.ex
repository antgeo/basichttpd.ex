defmodule BasicHttpd.Supervisor do
	use Supervisor
	import Supervisor.Spec

	require Logger
	
	def start_link do
		Supervisor.start_link(__MODULE__, [], name: __MODULE__)
	end

	def init(_) do
		
		opts = [:binary, {:packet, :raw}, {:reuseaddr, true},
				{:keepalive, true}, {:backlog, 1024}, {:active, true}]
		{:ok, socket} = :gen_tcp.listen(8888, opts) 
				Logger.info("Listening on port")
		spawn_link(fn -> empty_listeners end)	
		children = [
			worker(BasicHttpd.Acceptor, [socket], restart: :transient)
		]
		supervise(children, strategy: :simple_one_for_one)
	end
	
	def start_socket do
		Supervisor.start_child(__MODULE__,[])
	end
	
	def empty_listeners do
		Enum.map(1..10, fn _ -> start_socket end)
	end
end
