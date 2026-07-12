Name:           rhcsa-trainer
Version:        %{version}
Release:        %{release}
Summary:        RHCSA mini-trainer script
License:        MIT
URL:            https://github.com/LdeAlejandro/RHCSA-TRAINER
Source0:        rhcsa_trainer.sh
BuildArch:      noarch
Requires:       bash, coreutils
Requires:       findutils
Requires:       util-linux
Requires:       shadow-utils
Requires:       grep
Requires:       sed
Requires:       gawk
Requires:       acl
Requires:       systemd
Requires:       cronie
Requires:       at
Requires:       openssh-clients
Requires:       firewalld
Requires:       policycoreutils
Requires:       policycoreutils-python-utils
Requires:       lvm2
Requires:       e2fsprogs
Requires:       xfsprogs
Requires:       rpm
Requires:       dnf
Requires:       flatpak

%description
Small trainer for RHCSA tasks.

%prep
%build

%install
# install the script as /usr/bin/rhcsa-trainer
install -D -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/rhcsa-trainer

%files
%{_bindir}/rhcsa-trainer