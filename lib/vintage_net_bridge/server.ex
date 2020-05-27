defmodule VintageNetBridge.Server do
  @moduledoc false
  use GenServer
  require Logger

  @doc """
  Start a server that monitors interfaces for adding them to a bridge.

  Pass in a map with the following:

  * `:brctl` - the path to brctl
  * `:bridge_ifname` - the name of the bridge interface
  * `:interfaces` - a list of interface names to add to the bridge
  """
  @spec start_link(%{
          brctl: Path.t(),
          bridge_ifname: VintageNet.ifname(),
          interfaces: [VintageNet.ifname()]
        }) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    Enum.each(args.interfaces, &VintageNet.subscribe(["interface", &1, "present"]))

    {:ok, args}
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
