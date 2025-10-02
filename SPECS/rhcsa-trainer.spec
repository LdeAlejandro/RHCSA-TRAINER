Name:           rhcsa-trainer
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        RHCSA mini-trainer script
License:        MIT
URL:            https://github.com/LdeAlejandro/RHCSA-TRAINER
Source0:        rhcsa-trainer
BuildArch:      noarch
Requires:       bash, coreutils

%description
Small trainer for RHCSA tasks.

%prep
%build

%install
install -D -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/rhcsa-trainer

%files
%{_bindir}/rhcsa-trainer
