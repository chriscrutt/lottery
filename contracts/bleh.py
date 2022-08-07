yo = 21000000000000000000000000
i = yo * 0.03
counter = 0
all = 0

while i >= 1:
    print(i, yo, counter, counter / 365, all)
    all += i
    counter += 1
    yo = yo - i
    i = yo * 0.03