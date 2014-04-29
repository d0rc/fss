defmodule Fss do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Fss.Supervisor.start_link
  end
end

defmodule FSS.Server do
	def start_link() do
		{:ok, listen} = :gen_tcp.listen(843, [:binary, {:reuseaddr, true}, {:active, true}])
		{:ok, spawn(fn -> connect(listen) end)}
	end

	def connect(listen) do
		{:ok, socket} = :gen_tcp.accept(listen)
		IO.puts "Connection accepted, worker #{inspect self}, socket #{inspect socket}"
		spawn(fn -> connect(listen) end)
		loop(socket)
	end

	def loop(socket) do
		receive do
			{:tcp, ^socket, <<"<policy-file-request/>", 0>>} ->
				IO.puts "Got policy-file-request, sending response"
				reply = <<"<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>", 0>>
				:gen_tcp.send(socket, reply)
				loop(socket)
			{:tcp, ^socket, <<0, 5, "hello">>} ->
				reply = <<"hello there...", 0>>
				:gen_tcp.send(socket, reply)
				loop(socket)
			{:tcp, ^socket, <<0, 7, "msgpack">>} ->
				reply = MessagePack.pack!([hello: "world", time: :calendar.local_time |> :calendar.datetime_to_gregorian_seconds])
				:gen_tcp.send(socket, reply)
				loop(socket)
			{:tcp, :closed, ^socket} ->
				IO.puts "TCP connection closed"
			msg ->
				IO.puts "Got some message: #{inspect msg}"
				loop(socket)
		end
	end
end