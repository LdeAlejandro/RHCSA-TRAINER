Name:           rhcsa-trainer
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        RHCSA mini-trainer script
License:        MIT
URL:            https://github.com/LdeAlejandro/RHCSA-TRAINER
Source0:        rhcsa_trainer.sh
BuildArch:      noarch
Requires:       bash, coreutils

%description
Small trainer for RHCSA tasks.

%prep
%build

%install
# install the script as /usr/bin/rhcsa-trainer
install -D -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/rhcsa-trainer

%files
%{_bindir}/rhcsa-trainer
