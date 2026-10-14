# Data Format Reference

> Project Earth — JSON Content Schemas
> Stage 2 — Data-Driven World Design

All world content is stored as JSON in `game-client/data/`. This document defines the schemas for each content type. Managers validate against these schemas at load time; invalid entries are logged via `DebugManager` and skipped.

---

## 1. Conventions

- All files are UTF-8 JSON, 2-space indented.
- One record per file, or an array of records in a collection file.
- IDs are `snake_case` strings, globally unique within their type.
- Units: meters for distance, seconds for time, game currency for money.
- Coordinates are `[x, z]` (Y is up; elevation derived from terrain).

---

## 2. World (`data/world/`)

Top-level world definition.

```json
{
  "id": "earth",
  "name": "Earth",
  "version": 1,
  "seed": 0,
  "scale_km": 400,
  "continents": ["continent_north_america", "continent_eurasia"]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✓ | Unique world ID |
| `name` | string | ✓ | Display name |
| `version` | int | ✓ | Schema version |
| `seed` | int | ✓ | World generation seed |
| `scale_km` | float | ✓ | World extent in km |
| `continents` | string[] | ✓ | Continent IDs |

---

## 3. Continents (`data/`)

```json
{
  "id": "continent_north_america",
  "name": "North America",
  "position": [0, 0],
  "extent_km": [4000, 3000],
  "countries": ["country_usa", "country_canada"]
}
```

---

## 4. Countries (`data/countries/`)

```json
{
  "id": "country_usa",
  "name": "United States",
  "continent": "continent_north_america",
  "currency": "USD",
  "states": ["state_california", "state_nevada"],
  "position": [1200, -800]
}
```

---

## 5. States / Regions (`data/regions/`, `data/states/`)

```json
{
  "id": "state_california",
  "name": "California",
  "country": "country_usa",
  "cities": ["city_san_francisco", "city_los_angeles"]
}
```

---

## 6. Cities (`data/cities/`)

```json
{
  "id": "city_san_francisco",
  "name": "San Francisco",
  "state": "state_california",
  "country": "country_usa",
  "position": [1180, -820],
  "population": 874961,
  "districts": ["district_downtown", "district_mission"],
  "time_zone": "America/Los_Angeles"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `position` | `[x, z]` | ✓ | World position in meters |
| `population` | int | | Lore population |
| `districts` | string[] | | District IDs |

---

## 7. Districts (`data/`)

```json
{
  "id": "district_downtown",
  "name": "Downtown",
  "city": "city_san_francisco",
  "position": [1180, -820],
  "buildings": []
}
```

---

## 8. Items (`data/items/`)

```json
{
  "id": "item_bread",
  "name": "Bread",
  "category": "food",
  "base_price": 3.50,
  "stackable": true,
  "max_stack": 99,
  "weight_kg": 0.5,
  "icon": "res://assets/icons/items/bread.png"
}
```

---

## 9. Jobs (`data/jobs/`)

```json
{
  "id": "job_barista",
  "name": "Barista",
  "hourly_wage": 18.00,
  "schedule": { "start_hour": 6, "end_hour": 14 },
  "location_type": "shop",
  "skills": ["coffee", "service"]
}
```

---

## 10. NPCs (`data/npc/`)

```json
{
  "id": "npc_template_civilian",
  "name": "Civilian",
  "type": "civilian",
  "home_city": "city_san_francisco",
  "schedule": [],
  "traits": []
}
```

---

## 11. Shops (`data/shops/`)

```json
{
  "id": "shop_grocery_mission",
  "name": "Mission Grocery",
  "type": "grocery",
  "position": [1185, -818],
  "district": "district_mission",
  "inventory": ["item_bread", "item_milk"],
  "open_hours": { "start": 7, "end": 22 }
}
```

---

## 12. Vehicles (`data/vehicles/`)

```json
{
  "id": "vehicle_sedan_civic",
  "name": "Civic",
  "type": "sedan",
  "max_speed_kmh": 180,
  "seats": 4,
  "fuel_capacity_l": 47,
  "model": "res://assets/vehicles/sedan.glb"
}
```

---

## 13. Roads (`data/roads/`)

```json
{
  "id": "road_us101_segment_42",
  "name": "US-101",
  "type": "highway",
  "points": [[1180, -820], [1190, -810]],
  "lanes": 4,
  "speed_limit_kmh": 100
}
```

---

## 14. Weather (`data/weather/`)

```json
{
  "id": "weather_fog_morning",
  "name": "Morning Fog",
  "fog_density": 0.8,
  "cloud_cover": 0.6,
  "temperature_c": 12,
  "wind_speed_ms": 1.5,
  "wind_direction_deg": 270
}
```

---

## 15. Validation

At load time, each manager:
1. Parses the JSON (errors logged via `DebugManager.log_error`).
2. Checks required fields exist (missing → `log_warn`, skip record).
3. Checks types match the schema (mismatch → `log_warn`, skip record).
4. Caches valid records in a typed dictionary keyed by `id`.

Use `tools/validate_data.gd` (Stage 2.11) to run a full validation pass offline.
