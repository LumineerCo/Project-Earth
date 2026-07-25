# Phase 8: Civic Systems and Services

## Purpose

Add city services, lawful consequences, public transport, incident reports, and dynamic civic events.

## Enhanced Features and Functions

- Police patrol/service response.
- Clinic/medical service.
- Public transport timetable.
- Sanitation/maintenance hooks.
- Incident report model.

## Core Deliverables

- Service archetypes.
- Incident data.
- 10 civic events.
- Legal status UI.
- Transport schedule data.

## Exit Gate

At least three services respond to incidents/schedules and legal status affects fines, trust, and admin data.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Services need dispatch rules, response time, coverage area, staff/vehicle availability, and incident priority.
- Law system must separate suspicion, witnessed crime, evidence, fine, arrest, and resolved states.
- Public transport needs timetable, route stops, fare, capacity, and delay state.
- Events must affect schedules, prices, traffic, services, and news messages.

### Recommended Implementation Steps

1. Implement incident reports as data before adding complex service AI.
2. Add non-violent, consequence-focused legal responses first.
3. Use simple timetables before real-time vehicle simulation.
4. Show civic events through phone news and world signage.

### Potential Issues to Troubleshoot

- Police/service NPCs spawn endlessly.
- Legal consequences trigger without witnesses/evidence.
- Public transport breaks player schedule with no alternative.
- Events overlap and lock critical services forever.

## Troubleshooting Checklist

- Confirm the phase does not introduce paid tools, paid services, or unlicensed assets.
- Confirm all new data is versioned, validated, and safe to load after save/load cycles.
- Confirm mobile performance is protected with density, LOD, pooling, or abstract simulation controls.
- Confirm admin/security-sensitive work keeps secrets out of Git, logs, client exports, and screenshots.
- Confirm failures produce useful debug messages rather than silent corruption.

## Engineering Notes

- Prefer data-driven configuration before hard-coded content.
- Keep the implementation small enough to demo at the phase gate.
- Add automated checks as soon as a data format or save format is introduced.
- Update `ASSET_LICENSES.md` before importing any third-party asset.
