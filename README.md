# VintageNetBridge

`VintageNetBridge` makes it easy to add and remove interfaces from a
linux bridge. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `vintage_net_bridge` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vintage_net_bridge, "~> 0.1.0"}
  ]
end
```

add the following to your config.exs:

```elixir
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"eth0",
     %{
       type: VintageNetEthernet,
       # ipv4: %{method: :dhcp}
       ipv4: %{method: :disabled}
     }},
    {"br0",
     %{
       type: VintageNetBridge,
       # ipv4: %{method: :disabled},
       ipv4: %{method: :dhcp},
       vintage_net_bridge: %{
         interfaces: ["eth0", "mesh0"]
       }
     }},
    {"mesh0",
     %{
       type: VintageNetWiFi,
       # ipv4: %{method: :dhcp},
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

