// Atmaca masaüstü düzeni: KDE'nin varsayılan paneli, Atmaca menü simgesi ve
// panele sabitlenmiş temel uygulamalar.
loadTemplate("org.kde.plasma.desktop.defaultPanel")

var masaustleri = desktopsForActivity(currentActivity());
for (var j = 0; j < masaustleri.length; j++) {
    masaustleri[j].wallpaperPlugin = 'org.kde.image';
}

var paneller = panels();
for (var i = 0; i < paneller.length; i++) {
    var araclar = paneller[i].widgets();
    for (var k = 0; k < araclar.length; k++) {
        var a = araclar[k];
        if (a.type == "org.kde.plasma.kickoff") {
            a.currentConfigGroup = ["General"];
            a.writeConfig("icon", "atmaca-logo-icon");
        }
        if (a.type == "org.kde.plasma.icontasks" || a.type == "org.kde.plasma.taskmanager") {
            a.currentConfigGroup = ["General"];
            a.writeConfig("launchers", [
                "applications:org.kde.dolphin.desktop",
                "applications:org.mozilla.firefox.desktop",
                "applications:org.kde.konsole.desktop",
                "applications:org.kde.discover.desktop",
                "applications:systemsettings.desktop"
            ]);
        }
    }
}
