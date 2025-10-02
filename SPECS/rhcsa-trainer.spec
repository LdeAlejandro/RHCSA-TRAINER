Name:           rhcsa-trainer
Version:        %{version}
Release:        %{release}
Summary:        RHCSA mini-trainer script
License:        MIT
URL:            https://github.com/LdeAlejandro/RHCSA-TRAINER
Source0:        rhcsa_trainer.sh
BuildArch:      noarch
Requires:       bash, coreutils

%description
Pequeno script de treino para RHCSA.

%prep
%build

%install
install -D -m 0755 %{SOURCE0} %{buildroot}/usr/local/bin/rhcsa-trainer

%files
/usr/local/bin/rhcsa-trainer
