# print((60*80*24*365.25*20/12))

# yo = 60*80*24*365.25*20/12
# total = 0
# for i in range(70128001):
#     total += i * 10**10

# print(total)

# 2458968156936000
# 10000000123456789012345678
# 24589682270640000000000000

# print((70128001) * (70128000) / 2)
# # (upper - lower + 1) * (first + last number) / 2
# # (this block - last block + 1) * (70128000 - (last block - first block) + 70128000 - (this block - first block))
# # (150 - 100 + 1)               * (70128000 - (100 - 50)                 + 70128000 - (150 - 50))
# # 51 * (70128000-50 + 70128000-100)
# print(51 * (70128000-50 + 70128000-100) / 2 * 10**10)
# total = 0
# for j in range(70128000-100, 70128000-50+1):
#     total += j * 10**10
# print(total)


blocknumber = 151
lastrewardblock = 150
startingblock = 150
print((blocknumber - lastrewardblock + 1) *
      (70128000 - (lastrewardblock - startingblock) + 70128000 - (blocknumber - startingblock)) / 2)

print((blocknumber - lastrewardblock + 1) *
      (2 * 70128000 - lastrewardblock - blocknumber + 2 * startingblock) / 2)

print((blocknumber - lastrewardblock + 1) *
      (2 * (70128000 + startingblock) - lastrewardblock - blocknumber) / 2)