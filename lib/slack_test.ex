defmodule SlackTest do
  use Application

  @slack_rpm_start_url "https://slack.com/api/rtm.start"

  def start(_type, _args) do
    request_web_socket
    |> create_socket
    |> listen
  end

  def token do
    System.get_env("TOKEN")
  end

  def request_web_socket do
    response = HTTPotion.get(@slack_rpm_start_url, query: %{token: token})

    Poison.decode!(response.body)["url"] |> URI.parse
  end

  def create_socket(web_socket_uri) do
    Socket.Web.connect!(web_socket_uri.host, path: web_socket_uri.path, secure: true)
  end

  def listen(socket) do
    case socket |> Socket.Web.recv! do
      {:text, data} ->
        spawn(fn -> handle(socket, Poison.decode!(data)) end)
      {:ping, _ } ->
        socket |> Socket.Web.send!({:pong, ""})
    end

    listen(socket)
  end

  def handle(socket, data) do
    if data["type"] == "message" do
      response =  Poison.encode! %{
        type: "message",
        text: "Yo!",
        channel: data["channel"]
      }

      socket |> Socket.Web.send!({:text, response})
    end
  end

end
