# Basalte logic: inventory

Generated from the Studio export with `task basalte:inventory` — **do not hand-edit**.
Regenerate after every change in Basalte and read the diff.

The export itself is not in the repo: 14 MB of binary, and it carries at least one
value that looks like an access token. See `docs/basalte/README.md` for where it goes.

**166 logic blocks**, **28 of them notifying**, carrying **127 notifications** (112 push, 15 e-mail) between them. 878 named objects in the export.

## Notifications

The existing set, against which every newly planned fault has to be checked.
One row per notification — a block often carries several, one per room or device.

| Block | Message | Via | Thresholds | Devices |
|---|---|---|---|---|
| A5 - Dach | Windgeschwindigkeit größer als 36km/h für mehr als 3 Minuten. | push | False, True | — |
| Alarmauslösung EMA Extern Scharf | Linienüberschreitung auf der Terrasse! | push | 1, False | Pollerleuchte |
| An/Abwesend - Meldung | Willkommen zu Hause. | push | — | — |
| An/Abwesend - Meldung | Außer Haus. | push | — | — |
| Anomalie Temperatur | Kritisch: Heizung Vorlauf Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Temperatur | Warnung: Heizung Vorlauf Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Temperatur | Warnung: Heizung Rücklauf Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Temperatur | Kritisch: Heizung Rücklauf Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Temperatur | Info: Heizung Rücklauf Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Temperatur | Info: Heizung Vorlauf Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Therme | Kritisch: Brenner Modulation auffällig. | e-mail | — | — |
| Anomalie Therme | Info: Brenner Modulation auffällig. | e-mail | — | — |
| Anomalie Therme | Warnung: Brenner Modulation auffällig. | e-mail | — | — |
| Anomalie Warmwasser | Kritisch: Warmwasser Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Warmwasser | Kritisch: Warmwasser Durchfluss auffällig. | e-mail | — | — |
| Anomalie Warmwasser | Warnung: Warmwasser Ist-Temperatur auffällig. | e-mail | — | — |
| Anomalie Warmwasser | Info: Warmwasser Durchfluss auffällig. | e-mail | — | — |
| Anomalie Warmwasser | Warnung: Warmwasser Durchfluss auffällig. | e-mail | — | — |
| Anomalie Warmwasser | Info: Warmwasser Ist-Temperatur auffällig. | e-mail | — | — |
| CO-Melder Alarm | Technischer Alarm: Technikraum (K3) CO-Melder. | push | — | — |
| DG - Dachgeschoss | Warnung: im Speicher (S) ist der Taupunkt unterschritten. | push | — | — |
| DG - Dachgeschoss | Warnung: im Speicher (S) ist der CO2 Wert > 1600ppm. | push | — | — |
| DG - Dachgeschoss | Warnung: im Abstellraum (O2) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| EG - Erdgeschoss | Warnung: im Büro (E3) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| EG - Erdgeschoss | Warnung: im Esszimmer (E5) ist der CO2 Wert > 1400ppm. | push | — | — |
| EG - Erdgeschoss | Warnung: im der Küche (E6) ist der Taupunkt unterschritten. | push | — | — |
| EG - Erdgeschoss | Warnung: im Wohnzimmer (E4) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| EG - Erdgeschoss | Warnung: in der Küche (E6) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| EG - Erdgeschoss | Warnung: im Gäste WC (E2) ist der CO2 Wert > 1400ppm. | push | — | — |
| EG - Erdgeschoss | Warnung: im Gäste WC (E2) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| EG - Erdgeschoss | Warnung: im Wohnzimmer (E4) ist der CO2 Wert > 1400ppm. | push | — | — |
| EG - Erdgeschoss | Warnung: im Esszimmer (E5) ist der Taupunkt unterschritten. | push | — | — |
| EG - Erdgeschoss | Warnung: im Gäste WC (E2) ist der Taupunkt unterschritten. | push | — | — |
| EG - Erdgeschoss | Warnung: im Esszimmer (E5) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| EG - Erdgeschoss | Warnung: im Arbeitszimmer (E3) ist der Taupunkt unterschritten. | push | — | — |
| EG - Erdgeschoss | Warnung: im der Küche (E6) ist der CO2 Wert > 1400ppm. | push | — | — |
| EG - Erdgeschoss | Warnung: im Wohnzimmer (E4) ist der Taupunkt unterschritten. | push | — | — |
| EG - Erdgeschoss | Warnung: im Arbeitszimmer (E3) ist der CO2 Wert > 1400ppm. | push | — | — |
| EG - Erdgeschoss | Warnung: im Flur (E1) ist noch ein Fenster geöffnet. | push | — | Eingangstüre, Fenster, Fenster Links, Fenster Mitte, Fenster Mitte Links, Fenster Mitte Rechts, Fenster Rechts, Fenster Seite |
| EG - Erdgeschoss | Warnung: im Gäste WC (E2) ist noch ein Fenster geöffnet. | push | — | Eingangstüre, Fenster, Fenster Links, Fenster Mitte, Fenster Mitte Links, Fenster Mitte Rechts, Fenster Rechts, Fenster Seite |
| EG - Erdgeschoss | Warnung: in der Küche (E6) ist noch ein Fenster geöffnet. | push | — | Eingangstüre, Fenster, Fenster Links, Fenster Mitte, Fenster Mitte Links, Fenster Mitte Rechts, Fenster Rechts, Fenster Seite |
| EG - Erdgeschoss | Warnung: im Arbeitszimmer (E3) ist noch ein Fenster geöffnet. | push | — | Eingangstüre, Fenster, Fenster Links, Fenster Mitte, Fenster Mitte Links, Fenster Mitte Rechts, Fenster Rechts, Fenster Seite |
| EG - Erdgeschoss | Warnung: im Esszimmer (E5) ist noch ein Fenster geöffnet. | push | — | Eingangstüre, Fenster, Fenster Links, Fenster Mitte, Fenster Mitte Links, Fenster Mitte Rechts, Fenster Rechts, Fenster Seite |
| EG - Erdgeschoss | Warnung: im Wohnzimmer (E4) ist noch ein Fenster geöffnet. | push | — | Eingangstüre, Fenster, Fenster Links, Fenster Mitte, Fenster Mitte Links, Fenster Mitte Rechts, Fenster Rechts, Fenster Seite |
| Gasmelder Alarm | Technischer Alarm: Vorratsraum (K4) Gasmelder. | push | — | — |
| Gasmelder Alarm | Technischer Alarm: Technikraum (K3) Gasmelder. | push | — | — |
| Gefriehrschrank - Türe auf | Warnung:erhöhter Stromverbrauch festgestellt. Möglicherweise ist die Türe nicht richtig geschlossen. | push | 120, 150, 180, 210, 25.5, 27 | Fußbodenheizung |
| KG - Kellergeschoss | Warnung: im Hauswirtschaftsraum (K5) ist noch ein Fenster geöffnet. | push | — | Fenster, Garagentor |
| KG - Kellergeschoss | Warnung: im Technikraum (K3) ist noch ein Fenster geöffnet. | push | — | Fenster, Garagentor |
| KG - Kellergeschoss | Warnung: in der Garage (K2) ist noch ein Fenster geöffnet. | push | — | Fenster, Garagentor |
| KG - Kellergeschoss | Warnung: im Vorratsraum (K4) ist noch ein Fenster geöffnet. | push | — | Fenster, Garagentor |
| KG - Kellergeschoss | Warnung: im Hauswirtschaftsraum (K5) ist der Taupunkt unterschritten. | push | — | — |
| KG - Kellergeschoss | Warnung: im Hauswirtschaftsraum (K5) ist der CO2 Wert > 1400ppm. | push | — | — |
| KG - Kellergeschoss | Warnung: im der Garage (K2) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| KG - Kellergeschoss | Warnung: im Vorratsraum (K4) ist der CO2 Wert > 1400ppm. | push | — | — |
| KG - Kellergeschoss | Warnung: im Hauswirtschaftsraum (K5) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| KG - Kellergeschoss | Warnung: im Technikraum (K3) ist der CO2 Wert > 1400ppm. | push | — | — |
| KG - Kellergeschoss | Warnung: in der Garage (K2) ist der Taupunkt unterschritten. | push | — | — |
| KG - Kellergeschoss | Warnung: im Technikraum (K3) i ist der Taupunkt unterschritten. | push | — | — |
| KG - Kellergeschoss | Warnung: im Technikraum (K3) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| KG - Kellergeschoss | Warnung: im Vorratsraum (K4) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| KG - Kellergeschoss | Warnung: im Vorratsraum (K4)  ist der Taupunkt unterschritten. | push | — | — |
| KG - Kellergeschoss | Warnung: in der Garage (K2) ist der CO2 Wert > 1400ppm. | push | — | — |
| Kühlschrank - Türe auf | Warnung:erhöhter Stromverbrauch festgestellt. Möglicherweise ist die Türe nicht richtig geschlossen. | push | 25.5, 27, 30, 60, 80, 90 | Fußbodenheizung |
| Meldung Bewässerung | Die Bewässerung für Kreislauf 1 ist gestoppt worden. | push | — | — |
| Meldung Bewässerung | Die Bewässerung für Kreislauf 1 ist gestartet worden. | push | — | — |
| Meldungen Sabotage | Sabotage: Leitungsüberwachung Optischer Signalgeber. | push | — | — |
| Meldungen Sabotage | Sabotage: Wandabreisskontakt Signalgeber. | push | — | — |
| Meldungen Sabotage | Sabotage: Deckelkontakt. | push | — | — |
| Meldungen Sabotage | Sabotage: Leitungsüberwachung Akustischer Signalgeber. | push | — | — |
| Meldungen Sicherungsbereich | Sicherungsbereich Alarm! | push | — | — |
| Meldungen Sicherungsbereich | Warnung: das Haus ist verlassen worden und die Sicherungsbereich ist nicht extern scharf geschaltet worden. | push | — | — |
| Meldungen Sicherungsbereich | Sicherungsbereich extern scharf geschaltet. | push | — | — |
| Meldungen Sicherungsbereich | Sicherungsbereich unscharf geschaltet. | push | — | — |
| Meldungen Sicherungsbereich | Sicherungsbereich intern scharf geschaltet. | push | — | — |
| Meldungen Sicherungsbereich | Sicherungsbereich unscharf geschaltet. | push | — | — |
| Meldungen Sicherungsbereich | Sicherungsbereich scharf geschaltet. | push | — | — |
| Meldungen Störung | Störung Akku. | push | — | — |
| Meldungen Störung | Störung Netz. | push | — | — |
| Meldungen Störung | Störung Übertragungseinrichtung. | push | — | — |
| Meldungen Störung | Störung des Sicherungsbereich. | push | — | — |
| Meldungen Terrasse EMA Extern Scharf | Sirenengeräusch auf der Terrasse Wohnzimmer erkannt! | push | False, True | — |
| Meldungen Terrasse EMA Extern Scharf | Einruchsgegäusch auf der Wohnzimmer Esszimmer erkannt! | push | False, True | — |
| Meldungen Terrasse EMA Extern Scharf | Glasbruchgeräusch auf der Wohnzimmer Esszimmer erkannt! | push | False, True | — |
| Meldungen Terrasse EMA Extern Scharf | Personen auf der Terrasse Wohnzimmer erkannt! | push | False, True | — |
| Meldungen Terrasse EMA Extern Scharf | Geschrächsgeräusch auf der Wohnzimmer Esszimmer erkannt! | push | False, True | — |
| Meldungen Wohnzimmer EMA Extern Scharf | Sirenengeräusch auf der Terrasse Esszimmer erkannt! | push | False, True | — |
| Meldungen Wohnzimmer EMA Extern Scharf | Geschrächsgeräusch auf der Terrasse Esszimmer erkannt! | push | False, True | — |
| Meldungen Wohnzimmer EMA Extern Scharf | Glasbruchgeräusch auf der Terrasse Esszimmer erkannt! | push | False, True | — |
| Meldungen Wohnzimmer EMA Extern Scharf | Einruchsgegäusch auf der Terrasse Esszimmer erkannt! | push | False, True | — |
| Meldungen Wohnzimmer EMA Extern Scharf | Personen auf der Terrasse Esszimmer erkannt! | push | False, True | — |
| OG - Obergeschoss | Warnung: im Kinderbad (O3) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| OG - Obergeschoss | Warnung: im Abstellraum (O2) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| OG - Obergeschoss | Warnung: in Luis Schlafzimmer (O5) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| OG - Obergeschoss | Warnung: in Luis Schlafzimmer (O5) ist der Taupunkt unterschritten. | push | — | — |
| OG - Obergeschoss | Warnung: im Kinderbad (O3) ist der CO2 Wert > 1600ppm. | push | — | — |
| OG - Obergeschoss | Warnung: im Gregory's Schlafzimmer (O4) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| OG - Obergeschoss | Warnung: im Kinderbad (O3) ist der Taupunkt unterschritten. | push | — | — |
| OG - Obergeschoss | Warnung: im Abstellraum (O2) ist der CO2 Wert > 1600ppm. | push | — | — |
| OG - Obergeschoss | Warnung: im Elternbad (O8) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| OG - Obergeschoss | Warnung: im Gregory's Schlafzimmer (O4) ist der CO2 Wert > 1600ppm. | push | — | — |
| OG - Obergeschoss | Warnung: im Elternbad (O8) ist der CO2 Wert > 1600ppm. | push | — | — |
| OG - Obergeschoss | Warnung: im Abstellraum (O2) ist der Taupunkt unterschritten. | push | — | — |
| OG - Obergeschoss | Warnung: in Luis Schlafzimmer (O5) ist der CO2 Wert > 1600ppm. | push | — | — |
| OG - Obergeschoss | Warnung: im Elternschlafzimmer (O6) ist die Luftfeuchtigkeit > 65%. | push | — | — |
| OG - Obergeschoss | Warnung: in Gregory's Schlafzimmer (O4) ist der Taupunkt unterschritten. | push | — | — |
| OG - Obergeschoss | Warnung: im Elternbad (O8) ist der Taupunkt unterschritten. | push | — | — |
| OG - Obergeschoss | Warnung: im Elternschlafzimmer (O6) ist der CO2 Wert > 1600ppm. | push | — | — |
| OG - Obergeschoss | Warnung: im Elternschlafzimmer (O6) ist der Taupunkt unterschritten. | push | — | — |
| OG - Obergeschoss | Warnung: im Schlafzimmer (O6) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| OG - Obergeschoss | Warnung: im Kinderbad (O3) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| OG - Obergeschoss | Warnung: in Luis Schafzimmer (O5) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| OG - Obergeschoss | Warnung: im Elternbad (O8) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| OG - Obergeschoss | Warnung: in Gregory's Schlafzimmer (O4) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| OG - Obergeschoss | Warnung: im Flur (O1) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| OG - Obergeschoss | Warnung: im Abstellraum (O2) ist noch ein Fenster geöffnet. | push | — | Fenster, Fenster Gallerie, Fenster Gang |
| Trockner - Programmaktionen | Trockenprogramm ist beendet. | push | False, True | — |
| Waschmaschine - Programmaktionen | Waschmaschinenprogramm ist beendet. | push | False, True | — |
| Wasser - Erweiteter Durchflussalarm | Wasserdurchfluss für Wasserzähler Haus größer als 1000 l/h für mehr als 1 Minute. | push | False, True | — |
| Wasser - Erweiteter Durchflussalarm | Wasserdurchfluss für Wasserzähler Garten größer als 1000 l/h für mehr als 1 Minute. | push | False, True | — |
| Wassermelder Alarm | Technischer Alarm: Flur (E1) Wassermelder. | push | — | — |
| Wassermelder Alarm | Technischer Alarm: Küche (E6) Wassermelder Küchenzeile Links. | push | — | — |
| Wassermelder Alarm | Technischer Alarm: Küche (E6) Wassermelder Kücheninsel. | push | — | — |
| Wassermelder Alarm | Technischer Alarm: Flur (E6) Wassermelder Küchenzeile Rechts. | push | — | — |
| Wassermelder Alarm | Technischer Alarm: Elternschlafzimmer (O6) Wassermelder. | push | — | — |
| Wassermelder Alarm | Technischer Alarm: Technikraum (K3) Wassermelder. | push | — | — |
| Wassermelder Alarm | Technischer Alarm: Hauswirtschaftsraum (K5) Wassermelder. | push | — | — |

## KNX bindings

The group addresses each block binds, as Studio labels them — the label
is a copy taken when the node was placed, so `task basalte:sync` is what
says whether it still matches ETS. A node placed but connected to nothing
is a half-built block; it lands in the last column.

| Block | Reads | Writes | Unconnected |
|---|---|---|---|
| (unnamed) | 11/1/11 Sperren_Status (1.001), 11/1/13 Automatik_Sperren_Status (1.001) | 11/1/14 Automatik_Bereit (1.011) | — |
| A2 - Terrasse | 0/5/21 A2_Alles_Aus (1.001), 0/6/41 G3_Alles_Aus (1.001) | — | — |
| A5 - Dach | 8/5/47 Windalarm (1.001) | 8/5/48 Windalarm_Erweitert (1.001) | — |
| Alarmauslösung EMA Extern Scharf | 14/3/90 Wohnzimmer_Linienuberschreitung (1.005), 14/3/130 Esszimmer_Linienuberschreitung (1.005) | — | — |
| Alarmauslösung EMA Intern Scharf | 14/3/81 Wohnzimmer_Person (1.005), 14/3/90 Wohnzimmer_Linienuberschreitung (1.005), 14/3/121 Esszimmer_Person (1.005), 14/3/130 Esszimmer_Linienuberschreitung (1.005) | — | — |
| An/Abwesend - Zustand | 18/1/0 Alexander_Anwesend (1.002), 18/2/0 Vanessa_Anwesend (1.002) | — | — |
| Anomalie Temperatur | 15/2/23 Vorlauf_Anomalie (5.010), 15/2/26 Ruecklauf_Anomalie (5.010) | — | — |
| Anomalie Therme | 15/2/12 Brenner_Modulation_Anomalie (5.010) | — | — |
| Anomalie Warmwasser | 15/2/52 Durchfluss_Anomalie (5.010), 15/2/54 Temperatur_Anomalie (5.010) | — | — |
| Automatik Bereit - Status senden | 11/1/14 Automatik_Bereit (1.003) | 11/1/15 Automatik_Bereit_Status (1.011) | — |
| Automatik Sperren - Status senden | 11/1/12 Automatik_Sperren (1.003) | 11/1/13 Automatik_Sperren_Status (1.011) | — |
| CO 2 Alarm | 8/2/42 E2_CO2_Alarm_1 (1.005), 8/2/43 E2_CO2_Alarm_2 (1.005), 8/2/44 E2_CO2_Alarm_3 (1.005), 8/2/72 E3_CO2_Alarm_1 (1.005), 8/2/73 E3_CO2_Alarm_2 (1.005), 8/2/74 E3_CO2_Alarm_3 (1.005), 8/2/102 E4_CO2_Alarm_1 (1.005), 8/2/103 E4_CO2_Alarm_2 (1.005), 8/2/104 E4_CO2_Alarm_3 (1.005), 8/2/132 E5_CO2_Alarm_1 (1.005), 8/2/133 E5_CO2_Alarm_2 (1.005), 8/2/134 E5_CO2_Alarm_3 (1.005), 8/2/162 E6_CO2_Alarm_1 (1.005), 8/2/163 E6_CO2_Alarm_2 (1.005), 8/2/164 E6_CO2_Alarm_3 (1.005) | — | — |
| CO 2 Alarm | 8/3/42 O2_CO2_Alarm_1 (1.005), 8/3/43 O2_CO2_Alarm_2 (1.005), 8/3/44 O2_CO2_Alarm_3 (1.005), 8/3/72 O3_CO2_Alarm_1 (1.005), 8/3/73 O3_CO2_Alarm_2 (1.005), 8/3/74 O3_CO2_Alarm_3 (1.005), 8/3/102 O4_CO2_Alarm_1 (1.005), 8/3/103 O4_CO2_Alarm_2 (1.005), 8/3/104 O4_CO2_Alarm_3 (1.005), 8/3/132 O5_CO2_Alarm_1 (1.005), 8/3/133 O5_CO2_Alarm_2 (1.005), 8/3/134 O5_CO2_Alarm_3 (1.005), 8/3/162 O6_CO2_Alarm_1 (1.005), 8/3/163 O6_CO2_Alarm_2 (1.005), 8/3/164 O6_CO2_Alarm_3 (1.005), 8/3/222 O8_CO2_Alarm_1 (1.005), 8/3/223 O8_CO2_Alarm_3 (1.005), 8/3/224 O8_CO2_Alarm_4 (1.005) | — | — |
| CO-Melder Alarm | 10/1/41 K3_CO_Melder (1.011) | — | — |
| DG - Dachgeschoss | — | 9/4/9 S1_KNX_Nacht_Tag (1.002) | — |
| DG - Dachgeschoss | — | 9/4/9 S1_KNX_Nacht_Tag (1.002) | — |
| E1 - Flur | 10/2/1 E1_Fenster_Auf (1.019), 10/2/2 E1_Fenster_Stellung_Kipp (1.019) | 10/2/3 E1_Fenster_Stellung_Auf (1.019) | — |
| E1 - Flur | 8/5/52 Wetterstation_Helligkeit (9.000), 9/2/60 EMA_BWM_Sperren (1.003), 9/2/66 EMA_BWM_Prasenz (1.001) | 9/2/7 BWM_Eingang_Praesenz_Eingang (1.001), 9/2/61 EMA_BWM_Sperren_Status (1.011) | — |
| E2 - Gäste WC | 10/2/31 E2_Fenster_Auf (1.019), 10/2/32 E2_Fenster_Stellung_Kipp (1.019) | 10/2/33 E2_Fenster_Stellung_Auf (1.019) | — |
| E3 - Büro | 0/0/111 EG_Alles_Aus (1.001), 0/0/241 Alles_Aus (1.001), 0/2/41 E3_Alles_Aus (1.001) | — | — |
| E3 - Büro | 10/2/41 E3_Fenster_Links_Auf (1.019), 10/2/42 E3_Fenster_Links_Stellung_Kipp (1.019), 10/2/51 E3_Fenster_Mitte_Auf (1.019), 10/2/52 E3_Fenster_Mitte_Stellung_Kipp (1.019), 10/2/61 E3_Fenster_Rechts_Auf (1.019), 10/2/62 E3_Fenster_Rechts_Stellung_Kipp (1.019), 10/2/71 E3_Fenster_Seite_Auf (1.019), 10/2/72 E3_Fenster_Seite_Stellung_Kipp (1.019) | 10/2/43 E3_Fenster_Links_Stellung_Auf (1.019), 10/2/53 E3_Fenster_Mitte_Stellung_Auf (1.019), 10/2/63 E3_Fenster_Rechts_Stellung_Auf (1.019), 10/2/73 E3_Fenster_Seite_Stellung_Auf (1.019) | — |
| E3 - Büro | 8/5/52 Wetterstation_Helligkeit (9.000), 9/2/100 EMA_BWM_Sperren (1.003), 9/2/106 EMA_BWM_Prasenz (1.001), 9/2/109 BWM_Tag_Nacht (1.002) | 0/2/40 E3_Szenen (17.001), 0/2/41 E3_Alles_Aus (1.001), 9/2/101 EMA_BWM_Sperren_Status (1.011) | — |
| E3 - Büro | 0/2/41 E3_Alles_Aus (1.001) | — | — |
| E4 - Wohnzimmer | 0/0/111 EG_Alles_Aus (1.001), 0/0/241 Alles_Aus (1.001), 0/2/61 E4_Alles_Aus (1.001) | — | — |
| E4 - Wohnzimmer | 8/5/52 Wetterstation_Helligkeit (9.000), 9/2/120 EMA_BWM_Sperren (1.003), 9/2/126 EMA_BWM_Prasenz (1.001), 9/2/130 BWM_Tag_Nacht (1.002) | 0/2/60 E4_Szenen (17.001), 0/2/61 E4_Alles_Aus (1.001), 9/2/121 EMA_BWM_Sperren_Status (1.011) | — |
| E4 - Wohnzimmer | 0/2/61 E4_Alles_Aus (1.001) | — | — |
| E5 - Esszimmer | 0/2/81 E5_Alles_Aus (1.001) | — | — |
| E6 - Küche | 10/2/101 E6_Fenster_Links_Auf (1.019), 10/2/102 E6_Fenster_Links_Stellung_Kipp (1.019), 10/2/111 E6_Fenster_Mitte_Links_Auf (1.019), 10/2/112 E6_Fenster_Mitte_Links_Stellung_Kipp (1.019), 10/2/121 E6_Fenster_Mitte_Rechts_Auf (1.019), 10/2/122 E6_Fenster_Mitte_Rechts_Stellung_Kipp (1.019), 10/2/131 E6_Fenster_Rechts_Auf (1.019), 10/2/132 E6_Fenster_Rechts_Stellung_Kipp (1.019) | 10/2/103 E6_Fenster_Links_Stellung_Auf (1.019), 10/2/113 E6_Fenster_Mitte_Links_Stellung_Auf (1.019), 10/2/123 E6_Fenster_Mitte_Rechts_Stellung_Auf (1.019), 10/2/133 E6_Fenster_Rechts_Stellung_Auf (1.019) | — |
| E6 - Küche | 0/0/111 EG_Alles_Aus (1.001), 0/0/241 Alles_Aus (1.001), 0/2/61 E6_Alles_Aus (1.001) | — | — |
| E6 - Küche | 8/5/52 Wetterstation_Helligkeit (9.000), 9/2/140 EMA_BWM_Sperren (1.003), 9/2/146 EMA_BWM_Prasenz (1.001), 9/2/150 BWM_Tag_Nacht (1.002) | 0/2/100 E6_Szenen (17.001), 0/2/101 E6_Alles_Aus (1.001), 9/2/141 EMA_BWM_Sperren_Status (1.011) | — |
| E6 - Küche | 0/2/101 E6_Alles_Aus (1.001) | — | — |
| EG - Erdgeschoss | — | 10/0/110 EG_Fenster_Offen_Status (1.019) | — |
| EG - Erdgeschoss | — | 7/2/16 E3_Sentido_Tag_Nacht (1.002), 7/2/36 E4_Sentido_Tag_Nacht (1.002) | — |
| EG - Erdgeschoss | — | 7/2/16 E3_Sentido_Tag_Nacht (1.002), 7/2/36 E4_Sentido_Tag_Nacht (1.002) | — |
| EG - Erdgeschoss | — | 9/2/9 E1_KNX_Eingang_Tag_Nacht (1.002), 9/2/29 E1_KNX_Diele_Tag_Nacht (1.002), 9/2/89 E2_KNX_Tag_Nacht (1.002) | — |
| EG - Erdgeschoss | — | 9/2/9 E1_KNX_Eingang_Tag_Nacht (1.002), 9/2/29 E1_KNX_Diele_Tag_Nacht (1.002), 9/2/89 E2_KNX_Tag_Nacht (1.002) | — |
| EG - Erdgeschoss | 9/2/0 E1_KNX_Eingang_Sperren (1.013), 9/2/20 E1_KNX_Diele_Sperren (1.013), 9/2/80 E2_KNX_Sperren (1.011) | 9/2/1 E1_KNX_Eingang_Sperren_Status (1.011), 9/2/21 E1_KNX_Diele_Sperren_Status (1.011), 9/2/81 E2_KNX_Sperren_Status (1.011) | — |
| G3 - Garten | 0/6/41 G3_Alles_Aus (1.001) | — | — |
| Garagentoröffnung bei Nummerschilderkennung | 11/1/14 Automatik_Bereit (1.003), 14/3/6 Nummerschilderkennung (5.010) | — | — |
| Gasmelder Alarm | 10/1/31 K3_Gas_Melder (1.011), 10/1/71 K4_Gas_Melder (1.011) | — | — |
| Geladene Energie | 15/6/15 Zaehlerstand_Aktuell (13.001), 15/6/16 Zaehlerstand_Ladebeginn (13.001) | 15/6/14 Geladene_Energie (13.001) | — |
| Initialisierung | — | 14/1/4 EMA_Zustaende_aktualisieren (1.001) | — |
| K1 - Flur | 8/5/52 Wetterstation_Helligkeit (9.000), 9/1/40 EMA_BWM_Sperren (1.003), 9/1/46 EMA_BWM_Prasenz (1.001) | 9/1/41 EMA_BWM_Sperren_Status (1.011), 9/1/42 BWM_Decke_Praesenz_Eingang (1.001) | — |
| K2 - Garage | 8/5/52 Wetterstation_Helligkeit (9.000), 9/1/100 EMA_BWM_Sperren (1.003), 9/1/106 EMA_BWM_Prasenz (1.001) | 9/1/101 EMA_BWM_Sperren_Status (1.011), 9/1/102 BWM_Decke_Praesenz_Eingang (1.001) | — |
| KG - Kellergeschoss | — | 10/0/100 KG_Fenster_Offen_Status (1.001) | — |
| KG - Kellergeschoss | — | 9/1/9 K1_KNX_Decke_Tag_Nacht (1.002), 9/1/29 K1_KNX_Wand_Tag_Nacht (1.002), 9/1/69 K2_KNX_Decke_Nacht_Tag (1.002), 9/1/129 K3_KNX_Nacht_Tag (1.002), 9/1/149 K4_KNX_Nacht_Tag (1.002), 9/1/169 K5_KNX_Nacht_Tag (1.002) | — |
| KG - Kellergeschoss | — | 9/1/9 K1_KNX_Decke_Tag_Nacht (1.002), 9/1/29 K1_KNX_Wand_Tag_Nacht (1.002), 9/1/69 K2_KNX_Decke_Nacht_Tag (1.002), 9/1/129 K3_KNX_Nacht_Tag (1.002), 9/1/149 K4_KNX_Nacht_Tag (1.002), 9/1/169 K5_KNX_Nacht_Tag (1.002) | — |
| KG - Kellergeschoss | 9/1/0 K1_KNX_Decke_Sperren (1.013), 9/1/20 K1_KNX_Wand_Sperren (1.013) | 9/1/1 K1_KNX_Decke_Sperren_Status (1.011), 9/1/21 K1_KNX_Wand_Sperren_Status (1.011) | — |
| Luftfeuchtigkeit Alarm | 8/2/35 E2_Luftfeuchtigkeit_Alarm_1 (1.005), 8/2/36 E2_Luftfeuchtigkeit_Alarm_2 (1.005), 8/2/65 E3_Luftfeuchtigkeit_Alarm_1 (1.005), 8/2/66 E3_Luftfeuchtigkeit_Alarm_2 (1.005), 8/2/95 E4_Luftfeuchtigkeit_Alarm_1 (1.005), 8/2/96 E4_Luftfeuchtigkeit_Alarm_2 (1.005), 8/2/125 E5_Luftfeuchtigkeit_Alarm_1 (1.005), 8/2/126 E5_Luftfeuchtigkeit_Alarm_2 (1.005), 8/2/155 E6_Luftfeuchtigkeit_Alarm_1 (1.005), 8/2/156 E6_Luftfeuchtigkeit_Alarm_2 (1.005) | — | — |
| Luftfeuchtigkeit Alarm | 8/3/35 O2_Luftfeuchtigkeit_Alarm_1 (1.005), 8/3/36 O2_Luftfeuchtigkeit_Alarm_2 (1.005), 8/3/65 O3_Luftfeuchtigkeit_Alarm_1 (1.005), 8/3/66 O3_Luftfeuchtigkeit_Alarm_2 (1.005), 8/3/95 O4_Luftfeuchtigkeit_Alarm_1 (1.005), 8/3/96 O4_Luftfeuchtigkeit_Alarm_2 (1.005), 8/3/125 O5_Luftfeuchtigkeit_Alarm_1 (1.005), 8/3/126 O5_Luftfeuchtigkeit_Alarm_2 (1.005), 8/3/155 O6_Luftfeuchtigkeit_Alarm_1 (1.005), 8/3/156 O6_Luftfeuchtigkeit_Alarm_2 (1.005), 8/3/215 O8_Luftfeuchtigkeit_Alarm_1 (1.005), 8/3/216 O8_Luftfeuchtigkeit_Alarm_3 (1.005) | — | — |
| Lüftermodus - Manuell / Automatik | 6/0/201 Lueftermodi_Status (5.010) | — | — |
| Lüftermodus - Status senden | 6/0/200 Lueftermodi (5.010) | 6/0/201 Lueftermodi_Status (5.010) | — |
| Lüfterstufe - Manuell | 6/0/200 Lueftermodi (5.010) | — | — |
| Lüfterstufe setzen | — | 15/3/5 Lueftung_Away (1.017), 15/3/7 Lueftung_Niedrig (1.001), 15/3/9 Lueftung_Mittel (1.001), 15/3/11 Lueftung_Hoch (1.001) | — |
| Meldung Bewässerung | 15/5/12 Kreislauf_1_Ein_Aus_Status (1.011) | — | — |
| Meldungen Sabotage | 14/1/5 Deckelkontakt (1.011), 14/1/6 ASG (1.011), 14/1/7 OSG (1.011), 14/1/8 Wandabreisskontakt (1.011) | — | — |
| Meldungen Sicherungsbereich | 14/3/200 Scharf_Status (1.011), 14/3/201 Unscharf_Status (1.001) | — | — |
| Meldungen Störung | 14/1/9 Netz (1.011), 14/1/10 Akku (1.011), 14/1/11 Uebertragungseinrichtung (1.011), 14/1/30 Stroerung (1.011) | — | — |
| Meldungen Terrasse EMA Extern Scharf | 14/3/121 Person (1.005), 14/3/131 Gesprach (1.005), 14/3/132 Sirene (1.005), 14/3/133 Glasbruch (1.005), 14/3/134 Einbruch (1.005) | — | — |
| Meldungen Wohnzimmer EMA Extern Scharf | 14/3/81 Person (1.005), 14/3/91 Gesprach (1.005), 14/3/92 Sirene (1.005), 14/3/93 Glasbruch (1.005), 14/3/94 Einbruch (1.005) | — | — |
| O1 - Flur | 10/3/1 O1_Fenster_Treppe_Auf (1.019), 10/3/2 O1_Fenster_Treppe_Stellung_Kipp (1.019), 10/3/11 O1_Fenster_Galerie_Auf (1.019), 10/3/12 O1_Fenster_galerie_Stellung_Kipp (1.019) | 10/3/3 O1_Fenster_Treppe_Stellung_Auf (1.019), 10/3/13 O1_Fenster_Stellung_Galerie_Auf (1.019) | — |
| O1 - Flur (Gang) | 8/5/52 Wetterstation_Helligkeit (9.000), 9/3/60 EMA_BWM_Sperren (1.003), 9/3/66 EMA_BWM_Prasenz (1.001) | 9/3/27 BWM_Gang_Praesenz_Eingang (1.001), 9/3/61 EMA_BWM_Sperren_Status (1.011) | — |
| O1 - Flur (Treppe) | 8/5/52 Wetterstation_Helligkeit (9.000), 9/3/40 EMA_BWM_Sperren (1.003), 9/3/46 EMA_BWM_Prasenz (1.001) | 9/3/27 BWM_Gang_Praesenz_Eingang (1.001), 9/3/41 EMA_BWM_Sperren_Status (1.011) | — |
| O2 - Abstellraum | 10/3/21 O2_Fenster_Auf (1.019), 10/3/22 O2_Fenster_Stellung_Kipp (1.019) | 10/3/23 O2_Fenster_Stellung_Auf (1.019) | — |
| O2 - Abstellraum | 0/3/21 O2_Alles_Aus (1.001) | — | — |
| O3 - Badezimmer Kinder | 10/3/31 O3_Fenster_Auf (1.019), 10/3/32 O3_Fenster_Stellung_Kipp (1.019) | 10/3/33 O3_Fenster_Stellung_Auf (1.019) | — |
| O3 - Badezimmer Kinder | 0/3/41 Alles_Aus (1.001), 9/3/100 Sperren (1.003), 9/3/107 Prasenz (1.001), 9/3/109 Tag_Nacht (1.002) | — | — |
| O3 - Badezimmer Kinder | 0/3/41 O3_Alles_Aus (1.001) | — | — |
| O4 - Schlafzimmer Gregory | 0/0/121 OG_Alles_Aus (1.001), 0/0/241 Alles_Aus (1.001), 0/3/61 O4_Alles_Aus (1.001) | — | — |
| O4 - Schlafzimmer Gregory | 0/3/61 O4_Alles_Aus (1.001) | — | — |
| O4 - Schlafzimmer Luis | 0/3/81 O5_Alles_Aus (1.001) | — | — |
| O5 - Schlafzimmer Luis | 0/0/121 OG_Alles_Aus (1.001), 0/0/241 Alles_Aus (1.001), 0/3/81 O5_Alles_Aus (1.001) | — | — |
| O6 - Schlafzimmer Eltern | 0/0/121 OG_Alles_Aus (1.001), 0/0/241 Alles_Aus (1.001), 0/3/101 O6_Alles_Aus (1.001) | — | — |
| O6 - Schlafzimmer Eltern | 0/3/101 Alles_Aus (1.001), 9/3/160 Sperren (1.003), 9/3/167 Prasenz (1.001), 9/3/169 Tag_Nacht (1.002) | — | — |
| O6 - Schlafzimmer Eltern | 0/3/101 O6_Alles_Aus (1.001) | — | — |
| O8 - Badezimmer Eltern | 10/3/81 O8_Fenster_Auf (1.019), 10/3/82 O8_Fenster_Stellung_Kipp (1.019) | 10/3/83 O8_Fenster_Stellung_Auf (1.019) | — |
| O8 - Badezimmer Eltern | 0/3/141 Alles_Aus (1.001), 9/3/200 Sperren (1.003), 9/3/207 Prasenz (1.001), 9/3/209 Tag_Nacht (1.002) | — | — |
| O8 - Badezimmer Eltern | 0/3/141 O8_Alles_Aus (1.001) | — | — |
| OG - Obergeschoss | — | 10/0/120 OG_Fenster_Offen_Status (1.019) | — |
| OG - Obergeschoss | — | 7/3/16 O2_Tag_Nacht (1.002), 7/3/36 O3_Tag_Nacht (1.002), 7/3/56 O4_Tag_Nacht (1.002), 7/3/76 O5_Tag_Nacht (1.002), 7/3/96 O6_Tag_Nacht (1.002), 7/3/116 O6_Links_Tag_Nacht (1.002), 7/3/136 O6_Rechts_Tag_Nacht (1.002), 7/3/156 O8_Tag_Nacht (1.002) | — |
| OG - Obergeschoss | — | 7/3/16 O2_Tag_Nacht (1.002), 7/3/36 O3_Tag_Nacht (1.002), 7/3/56 O4_Tag_Nacht (1.002), 7/3/76 O5_Tag_Nacht (1.002), 7/3/96 O6_Tag_Nacht (1.002), 7/3/116 O6_Links_Tag_Nacht (1.002), 7/3/136 O6_Rechts_Tag_Nacht (1.002), 7/3/156 O8_Tag_Nacht (1.002) | — |
| OG - Obergeschoss | 9/3/20 O1_KNX_Sperren (1.013), 9/3/100 O3_KNX_Sperren (1.013), 9/3/160 O6_KNX_Sperren (1.011), 9/3/180 O7_KNX_Sperren (1.011), 9/3/200 O8_KNX_Sperren (1.011) | 9/3/21 O1_KNX_Sperren_Status (1.011), 9/3/101 O3_KNX_Sperren_Status (1.011), 9/3/161 O6_KNX_Sperren_Status (1.011), 9/3/181 O7_KNX_Sperren_Status (1.011), 9/3/201 O8_KNX_Sperren_Status (1.011) | — |
| OG - Obergeschoss | — | 9/3/29 O1_KNX_Gang_Tag_Nacht (1.002), 9/3/109 O3_KNX_Tag_Nacht (1.002), 9/3/169 O6_KNX_Tag_Nacht (1.002), 9/3/189 O7_KNX_Tag_Nacht (1.002), 9/3/209 O8_KNX_Tag_Nacht (1.002) | — |
| OG - Obergeschoss | 9/3/207 O8_Prasenz (1.001) | 9/3/29 O1_KNX_Gang_Tag_Nacht (1.002), 9/3/109 O3_KNX_Tag_Nacht (1.002), 9/3/169 O6_KNX_Tag_Nacht (1.002), 9/3/189 O7_KNX_Tag_Nacht (1.002), 9/3/209 O8_KNX_Tag_Nacht (1.002), 9/3/210 O8_Slave (1.001) | — |
| PV Erzeugung Gesamt | 15/4/21 WR_1_Leistung (14.000), 15/4/41 WR_2_Leistung (14.000) | 15/4/10 PV_Erzeugung_Gesamt (14.000) | — |
| Relais 1 - Garagentor sperren | 11/1/10 Garagentor_Sperren (1.001), 14/1/61 Relais_1_Ein_Aus_Status (1.011) | 11/1/11 Garagentor_Sperren_Status (1.001), 14/1/60 Relais_1_Ein_Aus (1.001) | — |
| Relais 2 - Garagentor fahren | 11/1/16 Garagentor_Fahren (1.001) | 14/1/62 Relais_2_Ein_Aus (1.001) | — |
| Scharfschaltung bei Gute Nacht | — | 14/1/20 Unscharf (1.001), 14/1/22 Intern_Scharf (1.001) | — |
| Sicherungsbereich Status | 14/1/21 Unscharf_Status (1.001), 14/1/23 Intern_Scharf_Status (1.011), 14/1/26 Extern_Scharf_Status (1.011), 14/1/28 Alarm (1.011) | — | — |
| Sommer/Winter | — | 0/0/248 Sommer_Winter (1.002) | — |
| Sony TV Status - Schlafzimmer Eltern | 12/3/121 Ein_Aus (1.001), 12/3/123 Stummschalten (1.001), 12/3/125 Lautstarke (5.001) | 12/3/122 Ein_Aus_Status (1.011), 12/3/124 Stummschalten_Status (1.001), 12/3/126 Lautstarke_Status (5.001) | — |
| Sony TV Status - Wohnzimmer | 12/2/101 Ein_Aus (1.003), 12/2/103 Stummschalten (1.001), 12/2/105 Lautstarke (5.001) | 12/2/102 Ein_Aus_Status (1.011), 12/2/104 Stummschalten_Status (1.001), 12/2/106 Lautstarke_Status (5.001) | — |
| Statustext - DC Fehlerstrom | 15/6/6 DC_Fehlerstrom_Status (5.010) | 15/6/7 DC_Fehlerstrom_Statustext (16.001) | — |
| Statustext - Fehlerzustand | 15/6/0 Fehlerzustand_Status (5.010) | 15/6/1 Fehlerzustand_Statustext (16.001) | — |
| Statustext - IEC61851 | 15/6/4 IEC61851_Status (5.010) | 15/6/5 IEC61851_Statustext (16.001) | — |
| Statustext - Ladecontroller | 15/6/2 Ladecontroller_Status (5.010) | 15/6/3 Ladecontroller_Statustext (16.001) | — |
| Statustext - Lademodus | 15/6/23 Lademodi_Status (5.010) | 15/6/24 Lademodi_Statustext (16.001) | — |
| Statustext - Schütz Fehler | 15/6/8 Schuetz_Status (5.010) | 15/6/9 Schuetz_Statustext (16.001) | — |
| Strom - Einspeisung | 15/1/7 Einspeisung_Zaehlerstand_Gesamt_1 (13.001), 15/1/9 Einspeisung_Zaehlerstand_Tagtarif_1 (13.001), 15/1/11 Einspeisung_Zaehlerstand_Nachtarif_1 (13.001), 15/1/13 Einspeisung_Wirkleistung_Gesamt_1 (14.000) | 15/1/8 Einspeisung_Zaehlerstand_Gesamt_2 (13.001), 15/1/10 Einspeisung_Zaehlerstand_Tagtarif_2 (13.001), 15/1/12 Einspeisung_Zaehlerstand_Nachtarif_2 (13.001), 15/1/14 Einspeisung_Wirkleistung_Gesamt_2 (14.000) | — |
| Strom - Einspeisung Gesamt | 15/1/9 Einspeisung_Zaehlerstand_Tagtarif_1 (13.001), 15/1/11 Einspeisung_Zaehlerstand_Nachtarif_1 (13.001) | 15/1/7 Einspeisung_Zaehlerstand_Gesamt_1 (13.001) | — |
| Strom - Netzbezug Gesamt | 15/1/1 Netzbezug_Zaehlerstand_Tagtarif (13.001), 15/1/2 Netzbezug_Zaehlerstand_Nachtarif (13.001) | 15/1/0 Netzbezug_Zaehlerstand_Gesamt (13.001) | — |
| Strom - Wirkleistung Gesamt | 15/1/3 Netzbezug_Wirkleistung_Gesamt (14.000), 15/1/13 Einspeisung_Wirkleistung_Gesamt_1 (14.000) | 15/1/24 Wirkleistung_Gesamt (14.000) | — |
| Trockner - Programmaktionen | 9/1/167 BWM_Praesenz (1.001) | — | — |
| Waschmaschine - Programmaktionen | 9/1/167 BWM_Praesenz (1.001) | — | — |
| Wasser - Durchfluss | 15/1/26 Durchfluss (14.000), 15/1/33 Skalenumschaltung (1.002) | 15/1/27 Durchfluss_Skala1 (14.000), 15/1/28 Durchfluss_Skala2 (14.000) | — |
| Wasser - Erweiteter Durchflussalarm | 15/1/29 Skala1_Alarm (1.001), 15/1/30 Skala2_Alarm (1.001) | 15/1/31 Skala1_Alarm_Erweitert (1.001), 15/1/32 Skala2_Alarm_Erweitert (1.001) | — |
| Wassermelder Alarm | 10/1/51 K3_Wassermelder (1.011), 10/1/91 K5_Wassermelder (1.011), 10/2/21 E1_Wassermelder (1.011), 10/2/141 E6_Wassermelder1 (1.011), 10/2/151 E6_Wassermelder2 (1.011), 10/2/161 E6_Wassermelder3 (1.011), 10/3/71 O6_Wassermelder (1.011) | — | — |
| Zehnder Automatik deaktivieren | — | 15/3/3 Belueftung_Lueftermodus_Auto (1.001) | — |

## All blocks

| Block | Nodes | Node types |
|---|---:|---|
| (unnamed) | 10 | and×1, knxbool×3, linkinput×1, not×2, openclosedevice×1 |
| 1 Minute | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| 1 Stunde | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| 10 Minuten | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| 2 Minuten | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| 3 Stunden | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| 30 Minuten | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| 5 Minuten | 4 | init×1, linkoutput×1, oscillator×1, setbool×1 |
| A1 - Fassade | 6 | daylight×1, delay×1, lights×1, multiplexer×1, setbool×1, when×1 |
| A2 - Eingang | 6 | daylight×1, delay×1, lights×1, multiplexer×1, setbool×1, when×1 |
| A2 - Terrasse | 18 | init×2, interlock×2, knxbool×2, linkoutput×4, memory×2, multiplexer×2, not×2, scenes×2 |
| A3/A4/A5 - Terrasse / Balkon / Garten | 23 | and×1, area×2, daylight×1, delay×1, lights×4, not×3, openclosedevice×2, or×1, setbool×2, setpercentage×2, setreset×1, when×1 |
| A5 - Dach | 15 | delay×3, init×1, knxbool×2, memory×1, multiplexer×1, not×1, notification×1, setbool×2 |
| Alarmauslösung EMA Extern Scharf | 17 | and×1, audio_notification×1, daylight×1, gate×1, knxbool×2, lights×3, linkinput×2, multiplexer×2, notification×1, setbool×2, setpercentage×1 |
| Alarmauslösung EMA Intern Scharf | 18 | and×1, audio_notification×1, daylight×1, gate×1, knxbool×4, lights×3, linkinput×2, multiplexer×2, setbool×2, setpercentage×1 |
| An/Abwesend - Home Szenen | 5 | linkinput×2, not×1, or×1, scenes×1 |
| An/Abwesend - Meldung | 17 | compare×2, debouncer×2, gate×1, linkinput×2, memory×1, not×1, notification×2, or×1 |
| An/Abwesend - Zustand | 8 | debouncer×2, init×1, knxbool×2, linkoutput×2, memory×1 |
| Anomalie Temperatur | 12 | changedetector×2, knxnumber×2, lookuptable×2, notification×6 |
| Anomalie Therme | 6 | changedetector×1, knxnumber×1, lookuptable×1, notification×3 |
| Anomalie Warmwasser | 12 | changedetector×2, knxnumber×2, lookuptable×2, notification×6 |
| Automatik Bereit - Präsenzfenster | 6 | linkinput×2, linkoutput×1, multiplexer×1, oneshot×1 |
| Automatik Bereit - Status senden | 7 | init×1, knxbool×2, linkinput×1, memory×1, multiplexer×1 |
| Automatik Sperren - Status senden | 7 | init×1, knxbool×2, linkinput×1, memory×1, multiplexer×1 |
| CO 2 Alarm | 36 | changedetector×3, knxbool×15, linkinput×3, linkoutput×3, memory×3, or×3 |
| CO 2 Alarm | 39 | changedetector×3, knxbool×18, linkinput×3, linkoutput×3, memory×3, or×3 |
| CO-Melder Alarm | 3 | changedetector×1, knxbool×1, notification×1 |
| DG - Dachgeschoss | 10 | changedetector×3, debouncer×3, genericdevice×1, notification×3 |
| DG - Dachgeschoss | 5 | knxbool×1, linkinput×1, scenes×1, setbool×1 |
| DG - Dachgeschoss | 4 | knxbool×1, scenes×1, setbool×1 |
| E1 - Flur | 9 | and×1, changedetector×1, knxbool×3, linkinput×1, memory×1, not×1 |
| E1 - Flur | 9 | init×1, knxbool×4, knxnumber×1, memory×1, motion_detection×1, not×1 |
| E2 - Gäste WC | 9 | and×1, changedetector×1, knxbool×3, linkinput×1, memory×1, not×1 |
| E3 - Büro | 5 | audioroom×1, knxbool×3, multiplexer×1 |
| E3 - Büro | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| E3 - Büro | 36 | and×4, changedetector×4, knxbool×12, linkinput×4, memory×4, not×4 |
| E3 - Büro | 19 | init×1, knxbool×5, knxnumber×2, memory×2, motion_detection×1, multiplexer×1, not×2, pacer×1, scenes×1, setnumber×2 |
| E3 - Büro | 10 | init×1, interlock×1, knxbool×1, linkoutput×2, memory×1, multiplexer×2, not×1, scenes×1 |
| E4 - Wohnzimmer | 5 | knxbool×3, multiplexer×1, television×1 |
| E4 - Wohnzimmer | 19 | init×1, knxbool×5, knxnumber×2, memory×2, motion_detection×1, multiplexer×1, not×2, pacer×1, scenes×1, setnumber×2 |
| E4 - Wohnzimmer | 12 | init×1, interlock×1, knxbool×1, linkoutput×3, memory×1, multiplexer×3, not×1, scenes×1 |
| E5 - Esszimmer | 12 | init×1, interlock×1, knxbool×1, linkoutput×3, memory×1, multiplexer×3, not×1, scenes×1 |
| E6 - Küche | 16 | delay×1, gate×1, init×1, lights×2, memory×1, multiplexer×1, scenes×2, setbool×1, setpercentage×2 |
| E6 - Küche | 36 | and×4, changedetector×4, knxbool×12, linkinput×4, memory×4, not×4 |
| E6 - Küche | 5 | audioroom×1, knxbool×3, multiplexer×1 |
| E6 - Küche | 19 | init×1, knxbool×5, knxnumber×2, memory×2, motion_detection×1, multiplexer×1, not×2, pacer×1, scenes×1, setnumber×2 |
| E6 - Küche | 12 | init×1, interlock×1, knxbool×1, linkoutput×3, memory×1, multiplexer×3, not×1, scenes×1 |
| E6 - Küche Links | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| E6 - Küche Rechts | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| EG - Erdgeschoss | 35 | changedetector×1, knxbool×1, linkinput×1, memory×1, not×13, openclosedevice×13, or×4 |
| EG - Erdgeschoss | 18 | genericdevice×2, not×7, openclosedevice×7, or×2 |
| EG - Erdgeschoss | 50 | changedetector×15, debouncer×15, genericdevice×5, notification×15 |
| EG - Erdgeschoss | 38 | memory×1, multiplexer×1, not×13, notification×6, openclosedevice×13, or×3, scenes×1 |
| EG - Erdgeschoss | 7 | knxbool×2, linkinput×1, scenes×2, setbool×2 |
| EG - Erdgeschoss | 6 | knxbool×2, scenes×2, setbool×2 |
| EG - Erdgeschoss | 8 | knxbool×3, scenes×2, setbool×2 |
| EG - Erdgeschoss | 9 | knxbool×3, linkinput×1, scenes×2, setbool×2 |
| EG - Erdgeschoss | 15 | changedetector×3, knxbool×6, linkinput×3, memory×3 |
| G3 - Garten | 10 | init×1, interlock×1, knxbool×1, linkoutput×2, memory×1, multiplexer×2, not×1, scenes×1 |
| Garagentoröffnung bei Nummerschilderkennung | 8 | gate×1, knxbool×1, knxnumber×1, lookuptable×1, oneshot×1, openclosedevice×1 |
| Gasmelder Alarm | 6 | changedetector×2, knxbool×2, notification×2 |
| Gefriehrschrank - Türe auf | 29 | and×2, changedetector×1, chrono×1, compare×4, genericdevice×1, init×3, linkinput×1, linkoutput×1, multiplexer×1, not×3, notification×1, setnumber×6, t |
| Geladene Energie | 7 | divide×1, init×1, knxnumber×3, setnumber×1, subtract×1 |
| Initialisierung | 6 | delay×1, init×1, knxbool×1, linkinput×1, multiplexer×1 |
| K1 - Flur | 9 | init×1, knxbool×4, knxnumber×1, memory×1, motion_detection×1, not×1 |
| K2 - Garage | 9 | init×1, knxbool×4, knxnumber×1, memory×1, motion_detection×1, not×1 |
| KG - Kellergeschoss | 16 | changedetector×1, knxbool×1, linkinput×1, memory×1, not×5, openclosedevice×5, or×1 |
| KG - Kellergeschoss | 18 | memory×1, multiplexer×1, not×5, notification×4, openclosedevice×5, or×1, scenes×1 |
| KG - Kellergeschoss | 40 | changedetector×12, debouncer×12, genericdevice×4, notification×12 |
| KG - Kellergeschoss | 17 | knxbool×6, scenes×5, setbool×5 |
| KG - Kellergeschoss | 18 | knxbool×6, linkinput×1, scenes×5, setbool×5 |
| KG - Kellergeschoss | 10 | changedetector×2, knxbool×4, linkinput×2, memory×2 |
| KG - Kellergeschoss | 6 | changedetector×2, genericdevice×4 |
| Kühlschrank - Türe auf | 29 | and×2, changedetector×1, chrono×1, compare×4, genericdevice×1, init×3, linkinput×1, linkoutput×1, multiplexer×1, not×3, notification×1, setnumber×6, t |
| Luftfeuchtigkeit Alarm | 24 | changedetector×2, knxbool×10, linkinput×2, linkoutput×2, memory×2, or×2 |
| Luftfeuchtigkeit Alarm | 26 | changedetector×2, knxbool×12, linkinput×2, linkoutput×2, memory×2, or×2 |
| Lüftermodus - Automatik im Sensorprofil | 6 | and×1, linkinput×2, linkoutput×1, not×1 |
| Lüftermodus - Automatik im Szenenprofil | 14 | and×1, linkinput×9, linkoutput×1, or×1 |
| Lüftermodus - Manuell / Automatik | 7 | compare×1, init×1, knxnumber×1, linkoutput×1, setnumber×1 |
| Lüftermodus - Status senden | 7 | init×1, knxnumber×2, linkinput×1, memory×1, multiplexer×1 |
| Lüfterstufe - Manuell | 7 | debouncer×1, gate×1, knxnumber×1, linkinput×1, linkoutput×1, not×1 |
| Lüfterstufe - Sensormodus | 29 | and×3, debouncer×1, gate×1, linkinput×7, linkoutput×1, multiplexer×1, not×2, or×3, setbool×3, setnumber×3 |
| Lüfterstufe - Szenenmodus | 21 | gate×1, linkinput×9, linkoutput×1, multiplexer×1, setnumber×8 |
| Lüfterstufe setzen | 9 | knxbool×4, linkinput×3, lookuptable×1, multiplexer×1 |
| Meldung Bewässerung | 5 | changedetector×1, knxbool×1, not×1, notification×2 |
| Meldungen Sabotage | 12 | changedetector×4, knxbool×4, notification×4 |
| Meldungen Sicherungsbereich | 19 | changedetector×4, delay×1, linkinput×4, memory×1, multiplexer×1, not×1, notification×5, scenes×1 |
| Meldungen Sicherungsbereich | 6 | changedetector×2, knxbool×2, notification×2 |
| Meldungen Störung | 12 | changedetector×4, knxbool×4, notification×4 |
| Meldungen Terrasse EMA Extern Scharf | 16 | gate×1, knxbool×5, linkinput×2, multiplexer×1, notification×5, setbool×2 |
| Meldungen Wohnzimmer EMA Extern Scharf | 16 | gate×1, knxbool×5, linkinput×2, multiplexer×1, notification×5, setbool×2 |
| O1 - Flur | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| O1 - Flur | 18 | and×2, changedetector×2, knxbool×6, linkinput×2, memory×2, not×2 |
| O1 - Flur (Gang) | 9 | init×1, knxbool×4, knxnumber×1, memory×1, motion_detection×1, not×1 |
| O1 - Flur (Treppe) | 9 | init×1, knxbool×4, knxnumber×1, memory×1, motion_detection×1, not×1 |
| O2 - Abstellraum | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| O2 - Abstellraum | 9 | and×1, changedetector×1, knxbool×3, linkinput×1, memory×1, not×1 |
| O2 - Abstellraum | 10 | init×1, interlock×1, knxbool×1, linkoutput×2, memory×1, multiplexer×2, not×1, scenes×1 |
| O3 - Badezimmer Kinder | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| O3 - Badezimmer Kinder | 9 | and×1, changedetector×1, knxbool×3, linkinput×1, memory×1, not×1 |
| O3 - Badezimmer Kinder | 16 | delay×1, gate×1, knxbool×4, multiplexer×1, not×3, or×1, scenes×1, setbool×1 |
| O3 - Badezimmer Kinder | 18 | debouncer×3, gate×1, genericdevice×1, linkinput×1, memory×1, not×2, setbool×1, windowtreatments×2 |
| O3 - Badezimmer Kinder | 13 | changedetector×1, init×1, interlock×1, knxbool×1, linkinput×1, linkoutput×2, memory×1, multiplexer×1, not×2, oneshot×1, scenes×1 |
| O3 - Badezimmer Kinder | 7 | genericdevice×1, linkinput×1, not×2, setbool×1 |
| O4 - Schlafzimmer Gregory | 8 | linkinput×2, memory×2, not×1, windowtreatments×2 |
| O4 - Schlafzimmer Gregory | 5 | audioroom×1, knxbool×3, multiplexer×1 |
| O4 - Schlafzimmer Gregory | 10 | init×1, interlock×1, knxbool×1, linkoutput×2, memory×1, multiplexer×2, not×1, scenes×1 |
| O4 - Schlafzimmer Luis | 10 | init×1, interlock×1, knxbool×1, linkoutput×2, memory×1, multiplexer×2, not×1, scenes×1 |
| O5 - Schlafzimmer Luis | 8 | linkinput×2, memory×2, not×1, windowtreatments×2 |
| O5 - Schlafzimmer Luis | 5 | audioroom×1, knxbool×3, multiplexer×1 |
| O6 - Schlafzimmer Eltern | 8 | linkinput×2, memory×2, not×1, windowtreatments×2 |
| O6 - Schlafzimmer Eltern | 5 | knxbool×3, multiplexer×1, television×1 |
| O6 - Schlafzimmer Eltern | 16 | delay×1, gate×1, knxbool×4, multiplexer×1, not×3, or×1, scenes×1, setbool×1 |
| O6 - Schlafzimmer Eltern | 10 | init×1, interlock×1, knxbool×1, linkoutput×2, memory×1, multiplexer×2, not×1, scenes×1 |
| O8 - Badezimmer Eltern | 16 | delay×2, linkinput×2, memory×2, multiplexer×3, not×1, setpercentage×4, windowtreatments×2 |
| O8 - Badezimmer Eltern | 9 | and×1, changedetector×1, knxbool×3, linkinput×1, memory×1, not×1 |
| O8 - Badezimmer Eltern | 21 | debouncer×3, gate×1, genericdevice×1, linkinput×2, memory×1, multiplexer×1, not×3, setbool×1, windowtreatments×2 |
| O8 - Badezimmer Eltern | 10 | genericdevice×1, linkinput×2, multiplexer×1, not×3, setbool×1 |
| O8 - Badezimmer Eltern | 16 | delay×1, gate×1, knxbool×4, multiplexer×1, not×3, or×1, scenes×1, setbool×1 |
| O8 - Badezimmer Eltern | 20 | changedetector×2, init×1, interlock×1, knxbool×1, linkinput×2, linkoutput×4, memory×1, multiplexer×2, not×3, oneshot×2, scenes×1 |
| OG - Obergeschoss | 22 | changedetector×1, knxbool×1, linkinput×1, memory×1, not×8, openclosedevice×8, or×1 |
| OG - Obergeschoss | 21 | genericdevice×7, not×7, openclosedevice×7 |
| OG - Obergeschoss | 60 | changedetector×18, debouncer×18, genericdevice×6, notification×18 |
| OG - Obergeschoss | 27 | memory×1, multiplexer×1, not×8, notification×7, openclosedevice×8, or×1, scenes×1 |
| OG - Obergeschoss | 21 | knxbool×8, linkinput×1, scenes×6, setbool×6 |
| OG - Obergeschoss | 20 | knxbool×8, scenes×6, setbool×6 |
| OG - Obergeschoss | 25 | changedetector×5, knxbool×10, linkinput×5, memory×5 |
| OG - Obergeschoss | 16 | knxbool×5, scenes×5, setbool×5 |
| OG - Obergeschoss | 21 | and×1, knxbool×7, linkinput×1, scenes×5, setbool×5 |
| PV Erzeugung Gesamt | 9 | add×1, compare×1, init×1, knxnumber×3, memory×1, setnumber×1 |
| Relais 1 - Garagentor sperren | 8 | knxbool×4, not×2 |
| Relais 2 - Garagentor fahren | 3 | knxbool×2 |
| Scharfschaltung bei Gute Nacht | 3 | knxbool×2, scenes×1 |
| Sicherungsbereich Status | 8 | knxbool×4, linkoutput×4 |
| Sommer/Winter | 11 | changedetector×1, compare×1, init×2, knxbool×1, linkinput×1, memory×1, multiplexer×1, setnumber×1, weatherstation×1 |
| Sonnenaufgang oder 6:00 | 18 | daylight×1, init×2, linkoutput×1, lookuptable×1, memory×1, modulo×1, multiplexer×2, numberincrement×1, setnumber×2, when×2 |
| Sonnenaufgang und 6:00 | 18 | daylight×1, init×2, linkoutput×1, lookuptable×1, memory×1, modulo×1, multiplexer×2, numberincrement×1, setnumber×2, when×2 |
| Sonnenaufgang und 7:10/9:00 | 22 | daylight×1, delay×1, init×2, linkoutput×1, lookuptable×1, memory×1, modulo×1, multiplexer×2, numberincrement×1, setnumber×2, when×3 |
| Sonnenaufgang und 7:45/9:00 | 22 | daylight×1, delay×1, init×2, linkoutput×1, lookuptable×1, memory×1, modulo×1, multiplexer×2, numberincrement×1, setnumber×2, when×3 |
| Sonnenuntergang oder 21:30 | 19 | daylight×1, delay×1, init×2, linkoutput×1, lookuptable×1, memory×1, modulo×1, multiplexer×2, numberincrement×1, setnumber×2, when×2 |
| Sonnenuntergang oder 22:00 | 19 | daylight×1, delay×1, init×2, linkoutput×1, lookuptable×1, memory×1, modulo×1, multiplexer×2, numberincrement×1, setnumber×2, when×2 |
| Sony TV Status - Schlafzimmer Eltern | 10 | debouncer×1, init×1, knxbool×4, knxpercentage×2, memory×1, television×1 |
| Sony TV Status - Wohnzimmer | 10 | debouncer×1, init×1, knxbool×4, knxpercentage×2, memory×1, television×1 |
| Statustext - DC Fehlerstrom | 11 | knxnumber×1, knxstring×1, lookuptable×1, multiplexer×1, setstring×7 |
| Statustext - Fehlerzustand | 9 | knxnumber×1, knxstring×1, lookuptable×1, multiplexer×1, setstring×5 |
| Statustext - IEC61851 | 9 | knxnumber×1, knxstring×1, lookuptable×1, multiplexer×1, setstring×5 |
| Statustext - Ladecontroller | 9 | knxnumber×1, knxstring×1, lookuptable×1, multiplexer×1, setstring×5 |
| Statustext - Lademodus | 7 | knxnumber×1, knxstring×1, lookuptable×1, multiplexer×1, setstring×3 |
| Statustext - Schütz Fehler | 17 | knxnumber×1, knxstring×1, lookuptable×1, multiplexer×1, setstring×13 |
| Strom - Einspeisung | 15 | init×1, knxnumber×8, multiply×4, setnumber×1 |
| Strom - Einspeisung Gesamt | 9 | add×1, compare×1, init×1, knxnumber×3, memory×1, setnumber×1 |
| Strom - Netzbezug Gesamt | 9 | add×1, compare×1, init×1, knxnumber×3, memory×1, setnumber×1 |
| Strom - Wirkleistung Gesamt | 10 | compare×1, init×1, knxnumber×3, memory×1, setnumber×1, subtract×1 |
| Trockner - Programmaktionen | 15 | audio_notification×1, gate×1, genericdevice×1, knxbool×1, linkinput×2, multiplexer×2, notification×1, setbool×3 |
| Trockner - Status | 13 | compare×1, delay×2, genericdevice×1, init×1, linkoutput×1, multiplexer×1, not×1, setbool×2, setnumber×1 |
| Trockner - Statusänderung | 16 | compare×2, debouncer×2, gate×1, linkinput×1, linkoutput×2, memory×1, not×1, setbool×2 |
| Trockner - Strom sparen | 10 | gate×1, genericdevice×1, linkinput×1, multiplexer×1, not×1, setbool×1, when×2 |
| Waschmaschine - Programmaktionen | 15 | audio_notification×1, gate×1, genericdevice×1, knxbool×1, linkinput×2, multiplexer×2, notification×1, setbool×3 |
| Waschmaschine - Status | 13 | compare×1, delay×2, genericdevice×1, init×1, linkoutput×1, multiplexer×1, not×1, setbool×2, setnumber×1 |
| Waschmaschine - Statusänderung | 16 | compare×2, debouncer×2, gate×1, linkinput×1, linkoutput×2, memory×1, not×1, setbool×2 |
| Waschmaschine - Strom sparen | 10 | gate×1, genericdevice×1, linkinput×1, multiplexer×1, not×1, setbool×1, when×2 |
| Wasser - Durchfluss | 18 | gate×2, init×1, knxbool×1, knxnumber×3, multiplexer×2, multiply×2, not×1, setnumber×3 |
| Wasser - Erweiteter Durchflussalarm | 28 | delay×6, init×2, knxbool×4, memory×2, multiplexer×2, not×2, notification×2, setbool×4 |
| Wassermelder Alarm | 21 | changedetector×7, knxbool×7, notification×7 |
| Zehnder Automatik deaktivieren | 4 | knxbool×1, linkinput×1, setbool×1 |
| Zentral | 10 | init×1, interlock×1, linkoutput×3, memory×1, multiplexer×3, scenes×1 |
