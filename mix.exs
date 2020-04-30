defmodule VintageNetBridge.MixProject do
  use Mix.Project

  @version "0.7.0"
  @source_url "https://github.com/nerves-networking/vintage_net_wifi"

  def project do
    [
      app: :vintage_net_bridge,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      config: [],
      max_interface_count: 8,
      tmpdir: "/tmp/vintage_net",
      to_elixir_socket: "comms",
      bin_dnsd: "dnsd",
      bin_ifup: "ifup",
      bin_ifdown: "ifdown",
      bin_ifconfig: "ifconfig",
      bin_chat: "chat",
      bin_pppd: "pppd",
      bin_mknod: "mknod",
      bin_killall: "killall",
      bin_wpa_supplicant: "/usr/sbin/wpa_supplicant",
      bin_ip: "ip",
      bin_udhcpc: "udhcpc",
      bin_udhcpd: "udhcpd",
      bin_brctl: "brctl",
      path: "/usr/sbin:/usr/bin:/sbin:/bin",
      udhcpc_handler: VintageNet.Interface.Udhcpc,
      udhcpd_handler: VintageNet.Interface.Udhcpd,
      resolvconf: "/etc/resolv.conf",
      persistence: VintageNet.Persistence.FlatFile,
      persistence_dir: "/root/vintage_net",
      persistence_secret: "obfuscate_things",
      internet_host: {1, 1, 1, 1},
      regulatory_domain: "00",
      # Contain processes in cgroups by setting to:
      #   [cgroup_base: "vintage_net", cgroup_controllers: ["cpu"]]
      muontrap_options: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "bridge networking for VintageNet"
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:vintage_net, "~> 0.8.0",
       github: "nerves-networking/vintage_net", branch: "wait-for-list"},
      {:credo, "~> 1.2", only: :test, runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
