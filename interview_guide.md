# Hockey Game Model Interview Guide

_Drafted for a first discovery meeting about a hockey game event model._

## Facilitator Preamble

This guide is for a 60- to 90-minute conversation with people who understand hockey game flow, event data, coaching/analytics needs, or the systems where game events are recorded. The purpose is to narrow the model design enough that a later pass can turn the notes into a precise model specification.

Have one person facilitate and one person take notes. Capture exact terminology when stakeholders name events, actions, stoppages, and game phases. When people disagree, write down both versions and who uses each one. Do not try to settle every detail in this first meeting; mark open questions clearly.

## Meeting Plan

This is Meeting 1: discovery and framing.

Likely follow-up: one focused model-design meeting after notes are reviewed. That meeting should close definitions for event timing, competing events, state changes, data fields, and any unresolved `[REVIEW]` items.

## What This Meeting Must Answer

1. What practical question should this hockey game model help answer?
2. What is the main thing being followed: the game, the puck, a possession, a player, a team, or something else?
3. What game events and puck-touch actions are inside the initial scope?
4. What information must be tracked for the model to know what can happen next?
5. What existing data can support the event definitions, timing, and action probabilities?

## 1. The Problem

**Main question:**  
What decision or analysis do you want this hockey game model to support?
* _Answer: My original intention was just to build a sound, sensible basic model for the flow of an NHL hockey game, according to playoff format (i.e., if the game is tied at the end of regulation, you just continue with 20 minute periods until someone scores). In terms of a specific question to build around: one hypothesis I have is that a 3-0 lead in the first period of a hockey game is not as ideal as it seems (I call it "the worst lead in hockey"), mainly because I've observed so often that when this happens, the opposing team often comes back to tie. This may just be a perception thing in that being up 3-0 seems huge, so when a comeback occurs it is shocking. But if it's a 1-0 lead, then tying it up seems normal. But getting at this idea would interesting, to see, for example, if there are detriments to a 3-0 lead in the first period. Obviously lots of confounding here (i.e., an earlier lead just means the other team has more time to come back), but I think there's something around complacency and desperation at play here too._

Follow-up probes:
- Are we trying to recreate realistic game flow, evaluate strategies, forecast outcomes, test player/team behavior, generate synthetic play-by-play, or something else?
* _Answer: Mainly evaluate if there's any signal in the idea that a 3-0 lead in the first period is detrimental. Specifically, do we see complacency by the leading team and desperation from the losing team? This could be quantified by shift lengths, skating speed, or a number of other things._

- Who will use the model: coaches, analysts, researchers, product users, bettors, broadcasters, or internal developers?
* _Answer: Coaches could use this analysis to generate insights to prevent their teams from becoming complacent after having a lead, thus creating a strategy to avoid a comeback._
- What would be different if the model worked well?
* _Answer: Teams could question/evaluate why this is the case. They could look into player behavior after the lead occurs to see what's changed and correct for it_
- What decisions are currently made with incomplete information?
* _Answer: Some teams may "hold-off" and become defensive after gaining a lead._
- What is out of scope for the first version, even if it matters in real hockey?
* _Answer: Probably modeling exact coordinates of every player on the ice throughout the game. But that could be important._

**Main question:**  
What level of detail is useful for the first version?
* _Answer: Probably player-level representation. You need to know if individual players change their game when the lead occurs._

Follow-up probes:
- Should the model care about every puck touch, only recorded play-by-play events, or a middle layer between those?
* _Answer: I think shift-level analysis is important, to see what happens to a player over shifts throughout a game._
- Should it represent individual players, lines, positions, teams, or generic home/away actors?
* _Answer: Those could all be at play. But for simplicity we might have teams, then players nested in teams. I think the team matters because there are cases where a 3-0 lead from a team you know is better will continue crushing the opponent. It's a certain feel of the game and specific team matchups where the lead may be in jeopardy._
- Should it include spatial detail such as zone, rink coordinates, or distance to net?
* _Answer: Yes, potentially. You want to know if scoring chances are decreasing/changing after the lead occurs compared to before, which might be quantified by a players location._
- Should it include tactical context such as forecheck pressure, rush vs cycle, or odd-man situations? `[REVIEW: likely not first-version unless data supports it]` * _Answer: Yeah these may be key indicators._

## 2. Outcomes

**Main question:**  
What should we measure at the end of a simulated game or sequence?
* _Answer: We should measure some sort of quantification of "complacency" and "desperation" for the team with the 3-0 lead and the opposing team, respectively._

Follow-up probes:
- Final score?
* _Answer: Yeah it matters who ultimately won and by how much._
- Shots, shot attempts, expected goals, goals, penalties, faceoffs, zone entries, turnovers, possession time, or special-teams time?
* _Answer: All relevant to the question._
- Player-level outputs such as touches, shots, assists, time on ice, or plus/minus?
* _Answer: All relevant to the question._
- Team-level outputs such as offensive-zone time, shot share, scoring chances, or penalty differential?
* _Answer: Yes, a rollup of player-level metrics would be useful._
- Do we care more about game-level totals or the order and timing of events?
* _Answer: Yes_

**Main question:**  
How would you judge whether the model is realistic?
* _Answer: First, if the rate of these types of games matches reality. A 3-0 lead in the first period only occurs in <10% of playoff games._

Follow-up probes:
- Which observed distributions should the model reproduce: event counts per game, time between whistles, shot rates, goal rates, possession lengths, penalties, faceoffs, or score effects?
* _Answer: Player complacency and desperation distributions before and after the lead, and/or throughout the game._
- Are there specific leagues, seasons, teams, or game states that should be used as benchmarks?
* _Answer: The 2026 playoffs saw this occur multiple times._
- What would immediately make the model feel wrong to a hockey expert?
* _Answer: If a 3-0 lead in the first period always led to a blowout win. Or if the win rates was the same for every team._

## 3. The Lifecycle

**Main question:**  
Walk me through a game from before puck drop to the final horn. What are the major phases?
* _Answer: The basic structure: puck drop, then gameplay with intermittant whistles for icing, offsides, penalties, etc., and then a hard stop at 20 minutes of gameplay for the first period. Repeat this two more times for the second and third. If it's tied at the end of the third. Keep repeating until someone scores, then the game is over._

Follow-up probes:
- How should period start, period end, intermissions, overtime, and shootout be represented?
* _Answer: The state of a game could be in progress (when the game is happening), or intermission (between periods). A status of final means the game is over. Another state would indicate if there is active play at a given point in time (to distinguish between active game play versus time between when a whistle occurred but the game is still in progress)._
- Are preseason, regular season, playoff overtime, or international rule variants in scope? `[REVIEW: choose rule set]`
* _Answer: Playoff overtime. Just NHL playoff hockey games are represented here._
- Does the model start at opening faceoff, or does it need pre-game context such as rosters, starting goalies, home ice, or lineups?
* _Answer: Yes, starts at puck drop._
- Does the model end only at regulation end, or can it continue into overtime and shootout?
* _Answer: Just continuous overtime in 20 minute periods like NHL playoff hockey rules._

**Main question:**  
What smaller story should the model repeat during the game?
* _Answer: Each period is sort of similar. Just repeating the process. Through subsequent periods may be dependent upon what happened earlier._

Follow-up probes:
- Is the natural cycle a puck possession, a puck touch, a play segment between whistles, a shift, or something else?
* _Answer: A shift would be good._
- When a player touches the puck, what are the allowable next actions?
* _Answer: Advance/possess the puck, pass the puck, shoot the puck._
- When does a possession begin and end?
* _Answer: A player possession starts when they have the puck on their stick and ends when they get rid of it. A team possession starts when any player on the team has the puck and ends when any player on the other teams gains possession of the puck (or a goal is scored, or whistle is blown, or period ends). A possession is different than simply touching the puck: a goalie might technically touch the puck when they save it, but it comes back to the same team--they maintain possession. Similar for blocks or deflections._
- When does a stoppage reset the story?
* _Answer: Whistles or period endings._

## 4. Key Events

**Main question:**  
What named events must the model recognize in the first version?

Follow-up probes:
- Game-clock events: period start, period end, timeout, intermission, overtime start, game end.
- Stoppage events: whistle, puck frozen, offside, icing, puck out of play, goalie cover, hand pass, net off, injury stoppage.
- Restart events: faceoff, neutral-zone faceoff, offensive-zone faceoff, defensive-zone faceoff.
- Puck actions: pass, shot, carry/advance, dump-in, clear, rim, regroup, drop pass, chip, dump back to goalie, turnover, takeaway.
- Shot outcomes: goal, save, miss, block, rebound, frozen puck.
- Penalty events: penalty called, delayed penalty, power play start/end, penalty shot. `[REVIEW: first-version scope]`
- Goalie events: save, cover, goalie pulled, goalie returned, goalie puck play. `[REVIEW: first-version scope]`
- Bench/roster events: line change, timeout, goalie change. `[REVIEW: first-version scope]`

**Main question:**  
For each puck-touch action, what can happen immediately afterward?

Follow-up probes:
- After a pass: completed pass, intercepted pass, deflection, missed target, receiver touch.
- After a shot: goal, save, rebound, block, miss, whistle.
- After advancing the puck: continued control, pressure, turnover, zone entry, dump-in.
- After dumping the puck: retrieval by same team, retrieval by opponent, goalie play, icing, puck battle.
- After dumping back to the goalie: goalie controls, goalie passes, goalie freezes, turnover.
- After a turnover: opponent gains control, loose puck, whistle, immediate shot chance.

## 5. Timing, Frequency, and Competing Events

**Main question:**  
How should time move during the model?

Follow-up probes:
- Should time be measured in seconds of game clock?
- Does the model need both game-clock time and real elapsed time including intermissions?
- During whistles, does game time stop while other events can still happen?
- How should delayed events work, such as a delayed penalty, pending line change, or penalty expiration?

**Main question:**  
How often do key events happen, and what changes those rates?

Follow-up probes:
- How long does a typical possession last?
- How long between player puck touches?
- How long between whistles?
- How do score, period, zone, manpower, team strength, player skill, fatigue, or home/away status change event chances?
- Are there event rates that should be learned directly from data rather than specified by experts?

**Main question:**  
When several things could happen at nearly the same time, which one takes precedence?

Follow-up probes:
- If the period clock expires during an ongoing possession, does the period end immediately?
- If a penalty expires while the puck is live, does the player return immediately, at the next whistle, or by rule-specific timing?
- If a delayed penalty is pending and the non-offending team scores, what happens?
- If a shot creates both a rebound and a whistle possibility, how is that resolved?
- Which scheduled items stay scheduled even when game state changes: period end, penalty expiration, timeout availability, goalie-pull threshold?

## 6. Tracking Properties

**Main question:**  
At any moment, what must we know to decide what can happen next?

Follow-up probes:
- Game context: period, clock time, score, home/away, rink zone, manpower, timeout availability.
- Puck context: which team controls the puck, whether puck is loose, puck location, current possessor, last action, last touch team.
- Player/team context: players on ice, goalie status, fatigue, handedness, position, team strength. `[REVIEW: first-version scope]`
- Penalty context: active penalties, delayed penalties, remaining penalty time, coincidental penalties.
- Sequence context: possession start time, number of passes in possession, zone entry status, rebound status, rush/cycle status.

**Main question:**  
Which details are essential versus nice-to-have?

Follow-up probes:
- Could the first model work without individual player identities?
- Could it work with zone-only location instead of coordinates?
- Could it work without line changes?
- What simplification would make the model unusable?

## 7. Computed Flags and Summaries

**Main question:**  
Are there summaries or labels analysts commonly compute from raw hockey events?

Follow-up probes:
- Possession length, time since last whistle, time since zone entry, time since last shot.
- Rush vs settled offense, rebound chance, odd-man rush, high-danger shot, scoring chance.
- Shot quality or expected goal value.
- Team momentum or pressure sequence.
- Fatigue estimates from shift length or recent play.

**Main question:**  
Which summaries should be recalculated from detailed events rather than stored as separate facts?

Follow-up probes:
- Can possession time be rebuilt from event timestamps?
- Can manpower state be rebuilt from penalties?
- Can zone state be rebuilt from puck movement events?
- Which labels depend on expert judgment or proprietary definitions?

## 8. Decision Points

**Main question:**  
Where does a person or team make a meaningful choice during the game?

Follow-up probes:
- Player with puck chooses pass, shoot, carry, dump, clear, or reset.
- Coach chooses line match, timeout, goalie pull, challenge, or deployment.
- Goalie chooses freeze puck, play puck, pass, clear, or leave puck.
- Team chooses forecheck/pressure level, power-play setup, penalty-kill behavior. `[REVIEW: abstraction level]`

**Main question:**  
What information is visible at each choice?

Follow-up probes:
- Score, time, zone, pressure, teammates/opponents nearby, fatigue, player skill, shot lane, passing lane.
- For coach decisions: score, period, faceoff location, rest, matchup, timeout availability, goalie status.
- For goalie-pull decisions: score, time remaining, possession, faceoff location, manpower, opponent threat.

## 9. Current and Alternative Policies

**Main question:**  
How should the model choose actions today?

Follow-up probes:
- Should choices be based on observed historical rates?
- Should choices vary by player, team, score state, zone, period, and manpower?
- Are there known hockey rules of thumb that should be included?
- Should expert assumptions fill gaps where data is missing?

**Main question:**  
What alternatives would you want to compare?

Follow-up probes:
- More aggressive shooting vs more passing.
- Earlier or later goalie pull.
- Different dump-and-chase vs controlled-entry behavior.
- Conservative vs aggressive breakout choices.
- Different timeout or challenge policies.
- Different player usage or line matching. `[REVIEW: may require player/line modeling]`

## 10. Uncertainty in the Inputs

**Main question:**  
Which assumptions are most uncertain or likely to change model conclusions?

Follow-up probes:
- Probability of each puck-touch action by context.
- Probability that a pass completes, shot becomes goal, dump-in is recovered, or turnover occurs.
- Time between touches, whistles, shots, and possession changes.
- Effects of score, fatigue, team strength, player skill, and rink location.
- Rare events such as penalties, goalie pulls, injuries, video reviews, or empty-net goals.

**Main question:**  
Where should we use ranges instead of single values?

Follow-up probes:
- Are there published or internal estimates for action probabilities?
- Are some values better represented by team-specific or player-specific distributions?
- Which assumptions should analysts be able to vary in scenarios?

## 11. Data Inventory

**Main question:**  
What data exists today that describes hockey game events?

Follow-up probes:
- NHL play-by-play, shift charts, event coordinates, tracking data, video tagging, internal scouting data, betting feeds, or manually coded events.
- Which data source has puck touches, if any?
- Which data source has passes, carries, dumps, recoveries, and turnovers?
- Which data source has player identities and on-ice players?
- Which data source has event timestamps, period, score, manpower, zone, and coordinates?

**Main question:**  
What are the known data gaps or inconsistencies?

Follow-up probes:
- Are passes recorded consistently?
- Are turnovers and takeaways subjective?
- Can possession be inferred reliably?
- Are goalie puck plays separately recorded?
- Are coordinates standardized across rinks and seasons?
- Are stoppage reasons coded consistently?

**Main question:**  
Who needs to confirm the data definitions?

Follow-up probes:
- Analyst who knows derived event labels.
- Database owner who knows source tables and fields.
- Hockey expert who can validate event taxonomy.
- Engineer who knows data extraction limits.

## 12. Scope and Boundaries

**Main question:**  
What counts as a complete run of this model?

Follow-up probes:
- One full game through regulation?
- Regulation plus overtime and shootout?
- One period?
- One possession or sequence between whistles?
- A season made of many games? `[REVIEW: likely not first-version]`

**Main question:**  
What should make the model stop naturally?

Follow-up probes:
- Final horn at regulation or overtime.
- Shootout complete.
- Fixed game-clock horizon reached.
- A target event occurs, such as next goal, next whistle, or end of possession.

**Main question:**  
What should be excluded from the first version?

Follow-up probes:
- Injuries, fights, video review, equipment issues, goalie substitutions, full line-change mechanics, arena effects, referee tendencies, weather/travel/rest effects.
- Player development or season fatigue.
- Detailed tactics not visible in data.
- Anything that cannot be validated with available data.

## Scribe Capture Template

| Section | Notes | Decisions | Open Questions / Review Tags |
|---|---|---|---|
| Problem |  |  |  |
| Outcomes |  |  |  |
| Lifecycle |  |  |  |
| Key events |  |  |  |
| Timing and competing events |  |  |  |
| Tracking properties |  |  |  |
| Computed summaries |  |  |  |
| Decision points |  |  |  |
| Current and alternative policies |  |  |  |
| Uncertainty |  |  |  |
| Data inventory |  |  |  |
| Scope and boundaries |  |  |  |

## Parking Lot

- Confirm the intended first-version unit: game, play segment, possession, puck touch, team-game, player-game, or player-shift.
- Confirm the rule set: NHL regular season, NHL playoffs, international, or simplified generic hockey.
- Decide whether the first version includes individual players or only team-level behavior.
- Decide whether puck location is absent, zone-based, coordinate-based, or inferred from event type.
- Decide whether penalties, line changes, and goalie-pull strategy are first-version requirements or later extensions.
