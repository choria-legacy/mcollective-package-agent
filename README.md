# Package Agent

The package agent that lets you install, uninstall, update, purge and query the status of packages on your system.

The package agent does not do any management of packages itself. Instead it
uses the functionality defined in MCollective::Util::Package classes to
perform the actions. By default the Package agent ships with a PuppetPackage
util class, but creating your own is as simple as adding a new class to
util/package/ and implementing the #install, #uninstall, #purge, #update and #status
methods.

## Installation

Follow the [basic plugin install guide](https://docs.puppetlabs.com/mcollective/deploy/plugins.html).

## Configuration

There is one plugin configuration setting for the package agent.

* provider   - The Util class that implements the install, uninstall, purge, update and status behavior. Defaults to 'puppet'

General provider configuration options can then also be set in the config file.

```
plugin.package.provider = puppet

# Puppet provider specific options
plugin.package.puppet.allowcdrom = true

```

## Usage
```
% mco rpc package install package=nano

 * [ ============================================================> ] 4 / 4



Summary of Ensure:

   2.0.9-7.el6 = 4


Finished processing 4 / 4 hosts in 18176.83 ms
```

```
% mco package nano uninstall

 * [ ============================================================> ] 4 / 4


Summary of Ensure:

   absent = 4


Finished processing 4 / 4 hosts in 393.68 ms
```
```
% mco rpc package install package=openssl version=0.9.8k-7ubuntu8

 * [ ============================================================> ] 4 / 4



Summary of Ensure:

   0.9.8k-7ubuntu8 = 4


Finished processing 4 / 4 hosts in 18176.83 ms
```

## Data Plugin

The Package agent also supplies a data plugin which uses the Package agent to
check the current status of a package. The data plugin will set installed to
true/false if the package is not installed or not, and will set status to the
currently installed version if it is present and can be used during discovery
or any other place where the MCollective discovery language is used.

```
mco rpc rpcutil ping -S "package('mypackage').installed=false"

mco rpc rpcutil ping -S "package('mypackage').status=3.2-1"
```

## Extending

The default package agent achieves platform portability by using the Puppet
provider system to support package managers on all platforms that Puppet
supports.

If however you are not a Puppet user or simply want to implement some new
method of package management you can do so by providing your own backend
provider for this agent.

The logic for the Puppet version of this agent is implemented in
Util::Package::PuppetPackage, you can create a custom package implementation
that overrides #install, #uninstall, #update, #purge and #status.

This agent defaults to Util::Package::PuppetPackage but if you have your own
you can configure it in the config file using:

```
plugin.package.provider = puppet
```

## Maintenance

Maintainers: Alessandro Parisi <alessandro@puppet.com>, Michael Smith
<michael.smith@puppet.com>, Michal Ruzicka <michal.ruzicka@puppet.com>.

Tickets: File bug tickets at https://tickets.puppet.com/browse/MCOP.
