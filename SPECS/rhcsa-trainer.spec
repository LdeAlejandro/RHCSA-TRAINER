Name:           rhcsa-trainer
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        RHCSA mini-trainer script

License:        MIT
URL:            https://github.com/LdeAlejandro/RHCSA-TRAINER

# Fontes
Source0:        rhcsa-trainer-bin.sh
Source1:        rhcsa_trainer.sh
Source2:        profile.d-rhcsa-trainer.sh

BuildArch:      noarch
Requires:       bash, coreutils

%description
Small trainer for RHCSA tasks.

%prep
# nothing

%build
# nothing

%install
# /usr/bin executáveis
install -Dm0755 %{SOURCE0} %{buildroot}%{_bindir}/rhcsa-trainer-bin
install -Dm0755 %{SOURCE1} %{buildroot}%{_bindir}/rhcsa-trainer

# shim de shell carregado em sessões interativas
install -Dm0644 %{SOURCE2} %{buildroot}%{_sysconfdir}/profile.d/rhcsa-trainer.sh

%files
%{_bindir}/rhcsa-trainer-bin
%{_bindir}/rhcsa-trainer
%config(noreplace) %{_sysconfdir}/profile.d/rhcsa-trainer.sh

%changelog
* Thu Oct 02 2025 Alejandro Amoroso <you@example.com> - %{version}-%{release}
- Initial profile.d shim packaging with split launcher/bin
