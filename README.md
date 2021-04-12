![VintageNet logo](assets/logo.png)

[![Hex version](https://img.shields.io/hexpm/v/vintage_net_bridge.svg "Hex version")](https://hex.pm/packages/vintage_net_bridge)
[![API docs](https://img.shields.io/hexpm/v/vintage_net_bridge.svg?label=hexdocs "API docs")](https://hexdocs.pm/vintage_net_bridge/VintageNetBridge.html)
[![CircleCI](https://circleci.com/gh/nerves-networking/vintage_net_bridge.svg?style=svg)](https://circleci.com/gh/nerves-networking/vintage_net_bridge)
[![Coverage Status](https://coveralls.io/repos/github/nerves-networking/vintage_net_bridge/badge.svg?branch=master)](https://coveralls.io/github/nerves-networking/vintage_net_bridge?branch=master)

`VintageNetBridge` adds support for creating Ethernet bridges with `VintageNet`.
Bridging two networks joins them together so that they form one LAN. One use
case would be to join a WiFi mesh network with a wired Ethernet LAN. Devices on
the mesh network would look like they're on the Ethernet LAN when in reality all
traffic was being transferred through the bridge. For example, a DHCP server
running on the Ethernet LAN would provide IP addresses for the WiFi mesh
devices. While bridging is not always an appropriate way of joining networks, in
this case, it enables one to provision multiple Mesh WiFi to Ethernet LAN
devices for redundancy in the mesh while still looking like a normal IPv4 LAN.

To use, add `:vintage_net_bridge` to your `mix` dependencies like this:

```elixir
def deps do
  [
    {:vintage_net_bridge, "~> 0.10.0"}
  ]
end
```

## Using

Bridges typically have names like `"br0"`, `"br1"`, etc. Here is an example
configuration:

```elixir
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :disabled}
     }},
    {"br0",
     %{
       type: VintageNetBridge,
       ipv4: %{method: :dhcp},
       vintage_net_bridge: %{
         interfaces: ["eth0", "mesh0"]
       }
     }},
    {"mesh0",
     %{
       type: VintageNetWiFi,
       ipv4: %{method: :disabled},
       vintage_net_wifi: %{
         user_mpm: 1,
         root_interface: "wlan0",
         networks: [
           %{
             key_mgmt: :none,
             ssid: "my-mesh",
             frequency: 2432,
             mode: :mesh
           }
         ]
       }
     }}
  ]
```

