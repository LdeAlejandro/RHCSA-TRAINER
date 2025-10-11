

To install

```bash
sudo tee /etc/yum.repos.d/rhcsa-trainer.repo <<'EOF'
[rhcsa-trainer]
name=RHCSA Trainer Repo (raw)
baseurl=https://raw.githubusercontent.com/LdeAlejandro/RHCSA-TRAINER/gh-pages/el9/
enabled=1
gpgcheck=0
metadata_expire=300
EOF

sudo dnf install -y rhcsa-trainer --disablerepo="*" --enablerepo="rhcsa-trainer"
sudo dnf install -y expect
sudo dnf install -y sos
sudo dnf install policycoreutils-python-utils -y

sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo dnf -y update rhcsa-trainer

```