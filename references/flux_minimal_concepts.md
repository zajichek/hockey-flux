# Minimal Flux Concepts for Hockey Model

This project uses fluxCore to build an event-based hockey game simulation.

## Core pieces

- Entity/state initialization defines the starting game state.
- Event proposal functions determine candidate next events.
- The engine selects the next valid event.
- Transition functions update state after an event fires.
- Derived variables calculate values from current state.
- Observations record state/output during simulation.
- The stopping function decides when the simulation ends.

## Hockey model conventions

- `game_status == "final"` is the stopping condition.
- Period progression should be explicit.
- Game clock values should be numeric internally.
- Clock labels like `MM:SS` should be formatting/output only.
- Derived variables should not be used as hidden mutable state.
- Event proposals must include valid numeric event times.