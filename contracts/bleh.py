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
# for i in range(1000):
#     totalCoinsRewarded += rewardsPerSecond
#     print(rewardsPerSecond, totalCoinsRewarded / 1e18, i)
#     rewardsPerSecond *= 0.999
#     if rewardsPerSecond <= 1:
#         break

# print(rewardsPerSecond, totalCoinsRewarded / 1e18)

yo = []
for i in range(0, 401, 2):
    yo.append(i)

print(yo)