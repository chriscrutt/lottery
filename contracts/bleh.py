from math import floor

rewardsPerSecond = 1e18
totalCoinsRewarded = 0
for i in range(7304000):
    totalCoinsRewarded += rewardsPerSecond
    print(rewardsPerSecond, totalCoinsRewarded / 1e18, i)
    rewardsPerSecond *= 0.9999
    if rewardsPerSecond <= 1:
        break

print(rewardsPerSecond, floor(totalCoinsRewarded / 1e18))


# tokensLeft = 21000000e18
# reward = 21000000e18
# totalRewards = 0
# i = 0
# while reward > 99:
#     reward = tokensLeft / 100
#     totalRewards += reward
#     tokensLeft -= reward
#     i += 1
#     print(reward, totalRewards, tokensLeft, i)


# import random
# # from math import round

# whimsicalCharacters = ["Rupert (Mime)", "Sandy (Ventriloquist)", "Roberta (Fairy)", "Sidney (Barbie Girl Living in a Barbie World)"]

# # print(round(random.random()))

# print("4 jolly good friends get on 'the ride'... who will survive???")

# for dude in whimsicalCharacters:
#     if round(random.random()) == 0:
#         print(dude, "sadly died on the rollercoaster known as life.")
#     else:
#         print(dude, "made it! But there's always tomorrow!")
