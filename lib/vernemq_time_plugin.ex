defmodule VerneMQTimePlugin do
  @moduledoc """
  VerneMQ Plugin hooks for publish/subscribe server time
  """

  @spec on_subscribe(binary(), {binary(), binary()}, list()) :: :ok
  def on_subscribe(_username, {_mountpoint, _clientid}, [{_topic, _qos} | _] = subs) do
    if Enum.any?(subs, fn {topic, _qos} -> topic == ["time"] end) do
      start_time_server()
    end

    :ok
  end

  @spec on_subscribe_m5(binary(), {binary(), binary()}, list(), map() | nil) :: :ok
  def on_subscribe_m5(
        _username,
        {_mountpoint, _clientid},
        [{_topic, {_qos, _sub_opts}} | _] = subs,
        _props
      ) do
    if Enum.any?(subs, fn {topic, {_qos, _sub_opts}} -> topic == ["time"] end) do
      start_time_server()
    end

    :ok
  end

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

  defp start_time_server() do
    TimeServer.start()
  end

  defp maybe_send_server_time(topic, payload) do
    if topic == ["time", "request"] && is_binary(payload) do
     TimeServer.publish_time(["time", payload])
    end
  end
end
