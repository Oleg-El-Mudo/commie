Name:       psuti.fishman.messenger
Summary:    p2p - мессенджер для ОС Аврора
Version:    0.5.4
Release:    54
License:    GPLv3+
URL:        https://gitverse.ru/Fishman/commie
Source0:    %{name}-%{version}.tar.bz2

Requires:       sailfishsilica-qt5 >= 0.10.9
Requires:       qr-filter-qml-plugin
BuildRequires:  pkgconfig(auroraapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)

%description
Проект к дипломной работе студента РПИС-11 Рыбина О.М.

%prep
%autosetup

%build
%qmake5
%make_build

%install
%make_install

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
