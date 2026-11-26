import random

from app.alias import ADJECTIVES, NOUNS, generate_alias


def test_pools_are_big_enough():
    assert len(ADJECTIVES) >= 55
    assert len(NOUNS) >= 55
    assert len(set(ADJECTIVES)) == len(ADJECTIVES)
    assert len(set(NOUNS)) == len(NOUNS)


def test_alias_format():
    alias = generate_alias(random.Random(1))
    adj, noun = alias.split(" ", 1)
    assert adj in ADJECTIVES
    assert noun in NOUNS


def test_alias_variety():
    rng = random.Random(7)
    aliases = {generate_alias(rng) for _ in range(200)}
    assert len(aliases) > 150  # collisions should be rare
