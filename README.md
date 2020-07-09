# SAP Netweaver salt formula

Salt formula to bootstrap and manage SAP Netweaver platforms.

## Features

Currently the next SAP Netweaver components are available:
- ASCS instance
- ERS instance
- PAS instance
- AAS instance
- Database instance (this adds the required users, tables, views, etc to the current Hana database)

Besides that, the formula setups all of the pre requirements as:
- Hostnames
- Virtual addresses
- NFS mounts
- Shared disks
- SWAP partition space

The formula follows the best practices defined in the official [SUSE documentation](https://www.suse.com/media/white-paper/sap_netweaver_availability_cluster_740_setup_guide.pdf?_ga=2.211949268.1511104453.1571203291-1421744106.1546416539).

**Disclaimer: the formula only works with SAP Hana as database.**

## Installation

The project can be installed in many ways, including but not limited to:

1. [RPM](#rpm)
2. [Manual clone](#manual-clone)

### RPM

On openSUSE or SUSE Linux Enterprise you can just use the `zypper` system package manager:
```shell
zypper install sapnwbootstrap-formula
```

**Important!** This will install the formula in `/usr/share/salt-formulas/states/netweaver`. Make sure that `/usr/share/salt-formulas/states` entry is correctly configured in your salt minion configuration `file_roots` entry if the formula is used in a masterless mode.

You can find the latest development repositories at [SUSE's Open Build Service](https://build.opensuse.org/package/show/network:ha-clustering:sap-deployments:devel/sapnwbootstrap-formula).

### Manual clone

```
git clone https://github.com/SUSE/sapnwbootstrap-formula
cp -R cluster /srv/salt
```

**Important!** The formulas depends on [salt-shaptools](https://github.com/SUSE/salt-shaptools) package, so make sure it is installed properly if you follow the manual installation (the package can be installed as a RPM package too).

## Usage

### Pre-requirements

The formula has some hard dependencies and all of them must be in place for a successful netweaver deployment.

- In order to deploy a correct Netweaver environment a NFS share is needed (SAP stores some shared files there). The NFS share must have the folders `sapmnt` and `usrsapsys` in the exposed folder. It's a good practice the create this folder with the Netweaver SID name (for example `/sapdata/HA1/sapmnt` and `/sapdata/HA1/usrsapsys`). **This subfolders content is removed by default during the deployment**.

- Netweaver installation software (`swpm`) must be available in the system. To install the whole Netweaver environment with all the 4 components, the `swpm` folder, `sapexe` folder, `Netweaver Export` folder and `HANA HDB Client` folders must already exist, or be previously mounted when provided by external service, like NFS share. The `netweaver.sls` pillar file must be updated with all this information. `Netweaver Export` and `HANA HDB Client` folders must go in `additional_dvds` list. Check the [pillar.example](./pillar.example) for more details.

- The optimal deployment requires 4 machines in the same network for each of the Netweaver instances (the DB instance can be installed anywhere after ASCS and ERS are installed).

- SAP Hana database must be up and running.

Find an example about all of the possible configurable options in the [pillar.example](pillar.example) file.

### Configuration

To use the formula the `netweaver` entry must be included in the salt execution `top.sls` file. Here an example to execute the netweaver formula in all of the nodes:

```
# This file is /srv/salt/top.sls
base:
  '*':
    - netweaver
```

To configure the execution a pillar file is needed. Here an example of a pillar file for this formula: [pillar.example](https://github.com/SUSE/sapnwbootstrap-formula/blob/master/pillar.example)
This file must be stored in `/srv/pillar` as `netweaver.sls` and the same folder must contain a `top.sls` to use it. For example:

```
# This file is /srv/pillar/top.sls
base:
  '*':
    - netweaver
```

**Important!** The hostnames and minion names of the netweaver nodes must match the output of the `hostname` command.

### Salt pillar encryption

Pillars are expected to contain private data such as user passwords required for the automated installation or other operations. Therefore, such pillar data need to be stored in an encrypted state, which can be decrypted during pillar compilation.

SaltStack GPG renderer provides a secure encryption/decryption of pillar data. The configuration of GPG keys and procedure for pillar encryption are desribed in the Saltstack documentation guide:

- [SaltStack pillar encryption](https://docs.saltstack.com/en/latest/topics/pillar/#pillar-encryption)

- [SALT GPG RENDERERS](https://docs.saltstack.com/en/latest/ref/renderers/all/salt.renderers.gpg.html)

**Note:**
- Only passwordless gpg keys are supported, and the already existing keys cannot be used.

- If a masterless approach is used (as in the current automated deployment) the gpg private key must be imported in all the nodes. This might require the copy/paste of the keys.

## License

See the [LICENSE](LICENSE) file for license rights and limitations.

## Author

Xabier Arbulu Insausti (xarbulu@suse.com)

## Reviewers

*Pull request* preferred reviewers for this project:
- Xabier Arbulu Insausti (xarbulu@suse.com)
