class_name RoadEvents
extends RefCounted
## Road events where you choose what to do. Each choice has outcomes picked
## by chance; each outcome has text and effects. Some choices need a certain
## survivor standing ("role") or a supply ("needs"). Rare events are secrets:
## they earn an award the first time. All text is original.
##
## Effects: food, fuel, ammo, medkits, scrap, money (add or remove),
## "hurt" (one random standing survivor), "hurt_all", "heal_all",
## "car" (car condition, only if you have one), "days" (time lost),
## "award" (award id).

const EVENTS: Array[Dictionary] = [
	{"id": "stranger", "title": "A Stranger Waves", "text": "Someone by the road is waving both arms. They look hungry. Or hungry-looking. Hard to tell these days.",
		"choices": [
			{"label": "Share some food (10 food)", "needs": {"food": 10}, "outcomes": [
				{"chance": 0.7, "text": "They thank you and hand over a box of shells they 'won't be needing'.", "effects": {"food": -10, "ammo": 15}},
				{"chance": 0.3, "text": "They eat, say nothing, and walk into the woods. Rude, but harmless.", "effects": {"food": -10}}]},
			{"label": "Let the Medic check on them", "role": "medic", "outcomes": [
				{"chance": 1.0, "text": "Just dehydrated. Grateful, they point you to a supply cache nearby.", "effects": {"medkits": 1, "food": 8}}]},
			{"label": "Keep going", "outcomes": [
				{"chance": 1.0, "text": "You keep going. In the mirror, the waving gets ruder.", "effects": {}}]}]},
	{"id": "convoy", "title": "Trading Convoy", "text": "Three armored buses block the road. A sign says TRADE OR TURN AROUND. A man with a megaphone says the same, but louder.",
		"choices": [
			{"label": "Trade $40 for fuel", "needs": {"money": 40}, "outcomes": [
				{"chance": 1.0, "text": "Fair deal. Weird smell, but fair.", "effects": {"money": -40, "fuel": 8}}]},
			{"label": "Trade 20 ammo for food", "needs": {"ammo": 20}, "outcomes": [
				{"chance": 1.0, "text": "They hand over a sack of canned peaches. Everyone is very happy about the peaches.", "effects": {"ammo": -20, "food": 30}}]},
			{"label": "Let the Thief browse", "role": "thief", "outcomes": [
				{"chance": 0.75, "text": "Your Thief comes back whistling with pockets full of cash.", "effects": {"money": 60}},
				{"chance": 0.25, "text": "Caught! You pay a 'fine' and leave quickly.", "effects": {"money": -30}}]},
			{"label": "Turn around and detour", "outcomes": [
				{"chance": 1.0, "text": "The detour costs you most of a day.", "effects": {"days": 0.7}}]}]},
	{"id": "noise", "title": "A Noise in the Gas Station", "text": "The gas station looks empty. Something inside knocks over a shelf. Then another shelf.",
		"choices": [
			{"label": "Go in shooting (5 ammo)", "needs": {"ammo": 5}, "outcomes": [
				{"chance": 0.6, "text": "One very surprised raccoon later, you load up on snacks.", "effects": {"ammo": -5, "food": 15}},
				{"chance": 0.4, "text": "It was not a raccoon. You win, but it bit someone.", "effects": {"ammo": -5, "hurt": 20, "scrap": 4}}]},
			{"label": "Sneak in with the Scout", "role": "scout", "outcomes": [
				{"chance": 1.0, "text": "In and out without a sound, with a full gas can.", "effects": {"fuel": 5}}]},
			{"label": "Drive on", "outcomes": [
				{"chance": 1.0, "text": "Whatever it was can keep its shelves.", "effects": {}}]}]},
	{"id": "detour_sign", "title": "Hand-Painted Detour", "text": "A sign says DETOUR -> with a smiley face. The main road ahead is clear. The smiley face is unsettling.",
		"choices": [
			{"label": "Follow the detour", "outcomes": [
				{"chance": 0.5, "text": "It leads to an abandoned farm with a full pantry. The smiley face was honest!", "effects": {"food": 25, "days": 0.4}},
				{"chance": 0.5, "text": "It leads to an ambush. You get away, but not cleanly.", "effects": {"hurt_all": 10, "days": 0.4}}]},
			{"label": "Stay on the main road", "outcomes": [
				{"chance": 1.0, "text": "Boring. Safe. Boring.", "effects": {}}]}]},
	{"id": "pothole_field", "title": "Cracked Highway", "text": "The road ahead is more hole than road.",
		"choices": [
			{"label": "Go slowly (lose time)", "outcomes": [
				{"chance": 1.0, "text": "You crawl through. Your back hurts from tension alone.", "effects": {"days": 0.5}}]},
			{"label": "Floor it", "outcomes": [
				{"chance": 0.5, "text": "You fly over it like a stunt driver. Nobody claps, but they want to.", "effects": {}},
				{"chance": 0.5, "text": "CLUNK. Something important falls off.", "effects": {"car": -20, "scrap": -2}}]},
			{"label": "Let the Mechanic pick the line", "role": "mechanic", "outcomes": [
				{"chance": 1.0, "text": "Smooth as anything. They even spot a toolbox on the way.", "effects": {"scrap": 4}}]}]},
	{"id": "abandoned_bus", "title": "Abandoned School Bus", "text": "A school bus sits sideways across one lane. The doors are open.",
		"choices": [
			{"label": "Search it", "outcomes": [
				{"chance": 0.6, "text": "Lunchboxes! Old, but sealed.", "effects": {"food": 12, "medkits": 1}},
				{"chance": 0.4, "text": "Someone was still on board. Not anymore, but they bit first.", "effects": {"hurt": 15, "food": 6}}]},
			{"label": "Strip it for parts", "outcomes": [
				{"chance": 1.0, "text": "You pull off what you can carry.", "effects": {"scrap": 6, "days": 0.2}}]},
			{"label": "Leave it", "outcomes": [
				{"chance": 1.0, "text": "Some buses are best left alone.", "effects": {}}]}]},
	{"id": "hitchhiker_dog", "title": "A Dog on the Road", "text": "A scruffy dog sits in the middle of the road and refuses to move.",
		"choices": [
			{"label": "Give it some food (3 food)", "needs": {"food": 3}, "outcomes": [
				{"chance": 1.0, "text": "It eats, then leads you to a crate behind a billboard. Good dog.", "effects": {"food": -3, "ammo": 10, "medkits": 1}}]},
			{"label": "Honk", "outcomes": [
				{"chance": 1.0, "text": "It moves, slowly, with great judgment in its eyes.", "effects": {}}]}]},
	{"id": "toll_booth", "title": "Toll Booth", "text": "A toll booth, staffed. A cardboard sign: TOLL $25. EVERYTHING ELSE IS FREE NOW BUT NOT THIS.",
		"choices": [
			{"label": "Pay the $25", "needs": {"money": 25}, "outcomes": [
				{"chance": 1.0, "text": "They give you a receipt. You will treasure it.", "effects": {"money": -25}}]},
			{"label": "Run the gate", "outcomes": [
				{"chance": 0.6, "text": "The gate was cardboard too.", "effects": {}},
				{"chance": 0.4, "text": "The gate was not cardboard.", "effects": {"car": -15, "hurt": 10}}]},
			{"label": "Let the Gunner negotiate", "role": "gunner", "outcomes": [
				{"chance": 1.0, "text": "The toll is suddenly waived. They even add a 'customer appreciation' gift.", "effects": {"ammo": 8}}]}]},
	{"id": "storm", "title": "Storm Rolling In", "text": "Black clouds ahead, the wrong kind of black. The radio says nothing helpful.",
		"choices": [
			{"label": "Wait it out under a bridge", "outcomes": [
				{"chance": 1.0, "text": "You wait. You eat. You play a long game of I-Spy with very little to spy.", "effects": {"days": 0.8, "food": -6}}]},
			{"label": "Push through", "outcomes": [
				{"chance": 0.5, "text": "You make it. Soaked, but through.", "effects": {}},
				{"chance": 0.5, "text": "The rain stings. Everyone feels worse.", "effects": {"hurt_all": 8}}]}]},
	{"id": "merchant", "title": "Roadside Merchant", "text": "A woman sells 'MEDICINE, MAPS, MYSTERY BOXES' from a shopping cart.",
		"choices": [
			{"label": "Buy a medkit ($30)", "needs": {"money": 30}, "outcomes": [
				{"chance": 1.0, "text": "It's real. You checked twice.", "effects": {"money": -30, "medkits": 1}}]},
			{"label": "Buy a mystery box ($20)", "needs": {"money": 20}, "outcomes": [
				{"chance": 0.4, "text": "Ammo! A lot of it!", "effects": {"money": -20, "ammo": 30}},
				{"chance": 0.3, "text": "Car parts and a postcard from Ohio.", "effects": {"money": -20, "scrap": 8}},
				{"chance": 0.3, "text": "A single rubber duck. It squeaks. You keep it.", "effects": {"money": -20}}]},
			{"label": "Wave and move on", "outcomes": [
				{"chance": 1.0, "text": "She waves back with both hands and one foot.", "effects": {}}]}]},
	{"id": "camp", "title": "Abandoned Campsite", "text": "A tidy campsite. Tents up, fire pit cold. Nobody around. Suspiciously tidy.",
		"choices": [
			{"label": "Rest here a while", "outcomes": [
				{"chance": 0.7, "text": "A real night's sleep. Everyone feels better.", "effects": {"heal_all": 20, "days": 0.5}},
				{"chance": 0.3, "text": "The owners come back. They are not tidy people after all.", "effects": {"hurt_all": 10, "days": 0.3}}]},
			{"label": "Grab what you can and go", "outcomes": [
				{"chance": 1.0, "text": "Canned beans and a lantern. Classic.", "effects": {"food": 10, "scrap": 2}}]}]},
	{"id": "cook_off", "title": "Wild Garden", "text": "An overgrown vegetable garden, still growing. Some of it looks edible. Some of it looks back.",
		"choices": [
			{"label": "Let the Cook forage", "role": "cook", "outcomes": [
				{"chance": 1.0, "text": "The Cook knows exactly which ones won't kill you. Dinner is served.", "effects": {"food": 30}}]},
			{"label": "Pick some yourself", "outcomes": [
				{"chance": 0.6, "text": "Turnips! Probably turnips.", "effects": {"food": 12}},
				{"chance": 0.4, "text": "Definitely not turnips. Someone feels very sick.", "effects": {"food": 4, "hurt": 15}}]},
			{"label": "Leave it", "outcomes": [
				{"chance": 1.0, "text": "The garden watches you go.", "effects": {}}]}]},
	{"id": "broken_truck", "title": "Truck in a Ditch", "text": "A delivery truck lies on its side. The cargo doors are jammed.",
		"choices": [
			{"label": "Pry the doors (takes time)", "outcomes": [
				{"chance": 0.7, "text": "Boxes of supplies! Some even match their labels.", "effects": {"food": 15, "ammo": 10, "days": 0.3}},
				{"chance": 0.3, "text": "The doors give way all at once. Something heavy lands on someone.", "effects": {"hurt": 20, "food": 10}}]},
			{"label": "Siphon its fuel", "outcomes": [
				{"chance": 1.0, "text": "You get a few gallons and a mouthful of regret.", "effects": {"fuel": 4}}]},
			{"label": "Ignore it", "outcomes": [
				{"chance": 1.0, "text": "Not your truck, not your problem.", "effects": {}}]}]},
	{"id": "bridge_out", "title": "Bridge Out", "text": "The bridge ahead is half gone. The other half is thinking about it.",
		"choices": [
			{"label": "Find another way (lose time)", "outcomes": [
				{"chance": 1.0, "text": "A long way round, but everyone arrives in one piece.", "effects": {"days": 0.9}}]},
			{"label": "Cross carefully", "outcomes": [
				{"chance": 0.6, "text": "It holds. Everyone breathes again.", "effects": {}},
				{"chance": 0.4, "text": "It mostly holds. Mostly.", "effects": {"hurt_all": 12, "car": -15}}]}]},
	{"id": "survivors_party", "title": "Survivors' Barbecue", "text": "A group of survivors is grilling something. They invite you over. It smells... fine?",
		"choices": [
			{"label": "Join them", "outcomes": [
				{"chance": 0.75, "text": "Good food, bad jokes, and a tip about a stash down the road.", "effects": {"food": 10, "heal_all": 10, "ammo": 6}},
				{"chance": 0.25, "text": "Best not to ask what the 'something' was. Everyone feels off.", "effects": {"hurt_all": 6}}]},
			{"label": "Politely decline", "outcomes": [
				{"chance": 1.0, "text": "They wave you off with tongs. No hard feelings.", "effects": {}}]}]},
]

## Secret events: rare, and each earns an award the first time.
const RARE_EVENTS: Array[Dictionary] = [
	{"id": "radio_signal", "title": "A Strange Signal", "text": "The radio, silent for days, crackles: a voice reads out numbers, then coordinates, then a recipe for pancakes.",
		"choices": [
			{"label": "Follow the coordinates", "outcomes": [
				{"chance": 1.0, "text": "An old ranger station, full of first-aid supplies. The pancake recipe was also excellent.", "effects": {"medkits": 3, "food": 10, "award": "radio_signal"}}]},
			{"label": "Turn it off", "outcomes": [
				{"chance": 1.0, "text": "Some mysteries are better left unsolved. This was probably not one of them.", "effects": {}}]}]},
	{"id": "bunker", "title": "Hatch in a Field", "text": "A rusted hatch in a field, half hidden by weeds, with a keypad. Someone scratched 1234 next to it.",
		"choices": [
			{"label": "Try 1234", "outcomes": [
				{"chance": 1.0, "text": "It opens. Of course it does. Inside: a prepper's dream, and a very old car battery.", "effects": {"food": 30, "ammo": 30, "scrap": 10, "award": "bunker"}}]},
			{"label": "Leave it closed", "outcomes": [
				{"chance": 1.0, "text": "You walk away. The hatch seems disappointed.", "effects": {}}]}]},
	{"id": "ice_cream", "title": "The Ice Cream Truck", "text": "Music. Tinny, cheerful music. An ice cream truck rolls past, completely normal, driver smiling. It stops.",
		"choices": [
			{"label": "Get in line", "outcomes": [
				{"chance": 1.0, "text": "Rocket pops for everyone. The driver won't take money. The truck drives off into a sunset that isn't there.", "effects": {"heal_all": 30, "award": "ice_cream"}}]},
			{"label": "Absolutely not", "outcomes": [
				{"chance": 1.0, "text": "Smart. Probably. The music fades.", "effects": {}}]}]},
]

## Chance that a road stretch has one of the rare events (if any are left to find).
const RARE_CHANCE := 0.08


## Picks the events for one stretch of road: "often" means 2 or 3.
static func pick_for_stretch(rng: RandomNumberGenerator, has_award: Callable) -> Array[Dictionary]:
	var pool := EVENTS.duplicate()
	var picked: Array[Dictionary] = []
	var count := rng.randi_range(2, 3)
	for index: int in count:
		if pool.is_empty():
			break
		picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	if rng.randf() < RARE_CHANCE:
		var unfound: Array[Dictionary] = []
		for event: Dictionary in RARE_EVENTS:
			if not has_award.call(event["id"]):
				unfound.append(event)
		var rare_pool: Array[Dictionary] = unfound if not unfound.is_empty() else RARE_EVENTS
		picked[rng.randi_range(0, picked.size() - 1)] = rare_pool[rng.randi_range(0, rare_pool.size() - 1)]
	return picked


## Why a choice can't be picked right now ("" if it can).
static func blocked_reason(choice: Dictionary) -> String:
	if choice.has("role"):
		var role := Survivor.role_from_id(str(choice["role"]))
		if not Trip.has_standing_role(role):
			return "needs a %s" % Survivor.name_of_role(role)
	var needs: Dictionary = choice.get("needs", {})
	for supply: String in needs:
		if Trip.get_supply(supply) < float(needs[supply]):
			return "not enough %s" % supply
	return ""


## Picks an outcome by chance and applies it. Returns the text to show.
static func resolve(choice: Dictionary, rng: RandomNumberGenerator) -> String:
	var outcomes: Array = choice["outcomes"]
	var roll := rng.randf()
	var outcome: Dictionary = outcomes[outcomes.size() - 1]
	for candidate: Dictionary in outcomes:
		roll -= float(candidate["chance"])
		if roll <= 0.0:
			outcome = candidate
			break
	var summary := apply_effects(outcome["effects"], rng)
	var text: String = outcome["text"]
	return text if summary.is_empty() else "%s\n\n%s" % [text, summary]


## Applies effects to the trip and returns a short summary like "+15 ammo, -10 food".
static func apply_effects(effects: Dictionary, rng: RandomNumberGenerator) -> String:
	var parts: Array[String] = []
	for key: String in effects:
		var value: Variant = effects[key]
		match key:
			"food", "fuel", "ammo", "medkits", "scrap", "money":
				var amount := int(value)
				if key == "money" and amount > 0 and Trip.has_standing_role(Survivor.Role.THIEF):
					amount = ceili(amount * 1.5)
				Trip.add_supply(key, amount)
				parts.append("%+d %s" % [amount, key])
			"hurt":
				var victim := _random_standing(rng)
				if victim != null:
					victim.hurt(int(value))
					parts.append("%s -%d health" % [victim.name, int(value)])
			"hurt_all":
				for survivor: Survivor in Trip.party:
					survivor.hurt(int(value))
				parts.append("everyone -%d health" % int(value))
			"heal_all":
				for survivor: Survivor in Trip.party:
					survivor.heal(int(value))
				parts.append("everyone +%d health" % int(value))
			"car":
				if Trip.has_vehicle:
					Trip.vehicle_health = clampi(Trip.vehicle_health + int(value), 0, 100)
					parts.append("car %+d%%" % int(value))
			"days":
				Trip.pass_time(float(value))
				parts.append("lost time")
			"award":
				Progress.earn(str(value))
	return ", ".join(parts)


static func _random_standing(rng: RandomNumberGenerator) -> Survivor:
	var standing: Array[Survivor] = []
	for survivor: Survivor in Trip.party:
		if not survivor.is_downed():
			standing.append(survivor)
	if standing.is_empty():
		return null
	return standing[rng.randi_range(0, standing.size() - 1)]
