board = [[0,0,4,8,6,0,0,3,0], 
         [0,0,1,0,0,0,0,9,0], 
         [8,0,0,0,0,9,0,6,0], 
         [5,0,0,2,0,6,0,0,1], 
         [0,2,7,0,0,1,0,0,0], 
         [0,0,0,0,4,3,0,0,6], 
         [0,5,0,0,0,0,0,0,0], 
         [0,0,9,0,0,0,4,0,0], 
         [0,0,0,4,0,0,0,1,5]]


def checkRow(num, rowNum):
    if num in board[rowNum]:
        return False
    else:
        return True


def checkColumn(num, columnNum):
    for i in board:
        if num == i[columnNum]:
            return False
    return True


def checkSquare(num, rowNum, columnNum):
    if rowNum < 3:
        if columnNum < 3:
            for i in range(3):
                for j in range(3):
                    if num == board[i][j]:
                        return False
        elif columnNum < 6:
            for i in range(3):
                for j in range(3, 6):
                    if num == board[i][j]:
                        return False
        else:
            for i in range(3):
                for j in range(6, 9):
                    if num == board[i][j]:
                        return False

    elif rowNum < 6:
        if columnNum < 3:
            for i in range(3, 6):
                for j in range(3):
                    if num == board[i][j]:
                        return False
        elif columnNum < 6:
            for i in range(3, 6):
                for j in range(3, 6):
                    if num == board[i][j]:
                        return False
        else:
            for i in range(3, 6):
                for j in range(6, 9):
                    if num == board[i][j]:
                        return False

    else:
        if columnNum < 3:
            for i in range(6, 9):
                for j in range(3):
                    if num == board[i][j]:
                        return False
        elif columnNum < 6:
            for i in range(6, 9):
                for j in range(3, 6):
                    if num == board[i][j]:
                        return False
        else:
            for i in range(6, 9):
                for j in range(6, 9):
                    if num == board[i][j]:
                        return False

    return True


def main():
    for i in range(9):
        for j in range(9):
            if board[i][j] == 0:
                tmpNum = 0
                for k in range(1, 10):
                    if checkRow(k, i) and checkColumn(k, j) and checkSquare(k, i, j):
                        if tmpNum == 0:
                            tmpNum = k
                        else:
                            tmpNum = 0
                            break
                board[i][j] = tmpNum


def checkForZeros():
    for i in board:
        if 0 in i:
            return True
    return False


def fin():
    print(board)
    while checkForZeros():
        main()
        print(board)

fin()


# if 1 in board[0]:
#     print(True)
# else:
#     print(False)
