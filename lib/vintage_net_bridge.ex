defmodule VintageNetBridge do
  @moduledoc """
  Configure network bridges with VintageNet

  Configurations for this technology are maps with a `:type` field set to
  `VintageNetBridge`. The following additional fields are supported:

  * `:vintage_net_bridge` - Bridge options
    * `:interfaces` - Set to a list of interface names to add to the bridge.
      This option is required for the bridge to be useful.
    * `:forward_delay`
    * `:priority`
    * `:hello_time`
    * `:max_age`
    * `:path_cost`
    * `:path_priority`
    * `:hairpin`
    * `:stp`

  Here's an example configuration for setting up a bridge:

  ```elixir
  %{
    type: VintageNetBridge,
    vintage_net_bridge: %{
      vintage_net_bridge: %{
      interfaces: ["eth0", "wlan0"],
    }
  }
  ```

  See [brctl(8)](https://www.man7.org/linux/man-pages/man8/brctl.8.html) for
  more information on individual options.
  """

  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig
  alias VintageNet.IP.{DhcpdConfig, DnsdConfig, IPv4Config}
  alias VintageNetBridge.Server

  @impl VintageNet.Technology
  def normalize(config) do
    config
    |> IPv4Config.normalize()
    |> DhcpdConfig.normalize()
    |> DnsdConfig.normalize()
  end

  @impl VintageNet.Technology
  def to_raw_config(ifname, config, opts) do
    normalized_config = normalize(config)
    bridge_config = normalized_config[:vintage_net_bridge]
    interfaces = Map.fetch!(bridge_config, :interfaces)

    up_cmds = [
      {:run_ignore_errors, "brctl", ["delbr", ifname]},
      {:run, "brctl", ["addbr", ifname]}
    ]

    down_cmds = [
      {:run, "brctl", ["delbr", ifname]}
    ]

    bridge_up_cmds =
      bridge_config |> Enum.sort() |> Enum.flat_map(&config_to_cmd(&1, "brctl", ifname))

    addif_up_cmds =
      Map.get(bridge_config, :interfaces, [])
      |> Enum.map(fn addif ->
        {:run_ignore_errors, "brctl", ["addif", ifname, addif]}
      end)

    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: normalized_config,
      up_cmds: up_cmds ++ bridge_up_cmds ++ addif_up_cmds,
      down_cmds: down_cmds,
      required_ifnames: [],
      child_specs: [{Server, %{brctl: "brctl", bridge_ifname: ifname, interfaces: interfaces}}]
    }
    |> IPv4Config.add_config(normalized_config, opts)
    |> DhcpdConfig.add_config(normalized_config, opts)
    |> DnsdConfig.add_config(normalized_config, opts)
  end

  @impl VintageNet.Technology
  def ioctl(_ifname, _command, _args) do
    {:error, :unsupported}
  end

  @impl VintageNet.Technology
  def check_system(_opts) do
    {:error, "unimplemented"}
  end

  defp config_to_cmd({:forward_delay, value}, brctl, ifname) do
    [{:run, brctl, ["setfd", ifname, to_string(value)]}]
  end

  defp config_to_cmd({:priority, value}, brctl, ifname) do
    [{:run, brctl, ["setbridgeprio", ifname, to_string(value)]}]
  end

  defp config_to_cmd({:hello_time, value}, brctl, ifname) do
    [{:run, brctl, ["sethello", ifname, to_string(value)]}]
  end

  defp config_to_cmd({:max_age, value}, brctl, ifname) do
    [{:run, brctl, ["setmaxage", ifname, to_string(value)]}]
  end

  defp config_to_cmd({:path_cost, value}, brctl, ifname) do
    [{:run, brctl, ["setpathcost", ifname, to_string(value)]}]
  end

  defp config_to_cmd({:path_priority, value}, brctl, ifname) do
    [{:run, brctl, ["setportprio", ifname, to_string(value)]}]
  end

  defp config_to_cmd({:hairpin, {port, value}}, brctl, ifname) do
    [{:run, brctl, ["hairpin", ifname, to_string(port), bool_to_yn(value)]}]
  end

  defp config_to_cmd({:stp, value}, brctl, ifname) do
    [{:run, brctl, ["stp", ifname, bool_to_yn(value)]}]
  end

  defp config_to_cmd(_other, _brctl, _ifname), do: []

  defp bool_to_yn(true), do: "yes"
  defp bool_to_yn(false), do: "no"
end
