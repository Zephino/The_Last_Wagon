class_name Flavor
extends RefCounted
## Dark-humor text: road events, shopkeeper lines and endings. All original.

## Road events: text plus an optional supply change ("" means no change).
const ROAD_EVENTS: Array[Dictionary] = [
	{"text": "A billboard reads: THE END IS NEAR. EAT AT DARLA'S. Darla's is on fire.", "supply": "", "amount": 0},
	{"text": "You pass a minivan with a sticker: MY OTHER CAR SURVIVED TOO.", "supply": "", "amount": 0},
	{"text": "A vending machine on the roadside. It still eats your money.", "supply": "money", "amount": -5},
	{"text": "A cooler in a ditch! It contains sandwiches of unknown vintage.", "supply": "food", "amount": 8},
	{"text": "Someone left ammo in a mailbox with a note: GOOD LUCK, DON'T COME BACK.", "supply": "ammo", "amount": 6},
	{"text": "A raccoon steals some food. It looks you dead in the eye while doing it.", "supply": "food", "amount": -6},
	{"text": "A gas station sign still spins. The pumps are dry, but there's a can behind the counter.", "supply": "fuel", "amount": 2},
	{"text": "The radio plays one song on loop. Nobody admits to liking it.", "supply": "", "amount": 0},
	{"text": "A hand-painted sign: TURN BACK. Another sign under it: NO, SERIOUSLY.", "supply": "", "amount": 0},
	{"text": "You find a toolbox in a crashed truck. Scrap is scrap.", "supply": "scrap", "amount": 3},
	{"text": "Somebody in the back asks, \"Are we there yet?\" Nobody is there yet.", "supply": "", "amount": 0},
	{"text": "A pothole the size of a swimming pool. You swerve. Something in the trunk breaks.", "supply": "scrap", "amount": -2},
]

const SHOPKEEPER_LINES: Array[String] = [
	"Cash only. The banks are mostly on fire.",
	"No refunds. No exchanges. No survivors, usually.",
	"Prices are high because the end of the world is a seller's market.",
	"You look like you'll make it. Probably. Buy a medkit.",
	"Last customer bought one can of beans and left crying. Don't be that guy.",
]

const WIN_LINES: Array[String] = [
	"You reached the coast. The beach is overrun, but it's YOUR overrun beach now.",
	"Miami at last. It's hot, it's ruined, and nobody here asks about the smell.",
]

const LOSE_LINES: Array[String] = [
	"Here lies your party. They got further than most. Not far, but further.",
	"The road takes everyone eventually. It took you a bit early.",
	"Your wagon rolls on without you. It does not look back.",
]


static func random_road_event(rng: RandomNumberGenerator) -> Dictionary:
	return ROAD_EVENTS[rng.randi_range(0, ROAD_EVENTS.size() - 1)]


static func pick(lines: Array[String], rng: RandomNumberGenerator) -> String:
	return lines[rng.randi_range(0, lines.size() - 1)]
