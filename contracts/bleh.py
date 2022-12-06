from math import floor

invertedFee = 9999e18

exp = 10

currentReward = 0
fee = invertedFee

for i in range(exp):
    print("fee = (fee / 10000e18) * (invertedFee / 10000e18) * 10000e18")
    print("fee =", fee, "/ 10000e18) * (9999e18 / 10000e18) * 10000e18")
    print("fee =", fee / 10000e18, "*", 9999e18 / 10000e18, "*", 10000e18)
    print("fee =", fee / 10000e18, "*", 9999e18 / 10000e18 * 10000e18)
    print("fee =", fee / 10000e18 * (9999e18 / 10000e18) * 10000e18)
    fee = (fee / 10000e18) * (invertedFee / 10000e18) * 10000e18
    currentReward += fee
    print(fee, currentReward / 1e18)
invertedFee = fee
print(invertedFee)



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
