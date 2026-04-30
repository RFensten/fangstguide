# Fangstguide

Flutter-app til danske lystfiskere. Giver hurtig adgang til fiskeriregler — mindstemål, fredningstider og fangstcheck — uden at skulle grave i Landbrugsstyrelsens hjemmeside.

## Funktioner

- **Fiskeliste** — alle 29 relevante arter med mindstemål og fredningstider pr. zone
- **Fangstcheck** — vælg art, zone og mål → appen siger om fisken må tages med
- **Kalender** — overblik over hvornår arter åbner og lukker per måned
- **Offline-first** — ingen internetforbindelse nødvendig

### Premium (39 kr. engangsbeløb)
Gratis-laget dækker 10 af de mest fangede arter og indeværende måned i kalenderen. Premium låser op for alle 29 arter og fuld 12-måneders kalender.

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Navigation | GoRouter |
| Lokal storage | Hive |
| IAP | in_app_purchase |
| Data | Lokal JSON (`assets/fish_data.json`) |

## Datakilde

Reglerne er baseret på Landbrugsstyrelsens officielle bekendtgørelser:
- Saltvand 2026
- Ferskvand 2025

Data opdateres manuelt ved årsstart når nye bekendtgørelser udkommer.

## Kom i gang

```bash
flutter pub get
flutter run
```

Kræver Flutter 3.x og Dart SDK ≥ 3.3.0.

## IAP-opsætning (til udvikling)

Product ID: `fangstguide_premium`

For at teste køb i simulator/emulator skal produktet oprettes i App Store Connect (iOS) med ovenstående ID. Brug Apples sandbox-testkonti til TestFlight-test.

## Kontakt

Rasmus Fensten — rasmus.fensten@gmail.com
