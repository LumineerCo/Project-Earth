# Project Earth: Game Design Document (GDD)

## 1. Document Control

| Field | Value |
| --- | --- |
| Project codename | Project Earth |
| Genre | Realistic Earth-inspired open-world life, work, travel, business, and adventure simulation |
| Owner | Bablu K Sahu |
| Company | LumineerCo |
| Budget constraint | Rs.00 direct spend; production must use free and open-source tools, services, and assets wherever legally possible |
| Target platforms | Android mobile, low-end laptop, desktop PC |
| Document purpose | Define the full game vision, systems, technical direction, content plan, admin requirements, and production rules before implementation |

## 2. High Concept

Project Earth is a realistic, living, Earth-inspired open-world game where every NPC has a purpose, every city feels alive, and players can build their own life through exploration, work, travel, business, social interaction, survival choices, and adventure. The game is not a direct copy of Earth; it is an original fictional world inspired by real geography, cultures, professions, transportation, economies, cities, villages, nature, and daily life.

The player begins as an ordinary person with limited money, basic skills, and no fixed destiny. They can become a traveler, worker, shop owner, delivery driver, farmer, mechanic, explorer, trader, pilot, sailor, builder, artist, criminal, police officer, politician, entrepreneur, or community leader. The game should support quiet everyday play as well as discovery, danger, mystery, and long-term progression.

## 3. Design Pillars

1. **Living world first:** NPCs must have jobs, homes, needs, schedules, relationships, spending patterns, and reactions to the world.
2. **Player freedom:** Players can earn money, travel, buy property, start businesses, build homes, learn skills, join factions, and choose lawful or risky paths.
3. **Device-friendly realism:** The world must feel believable while scaling graphics, simulation detail, traffic density, NPC density, shadows, draw distance, and effects to fit mobile and PC hardware.
4. **Zero-budget production:** Use free and open-source engines, tools, services, and assets. Paid assets, proprietary services, or paid APIs are not allowed unless replaced by open alternatives.
5. **Systems over scripts:** Cities feel alive through reusable systems, not only handcrafted missions.
6. **Admin observability:** The owner/admin panel must expose monitoring, moderation, economy, users, NPC systems, world events, and configuration safely.

## 4. Target Audience

- Players who enjoy open-world sandbox games, life simulators, management games, survival games, travel games, and role-playing games.
- Mobile players who need short sessions, offline-friendly activities, low graphics settings, and touch controls.
- PC players who want deeper systems, higher population density, longer draw distance, keyboard/mouse controls, and modding potential.
- Creators and community members who want to build content with free tools.

## 5. Platforms and Performance Targets

| Platform class | Target FPS | Resolution strategy | Simulation strategy |
| --- | --- | --- | --- |
| Low-end Android | 30 FPS | Dynamic resolution, low shadows, low density, compressed textures | Reduced active NPC bubble, simplified traffic, low physics frequency |
| Mid-range Android | 30-45 FPS | Medium textures, limited post-processing | Medium NPC density, pooled vehicles, limited background AI |
| Low-end laptop | 30 FPS | 720p/900p scalable settings | Medium world streaming and AI tick budgets |
| Desktop PC | 60 FPS | 1080p+ with scalable high settings | Higher city density, longer draw distance, richer traffic and crowds |

Minimum design goal: the same save and economy model should work across mobile and PC, while visual and simulation density scales based on device capability.

## 6. Recommended Free/Open-Source Stack

| Need | Recommended option | Reason |
| --- | --- | --- |
| Game engine | Godot Engine 4.x | Free, open source, supports desktop and Android, strong 2D/3D workflow |
| 3D creation | Blender | Free and open source modeling, animation, rigging, rendering |
| Texture creation | Krita, GIMP, Material Maker | Free/open-source art and procedural material creation |
| Audio editing | Audacity | Free/open-source sound editing |
| Version control | Git | Free/open-source source control |
| Database for local/dev | SQLite | Free, reliable, embedded data storage |
| Backend prototype | Supabase self-hosted or Appwrite self-hosted | Open-source backend options; only use self-hosting/free tiers if zero-cost is possible |
| Maps/world reference | OpenStreetMap data under its license | Open map data for inspiration/procedural layouts, not direct uncredited copying |
| CI/CD | GitHub Actions free tier or local scripts | Free for public/open-source projects, but must avoid paid usage |
| Web admin panel | SvelteKit, React, Vue, or plain server-rendered app | Free/open-source web tooling |

All third-party assets must be tracked in an `ASSET_LICENSES.md` file before use, including source URL, author, license, modification status, and attribution text.

## 7. World Design

### 7.1 World Structure

The world is divided into streaming regions:

- **Megacity zones:** Dense commercial districts, apartments, government offices, metro stations, airports, hospitals, police stations, markets, schools, entertainment areas, industrial zones.
- **Small towns:** Lower traffic, local shops, farming supply stores, bus stands, workshops, small clinics, local festivals.
- **Villages:** Farms, wells, local markets, temples/community centers, dirt roads, livestock, crop cycles, limited services.
- **Wilderness:** Forests, mountains, rivers, caves, beaches, deserts, ruins, wildlife, camping, mining, treasure, hazards.
- **Transport corridors:** Highways, railways, ports, ferry routes, air routes, mountain roads, rural paths.

### 7.2 Biomes

- Tropical coast
- Dry desert
- Temperate forest
- Snow mountains
- Rainforest
- Grassland/farms
- Urban industrial
- Wetlands and river deltas

Each biome affects temperature, clothing needs, vehicle handling, jobs, resources, wildlife, crops, storms, and travel risk.

### 7.3 Cities That Feel Alive

Each city must include:

- Morning commute wave
- School/work opening times
- Lunch rush
- Evening market/social wave
- Nightlife districts
- Emergency response simulation
- Trash collection and street maintenance
- Public transport routes
- Police patrol areas
- Business open/close schedules
- Delivery supply chains
- Dynamic price differences between districts
- Local events such as festivals, strikes, road closures, sports matches, accidents, storms, elections, and sales

## 8. Player Fantasy and Progression

### 8.1 Start of Game

The player starts with:

- Basic rented room or temporary shelter
- Low cash balance
- Basic phone
- Simple clothing
- Basic ID/profile
- Limited skills
- Optional tutorial job
- No forced class selection

### 8.2 Core Player Needs

Optional realism settings can include:

- Hunger
- Thirst
- Energy
- Health
- Hygiene
- Mood
- Temperature comfort
- Legal status
- Reputation
- Debt and bills

Casual mode can reduce or disable harsh survival penalties.

### 8.3 Skills

Skills improve through use, training, books, classes, apprenticeships, and jobs:

- Driving
- Mechanics
- Cooking
- Farming
- Trading
- Negotiation
- Construction
- Medicine basics
- Fitness
- Stealth
- Fishing
- Mining
- Electronics
- Programming
- Piloting
- Sailing
- Leadership
- Language/culture knowledge
- Business management

### 8.4 Life Paths

Players can mix paths freely:

- Employee: work jobs, gain promotions, receive salary.
- Entrepreneur: rent/buy shop, hire NPCs, manage stock, prices, wages, taxes.
- Traveler: complete travel logs, discover landmarks, collect stories.
- Builder: buy land, build house, decorate, rent property.
- Adventurer: explore ruins, caves, mountains, forests, and mysteries.
- Farmer: own land, grow crops, raise animals, sell produce.
- Transporter: taxi, bus, truck, train, ship, air cargo.
- Public servant: police, medic, firefighter, city worker.
- Creator: music, art, writing, streaming, street performance.
- Risk path: smuggling, theft, black market, hacking, bribery, with consequences.

## 9. NPC System

### 9.1 NPC Identity

Every persistent NPC should have:

- Name
- Age group
- Home location
- Job or role
- Daily schedule
- Money balance
- Needs
- Relationships
- Personality tags
- Skills
- Reputation memory
- Inventory
- Favorite places
- Fear/stress level
- Lawfulness level
- Ambition or life goal

### 9.2 NPC Purpose Categories

- Worker NPCs: maintain economy and services.
- Family NPCs: create social fabric and home schedules.
- Business owners: control shops, prices, hiring, and stock.
- Travelers/tourists: create movement and demand.
- Officials: police, doctors, teachers, clerks, firefighters.
- Criminal NPCs: create risk and illegal economy.
- Wildlife NPCs: ecosystem behavior.
- Story NPCs: provide deeper quests but still follow world rules.

### 9.3 NPC Daily Schedule Example

| Time | Behavior |
| --- | --- |
| 05:30 | Wake up, hygiene, breakfast |
| 06:30 | Travel to work |
| 08:00 | Work shift starts |
| 12:30 | Lunch break, shopping/social interaction |
| 17:00 | Return home or visit market |
| 19:00 | Family/social/free-time activity |
| 22:30 | Sleep |

NPCs can deviate due to weather, illness, traffic, crime, events, relationships, or economic pressure.

### 9.4 NPC Memory and Reaction

NPCs remember:

- Player helped or harmed them
- Unpaid debts
- Business satisfaction
- Witnessed crimes
- Gifts and conversations
- Reputation in local area
- Faction alignment

Reactions include discounts, job offers, refusal of service, calling police, gossip, friendship, rivalry, hiring, romance eligibility, and quest opportunities.

## 10. Economy and Business

### 10.1 Currency and Value

The economy should simulate money flows without requiring real-money purchases. No pay-to-win design is allowed for the zero-budget vision.

### 10.2 Jobs

Starter jobs:

- Delivery runner
- Taxi/rickshaw driver
- Farm helper
- Warehouse loader
- Shop assistant
- Cleaner
- Mechanic apprentice
- Food stall helper
- Courier
- Fisher
- Miner

Advanced jobs:

- Pilot
- Doctor assistant
- Police officer
- Engineer
- Construction contractor
- Factory manager
- Business owner
- Logistics operator
- City planner role/event consultant

### 10.3 Businesses

Player-owned businesses can include:

- Grocery store
- Food stall/restaurant
- Repair garage
- Taxi company
- Farm
- Hotel/guest house
- Factory workshop
- Clothing shop
- Transport company
- Marketplace warehouse
- Fishing business
- Tourism agency

Business systems:

- Rent or property ownership
- Inventory sourcing
- Supplier contracts
- Employee hiring
- Wages
- Customer satisfaction
- Pricing
- Maintenance
- Taxes/fees if enabled
- Theft/security
- Reviews and reputation
- Local demand based on district and season

## 11. Travel and Vehicles

### 11.1 Travel Modes

- Walking
- Bicycle
- Motorbike
- Car
- Taxi
- Bus
- Truck
- Train
- Boat/ferry
- Plane
- Off-road vehicle
- Animal transport in rural areas if appropriate

### 11.2 Vehicle Systems

- Fuel or charge
- Wear and repair
- Cargo capacity
- Speed and terrain handling
- Legal documents/license
- Insurance/registration if realism mode is enabled
- Damage
- Upgrades
- Theft risk
- Parking and fines

## 12. Adventure and Exploration

Adventure content should emerge from the world and include:

- Hidden caves
- Ancient ruins inspired by fictional cultures
- Shipwrecks
- Mountain rescue events
- Forest mysteries
- Treasure maps
- Rare wildlife photography
- Dangerous weather survival
- Remote villages with unique stories
- Abandoned factories
- Smuggler routes
- Archaeology mini-careers
- Fishing and legendary catches
- Mining and rare minerals

Adventure must not break the life-sim economy; discoveries can provide money, reputation, knowledge, unlocks, or story progress.

## 13. Law, Safety, and Consequences

The legal system includes:

- Traffic violations
- Theft
- Assault
- Trespassing
- Smuggling
- Fraud
- Bribery
- Illegal weapons/items if included
- Environmental damage

Consequences:

- Fines
- Reputation loss
- Arrest
- Jail time skip or playable prison segment
- Business license suspension
- NPC fear or hostility
- Police pursuit
- Court/hearing events

The game should avoid glorifying harm and should always show meaningful consequences for destructive actions.

## 14. Quests and Dynamic Events

Quest types:

- Personal NPC requests
- Business contracts
- Delivery routes
- Exploration clues
- Disaster response
- Festival preparation
- Police/medical/fire emergencies
- Political/community decisions
- Family/social events
- Skill training challenges

Dynamic event examples:

- Road accident blocks highway
- Flood damages village bridge
- Market price crash
- Rare tourist season
- Power outage
- Disease outbreak simulation at mild/non-graphic level
- Wildlife enters town
- Protest or strike
- Local election
- Factory shutdown creates unemployment

## 15. User Interface and Controls

### 15.1 Mobile Controls

- Virtual joystick
- Context action button
- Swipe camera
- Auto-run toggle
- Vehicle steering mode options
- Simplified inventory shortcuts
- Large readable text mode
- Battery saver mode

### 15.2 PC Controls

- Keyboard/mouse movement
- Controller support target
- Hotkeys for phone, inventory, map, job, vehicle, build mode
- Mouse-driven admin/debug tools for development

### 15.3 In-Game Phone

The phone is the main UI hub:

- Map
- Contacts
- Jobs
- Bank
- Messages
- Business dashboard
- Travel tickets
- Licenses
- News
- Weather
- Social reputation
- Settings

## 16. Admin Panel Requirements

### 16.1 Admin Identity Requirement

The owner/admin account is specified as `BabluKSahu`. The initial password must be provided through a secure local bootstrap step or environment variable and immediately stored only as a salted password hash. Plaintext credentials must never be hard-coded in client code, committed config, logs, analytics, or seed files intended for public release.

### 16.2 Admin Capabilities

The admin panel must allow authorized monitoring and management of:

- Users and player profiles
- Save data
- Inventory and currency adjustments
- Bans, warnings, and moderation notes
- Server/world health
- Economy metrics
- NPC population state
- Business ownership data
- Property ownership data
- Quest/event state
- Crash/error logs
- Device performance stats
- Suspicious activity
- Content flags
- World configuration
- Dynamic event triggers
- Asset/license registry
- Backups and restore points

### 16.3 Admin Security

Required security rules:

- Role-based access control
- Password hashing with a modern algorithm
- Two-factor authentication target if free/open-source implementation is available
- Audit log for every admin action
- Session expiry
- CSRF protection for web admin
- Rate limiting
- No admin secrets in the game client
- Separate development and production credentials
- Export/delete data tools for privacy compliance

## 17. Multiplayer and Online Scope

Because the budget is Rs.00, the first playable version should prioritize offline single-player with optional local/self-hosted online features later. Online multiplayer adds server cost, moderation cost, anti-cheat cost, and synchronization complexity.

Recommended phases:

1. Offline single-player prototype.
2. Local saves and simulated cloud interfaces.
3. Self-hosted admin panel for development.
4. Optional community server support only if free hosting or player self-hosting is practical.

## 18. Graphics Direction

Visual style: realistic but optimized, using modular low-to-mid-poly assets, physically inspired materials, baked lighting where possible, and scalable quality settings.

Art rules:

- Avoid ultra-high-poly assets.
- Use LOD levels for buildings, vehicles, trees, and crowds.
- Use impostors/billboards for far vegetation and crowds.
- Use texture atlases.
- Use baked lightmaps for interiors/static areas where possible.
- Use procedural variation for buildings and NPC outfits.
- Use weather/time-of-day color grading.

Quality settings:

- NPC density
- Traffic density
- Shadow quality
- Texture quality
- Reflection quality
- Vegetation density
- Draw distance
- Physics detail
- Weather effects
- Anti-aliasing
- Dynamic resolution

## 19. Audio Direction

Audio categories:

- City ambience by district
- Village ambience
- Forest/mountain/coast/desert ambience
- Vehicle engines
- Footsteps by surface
- NPC chatter variants
- Shop sounds
- Weather sounds
- Emergency sirens
- UI sounds
- Music layers by mood, region, and time

All audio must be generated in-house or sourced from free/open licensed libraries with attribution.

## 20. Accessibility

Accessibility goals:

- Remappable controls
- Subtitles
- Colorblind-friendly UI
- Text size options
- Low motion/camera shake option
- Difficulty and realism sliders
- Auto-drive/assisted travel option
- Tap-to-move optional mobile mode
- Audio sliders by category
- Simple language mode for tutorials

## 21. Data and Save System

Save data categories:

- Player profile
- Inventory
- Money/accounts
- Skills
- Owned properties
- Owned businesses
- Vehicles
- NPC relationship states
- World event states
- Quest states
- Discovered map regions
- Crime/legal status
- Settings

Local save format should be human-debuggable during development and safely migrated with version numbers.

## 22. Technical Architecture

### 22.1 Runtime Systems

- World streaming manager
- NPC scheduler
- Traffic manager
- Economy manager
- Quest/event manager
- Save/load manager
- Device quality manager
- Input abstraction layer
- Inventory system
- Vehicle system
- Business system
- Property/building system
- Weather/time manager
- Admin telemetry bridge for authorized builds

### 22.2 Simulation Bubble

To run smoothly, only nearby entities use full simulation. Distant entities use abstract simulation.

| Distance/state | Simulation level |
| --- | --- |
| Near player | Full AI, animation, physics, interactions |
| Same district | Simplified schedule, path targets, economy actions |
| Distant city | Aggregated population/economy updates |
| Offline/sleep time | Time-skip formulas and event summaries |

### 22.3 Device Quality Manager

On first launch and during gameplay, the game should benchmark or detect:

- CPU class
- GPU capability
- RAM
- thermal throttling
- frame rate stability
- battery saver state on mobile

It then adjusts graphics and simulation settings automatically while still allowing manual override.

## 23. Content Creation Rules for Zero Budget

Allowed sources:

- Original team-created assets
- Public domain assets
- Creative Commons assets compatible with the project
- OpenGameArt-compatible licenses after review
- OpenStreetMap data with proper license compliance
- Free/open-source tools

Not allowed:

- Pirated assets
- Unlicensed music or models
- Paid asset packs unless donated with written permission
- Proprietary online APIs that require paid usage
- Trademarked real-world brands without permission
- Direct copies of real cities marketed as exact replicas without legal review

## 24. MVP Scope

The first MVP should include:

- One small town
- One surrounding village/farm area
- One wilderness exploration zone
- 30-50 persistent NPCs
- 5 job types
- 2 player business types
- Basic vehicles: walking, bicycle, motorbike, car, bus/taxi ride
- Day/night cycle
- Weather prototype
- Local economy prototype
- Save/load
- Device quality settings
- Admin dashboard prototype for local data inspection
- 10 dynamic events
- 15 quests

## 25. Vertical Slice

The vertical slice should prove:

1. Player wakes up in a rented room.
2. NPC neighbors leave for work.
3. Player checks phone for jobs.
4. Player does delivery work using bicycle or motorbike.
5. Traffic, shops, and pedestrians react by time of day.
6. Player earns money and buys food/fuel.
7. Player travels by bus to a village.
8. Player helps a farmer or explores a nearby cave.
9. A storm changes travel risk.
10. Admin panel displays player, NPC, economy, and event state.

## 26. Development Roadmap

### Phase 0: Planning

- Finalize GDD
- Create license policy
- Create repository structure
- Define coding standards
- Choose engine version
- Prototype performance budget

### Phase 1: Core Prototype

- Player controller
- Camera
- World streaming test
- Simple town block
- NPC schedule prototype
- Save/load
- Basic jobs
- Basic UI phone

### Phase 2: Living Town MVP

- Persistent NPCs
- Shops
- Economy loop
- Delivery and worker jobs
- Traffic prototype
- Weather/day-night
- First admin dashboard

### Phase 3: Business and Travel

- Player businesses
- Property rental/ownership
- Regional travel
- Village/farm systems
- Vehicle ownership
- Reputation

### Phase 4: Adventure Layer

- Wilderness zone
- Ruins/caves
- exploration quests
- hazards
- rare resources
- wildlife

### Phase 5: Optimization and Release Candidate

- Mobile performance pass
- PC graphics settings
- Save migration
- Accessibility
- Bug fixing
- Legal/license audit
- Documentation

### Phase 6: Life and Civic Expansion

- Deeper needs and lifestyle systems
- Relationship memory expansion
- Housing upgrades and recurring bills
- Police, clinic, transport, and city maintenance services
- Public events and service disruptions

### Phase 7: Content Expansion and Operations

- Additional districts, village variants, and wilderness points of interest
- More jobs, businesses, vehicles, and NPC archetypes
- Data-driven content pack validation
- Optional self-hosted services for backups/admin workflows
- Final release candidate optimization and accessibility pass

## 27. Success Metrics

- MVP runs at 30 FPS on target low-end devices with low settings.
- NPCs visibly follow daily purposes without manual scripting for every action.
- Player can earn money through at least five legal jobs.
- Player can own or operate at least two business types.
- Player can travel between town, village, and wilderness.
- Admin can inspect users, NPCs, economy, events, and saves.
- All included tools/assets have free/open-source-compatible licensing records.

## 28. Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Scope too large | Build one town MVP first, expand only after systems work |
| Mobile performance issues | Simulation bubble, LODs, dynamic quality, low-poly assets |
| Zero budget hosting limits | Prioritize offline single-player and self-hosted tools |
| Asset licensing mistakes | Maintain asset registry and review before import |
| NPC simulation complexity | Use tiered AI and abstract distant simulation |
| Admin security weakness | Never hard-code secrets, hash passwords, audit actions |
| Content overload | Procedural variation plus focused handcrafted points of interest |

## 29. Immediate Next Steps

1. Create repository folders for game client, admin panel, docs, tools, and asset licenses.
2. Choose Godot version and initialize project.
3. Maintain the `ASSET_LICENSES.md` registry before importing any third-party asset.
4. Follow `docs/ENGINEERING_PLAN.md` for schemas, save design, performance budgets, and admin security.
5. Use `docs/IMPLEMENTATION_PLAN.md` to execute development through gated phases.
6. Build a greybox town block.
7. Prototype player movement on PC and Android.
8. Prototype NPC schedule data with 5 NPCs.
9. Prototype save/load using local data.
10. Prototype admin dashboard reading local development data.
11. Define MVP task board.
12. Review this GDD and lock MVP scope before adding more features.
