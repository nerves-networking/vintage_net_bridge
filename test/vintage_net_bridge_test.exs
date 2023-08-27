defmodule VintageNetBridgeTest do
  use ExUnit.Case
  alias VintageNet.Interface.RawConfig

  test "basic bridge" do
    input = %{
      type: VintageNetBridge,
      ipv4: %{method: :dhcp},
      vintage_net_bridge: %{
        interfaces: ["eth0", "mesh0"]
      },
      hostname: "unit_test"
    }

    output = %RawConfig{
      ifname: "br0",
      type: VintageNetBridge,
      source_config: input,
      required_ifnames: [],
      child_specs: [
        {VintageNetBridge.Server,
         %{brctl: "brctl", bridge_ifname: "br0", interfaces: ["eth0", "mesh0"]}},
        Utils.udhcpc_child_spec("br0", "unit_test"),
        {VintageNet.Connectivity.InternetChecker, "br0"}
      ],
      down_cmds: [
        {:run, "brctl", ["delbr", "br0"]},
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", "br0", "label", "br0"]},
        {:run, "ip", ["link", "set", "br0", "down"]}
      ],
      up_cmds: [
        {:run, "brctl", ["addbr", "br0"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "eth0"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "mesh0"]},
        {:run, "ip", ["link", "set", "br0", "up"]}
      ]
    }

    assert output == VintageNetBridge.to_raw_config("br0", input, Utils.default_opts())
  end

  test "bridge with all options" do
    input = %{
      type: VintageNetBridge,
      ipv4: %{method: :dhcp},
      vintage_net_bridge: %{
        interfaces: ["eth0", "mesh0"],
        forward_delay: 1,
        priority: 2,
        hello_time: 3,
        max_age: 4,
        path_cost: 5,
        path_priority: 6,
        hairpin: {7, false},
        stp: true
      },
      hostname: "unit_test"
    }

    output = %RawConfig{
      ifname: "br0",
      type: VintageNetBridge,
      source_config: input,
      required_ifnames: [],
      child_specs: [
        {VintageNetBridge.Server,
         %{brctl: "brctl", bridge_ifname: "br0", interfaces: ["eth0", "mesh0"]}},
        Utils.udhcpc_child_spec("br0", "unit_test"),
        {VintageNet.Connectivity.InternetChecker, "br0"}
      ],
      down_cmds: [
        {:run, "brctl", ["delbr", "br0"]},
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", "br0", "label", "br0"]},
        {:run, "ip", ["link", "set", "br0", "down"]}
      ],
      up_cmds: [
        {:run, "brctl", ["addbr", "br0"]},
        {:run, "brctl", ["setfd", "br0", "1"]},
        {:run, "brctl", ["hairpin", "br0", "7", "no"]},
        {:run, "brctl", ["sethello", "br0", "3"]},
        {:run, "brctl", ["setmaxage", "br0", "4"]},
        {:run, "brctl", ["setpathcost", "br0", "5"]},
        {:run, "brctl", ["setportprio", "br0", "6"]},
        {:run, "brctl", ["setbridgeprio", "br0", "2"]},
        {:run, "brctl", ["stp", "br0", "yes"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "eth0"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "mesh0"]},
        {:run, "ip", ["link", "set", "br0", "up"]}
      ]
    }

    assert output == VintageNetBridge.to_raw_config("br0", input, Utils.default_opts())
  end

  test "bridge with static ip" do
    input = %{
      type: VintageNetBridge,
      ipv4: %{
        method: :static,
        address: "169.254.169.254",
        prefix_length: 16
      },
      vintage_net_bridge: %{
        interfaces: ["eth0", "tap0"]
      },
      hostname: "unit_test"
    }

    ipv4_address_to_tuple = fn address ->
      address
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    end

    normalized_source_config = update_in(input[:ipv4][:address], &ipv4_address_to_tuple.(&1))

    output = %RawConfig{
      ifname: "br0",
      type: VintageNetBridge,
      source_config: normalized_source_config,
      required_ifnames: [],
      child_specs: [
        {VintageNetBridge.Server,
         %{brctl: "brctl", bridge_ifname: "br0", interfaces: ["eth0", "tap0"]}},
        {VintageNet.Connectivity.LANChecker, "br0"}
      ],
      down_cmds: [
        {:run, "brctl", ["delbr", "br0"]},
        {:fun, VintageNet.RouteManager, :clear_route, ["br0"]},
        {:fun, VintageNet.NameResolver, :clear, ["br0"]},
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", "br0", "label", "br0"]},
        {:run, "ip", ["link", "set", "br0", "down"]}
      ],
      up_cmds: [
        {:run, "brctl", ["addbr", "br0"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "eth0"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "tap0"]},
        {:run_ignore_errors, "ip", ["addr", "flush", "dev", "br0", "label", "br0"]},
        {:run, "ip",
         [
           "addr",
           "add",
           "169.254.169.254/16",
           "dev",
           "br0",
           "broadcast",
           "169.254.255.255",
           "label",
           "br0"
         ]},
        {:run, "ip", ["link", "set", "br0", "up"]},
        {:fun, VintageNet.RouteManager, :clear_route, ["br0"]},
        {:fun, VintageNet.NameResolver, :clear, ["br0"]}
      ]
    }

    assert output == VintageNetBridge.to_raw_config("br0", input, Utils.default_opts())
  end

  # test "teardown works"
end
