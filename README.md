# 🧪 RouterOS QEMU Network Lab

A fully automated multi-topology virtual networking lab built using QEMU and MikroTik RouterOS CHR images.

This project lets you spin up isolated network environments for testing:
- Routing protocols (OSPF, BGP)
- Firewall/NAT behavior
- RouterOS version differences (v6 vs v7)
- Multi-site network topologies

---

# ⚙️ Core Components

- QEMU virtual machines
- MikroTik Cloud Hosted Router (CHR)
- Linux socket-based virtual links
- NAT-based WAN access for edge routers
- Host-safe design (no TAP/bridge required by default)

---

# 🧱 Lab Topology

The lab creates 3 isolated networks, each with 2 routers:

Network 1 Network 2 Network 3

r1 (edge) r3 (edge) r5 (edge)
     |        |        |
r2 (core) r4 (core) r6 (core)


Each network is fully isolated unless explicitly modified.

---

# 🌐 External Access (Edge Routers)

Only edge routers are exposed to your host system.

| Router | SSH Port | Winbox Port | API Port |
|--------|----------|--------------|----------|
| r1     | 2221     | 8291         | 8721     |
| r3     | 2222     | 8292         | 8722     |
| r5     | 2223     | 8293         | 8723     |

### Example SSH access

```bash
ssh admin@127.0.0.1 -p 2221
```

Default credentials:

username: admin
password: (empty)

# Install Dependencies
sudo apt update
sudo apt install -y \
  qemu-system-x86 qemu-system-common qemu-utils qemu-kvm \
  iproute2 bridge-utils iputils-ping net-tools \
  wget unzip curl openssh-client

# Start the network
```
./start.sh
```

# Stop the network 
```
./stop.sh
```
