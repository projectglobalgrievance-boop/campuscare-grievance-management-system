"""Funny, campus-safe alias generator. Admin sees these instead of real names.

Per-complaint alias (maximum privacy: complaints from the same student are not
correlatable by the admin). ~60 x ~60 = 3600 combinations.
"""
from __future__ import annotations

import random

ADJECTIVES = [
    "Dancing", "Turbo", "Sneaky", "Mighty", "Wobbly", "Spicy", "Cosmic",
    "Grumpy", "Bouncy", "Sleepy", "Zooming", "Crispy", "Fluffy", "Jolly",
    "Ninja", "Captain", "Professor", "Doctor", "Agent", "Sergeant",
    "Whistling", "Galloping", "Invisible", "Legendary", "Curious", "Dramatic",
    "Caffeinated", "Speedy", "Gentle", "Roaring", "Silent", "Chatty",
    "Dizzy", "Fancy", "Glowing", "Heroic", "Iconic", "Jumpy", "Kindly",
    "Loopy", "Marvelous", "Nimble", "Oval", "Peppy", "Quirky", "Radiant",
    "Snoozy", "Twirling", "Upbeat", "Vibrant", "Wandering", "Xtra",
    "Yawning", "Zesty", "Breezy", "Chunky", "Daring", "Electric", "Frosty",
    "Golden",
]

NOUNS = [
    "Samosa", "Dosa", "Idli", "Vada", "Bonda", "Bhajji", "Pakoda",
    "Jalebi", "Laddu", "Barfi", "Chutney", "Rasam", "Pickle", "Papad",
    "Pigeon", "Parrot", "Peacock", "Squirrel", "Panda", "Penguin",
    "Koala", "Llama", "Otter", "Sparrow", "Tortoise", "Walrus",
    "Coconut", "Mango", "Banana", "Guava", "Papaya", "Jackfruit",
    "Cactus", "Bamboo", "Marigold", "Lotus", "Tulip", "Sunflower",
    "Scooter", "Cycle", "Rickshaw", "Rocket", "Umbrella", "Backpack",
    "Chalk", "Duster", "Notebook", "Compass", "Stapler", "Bench",
    "Filter", "Kettle", "Tumbler", "Thermos", "Lunchbox", "Tiffin",
    "Cloud", "Comet", "Meteor", "Galaxy",
]


def generate_alias(rng: random.Random | None = None) -> str:
    r = rng or random
    return f"{r.choice(ADJECTIVES)} {r.choice(NOUNS)}"
