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
        {VintageNetBridge.Server, ["brctl", "br0", ["eth0", "mesh0"]]},
        Utils.udhcpc_child_spec("br0", "unit_test"),
        {VintageNet.Interface.InternetConnectivityChecker, "br0"}
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
        {VintageNetBridge.Server, ["brctl", "br0", ["eth0", "mesh0"]]},
        Utils.udhcpc_child_spec("br0", "unit_test"),
        {VintageNet.Interface.InternetConnectivityChecker, "br0"}
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
        {:run_ignore_errors, "brctl", ["addif", "br0", "eth0"]},
        {:run_ignore_errors, "brctl", ["addif", "br0", "mesh0"]},
        {:run, "brctl", ["setmaxage", "br0", "4"]},
        {:run, "brctl", ["setpathcost", "br0", "5"]},
        {:run, "brctl", ["setportprio", "br0", "6"]},
        {:run, "brctl", ["setbridgeprio", "br0", "2"]},
        {:run, "brctl", ["stp", "br0", "yes"]},
        {:run, "ip", ["link", "set", "br0", "up"]}
      ]
    }

    assert output == VintageNetBridge.to_raw_config("br0", input, Utils.default_opts())
  end

  # test "teardown works"
end
