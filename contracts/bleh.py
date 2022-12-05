# yo = 21000000000000000000000000
# i = yo * 0.03
# counter = 0
# all = 0

# while i >= 1:
#     print(i, yo, counter, counter / 365, all)
#     all += i
#     counter += 1
#     yo = yo - i
#     i = yo * 0.03
# rewardsPerSecond = 21e18
# totalCoinsRewarded = 0
# for i in range(3652*200000):
#     totalCoinsRewarded += rewardsPerSecond
#     print(rewardsPerSecond, totalCoinsRewarded / 1e18, i)
#     rewardsPerSecond *= 0.999
#     if rewardsPerSecond <= 1:
#         break

# print(rewardsPerSecond, totalCoinsRewarded / 1e18)

import random
# from math import round

whimsicalCharacters = ["Rupert (Mime)", "Sandy (Ventriloquist)", "Roberta (Fairy)", "Sidney (Barbie Girl Living in a Barbie World)"]

# print(round(random.random()))

print("4 jolly good friends get on 'the ride'... who will survive???")

for dude in whimsicalCharacters:
    if round(random.random()) == 0:
        print(dude, "sadly died on the rollercoaster known as life.")
    else:
        print(dude, "made it! But there's always tomorrow!")