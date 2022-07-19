defmodule VerneMQTimePlugin do
  @moduledoc """
  VerneMQ Plugin hooks for publish/subscribe server time
  """

  @spec on_publish(any, {any, binary()}, any, [binary()], binary(), any) :: :ok
  def on_publish(_username, {_mp, _client_id}, _qos, topic, payload, _isretain) do
    maybe_send_server_time(topic, payload)

    :ok
  end

  @spec on_publish_m5(any, {any, any}, any, [binary()], binary(), any, any) :: :ok
  def on_publish_m5(_username, {_mp, _client_id}, _qos, topic, payload, _isretain, _props) do
    maybe_send_server_time(topic, payload)

    :ok
  end

  defp maybe_send_server_time(topic, payload) do
    if topic == ["time", "request"] && is_binary(payload) do
      VerneMQTimePlugin.TimeServer.publish_time(["time", payload])
    end
  end
end
