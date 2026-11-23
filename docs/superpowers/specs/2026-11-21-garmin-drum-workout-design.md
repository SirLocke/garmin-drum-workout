# Garmin Drum Workout – Design

## Ziel

Eine eigenständige Connect-IQ-App für die Garmin Forerunner 255, mit der
Schlagzeugtraining als FIT-Aktivität aufgezeichnet und mit Garmin Connect
synchronisiert werden kann. Die App zählt Schläge am Handgelenk und wertet sie
für die gesamte Aktivität sowie für einzelne Song-Abschnitte aus.

## MVP-Umfang

- Zielgerät ist zunächst ausschließlich die Garmin Forerunner 255.
- Die Uhr wird am Schlagarm getragen; Schläge werden automatisch aus den
  Accelerometer-Daten erkannt.
- Die App bietet Start, Pause, Fortsetzen und Stoppen einer Aktivität.
- Eine Lap-Taste beginnt jeweils einen neuen, nummerierten Song-Abschnitt.
  Songnamen werden im MVP nicht eingegeben.
- Die Aktivitäts-Gesamtwerte laufen über alle Abschnitte weiter. Beim neuen Lap
  beginnen dessen Schlagzahl und Tempoauswertung neu.
- Das Vibrations-Metronom ist optional und separat aktivierbar. Ist es aktiv,
  gibt es ein konfiguriertes Zieltempo per Vibration vor. Ohne Metronom gibt es
  keinen BPM-Zielwert.
- Die Live-Anzeige und Lap-Zusammenfassung unterscheiden:
  - erkannte Schlagzahl,
  - durchschnittliche Schläge pro Minute über die Lap-Dauer (Pausen zählen
    mit),
  - aus Zeitabständen zwischen Schlägen geschätztes Eigen-Tempo,
  - Regelmäßigkeit dieser Schlagabstände.
- Die App zeichnet eine FIT-Aktivität auf. Sie speichert die für die
  Aktivitäts- und Lap-Zusammenfassung verfügbaren Schlagmetriken als FIT-Daten,
  soweit sie auf dem Zielgerät und in Garmin Connect sinnvoll darstellbar sind.

## Bedeutung und Grenzen der Metriken

„BPM“ bedeutet hier zunächst Schlagfrequenz in Schlägen pro Minute. Der
Lap-Durchschnitt wird aus erkannter Schlagzahl geteilt durch vergangene
Lap-Zeit berechnet; Pausen reduzieren diesen Wert. Ein separates Tempo kann
aus den Intervallen zwischen Schlägen geschätzt werden und beschreibt die
Regelmäßigkeit der eigenen Schlagfolge.

Diese Messungen belegen ohne Songtempo oder externe Audio-/Beat-Referenz nicht,
ob die Person tatsächlich zum Song im Takt spielt. Das optionale
Vibrations-Metronom liefert eine bekannte BPM-Referenz, wenn es eingeschaltet
ist. Tempo- und Regelmäßigkeitswerte müssen als Schätzungen behandelt werden,
insbesondere bei Pausen, unregelmäßigen Mustern und Fehl- oder Nichterkennung.

### Ergänzung nach dem ersten Uhrentest

- Die Anzeige unterscheidet die geschätzte Frequenz erkannter Schläge am
  Uhrenarm in Schlägen/Minute von einem geschätzten musikalischen Beat in BPM.
  Für letzteren wählt die Person 1, 2 oder 4 Schläge pro Beat; die App teilt
  die geschätzte Schlagfrequenz durch diesen Faktor. Ohne Audio ist das keine
  automatische Erkennung des Songtempos und kann bei wechselnden Mustern
  falsch sein. Für Lap und Gesamtaktivität werden jeweils höchstens die
  letzten 64 Schlagintervalle ausgewertet, ohne Intervalle über Pausen oder
  Lap-Grenzen hinweg. Der aktuell eingestellte Faktor gilt beim Abschluss
  des jeweiligen Laps beziehungsweise der Aktivität.
- Garmin-Connect-FIT-Beiträge sollen Gesamt- und Lap-Schlagzahlen sowie
  verfügbare Schlagfrequenz- und Beat-Schätzungen enthalten. Nicht verfügbare
  Werte dürfen nicht als erfundene Null oder als Wert eines vorigen Laps
  erscheinen. Die gespeicherten FIT-Inhalte sind unabhängig von der Anzeige in
  Garmin Connect zu prüfen. Garmin-Foren zufolge benötigt die Anzeige eigener
  Felder eine Installation aus dem Connect-IQ-Store, auch eine private Beta
  kann dafür dienen; ein Upload erfolgt nur mit Zustimmung.
- Die Uhr soll nach Möglichkeit Garmins gerätespezifische Tastenhinweise
  für Speichern und Beenden nutzen. Die Lesbarkeit auf dem runden Display
  und ein sicherer Umgang mit ungespeicherten Aufzeichnungen bleiben wichtig.
- Die App ändert die systemweite Aktivitäts- und Schrittzählung nicht: Die
  verfügbaren Connect-IQ-Hinweise bieten hierfür keinen sicheren Schalter.
  Manuelles Abschalten betrifft andere Aktivitätsdaten und muss anschließend
  wieder eingeschaltet werden. Eine Änderung der Sportart nur zur
  Beeinflussung von Schritten oder Kilometern wird nicht stillschweigend
  vorgenommen.

## Nutzerablauf

1. App öffnen und optional das Vibrations-Metronom sowie dessen Ziel-BPM
   einstellen.
2. Aktivität starten; Live-Zähler, Schlagfrequenz, geschätztes Tempo und Dauer
   werden angezeigt.
3. Für jeden neuen Song die Lap-Taste drücken. Der neue nummerierte Abschnitt
   beginnt, Aktivitäts-Gesamtwerte bleiben erhalten.
4. Aktivität pausieren, fortsetzen oder beenden.
5. Aktivität und verfügbare Schlagmetriken als FIT aufzeichnen und den
   Garmin-Connect-Sync praktisch prüfen.

## Technischer Entwurf

- Eine native Connect-IQ-Watch-App in Monkey C, zunächst auf das
  Forerunner-255-Geräteprofil begrenzt.
- Accelerometer-Eingaben werden in einer isolierten Erkennungskomponente
  verarbeitet. Der erste Algorithmus soll Bewegungspeaks filtern und
  Mehrfachzählungen desselben Schlags durch eine Sperrzeit begrenzen.
- Anzeige und Session-Logik bleiben von der Erkennung getrennt, sodass
  synthetische oder simulierte Sensordaten ohne Uhr getestet werden können.
- Die FIT-Aufzeichnung nutzt die Connect-IQ-Activity-Recording-APIs. Lap-Daten
  und zusammenfassende Schlagmetriken werden in FIT-Ereignissen und/oder
  Developer Fields abgebildet, sofern die Ziel-APIs das unterstützen.
- Das Vibrations-Metronom wird über die Connect-IQ-Vibrations-API umgesetzt.
  Forerunner-Geräte unterstützen laut Garmin keine unterschiedlichen
  Vibrationsmuster; die App darf daher keine variablen Pulsformen voraussetzen.
- Die Darstellung der Aktivität und von Developer Fields in Garmin Connect ist
  ein expliziter Verifikationspunkt, kein garantierter MVP-Funktionsumfang.

## Umsetzungsplan auf hoher Ebene

1. **Geräte- und SDK-Proof-of-Concept:** Connect-IQ-Projekt für FR255 bauen und
   Accelerometer, Activity Recording/FIT-Laps, Developer Fields und Vibration
   auf dem Zielgerät bzw. Simulator verifizieren.
2. **Schlagerkennung:** Signalaufbereitung und Peak-Erkennung implementieren;
   synthetische/simulierte Bewegungsdaten und anschließend reale
   FR255-Handgelenk-Tests zur Fehlzählungsanalyse verwenden.
3. **Aktivität und Laps:** Start/Pause/Stop, nummerierte Laps, fortlaufende
   Gesamtwerte sowie lapweise Schlagzahl, Durchschnitt und
   Tempo-/Regelmäßigkeits-Schätzung integrieren.
4. **Anzeige und optionales Metronom:** Live-Ansicht und Lap-Abschlusswerte
   bauen; Metronom standardmäßig optional halten und die nutzbare
   Vibrationsfrequenz am Gerät validieren.
5. **FIT- und Sync-Verifikation:** Eine Aktivität mit mehreren Laps aufzeichnen,
   synchronisieren und prüfen, welche Standard- und eigenen Werte in
   Garmin Connect tatsächlich erscheinen.
6. **Abnahmetest am Handgelenk:** Die gezählten Schläge mit einer manuellen
   Referenz vergleichen und Fehlzählungen, Pausen, Lap-Wechsel sowie
   Metronomverhalten prüfen.

## Abnahmekriterien für den MVP

- Die App lässt sich für die Forerunner 255 bauen und auf dem Gerät starten.
- Start, Pause, Fortsetzen, Lap und Stoppen funktionieren ohne Verlust der
  bisherigen Aktivitäts-Gesamtwerte.
- Laps sind nummeriert; neue Laps setzen nur deren Abschnittswerte zurück.
- Schlagzahl, Lap-Durchschnitt in Schlägen/Minute und eine als Schätzung
  gekennzeichnete Tempo-/Regelmäßigkeitsauswertung sind in der App sichtbar.
- Das Vibrations-Metronom kann unabhängig von der Schlagzählung aktiviert und
  deaktiviert werden.
- Eine beendete Aktivität wird als FIT aufgezeichnet und Garmin Connect kann
  sie synchronisieren; die konkret sichtbaren Schlagmetriken sind dokumentiert.
- Die Erkennung wird gegen bekannte Testsequenzen geprüft und am Zielgerät
  praktisch evaluiert; nicht verifizierte Genauigkeitsversprechen werden
  vermieden.

## Nicht im MVP

- Weitere Garmin-Modelle oder Smartphone-App.
- Songnamen, Audioerkennung, automatische Songtempo-Erkennung oder ein
  verlässlicher „im Takt“-Score ohne Referenztempo.
- Schlagarten, linke/rechte Hand, Rudiments oder getrennte Zählung mehrerer
  Trommeln.
- Cloud-Backend, Konten oder eigene Datensynchronisierung.

## Garmin-Referenzen

Die Context7-Integration war in der aktuellen Sitzung nicht verfügbar. Für
diesen Entwurf wurden die offiziellen Garmin-Connect-IQ-Unterlagen direkt
herangezogen:

- [Connect IQ SDK](https://developer.garmin.com/connect-iq/)
- [Sensors – Accelerometer und Sensordaten-Listener](https://developer.garmin.com/connect-iq/articles/core-topics/Sensors.html)
- [ActivityRecording.Session – FIT-Aufzeichnung und Developer Fields](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording/Session.html)
- [Toybox.Attention – Vibrations-API und Gerätehinweise](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html)
- [Toybox.Attention.VibeProfile – unterstützte Geräte](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html)
