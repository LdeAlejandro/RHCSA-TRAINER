

To install

```bash
sudo dnf install -y rhcsa-trainer --disablerepo="*" --enablerepo="rhcsa-trainer"

mkdir -p ~/.local/bin
# copie/renomeie seus fontes:
cp SOURCES/rhcsa_trainer.sh ~/.local/bin/rhcsa-trainer
cp SOURCES/rhcsa-trainer-bin.sh ~/.local/bin/rhcsa-trainer-bin
chmod +x ~/.local/bin/rhcsa-trainer ~/.local/bin/rhcsa-trainer-bin
# garanta PATH
grep -q 'LOCAL/bin' <<<"$PATH" || { echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc; source ~/.bashrc; }
# 1ª execução instala o shim
rhcsa-trainer
source ~/.bashrc
# usar
rhcsa-trainer eval

```