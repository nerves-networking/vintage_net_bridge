defmodule VintageNetBridge.Server do
  @moduledoc """
  Server that listens to the property table and adds and remove
  interfaces as those events happen
  """
  use GenServer
  require Logger

  def start_link([brctl, bridge_ifname, interfaces]) do
    GenServer.start_link(__MODULE__, [brctl, bridge_ifname, interfaces])
  end

  @impl GenServer
  def init([brctl, bridge_ifname, interfaces]) do
    for ifname <- interfaces do
      :ok = VintageNet.subscribe(["interface", ifname])
    end

    {:ok, %{brctl: brctl, bridge_ifname: bridge_ifname, interfaces: interfaces}}
  end

  @impl GenServer
  def handle_info({VintageNet, ["interface", ifname, "present"], _, true, _}, state) do
    Logger.debug("adding ifname to bridge: #{state.bridge_ifname} #{ifname}")
    # TODO(Connor) maybe put this in the table for others to use?
    case MuonTrap.cmd(state.brctl, ["addif", state.bridge_ifname, ifname]) do
      {_, 0} ->
        {:noreply, state}

      {error, code} ->
        Logger.error("Bridge(#{state.bridge_ifname}) error(#{code}): #{error} ")
        {:noreply, state}
    end
  end

  # def handle_info({VintageNet, ["interfaces", ifname, "present"], _, false, _}, state) do
  #   # TODO(Connor) maybe put this in the table for others to use?
  #   case MuonTrap.cmd(state.brctl, ["addif", state.bridge_ifname, ifname]) do
  #     {_, 0} ->
  #       {:noreply, state}
  #     {error, code} ->
  #       Logger.error("Bridge(#{state.bridge_ifname}) error(#{code}): #{error} ")
  #       {:noreply, state}
  #   end
  # end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
