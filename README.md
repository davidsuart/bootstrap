# bootstrap

This is a collection of start-up scripts to setup various forms of remote management/functionality.

## Usage

From the client that you want to bootstrap, pipe the scripts into bash or PowerShell, or equally put the same command into your user_data.

You probably want either `linux-for-ansible.sh` or `windows-for-winrm.ps1`

### Linux

Note: Currently this script only targets Debian/Ubuntu/Mint. Your mileage may vary on other Debian-based distros.

```Shell
$ bash <(curl -s -L https://git.io/bstlnx)

# (Expanded)
# bash <(curl --silent --location \
#   https://raw.githubusercontent.com/davidsuart/bootstrap/master/linux-for-ansible.sh)
```

### Windows

Note: Currently this script only targets Windows 8/Server 2012 and above. This is due to some of the cmdlets not being available on Windows 6.1, regardless of the PowerShell version you upgrade to.

```PowerShell
# Powershell 3.0+
> iwr -useb https://git.io/bstwin | iex

# (Expanded)
# Invoke-WebRequest -UseBasicParsing `
#   https://raw.githubusercontent.com/davidsuart/bootstrap/master/windows-for-winrm.ps1 `
#   | Invoke-Expression
```

```PowerShell
# Powershell 2.0-
> (New-Object System.Net.WebClient).DownloadString('https://git.io/bstwin') | iex
```

## Troubleshooting

See notes above in Linux and Windows sections regarding compatibility.

## Contributing

Spotted an error? Something functional to add value? Send me a pull request!

1. Fork it (<https://github.com/yourname/yourproject/fork>)
2. Create your feature branch (`git checkout -b feature/foo`)
3. Commit your changes (`git commit -am 'Add some foo'`)
4. Push to the branch (`git push origin feature/foo`)
5. Create a new Pull Request

## License

MIT license. See [LICENSE](LICENSE) for full details.

